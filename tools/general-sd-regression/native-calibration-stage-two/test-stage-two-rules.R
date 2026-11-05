args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Supply stage-two adapter directory")
source(file.path(args[[1L]], "stage-two-rules.R"))
repo_root <- normalizePath(file.path(args[[1L]], "../../.."), mustWork = TRUE)
frozen_look2 <- file.path(repo_root, "docs/dev-log/general-sd-regression/evidence",
                          "calibration-20261019/clean-current-seed-design-v1/look2.csv")
source_look2 <- read.csv(frozen_look2, stringsAsFactors = FALSE, check.names = FALSE)
clean_first_look <- data.frame(
  index = seq_len(3000L),
  a = rep(c(-0.5, 0, 0.5), each = 1000L),
  replicate = rep(seq_len(1000L), 3L),
  seed = seq_len(3000L) + 9000000L,
  groups = rep(160L, 3000L), repeats = rep(16L, 3000L),
  beta0 = rep(-0.3, 3000L), beta1 = rep(0.6, 3000L),
  alpha0 = rep(-0.22314355131421, 3000L),
  design_mode = rep("clean_current", 3000L),
  master_seed = rep(2026101901L, 3000L), look = rep("look1", 3000L)
)
stopifnot(isTRUE(native_sd_stage_two_validate_first_look_manifest(clean_first_look)))
for (mutate in list(
  function(x) { x$master_seed[[1L]] <- 2026101902L; x },
  function(x) { x$design_mode[[1L]] <- "production"; x },
  function(x) { x$look[[1L]] <- "look2"; x },
  function(x) { x$index[[1L]] <- 2L; x },
  function(x) { x$seed[[2L]] <- x$seed[[1L]]; x }
)) {
  bad_first_look <- mutate(clean_first_look)
  stopifnot(inherits(try(native_sd_stage_two_validate_first_look_manifest(
    bad_first_look), silent = TRUE), "try-error"))
}
legacy_first_look <- clean_first_look
legacy_first_look$design_mode[] <- "production"
legacy_first_look$master_seed[] <- 2026101703L
legacy_first_look$replicate <- legacy_first_look$replicate + 1000L
legacy_first_look$look <- NULL
stopifnot(isTRUE(native_sd_stage_two_validate_first_look_manifest(legacy_first_look)))
make_clean_stage_two_batch <- function(batch_id) {
  start <- (batch_id - 1L) * 3000L
  batch <- source_look2[start + seq_len(3000L), , drop = FALSE]
  batch$stage_two_index <- batch$index
  batch$source_index <- batch$index
  batch$source_design_mode <- batch$design_mode
  batch$index <- seq_len(3000L)
  batch$batch_id <- batch_id
  batch$design_mode <- "clean_current_stage_two"
  batch
}
clean_stage_two <- make_clean_stage_two_batch(2L)
stopifnot(isTRUE(native_sd_stage_two_validate_clean_current_batch(
  clean_stage_two, frozen_look2, 2L)))
qualification_receipt <- list(
  design_mode = "clean_current_stage_two",
  master_seed = "2026101902",
  profile_level = "0.95",
  planned_attempts = "3000",
  calibration_claim = "false",
  clean_current_seed_stream = "2026101902",
  stage_two_manifest_sha256 =
    "7920b4d482d599828bffe4f6333661afcae6d6efea411758b03d2f0a263e1b98",
  stage_two_batch_id = "2",
  stage_two_status = "adapter_qualification_only_no_final_go",
  adapter_qualification_only = "true",
  qualification_local_index = "1001",
  qualification_stage_two_index = "4001"
)
stopifnot(isTRUE(native_sd_stage_two_validate_worker_receipt(
  qualification_receipt, clean_stage_two, 1001L)))
for (mutate in list(
  function(x) { x$calibration_claim <- "true"; x },
  function(x) { x$qualification_stage_two_index <- "4002"; x },
  function(x) { x$qualification_local_index <- "1002"; x },
  function(x) { x$adapter_qualification_only <- "false"; x }
)) {
  bad_receipt <- mutate(qualification_receipt)
  stopifnot(inherits(try(native_sd_stage_two_validate_worker_receipt(
    bad_receipt, clean_stage_two, 1001L), silent = TRUE), "try-error"))
}
production_receipt <- qualification_receipt
production_receipt$adapter_qualification_only <- "false"
production_receipt$calibration_claim <- "true"
production_receipt$stage_two_status <- "authorized_by_external_go_record"
stopifnot(isTRUE(native_sd_stage_two_validate_worker_receipt(
  production_receipt, clean_stage_two, seq_len(3000L))))
production_receipt$calibration_claim <- "false"
stopifnot(inherits(try(native_sd_stage_two_validate_worker_receipt(
  production_receipt, clean_stage_two, seq_len(3000L)), silent = TRUE), "try-error"))
for (mutate in list(
  function(x) { x$seed[[1L]] <- x$seed[[1L]] + 1L; x },
  function(x) { x$stage_two_index[[1L]] <- x$stage_two_index[[1L]] + 1L; x },
  function(x) { x$batch_id[[1L]] <- 1L; x },
  function(x) { x$master_seed[[1L]] <- x$master_seed[[1L]] + 1L; x },
  function(x) { x$design_mode[[1L]] <- "clean_current"; x },
  function(x) { x$look <- NULL; x },
  function(x) { x$unexpected <- 1L; x },
  function(x) x[-1L, , drop = FALSE]
)) {
  bad_batch <- mutate(clean_stage_two)
  stopifnot(inherits(try(native_sd_stage_two_validate_clean_current_batch(
    bad_batch, frozen_look2, 2L), silent = TRUE), "try-error"))
}
good_profile_levels <- data.frame(profile_level = rep(0.95, 3L))
stopifnot(isTRUE(native_sd_stage_two_validate_profile_level(good_profile_levels)))
bad_profile_levels <- list(
  data.frame(estimate = 1:3),
  data.frame(profile_level = rep(0.975, 3L)),
  data.frame(profile_level = c(0.95, 0.975, 0.95)),
  data.frame(profile_level = c(0.95, NA_real_, 0.95)),
  data.frame(profile_level = c(0.95, Inf, 0.95))
)
stopifnot(all(vapply(bad_profile_levels, function(x) inherits(try(
  native_sd_stage_two_validate_profile_level(x), silent = TRUE), "try-error"),
  logical(1L))))
stopifnot(identical(native_sd_stage_two_completion_result("accept"),
                    list(status = 0L, marker = "STAGE_TWO_COMBINE_COMPLETE accept")),
          identical(native_sd_stage_two_completion_result("fail"),
                    list(status = 0L, marker = "STAGE_TWO_COMBINE_COMPLETE fail")),
          identical(native_sd_stage_two_completion_result("inconclusive"),
                    list(status = 0L, marker = "STAGE_TWO_COMBINE_COMPLETE inconclusive")),
          identical(native_sd_stage_two_completion_result("incomplete"),
                    list(status = 2L, marker = "STAGE_TWO_COMBINE_NONQUALIFYING incomplete")),
          identical(native_sd_stage_two_completion_result("integrity_failure"),
                    list(status = 2L, marker = "STAGE_TWO_COMBINE_NONQUALIFYING integrity_failure")),
          identical(native_sd_stage_two_completion_result("unknown_state"),
                    list(status = 2L, marker = "STAGE_TWO_COMBINE_NONQUALIFYING unknown_state")))
valid_output <- capture.output(valid_result <- try(
  native_sd_stage_two_emit_completion("accept"), silent = TRUE))
invalid_output <- capture.output(invalid_result <- try(
  native_sd_stage_two_emit_completion("integrity_failure"), silent = TRUE))
unknown_output <- capture.output(unknown_result <- try(
  native_sd_stage_two_emit_completion("unknown_state"), silent = TRUE))
stopifnot(!inherits(valid_result, "try-error"), identical(valid_result, 0L),
          identical(valid_output, "STAGE_TWO_COMBINE_COMPLETE accept"),
          inherits(invalid_result, "try-error"),
          grepl("nonqualifying", as.character(invalid_result)[[1L]]),
          identical(invalid_output,
                    "STAGE_TWO_COMBINE_NONQUALIFYING integrity_failure"),
          inherits(unknown_result, "try-error"),
          identical(unknown_output,
                    "STAGE_TWO_COMBINE_NONQUALIFYING unknown_state"))
tmp_attempts <- tempfile("attempt-digest-"); dir.create(tmp_attempts)
writeLines("index", file.path(tmp_attempts,"manifest.csv"))
writeLines("{}", file.path(tmp_attempts,"supervisor-receipt.json"))
for(i in 1:3) writeLines(c("index",as.character(i)),file.path(tmp_attempts,sprintf("result-%04d.csv",i)))
full_digest <- native_sd_stage_two_attempt_digest(tmp_attempts,expected_results=3L)
stopifnot(nchar(full_digest)==64L)
unlink(file.path(tmp_attempts,"result-0002.csv"))
missing_digest <- try(native_sd_stage_two_attempt_digest(tmp_attempts,expected_results=3L),silent=TRUE)
stopifnot(inherits(missing_digest,"try-error"))
writeLines(c("index","2"),file.path(tmp_attempts,"result-0002.csv"))
writeLines(c("index","4"),file.path(tmp_attempts,"result-0004.csv"))
extra_digest <- try(native_sd_stage_two_attempt_digest(tmp_attempts,expected_results=3L),silent=TRUE)
stopifnot(inherits(extra_digest,"try-error"))
unlink(file.path(tmp_attempts,"result-0002.csv")); unlink(file.path(tmp_attempts,"result-0003.csv")); unlink(file.path(tmp_attempts,"result-0004.csv"))
writeLines(c("index","1"),file.path(tmp_attempts,"result-0001.csv"))
writeLines(c("index","2","partial"),file.path(tmp_attempts,"result-0002.csv"))
writeLines(c("index","3","failed"),file.path(tmp_attempts,"result-0003.csv"))
completed_digest <- native_sd_stage_two_attempt_digest(tmp_attempts,expected_indices=1L,
                                                       allowed_indices=1:3)
stopifnot(nchar(completed_digest)==64L)
unlink(file.path(tmp_attempts,"result-0003.csv"))
absent_failed_result_digest <- native_sd_stage_two_attempt_digest(
  tmp_attempts,expected_indices=1L,allowed_indices=1:3)
stopifnot(nchar(absent_failed_result_digest)==64L)
unlink(file.path(tmp_attempts,"result-0001.csv"))
missing_completed <- try(native_sd_stage_two_attempt_digest(tmp_attempts,expected_indices=1L,
                                                            allowed_indices=1:3),silent=TRUE)
writeLines(c("index","1"),file.path(tmp_attempts,"result-0001.csv"))
writeLines(c("index","4"),file.path(tmp_attempts,"result-0004.csv"))
out_of_range <- try(native_sd_stage_two_attempt_digest(tmp_attempts,expected_indices=1L,
                                                       allowed_indices=1:3),silent=TRUE)
unlink(file.path(tmp_attempts,"result-0004.csv"))
writeLines(c("index","1"),file.path(tmp_attempts,"result-10000.csv"))
malformed_result_name <- try(native_sd_stage_two_attempt_digest(
  tmp_attempts,expected_indices=1L,allowed_indices=1:3),silent=TRUE)
unlink(file.path(tmp_attempts,"result-10000.csv"))
both_index_contracts <- try(native_sd_stage_two_attempt_digest(tmp_attempts,expected_results=3L,
                                                               expected_indices=1:3),silent=TRUE)
stopifnot(inherits(missing_completed,"try-error"),inherits(out_of_range,"try-error"),
          inherits(malformed_result_name,"try-error"),
          inherits(both_index_contracts,"try-error"))
unlink(tmp_attempts,recursive=TRUE)
registry_source <- tempfile("registry-source-"); dir.create(registry_source)
registry_copy <- tempfile("registry-copy-"); dir.create(registry_copy)
writeLines(c("index","1"),file.path(registry_source,"manifest.csv"))
file.copy(file.path(registry_source,"manifest.csv"),file.path(registry_copy,"manifest.csv"))
write.csv(data.frame(path=file.path(registry_source,"manifest.csv"),
                     sha256=digest::digest(file.path(registry_source,"manifest.csv"),algo="sha256",file=TRUE)),
          file.path(registry_copy,"source-hashes.csv"),row.names=FALSE)
registry_hash <- digest::digest(file.path(registry_copy,"source-hashes.csv"),algo="sha256",file=TRUE)
stopifnot(isTRUE(native_sd_stage_two_verify_registry(registry_copy,registry_hash)))
writeLines(c("index","2"),file.path(registry_copy,"manifest.csv"))
copied_manifest_mismatch <- try(native_sd_stage_two_verify_registry(registry_copy,registry_hash),silent=TRUE)
stopifnot(inherits(copied_manifest_mismatch,"try-error"))
unlink(c(registry_source,registry_copy),recursive=TRUE)
source_fixture <- tempfile("reconstruction-sources-"); dir.create(source_fixture)
source_names <- c("stage_two.py", "reconstruct-first-look.py", "stage-two-rules.R",
                  "verify-first-look.R", "combine-stage-two.R")
for (name in source_names) writeLines(name, file.path(source_fixture, name))
source_hashes <- stats::setNames(vapply(source_names, function(name)
  digest::digest(file.path(source_fixture,name),algo="sha256",file=TRUE), character(1L)), source_names)
stopifnot(isTRUE(native_sd_stage_two_validate_reconstruction_sources(source_fixture,source_hashes)))
writeLines("changed",file.path(source_fixture,"verify-first-look.R"))
source_hash_mismatch <- try(native_sd_stage_two_validate_reconstruction_sources(source_fixture,source_hashes),silent=TRUE)
stopifnot(inherits(source_hash_mismatch,"try-error"))
unlink(source_fixture,recursive=TRUE)
seals <- c(`1`="registry-one", `2`="registry-two", `3`="registry-three")
stopifnot(identical(native_sd_stage_two_registry_for_offset(3000L,seals),"registry-one"),
          identical(native_sd_stage_two_registry_for_offset(6000L,seals),"registry-two"),
          identical(native_sd_stage_two_registry_for_offset(9000L,seals),"registry-three"))
run_hashes <- stats::setNames(c("attempt-three", "attempt-one", "attempt-two"),
                              c("3", "1", "2"))
seal_hashes <- jsonlite::fromJSON(
  '{"1":"attempt-one","2":"attempt-two","3":"attempt-three"}',
  simplifyVector = TRUE
)
legacy_healthy_map_comparison <- identical(
  run_hashes[sort(names(run_hashes))],
  as.character(seal_hashes[sort(names(seal_hashes))])
)
stopifnot(is.list(seal_hashes),
          !legacy_healthy_map_comparison,
          native_sd_stage_two_hash_maps_equal(run_hashes, seal_hashes),
          !native_sd_stage_two_hash_maps_equal(
            run_hashes,
            modifyList(seal_hashes, list("2" = "wrong-hash"))
          ),
          !native_sd_stage_two_hash_maps_equal(
            run_hashes[c("1", "2")], seal_hashes
          ),
          !native_sd_stage_two_hash_maps_equal(
            c(run_hashes, "3" = "duplicate-hash"), seal_hashes
          ))
for (offset in c(0L, 1L, 12000L)) {
  failed <- try(native_sd_stage_two_batch_id(offset), silent=TRUE)
  stopifnot(inherits(failed,"try-error"))
}
saved <- data.frame(metric=c("coverage","bias"),value=c(.95,.01))
roundtrip <- saved; roundtrip$value[[2L]] <- roundtrip$value[[2L]] + 1.2e-15
drift <- saved; drift$value[[2L]] <- .02
stopifnot(native_sd_stage_two_metrics_equal(saved,roundtrip),
          !native_sd_stage_two_metrics_equal(saved,drift))
rows <- data.frame(look=rep(1L,2),attempt_index=1:2,source_index=1:2,
                   truth=c(-.5,0),estimate=c(-.49,.01),lower=c(-.7,-.2),
                   upper=c(-.3,.2),profile_level=rep(.95,2),
                   valid=c(TRUE,TRUE),status=c("completed","completed"))
rows_roundtrip <- rows; rows_roundtrip$estimate[[1L]] <- rows_roundtrip$estimate[[1L]]+1.2e-15
rows_drift <- rows; rows_drift$estimate[[1L]] <- -.4
stopifnot(native_sd_stage_two_attempts_equal(rows,rows_roundtrip),
          !native_sd_stage_two_attempts_equal(rows,rows_drift))
stopifnot(native_sd_stage_two_deadline_ok(100,10600,200),
          !native_sd_stage_two_deadline_ok(100,10601,200),
          !native_sd_stage_two_deadline_ok(100,10600,10600),
          !native_sd_stage_two_deadline_ok(100,99,101))
cases <- data.frame(index=1:3000,status=rep(c("completed","error"),length.out=3000),
                    returncode=rep(c(0L,1L),length.out=3000))
receipt <- list(campaign_complete=TRUE,subset_complete=TRUE,interrupted=FALSE,cases=cases)
stopifnot(native_sd_stage_two_terminal_receipt(receipt))
missing_interrupt <- receipt; missing_interrupt$interrupted <- NULL
stopifnot(!native_sd_stage_two_terminal_receipt(missing_interrupt))
zero_exit_error <- receipt; zero_exit_error$cases$returncode[[2L]] <- 0L
stopifnot(!native_sd_stage_two_terminal_receipt(zero_exit_error))
bad <- receipt; bad$cases$status[[17L]] <- "campaign_timeout"
stopifnot(!native_sd_stage_two_terminal_receipt(bad))
timed <- receipt; timed$cases$status[[17L]] <- "timeout"
timed$cases$returncode[[17L]] <- 124L
stopifnot(native_sd_stage_two_terminal_receipt(timed))
zero_exit_timeout <- timed; zero_exit_timeout$cases$returncode[[17L]] <- 0L
stopifnot(!native_sd_stage_two_terminal_receipt(zero_exit_timeout))
cat("STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12\n")
