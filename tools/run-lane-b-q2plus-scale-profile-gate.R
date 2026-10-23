#!/usr/bin/env Rscript
# Retained all-attempt profile runner for the six exact structured q2 scale
# cells.  A failure writes its receipt before returning a non-zero status.

stop_q2scale <- function(...) stop(..., call. = FALSE)
root <- normalizePath(".", mustWork = TRUE)
args <- commandArgs(trailingOnly = TRUE)
arg <- function(name) { x <- grep(paste0("^--", name, "="), args, value = TRUE); if (length(x) != 1L) stop_q2scale("Require one --", name, "= value."); sub(paste0("^--", name, "="), "", x) }
if (!"--goal-authorized=lane-b-144-goal" %in% args) stop_q2scale("Execution requires the active Lane-B goal authority.")
cell <- arg("cell"); seed <- as.integer(arg("seed")); rung <- arg("rung"); out <- arg("output-dir")
contracts <- utils::read.delim(file.path(root, "docs/dev-log/interval-campaign-bindings/2026-07-29-q2plus-scale-canonical-contracts.tsv"), check.names = FALSE, stringsAsFactors = FALSE)
row <- contracts[contracts$cell_id == cell, , drop = FALSE]
if (nrow(row) != 1L || seed != row$seed[[1L]] || !identical(rung, row$execution_information_rung[[1L]])) stop_q2scale("Arguments differ from the exact q2-plus scale contract.")
sha <- system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE)[[1L]]
expected <- file.path(root, "docs/dev-log/interval-feasibility/results", sha, "q2plus-scale", cell)
actual <- normalizePath(if (grepl("^/", out)) out else file.path(root, out), mustWork = FALSE)
if (!identical(actual, expected)) stop_q2scale("--output-dir must use the source-SHA path: ", expected)
dir.create(actual, recursive = TRUE, showWarnings = FALSE)
paths <- stats::setNames(
  file.path(actual, c("trace.tsv", "interval.tsv", "receipt.tsv")),
  c("trace", "interval", "receipt")
)
if (any(file.exists(paths))) stop_q2scale("Refusing to replace retained artifacts.")
write_tsv <- function(x, p) utils::write.table(x, p, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
hash <- function(p) { cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"; z <- system2(cmd, if (identical(cmd, "sha256sum")) p else c("-a", "256", p), stdout = TRUE); sub("\\s.*$", "", z[[1L]]) }
stage <- "source_load"
tryCatch({
  pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
  e <- new.env(parent = globalenv()); sys.source(file.path(root, "tools/lane-b-q2plus-scale-production-adapter.R"), e)
  stage <- "fixture"; a <- e$lane_b_q2scale_fixture(cell, seed, rung)
  stage <- "fit"; fit <- a$fit(); target <- row$profile_parameter[[1L]]
  stage <- "target_check"; targets <- drmTMB::profile_targets(fit); if (nrow(targets[targets$parm == target & targets$profile_ready, , drop = FALSE]) != 1L) stop_q2scale("Exact target is not uniquely profile-ready.")
  stage <- "profile"; p <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(p, stringsAsFactors = FALSE)
  status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lo <- unique(as.numeric(trace$conf.low)); hi <- unique(as.numeric(trace$conf.high)); est <- unique(as.numeric(trace$estimate))
  diag <- drmTMB:::profile_interval_diagnostics(c(lo, hi), transformation = unique(trace$transformation)[[1L]], estimate = est)
  complete <- nrow(trace) > 0L && length(status) == 1L && length(message) == 1L && identical(status, "profile") && identical(message, "ok")
  pass <- complete && !isTRUE(diag$boundary) && is.finite(est) && is.finite(lo) && is.finite(hi) && lo < hi && est >= lo && est <= hi && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
  trace$cell_id <- cell; trace$target_id <- row$target_id; write_tsv(trace, paths[["trace"]]); write_tsv(data.frame(cell_id = cell, target_id = row$target_id, estimate = est, lower = lo, upper = hi, profile_engine = "tmbprofile"), paths[["interval"]])
  write_tsv(data.frame(cell_id=cell,target_id=row$target_id,dgp_id=row$dgp_id,provider=row$provider,seed=seed,information_rung=rung,source_sha=sha,profile_engine="tmbprofile",conf_status=if(pass)"profile" else "profile_failed",estimate=est,lower=if(pass)lo else NA_real_,upper=if(pass)hi else NA_real_,convergence=fit$opt$convergence,pdHess=isTRUE(fit$sdr$pdHess),profile_boundary=isTRUE(diag$boundary),clamp_limited=identical(status,"clamp_limited"),trace_complete=complete,failure_reason=if(pass)NA_character_ else message,trace_sha256=hash(paths[["trace"]]),interval_sha256=hash(paths[["interval"]])), paths[["receipt"]])
}, error = function(err) { write_tsv(data.frame(cell_id=cell,target_id=row$target_id,dgp_id=row$dgp_id,seed=seed,information_rung=rung,source_sha=sha,profile_engine="tmbprofile",conf_status="profile_failed",trace_complete=FALSE,failure_reason=paste0(stage, ": ", conditionMessage(err))), paths[["receipt"]]); stop(err) })
