args <- commandArgs(trailingOnly=TRUE)
registry_only <- length(args)==4L && identical(args[[4L]],"--registry-only")
if(length(args)!=3L && !registry_only) stop("Usage: Rscript verify-first-look.R FIRST_LOOK EXTERNAL_SEAL STANDARDIZED_CSV [--registry-only]")
d <- normalizePath(args[[1L]],mustWork=TRUE); seal <- jsonlite::fromJSON(args[[2L]],simplifyVector=TRUE); out <- args[[3L]]
if(file.exists(out)) stop("Refusing to overwrite standardized first-look output")
script_arg <- commandArgs()[grepl("^--file=",commandArgs())][[1L]]
script_path <- gsub("~\\+~"," ",sub("^--file=","",script_arg),fixed=FALSE)
source(file.path(dirname(normalizePath(script_path,mustWork=TRUE)),"stage-two-rules.R"))
hash_file <- function(p) digest::digest(p,algo="sha256",file=TRUE)
validate_first_look_registry <- function(dir, registry) {
  h <- read.csv(registry,stringsAsFactors=FALSE)
  if(!all(c("path","sha256")%in%names(h))||anyDuplicated(h$path)) stop("Invalid first-look registry")
  pinned_manifest <- which(basename(h$path)=="manifest.csv")
  if(length(pinned_manifest)!=1L) stop("First-look registry must pin exactly one prepared manifest")
  for(i in seq_len(nrow(h)))if(!file.exists(h$path[[i]])||hash_file(h$path[[i]])!=h$sha256[[i]])stop("First-look source artifact mismatch")
  copied <- file.path(dir,"manifest.csv")
  if(!file.exists(copied)||hash_file(copied)!=h$sha256[[pinned_manifest]]) stop("Copied first-look manifest differs from its pinned prepared manifest")
  h
}
registry<-file.path(d,"source-hashes.csv")
if(hash_file(registry)!=seal$registry_sha256) stop("First-look registry differs from external seal")
h<-validate_first_look_registry(d,registry)
if(registry_only){cat("FIRST_LOOK_REGISTRY_PASS copied_manifest_matches_pinned_artifact\n");quit(save="no",status=0L,runLast=FALSE)}
if(native_sd_stage_two_attempt_digest(d,expected_results=3000L)!=seal$attempts_sha256)stop("First-look attempt files differ from external seal")
decision_file<-normalizePath(seal$decision_path,mustWork=TRUE)
if(hash_file(decision_file)!=seal$decision_sha256)stop("First-look decision file differs from external seal")
staged_path<-normalizePath(seal$staged_decision_path,mustWork=TRUE)
if(hash_file(staged_path)!=seal$staged_decision_sha256)stop("Staged analyzer differs from external seal")
source(staged_path)
native_sd_stage_two_validate_reconstruction_sources(
  dirname(normalizePath(script_path, mustWork = TRUE)),
  seal$reconstruction_source_sha256
)
m<-read.csv(file.path(d,"manifest.csv"),stringsAsFactors=FALSE)
native_sd_stage_two_validate_first_look_manifest(m)
sup<-jsonlite::fromJSON(file.path(d,"supervisor-receipt.json"),simplifyVector=TRUE)
if(sup$registry_sha256!=seal$registry_sha256||sup$manifest_sha256!=hash_file(file.path(d,"manifest.csv"))||!native_sd_stage_two_terminal_receipt(sup))stop("First-look supervisor receipt incomplete or inconsistent")
cases<-as.data.frame(sup$cases,stringsAsFactors=FALSE); state<-setNames(as.character(cases$status),as.character(cases$index)); code<-setNames(as.integer(cases$returncode),as.character(cases$index))
files<-list.files(d,pattern="^result-[0-9]{4}[.]csv$",full.names=TRUE)
rr<-if(length(files))do.call(rbind,lapply(files,read.csv,stringsAsFactors=FALSE))else data.frame()
native_sd_stage_two_validate_profile_level(rr)
if(nrow(rr)&&(anyDuplicated(rr$index)||any(!rr$index%in%1:3000)))stop("Duplicate or out-of-range first-look result")
by<-if(nrow(rr))setNames(split(rr,rr$index),as.character(rr$index))else list()
for(f in files){v<-read.csv(f,stringsAsFactors=FALSE);if(nrow(v)!=1L||basename(f)!=sprintf("result-%04d.csv",as.integer(v$index[[1L]])))stop("First-look result filename/index mismatch")}
for(k in names(by)){v<-by[[k]];row<-m[match(as.integer(k),m$index),];if(v$seed[[1L]]!=row$seed||v$a[[1L]]!=row$a||v$replicate[[1L]]!=row$replicate)stop("First-look worker identity mismatch");if(isTRUE(v$valid_interval[[1L]])&&state[[k]]!="completed")stop("First-look valid interval has non-completed status")}
for(i in 1:3000)if(state[[as.character(i)]]=="completed"&&(!as.character(i)%in%names(by)||code[[as.character(i)]]!=0L))stop("First-look completed case lacks successful result")
attempts<-do.call(rbind,lapply(1:3000,function(i){k<-as.character(i);v<-by[[k]];status<-state[[k]];e<-if(!is.null(v)&&is.finite(v$estimate[[1L]]))as.numeric(v$estimate[[1L]])else NA_real_;lo<-if(!is.null(v)&&is.finite(v$lower[[1L]]))as.numeric(v$lower[[1L]])else NA_real_;hi<-if(!is.null(v)&&is.finite(v$upper[[1L]]))as.numeric(v$upper[[1L]])else NA_real_;profile_level<-if(!is.null(v)&&"profile_level"%in%names(v))as.numeric(v$profile_level[[1L]])else NA_real_;valid<-!is.null(v)&&status=="completed"&&code[[k]]==0L&&v$state[[1L]]=="completed"&&isTRUE(v$valid_interval[[1L]])&&isTRUE(v$oracle_pass[[1L]])&&is.finite(v$laplace_oracle_error[[1L]])&&abs(v$laplace_oracle_error[[1L]])<1e-6&&v$convergence[[1L]]==0L&&isTRUE(v$pdHess[[1L]])&&is.finite(v$max_abs_gradient[[1L]])&&v$max_abs_gradient[[1L]]<1e-3&&v$clamp_at_optimum[[1L]]=="ok"&&v$interval_status[[1L]]=="profile"&&identical(v$profile_boundary[[1L]],FALSE)&&is.finite(lo)&&is.finite(hi)&&lo<hi&&(!nzchar(v$error[[1L]])||is.na(v$error[[1L]]));data.frame(look=1L,attempt_index=i,source_index=i,truth=as.numeric(m$a[[i]]),estimate=e,lower=lo,upper=hi,profile_level=profile_level,valid=isTRUE(valid),status=status,stringsAsFactors=FALSE)}))
decision<-native_sd_staged_decision(attempts[c("truth","estimate","lower","upper","profile_level","valid","status")],3000L,1L,TRUE)
saved<-readRDS(file.path(d,"staged-decision.rds"))
if(decision$decision!="look2_required"||saved$decision!=decision$decision||!native_sd_stage_two_metrics_equal(decision$metrics,saved$metrics,1e-12)||!identical(decision$gates,saved$gates)||!identical(decision$status_counts,saved$status_counts))stop("Raw first-look replay differs from sealed analyzer result")
write.csv(attempts,out,row.names=FALSE)
receipt<-list(decision=decision$decision,first_look_seal_sha256=hash_file(args[[2L]]),
  first_look_registry_sha256=seal$registry_sha256,
  attempts_sha256=native_sd_stage_two_attempt_digest(d,expected_results=3000L),
  reconstruction_source_sha256=seal$reconstruction_source_sha256,
  standardized_sha256=hash_file(out),metrics_match=TRUE,gate_rows=nrow(decision$gates),attempt_rows=nrow(attempts))
writeLines(jsonlite::toJSON(receipt,auto_unbox=TRUE,pretty=TRUE),paste0(out,".receipt.json"))
cat("FIRST_LOOK_REPLAY_PASS standardized_rows=3000 decision=look2_required\n")
