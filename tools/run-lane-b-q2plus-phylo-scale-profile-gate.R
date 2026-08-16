#!/usr/bin/env Rscript
q2scale_stop <- function(...) stop(..., call. = FALSE)
q2scale_root <- normalizePath(".", mustWork = TRUE)
q2scale_hash <- function(path) { command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"; out <- system2(command, if (command == "sha256sum") path else c("-a", "256", path), stdout = TRUE); sub("\\s.*$", "", out[[1L]]) }
args <- commandArgs(trailingOnly = TRUE)
value <- function(name) { hit <- grep(paste0("^--", name, "="), args, value = TRUE); if (length(hit) != 1L) q2scale_stop("Require one --", name, "= value."); sub(paste0("^--", name, "="), "", hit) }
cell <- value("cell"); seed <- as.integer(value("seed")); rung <- value("rung"); output_dir <- value("output-dir")
if (!"--goal-authorized=lane-b-144-goal" %in% args) q2scale_stop("Execution requires --goal-authorized=lane-b-144-goal.")
validator <- new.env(parent = globalenv()); sys.source(file.path(q2scale_root, "tools/validate-lane-b-q2plus-phylo-scale-contracts.R"), validator)
registry <- validator$q2scale_read_validate(q2scale_root); row <- registry[registry$cell_id == cell, , drop = FALSE]
if (nrow(row) != 1L || seed != row$seed[[1L]] || !identical(rung, row$execution_information_rung[[1L]])) q2scale_stop("Arguments differ from the exact q2-plus scale contract.")
sha <- system2("git", c("-C", q2scale_root, "rev-parse", "HEAD"), stdout = TRUE)[[1L]]
expected <- file.path(q2scale_root, "docs/dev-log/interval-feasibility/results", sha, "q2plus-phylo-scale", cell)
actual <- normalizePath(if (grepl("^/", output_dir)) output_dir else file.path(q2scale_root, output_dir), mustWork = FALSE)
if (!identical(actual, expected)) q2scale_stop("--output-dir must be the source-SHA path: ", expected)
dir.create(actual, recursive = TRUE, showWarnings = FALSE)
paths <- list(trace = file.path(actual, "trace.tsv"), interval = file.path(actual, "interval.tsv"), receipt = file.path(actual, "receipt.tsv")); if (any(file.exists(unlist(paths)))) q2scale_stop("Refusing to replace retained artifact.")
write_tsv <- function(x, path) utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
stage <- "source_load"
tryCatch({
  pkgload::load_all(q2scale_root, quiet = TRUE, export_all = FALSE); adapters <- new.env(parent = globalenv()); sys.source(file.path(q2scale_root, "tools/lane-b-q2plus-phylo-production-adapter.R"), adapters)
  stage <- "adapter"; adapter <- adapters$lane_b_q2plus_phylo_production_adapter_fixture("mc-0089", seed, rung)
  stage <- "fit"; fit <- adapter$fit(adapter$data); target <- row$profile_parameter[[1L]]
  stage <- "target_check"; targets <- drmTMB::profile_targets(fit); if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) q2scale_stop("Exact scale target is not uniquely profile-ready.")
  stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
  status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate)); diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
  complete <- nrow(trace) > 0L && length(status) == 1L && length(message) == 1L && identical(status, "profile") && identical(message, "ok")
  passed <- complete && !isTRUE(diagnostics$boundary) && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
  trace$cell_id <- cell; trace$target_id <- row$target_id; write_tsv(trace, paths$trace); write_tsv(data.frame(cell_id = cell,target_id=row$target_id,estimate,lower,upper,profile_engine="tmbprofile"), paths$interval)
  write_tsv(data.frame(cell_id=cell,target_id=row$target_id,dgp_id=row$dgp_id,seed=seed,information_rung=rung,source_sha=sha,profile_engine="tmbprofile",conf_status=if(passed)"profile" else "profile_failed",estimate=estimate,lower=if(passed)lower else NA_real_,upper=if(passed)upper else NA_real_,convergence=fit$opt$convergence,pdHess=isTRUE(fit$sdr$pdHess),profile_boundary=isTRUE(diagnostics$boundary),clamp_limited=identical(status,"clamp_limited"),trace_complete=complete,failure_reason=if(passed)NA_character_ else message,trace_sha256=q2scale_hash(paths$trace),interval_sha256=q2scale_hash(paths$interval)), paths$receipt)
}, error=function(e) { write_tsv(data.frame(cell_id=cell,target_id=row$target_id,dgp_id=row$dgp_id,seed=seed,information_rung=rung,source_sha=sha,profile_engine="tmbprofile",conf_status="profile_failed",estimate=NA_real_,lower=NA_real_,upper=NA_real_,convergence=NA_integer_,pdHess=NA,profile_boundary=NA,clamp_limited=NA,trace_complete=FALSE,failure_reason=paste0(stage,": ",conditionMessage(e)),trace_sha256=NA_character_,interval_sha256=NA_character_), paths$receipt); stop(e) })
