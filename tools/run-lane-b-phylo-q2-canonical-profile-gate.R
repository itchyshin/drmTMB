#!/usr/bin/env Rscript
# Retained target-wise profile gate for the exact four-cell canonical phylo q2
# cohort.  It is executable only with the explicit Lane-B goal token; a dry run
# loads neither drmTMB nor the adapter fixture.  One target is run at a time,
# but the companion reducer refuses an incomplete ML/REML sibling pair.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
lane_b_phylo_q2_gate_stop <- function(...) stop(..., call. = FALSE)
lane_b_phylo_q2_gate_batch <- "phylo-q2-canonical"
lane_b_phylo_q2_gate_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
lane_b_phylo_q2_gate_script <- normalizePath(if (length(lane_b_phylo_q2_gate_file)) sub("^--file=", "", lane_b_phylo_q2_gate_file[[1L]]) else "tools/run-lane-b-phylo-q2-canonical-profile-gate.R", mustWork = FALSE)
lane_b_phylo_q2_gate_root <- local({
  candidates <- c(file.path(dirname(lane_b_phylo_q2_gate_script), ".."), ".", "..", "../..")
  roots <- candidates[file.exists(file.path(candidates, "tools", "run-lane-b-phylo-q2-canonical-profile-gate.R"))]
  if (!length(roots)) lane_b_phylo_q2_gate_stop("Cannot locate canonical phylo q2 profile-gate root.")
  normalizePath(roots[[1L]], mustWork = TRUE)
})

lane_b_phylo_q2_gate_sha256 <- function(path) {
  if (!file.exists(path)) lane_b_phylo_q2_gate_stop("Cannot hash missing file: ", path)
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  out <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) lane_b_phylo_q2_gate_stop("Cannot hash file: ", path)
  sub("\\s.*$", "", out[[1L]])
}
lane_b_phylo_q2_gate_git <- function(args) {
  out <- suppressWarnings(system2("git", c("-C", lane_b_phylo_q2_gate_root, args), stdout = TRUE, stderr = TRUE))
  if ((attr(out, "status") %||% 0L) != 0L) return(NA_character_)
  paste(out, collapse = "\n")
}
lane_b_phylo_q2_gate_args <- function(args) {
  out <- list(dry_run = FALSE)
  for (arg in args) {
    if (identical(arg, "--dry-run")) { out$dry_run <- TRUE; next }
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) lane_b_phylo_q2_gate_stop("Arguments must use --name=value syntax (except --dry-run).")
    kv <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    if (!is.null(out[[kv[[1L]]]])) lane_b_phylo_q2_gate_stop("Duplicate argument: --", kv[[1L]], ".")
    out[[kv[[1L]]]] <- paste(kv[-1L], collapse = "=")
  }
  required <- c("cell", "seed", "rung", "output-dir")
  missing <- required[vapply(required, function(x) is.null(out[[x]]) || !nzchar(out[[x]]), logical(1L))]
  if (length(missing)) lane_b_phylo_q2_gate_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  extra <- setdiff(names(out), c(required, "goal-authorized", "dry_run"))
  if (length(extra)) lane_b_phylo_q2_gate_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out$seed <- suppressWarnings(as.integer(out$seed))
  if (length(out$seed) != 1L || is.na(out$seed) || out$seed < 1L) lane_b_phylo_q2_gate_stop("--seed must be a positive integer.")
  out
}
lane_b_phylo_q2_gate_contract <- function(cell, seed, rung) {
  validator <- new.env(parent = baseenv())
  sys.source(file.path(lane_b_phylo_q2_gate_root, "tools", "validate-lane-b-phylo-q2-canonical-registry.R"), envir = validator)
  registry <- validator$lane_b_phylo_q2_validate(validator$lane_b_phylo_q2_read_registry(lane_b_phylo_q2_gate_root))
  row <- registry[registry$cell_id == cell, , drop = FALSE]
  if (nrow(row) != 1L) lane_b_phylo_q2_gate_stop("--cell is not one exact canonical phylo q2 target.")
  if (!identical(as.integer(seed), 4L) || !identical(as.character(rung), "low")) lane_b_phylo_q2_gate_stop("Canonical phylo q2 receipt requires frozen seed 4 and rung low.")
  list(row = row, registry = registry)
}
lane_b_phylo_q2_gate_expected_dir <- function(cell, source_sha = lane_b_phylo_q2_gate_git(c("rev-parse", "HEAD"))) {
  if (is.na(source_sha) || !grepl("^[0-9a-f]{40}$", source_sha)) lane_b_phylo_q2_gate_stop("A full current Git SHA is required for the retained receipt layout.")
  file.path(lane_b_phylo_q2_gate_root, "docs", "dev-log", "interval-feasibility", "results", source_sha, lane_b_phylo_q2_gate_batch, cell)
}
lane_b_phylo_q2_gate_normalize_dir <- function(path) normalizePath(if (grepl("^/", path)) path else file.path(lane_b_phylo_q2_gate_root, path), mustWork = FALSE)
lane_b_phylo_q2_gate_paths <- function(output_dir, cell, seed, rung) {
  stem <- sprintf("lane-b-phylo-q2-canonical-profile-%s-%s-seed-%d", cell, rung, seed)
  list(trace = file.path(output_dir, paste0(stem, "-trace.tsv")), interval = file.path(output_dir, paste0(stem, "-interval.tsv")), receipt = file.path(output_dir, paste0(stem, "-receipt.tsv")))
}
lane_b_phylo_q2_gate_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("lane-b-phylo-q2-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.table(x, tmp, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(tmp, path)) lane_b_phylo_q2_gate_stop("Cannot write retained artifact: ", path)
}
lane_b_phylo_q2_gate_fresh <- function(paths) {
  existing <- unlist(paths[file.exists(unlist(paths))], use.names = TRUE)
  if (length(existing)) lane_b_phylo_q2_gate_stop("Refusing to replace retained phylo q2 artifact(s): ", paste(names(existing), collapse = ", "), ".")
}
lane_b_phylo_q2_gate_receipt <- function(row, cell, seed, rung, paths, fields) {
  cbind(data.frame(
    cell_id = cell, target_id = row$target_id, cohort_id = row$cohort_id, estimator = row$estimator,
    dgp_id = row$dgp_id, dgp_version = row$dgp_version, formula = row$formula,
    true_parameter_scale = row$true_parameter_scale, profile_parameter = row$profile_parameter,
    seed = seed, execution_information_rung = rung, binding_source = row$binding_source,
    binding_source_sha = row$source_sha, source_sha = lane_b_phylo_q2_gate_git(c("rev-parse", "HEAD")),
    recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE), profile_engine = "tmbprofile",
    promotion_eligible = FALSE, runner_sha256 = lane_b_phylo_q2_gate_sha256(lane_b_phylo_q2_gate_script),
    adapter_sha256 = lane_b_phylo_q2_gate_sha256(file.path(lane_b_phylo_q2_gate_root, "tools", "lane-b-structured-q2-phylo-production-adapters.R")),
    trace_path = normalizePath(paths$trace, mustWork = FALSE), interval_path = normalizePath(paths$interval, mustWork = FALSE),
    stringsAsFactors = FALSE
  ), as.data.frame(fields, stringsAsFactors = FALSE))
}
lane_b_phylo_q2_gate_failure <- function(row, cell, seed, rung, paths, stage, error) {
  receipt <- lane_b_phylo_q2_gate_receipt(row, cell, seed, rung, paths, list(
    conf_status = "profile_failed", estimate = NA_real_, lower = NA_real_, upper = NA_real_,
    convergence = NA_integer_, pdHess = NA, profile_boundary = NA, clamp_limited = NA, trace_complete = FALSE,
    failure_reason = paste0(stage, ": ", conditionMessage(error)), trace_sha256 = NA_character_, interval_sha256 = NA_character_
  ))
  lane_b_phylo_q2_gate_write(receipt, paths$receipt)
}
lane_b_phylo_q2_gate_execute <- function(contract, cell, seed, rung, output_dir) {
  row <- contract$row
  expected <- lane_b_phylo_q2_gate_normalize_dir(lane_b_phylo_q2_gate_expected_dir(cell))
  output_dir <- lane_b_phylo_q2_gate_normalize_dir(output_dir)
  if (!identical(output_dir, expected)) lane_b_phylo_q2_gate_stop("--output-dir must be the full current-source-SHA receipt path: ", expected)
  paths <- lane_b_phylo_q2_gate_paths(output_dir, cell, seed, rung)
  lane_b_phylo_q2_gate_fresh(paths); stage <- "source_load"
  tryCatch({
    if (!requireNamespace("pkgload", quietly = TRUE)) lane_b_phylo_q2_gate_stop("pkgload is required for the exact source checkout.")
    pkgload::load_all(lane_b_phylo_q2_gate_root, quiet = TRUE, export_all = FALSE)
    if (!identical(normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = TRUE), lane_b_phylo_q2_gate_root)) lane_b_phylo_q2_gate_stop("Loaded package is not the exact source checkout.")
    stage <- "adapter"; adapters <- new.env(parent = globalenv())
    sys.source(file.path(lane_b_phylo_q2_gate_root, "tools", "lane-b-structured-q2-phylo-production-adapters.R"), envir = adapters)
    adapter <- adapters$lane_b_structured_q2_phylo_production_adapter_fixture(cell, seed, rung)
    if (!identical(adapter$truth$target_id, row$target_id[[1L]]) || !identical(adapter$truth$dgp_id, row$dgp_id[[1L]])) lane_b_phylo_q2_gate_stop("Adapter truth differs from frozen phylo q2 contract.")
    stage <- "fit"; fit <- adapter$fit(adapter$data)
    target <- row$profile_parameter[[1L]]; stage <- "target_check"; targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) lane_b_phylo_q2_gate_stop("Frozen phylo q2 target is not uniquely profile-ready: ", target)
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (!nrow(trace) || length(status) != 1L || length(message) != 1L || length(lower) != 1L || length(upper) != 1L || length(estimate) != 1L) lane_b_phylo_q2_gate_stop("phylo q2 trace lacks one status/message/estimate/endpoint pair.")
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    passed <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- cell; trace$target_id <- row$target_id; trace$seed <- seed; trace$execution_information_rung <- rung
    interval <- data.frame(cell_id = cell, target_id = row$target_id, seed = seed, execution_information_rung = rung, profile_parameter = target, level = .95, lower = lower, upper = upper, profile_engine = "tmbprofile", stringsAsFactors = FALSE)
    lane_b_phylo_q2_gate_write(trace, paths$trace); lane_b_phylo_q2_gate_write(interval, paths$interval)
    receipt <- lane_b_phylo_q2_gate_receipt(row, cell, seed, rung, paths, list(
      conf_status = if (passed) "profile" else "profile_failed", estimate = estimate, lower = if (passed) lower else NA_real_, upper = if (passed) upper else NA_real_,
      convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete,
      failure_reason = if (passed) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else message,
      trace_sha256 = lane_b_phylo_q2_gate_sha256(paths$trace), interval_sha256 = lane_b_phylo_q2_gate_sha256(paths$interval)
    ))
    lane_b_phylo_q2_gate_write(receipt, paths$receipt); invisible(paths)
  }, error = function(error) { lane_b_phylo_q2_gate_failure(row, cell, seed, rung, paths, stage, error); stop(error) })
}
lane_b_phylo_q2_gate_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  if (identical(args, "--dry-run")) {
    validator <- new.env(parent = baseenv())
    sys.source(file.path(lane_b_phylo_q2_gate_root, "tools", "validate-lane-b-phylo-q2-canonical-registry.R"), envir = validator)
    registry <- validator$lane_b_phylo_q2_validate(validator$lane_b_phylo_q2_read_registry(lane_b_phylo_q2_gate_root))
    message("Canonical phylo q2 profile gate dry-run validated: ", nrow(registry), " targets; no model was loaded or fit.")
    return(invisible(registry))
  }
  parsed <- lane_b_phylo_q2_gate_args(args); contract <- lane_b_phylo_q2_gate_contract(parsed$cell, parsed$seed, parsed$rung)
  if (isTRUE(parsed$dry_run)) { message("Canonical phylo q2 profile gate dry-run validated: ", parsed$cell, "; no model was loaded or fit."); return(invisible(contract$row)) }
  if (!identical(parsed[["goal-authorized"]], "lane-b-144-goal")) lane_b_phylo_q2_gate_stop("Execution requires --goal-authorized=lane-b-144-goal.")
  lane_b_phylo_q2_gate_execute(contract, parsed$cell, parsed$seed, parsed$rung, parsed[["output-dir"]])
}
if (sys.nframe() == 0L) lane_b_phylo_q2_gate_main()
