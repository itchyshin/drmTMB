args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 7L) stop("Usage: Rscript combine-stage-two.R FIRST_LOOK BATCH1 BATCH2 BATCH3 EXTERNAL_SEALS EXTERNAL_SEALS_SHA256 OUTPUT")
first <- normalizePath(args[[1L]], mustWork = TRUE)
batches <- lapply(args[2:4], normalizePath, mustWork = TRUE)
seals_path <- normalizePath(args[[5L]],mustWork=TRUE)
if(digest::digest(seals_path,algo="sha256",file=TRUE)!=args[[6L]]) stop("External seal file digest mismatch")
seals <- jsonlite::fromJSON(seals_path, simplifyVector = TRUE)
out <- args[[7L]]
if (file.exists(out)) stop("Refusing to overwrite combined output")
if (!requireNamespace("digest", quietly=TRUE) || !requireNamespace("jsonlite", quietly=TRUE)) stop("digest and jsonlite are required")
staged_path <- normalizePath(seals$staged_decision_path, mustWork=TRUE)
if (digest::digest(staged_path,algo="sha256",file=TRUE) != seals$staged_decision_sha256) stop("Staged analyzer source digest mismatch")
rules_path <- normalizePath(seals$adapter_rules_path,mustWork=TRUE)
if (digest::digest(rules_path,algo="sha256",file=TRUE) != seals$adapter_rules_sha256) stop("Adapter rule source digest mismatch")
source(rules_path)
native_sd_stage_two_validate_reconstruction_sources(dirname(rules_path),
                                                   seals$first_look_reconstruction_source_sha256)
source(staged_path)
hash_file <- function(p) digest::digest(p, algo="sha256", file=TRUE)
attempt_digest <- function(d, expected_results = NULL, expected_indices = NULL,
                           allowed_indices = NULL) {
  native_sd_stage_two_attempt_digest(d, expected_results = expected_results,
                                     expected_indices = expected_indices,
                                     allowed_indices = allowed_indices)
}
verify_registry <- function(d, expected) {
  native_sd_stage_two_verify_registry(d, expected)
}
native_sd_stage_two_preserve_source_identity <- function(attempts, manifest,
                                                          source_manifest_path,
                                                          batch_id) {
  native_sd_stage_two_validate_clean_current_batch(
    manifest, source_manifest_path, batch_id)
  local_index <- as.integer(attempts$attempt_index) - as.integer(batch_id) * 3000L
  manifest_row <- match(local_index, as.integer(manifest$index))
  if (anyNA(manifest_row) || anyDuplicated(local_index) ||
      any(as.character(manifest$source_design_mode[manifest_row]) != "clean_current")) {
    stop("Combined attempts do not map to clean-current source rows", call. = FALSE)
  }
  attempts$source_index <- as.integer(manifest$source_index[manifest_row])
  attempts$stage_two_index <- as.integer(manifest$stage_two_index[manifest_row])
  attempts$source_design_mode <- as.character(manifest$source_design_mode[manifest_row])
  attempts$source_manifest_sha256 <- rep(hash_file(source_manifest_path), nrow(attempts))
  attempts
}
verify_registry(first, seals$first_look_registry_sha256)
if(attempt_digest(first, expected_results=3000L)!=seals$first_look_attempts_sha256) stop("First-look attempt output seal mismatch")
prepared_root <- dirname(batches[[1L]])
root_receipt_path <- file.path(prepared_root,"root-preparation-receipt.json")
if(hash_file(root_receipt_path)!=seals$root_preparation_receipt_sha256) stop("Prepared-root receipt seal mismatch")
root_receipt <- jsonlite::fromJSON(root_receipt_path,simplifyVector=TRUE)
if(root_receipt$status!="prepared_not_launched" || !isTRUE(root_receipt$no_fits_launched)) stop("Prepared-root receipt state mismatch")
if(root_receipt$first_look_seal_sha256!=seals$first_look_seal_sha256 ||
   hash_file(file.path(prepared_root,"first-look-standardized.csv"))!=root_receipt$first_look_standardized_sha256 ||
   hash_file(file.path(prepared_root,"first-look-replay-receipt.json"))!=root_receipt$first_look_replay_receipt_sha256) stop("Prepared first-look replay artifacts are not root-receipt-bound")
if(root_receipt$go_record_sha256!=seals$go_record_sha256 || root_receipt$harness_archive_sha256!=seals$harness_archive_sha256 ||
   root_receipt$first_look_registry_sha256!=seals$first_look_registry_sha256 || root_receipt$first_look_decision_sha256!=seals$first_look_decision_sha256) stop("Prepared-root provenance differs from external seals")
root_batch_map <- setNames(as.character(root_receipt$batches$registry_sha256),as.character(root_receipt$batches$batch_id))
seal_batch_map <- unlist(seals$batch_registry_sha256)
if(!identical(root_batch_map[sort(names(root_batch_map))],seal_batch_map[sort(names(seal_batch_map))])) stop("Prepared-root batch registry list differs from external seals")
run_receipt_path <- file.path(prepared_root,"stage-two-run-receipt.json")
if(hash_file(run_receipt_path)!=seals$stage_two_run_receipt_sha256) stop("Stage-two run receipt seal mismatch")
run_receipt <- jsonlite::fromJSON(run_receipt_path,simplifyVector=TRUE)
if(run_receipt$status!="all_batches_terminal" || !isTRUE(run_receipt$no_retries)) stop("Stage-two run receipt is incomplete")
if(!native_sd_stage_two_deadline_ok(run_receipt$started_epoch,run_receipt$deadline_epoch,
                                    as.numeric(Sys.time()),10500)) stop("Whole stage-two run-plus-combine deadline expired or is invalid")
if(run_receipt$external_seals_sha256!=seals$run_authorization_seals_sha256) stop("Stage-two run receipt names a different run-authorization seal")
if(!identical(as.character(run_receipt$go_record_sha256),as.character(seals$go_record_sha256))) stop("Run receipt GO provenance differs from combination seal")
run_batches <- as.data.frame(run_receipt$batches,stringsAsFactors=FALSE)
run_batch_map <- setNames(as.character(run_batches$attempts_sha256),as.character(run_batches$batch_id))
if(!native_sd_stage_two_hash_maps_equal(run_batch_map,seals$batch_attempt_sha256)) stop("Run receipt batch attempts differ from combination seal")
first_decision_path <- normalizePath(seals$first_look_decision_path, mustWork=TRUE)
if(hash_file(first_decision_path) != seals$first_look_decision_sha256) stop("First-look decision seal mismatch")
first_decision_text <- paste(readLines(first_decision_path,warn=FALSE),collapse="\n")
if(!grepl("look2_required",first_decision_text,fixed=TRUE)) stop("First-look decision is not look2_required")
go <- jsonlite::fromJSON(seals$go_record_path)
if(go$decision != "look2_required" || hash_file(seals$go_record_path) != seals$go_record_sha256) stop("GO record identity/decision mismatch")
if(go$first_look_registry_sha256 != seals$first_look_registry_sha256 || go$first_look_decision_sha256 != seals$first_look_decision_sha256) stop("GO record does not bind first look")
read_attempts <- function(d, expected_mode="production", expected_master=NULL, offset=0L) {
  batch_id <- if(offset==0L) NULL else native_sd_stage_two_batch_id(offset)
  expected_registry <- if(offset==0L) seals$first_look_registry_sha256 else native_sd_stage_two_registry_for_offset(offset,seals$batch_registry_sha256)
  verify_registry(d, expected_registry)
  m <- read.csv(file.path(d,"manifest.csv"),stringsAsFactors=FALSE)
  sup <- jsonlite::fromJSON(file.path(d,"supervisor-receipt.json"),simplifyVector=TRUE)
  if(length(m$index)!=3000L || !identical(as.integer(m$index),1:3000)) stop("Wrong batch manifest index range")
  clean_current <- offset > 0L &&
    "design_mode" %in% names(m) &&
    all(as.character(m$design_mode) == "clean_current_stage_two")
  expected_master <- if(offset==0L) 2026101703L else if(clean_current) 2026101902L else 2026101705L
  expected_mode <- if(offset==0L || !clean_current) "production" else "clean_current_stage_two"
  if(any(m$master_seed != expected_master) || any(m$design_mode != expected_mode)) stop("Manifest master seed/design mode mismatch")
  if(offset>0L) {
    batch_id <- offset %/% 3000L
    h <- read.csv(file.path(d,"source-hashes.csv"),stringsAsFactors=FALSE)
    if(clean_current) {
      source_path <- h$path[basename(h$path)=="look2.csv"]
      if(length(source_path)!=1L) stop("Clean-current source manifest path is missing or ambiguous")
      native_sd_stage_two_validate_clean_current_batch(m, source_path, batch_id)
      conversion_path <- file.path(d, "conversion-receipt.json")
      if (!file.exists(conversion_path)) stop("Clean-current conversion receipt is missing")
      conversion <- jsonlite::fromJSON(conversion_path, simplifyVector = TRUE)
      native_sd_stage_two_validate_clean_current_receipt(
        conversion, m, hash_file(conversion_path), hash_file(file.path(d, "manifest.csv")),
        root_receipt, seals$go_record_sha256)
    } else {
      if(!identical(as.integer(m$stage_two_index),(batch_id-1L)*3000L+1:3000) ||
         !identical(as.integer(m$replicate),1000L+1:3000) || any(m$batch_id!=batch_id)) stop("Stage-two global row mapping mismatch")
      map <- jsonlite::fromJSON(file.path(d,"conversion-receipt.json"))
      if(map$batch_id!=batch_id || map$source_row_start!=(batch_id-1L)*3000L+1L ||
         map$source_row_end!=batch_id*3000L || map$manifest_sha256!=hash_file(file.path(d,"manifest.csv")) ||
         map$go_record_sha256!=seals$go_record_sha256) stop("Batch conversion receipt mismatch")
      seed_path <- h$path[basename(h$path)=="stage-two-manifest.csv"]
      if(length(seed_path)!=1L || hash_file(seed_path)!="8fd627ccb8a7f8689c56e629a5ff12e53405be1a508167216632bcf445652e96") stop("Frozen stage-two source manifest pin mismatch")
      source_rows <- read.csv(seed_path,stringsAsFactors=FALSE)
      src <- source_rows[match(as.integer(m$stage_two_index),as.integer(source_rows$index)),,drop=FALSE]
      if(nrow(src)!=3000L || anyNA(src$index) || !identical(as.integer(src$index),as.integer(m$stage_two_index))) stop("Stage-two source rows are missing or reordered")
      compare_cols <- setdiff(names(source_rows),c("index","master_seed","design_mode"))
      for(nm in compare_cols) if(!isTRUE(all.equal(as.character(m[[nm]]),as.character(src[[nm]]),tolerance=0))) stop("Stage-two source mapping differs in ",nm)
    }
  }
  if(sup$registry_sha256!=expected_registry || sup$manifest_sha256!=hash_file(file.path(d,"manifest.csv")) ||
     !identical(as.integer(unlist(sup$planned_indices)),1:3000)) stop("Supervisor receipt identity mismatch")
  if(!native_sd_stage_two_terminal_receipt(sup)) stop("Supervisor receipt is not complete and terminal")
  if(!isTRUE(sup$campaign_complete) || isTRUE(sup$interrupted) || !isTRUE(sup$subset_complete)) stop("Batch supervisor is incomplete")
  cases <- as.data.frame(sup$cases,stringsAsFactors=FALSE)
  state <- setNames(as.character(cases$status),as.character(cases$index)); code <- setNames(as.integer(cases$returncode),as.character(cases$index))
  if(anyDuplicated(cases$index) || nrow(cases)!=3000L || !setequal(as.integer(names(state)),1:3000) || any(!state %in% c("completed","error","timeout"))) stop("Batch has unresolved attempt statuses")
  if(offset>0L) {
    completed_indices <- as.integer(cases$index[cases$status=="completed"])
    if(attempt_digest(d,expected_indices=completed_indices,allowed_indices=1:3000)!=seals$batch_attempt_sha256[[as.character(native_sd_stage_two_batch_id(offset))]]) stop("Stage-two raw attempt output seal mismatch")
  }
  files <- list.files(d,pattern="^result-[0-9]{4}\\.csv$",full.names=TRUE)
  rr <- if(length(files)) do.call(rbind,lapply(files,read.csv,stringsAsFactors=FALSE)) else data.frame()
  if (nrow(rr)) native_sd_stage_two_validate_profile_level(rr, expected = 0.95)
  if(nrow(rr) && (anyDuplicated(rr$index)||any(!rr$index %in% 1:3000))) stop("Duplicate or out-of-range result identity")
  by <- if(nrow(rr)) setNames(split(rr,rr$index),as.character(rr$index)) else list()
  for(f in files) {
    v <- read.csv(f,stringsAsFactors=FALSE)
    if(nrow(v)!=1L || basename(f)!=sprintf("result-%04d.csv",as.integer(v$index[[1L]]))) stop("Result filename/index mismatch")
  }
  for(k in names(by)) {
    v <- by[[k]]; row <- m[match(as.integer(k),m$index),]
    if(nrow(v)!=1L) stop("Duplicate result index")
    if(v$seed[[1L]]!=row$seed || v$a[[1L]]!=row$a || v$replicate[[1L]]!=row$replicate) stop("Worker identity differs from manifest")
    if(isTRUE(v$valid_interval[[1L]]) && state[[k]]!="completed") stop("Valid interval reported for failed worker status")
  }
  for(i in 1:3000) if(state[[as.character(i)]]=="completed" && (!as.character(i) %in% names(by) || code[[as.character(i)]]!=0L)) stop("Completed attempt lacks successful result")
  rows <- lapply(1:3000,function(i) {
    k<-as.character(i); v<-by[[k]]; status<-state[[k]]
    estimate<-if(!is.null(v)&&is.finite(v$estimate[[1L]]))as.numeric(v$estimate[[1L]])else NA_real_
    lower<-if(!is.null(v)&&is.finite(v$lower[[1L]]))as.numeric(v$lower[[1L]])else NA_real_
    upper<-if(!is.null(v)&&is.finite(v$upper[[1L]]))as.numeric(v$upper[[1L]])else NA_real_
    profile_level<-if(!is.null(v)&&"profile_level"%in%names(v))as.numeric(v$profile_level[[1L]])else NA_real_
    valid<-!is.null(v)&&status=="completed"&&code[[k]]==0L&&v$state[[1L]]=="completed"&&isTRUE(v$valid_interval[[1L]])&&isTRUE(v$oracle_pass[[1L]])&&is.finite(v$laplace_oracle_error[[1L]])&&abs(v$laplace_oracle_error[[1L]])<1e-6&&v$convergence[[1L]]==0L&&isTRUE(v$pdHess[[1L]])&&is.finite(v$max_abs_gradient[[1L]])&&v$max_abs_gradient[[1L]]<1e-3&&v$clamp_at_optimum[[1L]]=="ok"&&v$interval_status[[1L]]=="profile"&&identical(v$profile_boundary[[1L]],FALSE)&&is.finite(lower)&&is.finite(upper)&&lower<upper&&(!nzchar(v$error[[1L]])||is.na(v$error[[1L]]))
    data.frame(look=if(offset==0L)1L else 2L,attempt_index=offset+i,source_index=if(offset==0L)i else as.integer(m$stage_two_index[[i]]),truth=as.numeric(m$a[[i]]),estimate=estimate,lower=lower,upper=upper,profile_level=profile_level,valid=isTRUE(valid),status=status,stringsAsFactors=FALSE)
  })
  attempts <- do.call(rbind,rows)
  if(clean_current) {
    attempts <- native_sd_stage_two_preserve_source_identity(
      attempts, m, source_path, batch_id)
  }
  attempts
}
# Recompute and compare the first-look decision using the retained frozen
# manifest and raw worker records. Saved decision is evidence, not an oracle.
first_attempts <- read_attempts(first,offset=0L)
first_recomputed <- native_sd_staged_decision(first_attempts[c("truth","estimate","lower","upper","profile_level","valid","status")],3000L,1L,TRUE)
saved <- readRDS(file.path(first,"staged-decision.rds"))
if(!identical(first_recomputed$decision,saved$decision)||first_recomputed$decision!="look2_required") stop("Recomputed first-look decision disagrees with the retained evidence")
if(!native_sd_stage_two_metrics_equal(first_recomputed$metrics,saved$metrics,tolerance=1e-12) ||
   !identical(first_recomputed$gates,saved$gates) ||
   !identical(first_recomputed$status_counts,saved$status_counts)) stop("Recomputed first-look standardized metrics differ from retained evidence")
prepared_attempts <- read.csv(file.path(prepared_root,"first-look-standardized.csv"),stringsAsFactors=FALSE)
if(!native_sd_stage_two_attempts_equal(first_attempts,prepared_attempts,tolerance=1e-12)) stop("First-look raw attempt replay differs from prelaunch standardized receipt")
parts <- lapply(seq_along(batches),function(i) read_attempts(batches[[i]],offset=i*3000L))
second <- do.call(rbind,parts)
if(any(vapply(parts,nrow,integer(1L))!=3000L)) stop("Each second-look batch must contain 3,000 planned attempts")
if (any(!names(first_attempts) %in% names(second))) {
  stop("First-look attempts contain fields absent from second-look attempts",
       call. = FALSE)
}
for (name in setdiff(names(second), names(first_attempts))) {
  prototype <- second[[name]]
  missing <- if (is.character(prototype)) NA_character_ else if (is.integer(prototype)) {
    NA_integer_
  } else if (is.logical(prototype)) {
    NA
  } else {
    NA_real_
  }
  first_attempts[[name]] <- rep(missing, nrow(first_attempts))
}
first_attempts <- first_attempts[names(second)]
attempts <- rbind(first_attempts, second)
if(nrow(attempts)!=12000L || anyDuplicated(attempts$attempt_index)) stop("Combined all-attempt denominator is not exactly 12,000")
truth_counts <- table(factor(attempts$truth,levels=c(-.5,0,.5)))
if(!identical(as.integer(truth_counts),rep(4000L,3L))) stop("Combined manifest must contain 4,000 attempts per truth")
decision <- native_sd_staged_decision(attempts[c("truth","estimate","lower","upper","profile_level","valid","status")],12000L,2L,TRUE)
if(!native_sd_stage_two_deadline_ok(run_receipt$started_epoch,run_receipt$deadline_epoch,
                                    as.numeric(Sys.time()),10500)) stop("Whole stage-two run-plus-combine deadline expired during combination")
dir.create(out,recursive=FALSE)
write.csv(attempts,file.path(out,"all-attempts.csv"),row.names=FALSE)
saveRDS(decision,file.path(out,"staged-decision.rds"))
write.csv(decision$metrics,file.path(out,"staged-metrics.csv"),row.names=FALSE)
write.csv(decision$gates,file.path(out,"staged-gates.csv"),row.names=FALSE)
receipt<-list(decision=decision$decision,look=2L,manifest_count=12000L,counts=as.list(table(attempts$status)),first_look_recomputed=first_recomputed$decision,all_attempts_sha256=hash_file(file.path(out,"all-attempts.csv")),decision_sha256=hash_file(file.path(out,"staged-decision.rds")),first_look_registry_sha256=seals$first_look_registry_sha256,batch_registry_sha256=seals$batch_registry_sha256,go_record_sha256=seals$go_record_sha256)
writeLines(jsonlite::toJSON(receipt,auto_unbox=TRUE,pretty=TRUE),file.path(out,"decision-receipt.json"))
if(!native_sd_stage_two_deadline_ok(run_receipt$started_epoch,run_receipt$deadline_epoch,
                                    as.numeric(Sys.time()),10500)) stop("Whole stage-two run-plus-combine deadline expired before combination receipt completion")
native_sd_stage_two_emit_completion(decision$decision)
