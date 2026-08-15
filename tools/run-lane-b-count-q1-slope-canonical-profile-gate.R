#!/usr/bin/env Rscript
# Targetwise receipt gate for the eight canonical count q1 slope targets.
# Dry runs validate only the registry. Non-dry execution needs explicit authority.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
lane_b_count_q1_gate_stop <- function(...) stop(..., call. = FALSE)
lane_b_count_q1_gate_batch <- "count-q1-slope-canonical"
lane_b_count_q1_gate_script <- "tools/run-lane-b-count-q1-slope-canonical-profile-gate.R"
lane_b_count_q1_gate_root <- function() normalizePath(".", mustWork = TRUE)

lane_b_count_q1_gate_hash <- function(path) {
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (command == "sha256sum") path else c("-a", "256", path)
  out <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) lane_b_count_q1_gate_stop("Cannot hash file: ", path)
  sub("\\s.*$", "", out[[1L]])
}
lane_b_count_q1_gate_git <- function(root) {
  out <- suppressWarnings(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE))
  if ((attr(out, "status") %||% 0L) != 0L || !length(out)) NA_character_ else out[[1L]]
}
lane_b_count_q1_gate_args <- function(args) {
  out <- list(dry_run = FALSE)
  for (arg in args) {
    if (identical(arg, "--dry-run")) { out$dry_run <- TRUE; next }
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) lane_b_count_q1_gate_stop("Arguments must use --name=value syntax, except --dry-run.")
    key <- sub("^--([^=]+)=.*$", "\\1", arg)
    if (!is.null(out[[key]])) lane_b_count_q1_gate_stop("Duplicate argument: --", key, ".")
    out[[key]] <- sub("^[^=]+=", "", arg)
  }
  required <- c("cell", "seed", "rung", "output-dir")
  if (length(missing <- required[vapply(required, function(x) is.null(out[[x]]) || !nzchar(out[[x]]), logical(1L))])) lane_b_count_q1_gate_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  if (length(extra <- setdiff(names(out), c(required, "goal-authorized", "dry_run")))) lane_b_count_q1_gate_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out$seed <- suppressWarnings(as.integer(out$seed))
  if (length(out$seed) != 1L || is.na(out$seed) || out$seed < 1L) lane_b_count_q1_gate_stop("--seed must be a positive integer.")
  out
}
lane_b_count_q1_gate_registry <- function(root) {
  env <- new.env(parent = baseenv())
  sys.source(file.path(root, "tools", "validate-lane-b-count-q1-slope-canonical-registry.R"), envir = env)
  env$lane_b_count_q1_slope_validate(env$lane_b_count_q1_slope_read_registry(root))
}
lane_b_count_q1_gate_contract <- function(root, cell, seed, rung) {
  registry <- lane_b_count_q1_gate_registry(root)
  row <- registry[registry$cell_id == cell & registry$seed == seed & registry$execution_information_rung == rung, , drop = FALSE]
  if (nrow(row) != 1L) lane_b_count_q1_gate_stop("--cell, --seed, and --rung must select one exact canonical count q1 slope target/DGP/rung.")
  list(row = row, registry = registry)
}
lane_b_count_q1_gate_expected_dir <- function(root, cell, rung) {
  sha <- lane_b_count_q1_gate_git(root)
  if (is.na(sha) || !grepl("^[0-9a-f]{40}$", sha)) lane_b_count_q1_gate_stop("A full current Git SHA is required for retained receipt layout.")
  file.path(root, "docs", "dev-log", "interval-feasibility", "results", sha, lane_b_count_q1_gate_batch, rung, cell)
}
lane_b_count_q1_gate_paths <- function(output_dir, cell, rung, seed) {
  stem <- paste0("lane-b-count-q1-slope-canonical-profile-", cell, "-", rung, "-seed-", seed)
  list(trace = file.path(output_dir, paste0(stem, "-trace.tsv")), interval = file.path(output_dir, paste0(stem, "-interval.tsv")), receipt = file.path(output_dir, paste0(stem, "-receipt.tsv")))
}
lane_b_count_q1_gate_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("lane-b-count-q1-slope-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.table(x, tmp, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(tmp, path)) lane_b_count_q1_gate_stop("Cannot write retained artifact: ", path)
}
lane_b_count_q1_gate_receipt <- function(root, row, paths, fields) {
  cbind(data.frame(
    cell_id = row$cell_id, target_id = row$target_id, cohort_id = row$cohort_id, family = row$family, provider = row$provider,
    dgp_id = row$dgp_id, dgp_version = row$dgp_version, formula = row$formula, true_parameter_scale = row$true_parameter_scale,
    profile_parameter = row$profile_parameter, seed = row$seed, execution_information_rung = row$execution_information_rung,
    binding_source = row$binding_source, binding_source_sha = row$source_sha, source_sha = lane_b_count_q1_gate_git(root),
    profile_engine = "tmbprofile", promotion_eligible = TRUE, receipt_scope = "targetwise_only_user_authorized_intercept_withheld",
    runner_sha256 = lane_b_count_q1_gate_hash(file.path(root, lane_b_count_q1_gate_script)),
    adapter_sha256 = lane_b_count_q1_gate_hash(file.path(root, "tools", "lane-b-count-q1-slope-production-adapters.R")),
    trace_path = normalizePath(paths$trace, mustWork = FALSE), interval_path = normalizePath(paths$interval, mustWork = FALSE),
    stringsAsFactors = FALSE
  ), as.data.frame(fields, stringsAsFactors = FALSE))
}
lane_b_count_q1_gate_failure <- function(root, row, paths, stage, error) {
  lane_b_count_q1_gate_write(lane_b_count_q1_gate_receipt(root, row, paths, list(
    conf_status = "profile_failed", estimate = NA_real_, lower = NA_real_, upper = NA_real_, convergence = NA_integer_, pdHess = NA,
    profile_boundary = NA, clamp_limited = NA, trace_complete = FALSE, failure_reason = paste0(stage, ": ", conditionMessage(error)),
    trace_sha256 = NA_character_, interval_sha256 = NA_character_
  )), paths$receipt)
}
lane_b_count_q1_gate_execute <- function(root, contract, output_dir) {
  row <- contract$row
  expected <- normalizePath(lane_b_count_q1_gate_expected_dir(root, row$cell_id, row$execution_information_rung), mustWork = FALSE)
  output_dir <- normalizePath(if (grepl("^/", output_dir)) output_dir else file.path(root, output_dir), mustWork = FALSE)
  if (!identical(output_dir, expected)) lane_b_count_q1_gate_stop("--output-dir must be the full current-source-SHA receipt path: ", expected)
  paths <- lane_b_count_q1_gate_paths(output_dir, row$cell_id, row$execution_information_rung, row$seed)
  if (any(file.exists(unlist(paths)))) lane_b_count_q1_gate_stop("Refusing to replace retained count q1 slope artifact(s).")
  stage <- "source_load"
  tryCatch({
    if (!requireNamespace("pkgload", quietly = TRUE)) lane_b_count_q1_gate_stop("pkgload is required for the exact source checkout.")
    pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
    if (!identical(normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = TRUE), root)) lane_b_count_q1_gate_stop("Loaded package is not the exact source checkout.")
    stage <- "adapter"
    adapters <- new.env(parent = globalenv())
    sys.source(file.path(root, "tools", "lane-b-count-q1-slope-production-adapters.R"), envir = adapters)
    adapter <- adapters$lane_b_count_q1_slope_production_adapter_fixture(row$cell_id, row$target_id, row$seed, row$execution_information_rung)
    if (!identical(adapter$truth$target_id, row$target_id[[1L]]) || !identical(adapter$truth$dgp_id, row$dgp_id[[1L]]) || !identical(as.integer(adapter$truth$n_level), as.integer(row$n_level))) lane_b_count_q1_gate_stop("Adapter truth differs from frozen count q1 slope contract.")
    stage <- "fit"; fit <- adapter$fit(adapter$data)
    stage <- "target_check"; target <- row$profile_parameter[[1L]]; targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) lane_b_count_q1_gate_stop("Frozen count q1 slope target is not uniquely profile-ready: ", target)
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (!nrow(trace) || length(status) != 1L || length(message) != 1L || length(lower) != 1L || length(upper) != 1L || length(estimate) != 1L || !all(trace$parm == target) || !all(trace$scale == "response") || !all(trace$transformation == "exp") || !all(trace$tmb_parameter == "log_sd_phylo") || !all(trace$index == 2L)) lane_b_count_q1_gate_stop("count q1 slope trace lacks the exact response-scale slope component identity.")
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    passed <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- row$cell_id; trace$target_id <- row$target_id; trace$seed <- row$seed; trace$execution_information_rung <- row$execution_information_rung
    interval <- data.frame(cell_id = row$cell_id, target_id = row$target_id, seed = row$seed, execution_information_rung = row$execution_information_rung, profile_parameter = target, level = .95, lower = lower, upper = upper, profile_engine = "tmbprofile", stringsAsFactors = FALSE)
    lane_b_count_q1_gate_write(trace, paths$trace); lane_b_count_q1_gate_write(interval, paths$interval)
    lane_b_count_q1_gate_write(lane_b_count_q1_gate_receipt(root, row, paths, list(
      conf_status = if (passed) "profile" else "profile_failed", estimate = estimate, lower = if (passed) lower else NA_real_, upper = if (passed) upper else NA_real_,
      convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete,
      failure_reason = if (passed) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else message,
      trace_sha256 = lane_b_count_q1_gate_hash(paths$trace), interval_sha256 = lane_b_count_q1_gate_hash(paths$interval)
    )), paths$receipt)
  }, error = function(error) { lane_b_count_q1_gate_failure(root, row, paths, stage, error); stop(error) })
}
lane_b_count_q1_gate_main <- function(args = commandArgs(trailingOnly = TRUE), root = ".") {
  root <- normalizePath(root, mustWork = TRUE); parsed <- lane_b_count_q1_gate_args(args); contract <- lane_b_count_q1_gate_contract(root, parsed$cell, parsed$seed, parsed$rung)
  if (isTRUE(parsed$dry_run)) { message("Canonical count q1 slope profile gate dry-run validated: ", parsed$cell, "; no model was loaded or fit."); return(invisible(contract$row)) }
  if (!identical(parsed[["goal-authorized"]], "lane-b-144-goal")) lane_b_count_q1_gate_stop("Execution requires --goal-authorized=lane-b-144-goal.")
  lane_b_count_q1_gate_execute(root, contract, parsed[["output-dir"]])
}
if (sys.nframe() == 0L) lane_b_count_q1_gate_main()
