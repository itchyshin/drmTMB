#!/usr/bin/env Rscript
# Retained target-wise q2-plus phylogenetic location-SD profile gate.  The
# paired reducer (not this runner) refuses an incomplete mu1/mu2 batch.

q2plus_stop <- function(...) stop(..., call. = FALSE)
q2plus_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
q2plus_script <- normalizePath(if (length(q2plus_file)) sub("^--file=", "", q2plus_file[[1L]]) else "tools/run-lane-b-q2plus-phylo-profile-gate.R", mustWork = FALSE)
q2plus_root <- local({
  candidates <- c(file.path(dirname(q2plus_script), ".."), ".", "..", getwd(), file.path(getwd(), ".."), file.path(getwd(), "..", ".."))
  hit <- candidates[file.exists(file.path(candidates, "tools", "run-lane-b-q2plus-phylo-profile-gate.R"))]
  if (!length(hit)) q2plus_stop("Cannot locate q2-plus profile-gate root.")
  normalizePath(hit[[1L]], mustWork = TRUE)
})
q2plus_hash <- function(path) {
  if (!file.exists(path)) q2plus_stop("Cannot hash missing file: ", path)
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  output <- suppressWarnings(system2(command, if (identical(command, "sha256sum")) path else c("-a", "256", path), stdout = TRUE, stderr = TRUE))
  if (!length(output) || !grepl("^[0-9a-f]{64}\\s", output[[1L]])) q2plus_stop("Cannot hash file: ", path)
  sub("\\s.*$", "", output[[1L]])
}
q2plus_sha <- function() {
  out <- suppressWarnings(system2("git", c("-C", q2plus_root, "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE))
  if (!length(out) || !grepl("^[0-9a-f]{40}$", out[[1L]])) q2plus_stop("A full current Git SHA is required.")
  out[[1L]]
}
q2plus_args <- function(args) {
  out <- list(dry_run = FALSE)
  for (arg in args) {
    if (identical(arg, "--dry-run")) { out$dry_run <- TRUE; next }
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) q2plus_stop("Arguments must use --name=value syntax (except --dry-run).")
    key_value <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]; key <- key_value[[1L]]
    if (!is.null(out[[key]])) q2plus_stop("Duplicate argument: --", key, ".")
    out[[key]] <- paste(key_value[-1L], collapse = "=")
  }
  needed <- c("cell", "seed", "rung", "output-dir")
  missing <- needed[vapply(needed, function(x) is.null(out[[x]]) || !nzchar(out[[x]]), logical(1L))]
  if (length(missing)) q2plus_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  if (length(extra <- setdiff(names(out), c(needed, "goal-authorized", "dry_run")))) q2plus_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out$seed <- suppressWarnings(as.integer(out$seed))
  if (length(out$seed) != 1L || is.na(out$seed) || out$seed < 1L) q2plus_stop("--seed must be a positive integer.")
  out
}
q2plus_contract <- function(cell, seed, rung) {
  validator <- new.env(parent = baseenv())
  sys.source(file.path(q2plus_root, "tools", "validate-lane-b-q2plus-phylo-canonical-contracts.R"), envir = validator)
  registry <- validator$lane_b_q2plus_contract_read_validate(q2plus_root)
  row <- registry[registry$cell_id == cell, , drop = FALSE]
  if (nrow(row) != 1L) q2plus_stop("--cell is not one exact q2-plus phylo target.")
  if (!identical(seed, 823001L) || !identical(as.character(rung), "low")) q2plus_stop("q2-plus receipt requires frozen seed 823001 and rung low.")
  row
}
q2plus_paths <- function(output_dir, cell, seed, rung) {
  stem <- sprintf("lane-b-q2plus-phylo-profile-%s-%s-seed-%d", cell, rung, seed)
  list(trace = file.path(output_dir, paste0(stem, "-trace.tsv")), interval = file.path(output_dir, paste0(stem, "-interval.tsv")), receipt = file.path(output_dir, paste0(stem, "-receipt.tsv")))
}
q2plus_expected_dir <- function(cell) file.path(q2plus_root, "docs", "dev-log", "interval-feasibility", "results", q2plus_sha(), "q2plus-phylo", cell)
q2plus_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("q2plus-profile-", tmpdir = dirname(path), fileext = ".tsv"); on.exit(unlink(tmp), add = TRUE)
  utils::write.table(x, tmp, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(tmp, path)) q2plus_stop("Cannot retain artifact: ", path)
}
q2plus_fresh <- function(paths) {
  existing <- unlist(paths[file.exists(unlist(paths))], use.names = TRUE)
  if (length(existing)) q2plus_stop("Refusing to replace retained artifact(s): ", paste(names(existing), collapse = ", "), ".")
}
q2plus_receipt <- function(row, cell, seed, rung, paths, fields) {
  cbind(data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, dgp_version = row$dgp_version,
    formula = row$formula, true_parameter_scale = row$true_parameter_scale, profile_parameter = row$profile_parameter,
    seed = seed, execution_information_rung = rung, source_sha = q2plus_sha(), recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    profile_engine = "tmbprofile", promotion_eligible = FALSE, runner_sha256 = q2plus_hash(q2plus_script),
    adapter_sha256 = q2plus_hash(file.path(q2plus_root, "tools", "lane-b-q2plus-phylo-production-adapter.R")),
    trace_path = normalizePath(paths$trace, mustWork = FALSE), interval_path = normalizePath(paths$interval, mustWork = FALSE), stringsAsFactors = FALSE), as.data.frame(fields, stringsAsFactors = FALSE))
}
q2plus_failure <- function(row, cell, seed, rung, paths, stage, error) {
  q2plus_write(q2plus_receipt(row, cell, seed, rung, paths, list(conf_status = "profile_failed", estimate = NA_real_, lower = NA_real_, upper = NA_real_, convergence = NA_integer_, pdHess = NA, profile_boundary = NA, clamp_limited = NA, trace_complete = FALSE, failure_reason = paste0(stage, ": ", conditionMessage(error)), trace_sha256 = NA_character_, interval_sha256 = NA_character_)), paths$receipt)
}
q2plus_execute <- function(row, cell, seed, rung, output_dir) {
  expected <- normalizePath(q2plus_expected_dir(cell), mustWork = FALSE)
  actual <- normalizePath(if (grepl("^/", output_dir)) output_dir else file.path(q2plus_root, output_dir), mustWork = FALSE)
  if (!identical(actual, expected)) q2plus_stop("--output-dir must be the current-source-SHA path: ", expected)
  paths <- q2plus_paths(actual, cell, seed, rung); q2plus_fresh(paths); stage <- "source_load"
  tryCatch({
    if (!requireNamespace("pkgload", quietly = TRUE)) q2plus_stop("pkgload is required for the source checkout.")
    pkgload::load_all(q2plus_root, quiet = TRUE, export_all = FALSE)
    if (!identical(normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = TRUE), q2plus_root)) q2plus_stop("Loaded package is not the exact source checkout.")
    stage <- "adapter"; adapters <- new.env(parent = globalenv()); sys.source(file.path(q2plus_root, "tools", "lane-b-q2plus-phylo-production-adapter.R"), envir = adapters)
    adapter <- adapters$lane_b_q2plus_phylo_production_adapter_fixture(cell, seed, rung)
    if (!identical(adapter$truth$target_id, row$target_id[[1L]]) || !identical(adapter$truth$dgp_id, row$dgp_id[[1L]])) q2plus_stop("Adapter truth differs from frozen q2-plus contract.")
    stage <- "fit"; fit <- adapter$fit(adapter$data); target <- row$profile_parameter[[1L]]
    stage <- "target_check"; targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) q2plus_stop("Frozen q2-plus target is not uniquely profile-ready: ", target)
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (!nrow(trace) || length(status) != 1L || length(message) != 1L || length(lower) != 1L || length(upper) != 1L || length(estimate) != 1L) q2plus_stop("q2-plus trace lacks one status/message/estimate/endpoint pair.")
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    passed <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- cell; trace$target_id <- row$target_id; trace$seed <- seed; trace$execution_information_rung <- rung
    interval <- data.frame(cell_id = cell, target_id = row$target_id, seed = seed, execution_information_rung = rung, profile_parameter = target, level = .95, lower = lower, upper = upper, profile_engine = "tmbprofile", stringsAsFactors = FALSE)
    q2plus_write(trace, paths$trace); q2plus_write(interval, paths$interval)
    q2plus_write(q2plus_receipt(row, cell, seed, rung, paths, list(conf_status = if (passed) "profile" else "profile_failed", estimate = estimate, lower = if (passed) lower else NA_real_, upper = if (passed) upper else NA_real_, convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete, failure_reason = if (passed) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else message, trace_sha256 = q2plus_hash(paths$trace), interval_sha256 = q2plus_hash(paths$interval))), paths$receipt)
  }, error = function(error) { q2plus_failure(row, cell, seed, rung, paths, stage, error); stop(error) })
}
q2plus_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- q2plus_args(args); row <- q2plus_contract(parsed$cell, parsed$seed, parsed$rung)
  if (isTRUE(parsed$dry_run)) { message("q2-plus phylo profile gate dry-run validated: ", parsed$cell); return(invisible(row)) }
  if (!identical(parsed[["goal-authorized"]], "lane-b-144-goal")) q2plus_stop("Execution requires --goal-authorized=lane-b-144-goal.")
  q2plus_execute(row, parsed$cell, parsed$seed, parsed$rung, parsed[["output-dir"]])
}
if (sys.nframe() == 0L) q2plus_main()
