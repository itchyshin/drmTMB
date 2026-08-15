#!/usr/bin/env Rscript
# Retained profile gate for the named 32-animal bivariate q2 slope DGP.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
stop_now <- function(...) stop(..., call. = FALSE)
script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- sub("^--file=", "", if (length(script_arg)) script_arg[[1L]] else "tools/run-lane-b-animal-q2-slope-highinfo-profile-gate.R")
root_candidates <- c(file.path(dirname(script), ".."), ".", "..", "../..")
root <- normalizePath(root_candidates[file.exists(file.path(root_candidates, "tools", "run-lane-b-animal-q2-slope-highinfo-profile-gate.R"))][[1L]], mustWork = TRUE)
hash <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  out <- system2(cmd, if (identical(cmd, "sha256sum")) path else c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) stop_now("Cannot hash ", path)
  sub("\\s.*$", "", out[[1L]])
}
git_head <- function() paste(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE), collapse = "\n")
write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) stop_now("Refusing to replace retained artifact: ", path)
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
}
args <- function(x) {
  out <- list()
  for (arg in x) {
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) stop_now("Arguments must use --name=value.")
    kv <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    if (!is.null(out[[kv[[1L]]]])) stop_now("Duplicate argument: ", kv[[1L]])
    out[[kv[[1L]]]] <- paste(kv[-1L], collapse = "=")
  }
  needed <- c("cell", "target-id", "seed", "rung", "output-dir")
  if (length(missing <- setdiff(needed, names(out)))) stop_now("Missing --", paste(missing, collapse = ", --"), "=.")
  if (length(extra <- setdiff(names(out), c(needed, "goal-authorized", "dry-run")))) stop_now("Unsupported --", paste(extra, collapse = ", --"), ".")
  out$seed <- as.integer(out$seed)
  out
}
contract_row <- function(parsed) {
  path <- file.path(root, "docs/dev-log/interval-campaign-bindings/2026-07-29-animal-q2-slope-high-information-canonical-contracts.tsv")
  reg <- utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
  must <- c("cell_id", "target_id", "dgp_id", "profile_parameter", "truth", "information_rung", "seed", "group_count", "within_group_replicates", "component_cardinality", "execution_authority")
  if (!all(must %in% names(reg)) || nrow(reg) != 2L || anyDuplicated(reg$target_id)) stop_now("Malformed animal q2 slope registry.")
  row <- reg[reg$cell_id == parsed$cell & reg$target_id == parsed[["target-id"]], , drop = FALSE]
  if (nrow(row) != 1L || !isTRUE(row$execution_authority[[1L]]) || row$component_cardinality[[1L]] != 1L || row$group_count[[1L]] < 20L || row$within_group_replicates[[1L]] < 10L) stop_now("No valid high-information exact target contract.")
  if (!identical(as.integer(row$seed[[1L]]), parsed$seed) || !identical(row$information_rung[[1L]], parsed$rung)) stop_now("Seed/rung differs from frozen contract.")
  row
}
main <- function(parsed) {
  row <- contract_row(parsed)
  if (identical(parsed[["dry-run"]], "TRUE")) return(invisible(row))
  if (!identical(parsed[["goal-authorized"]], "lane-b-144-goal")) stop_now("Requires --goal-authorized=lane-b-144-goal.")
  sha <- git_head(); expected <- normalizePath(file.path(root, "docs/dev-log/interval-feasibility/results", sha, "q2-animal-slope-highinfo", parsed$cell), mustWork = FALSE)
  output <- normalizePath(if (grepl("^/", parsed[["output-dir"]])) parsed[["output-dir"]] else file.path(root, parsed[["output-dir"]]), mustWork = FALSE)
  if (!identical(output, expected)) stop_now("--output-dir must equal the exact source-SHA retained path: ", expected)
  safe <- gsub("[^A-Za-z0-9]+", "-", sub("^[^:]+::", "", parsed[["target-id"]]))
  stem <- sprintf("lane-b-animal-q2-slope-profile-%s-%s-%s-seed-%d", parsed$cell, safe, parsed$rung, parsed$seed)
  paths <- list(trace = file.path(output, paste0(stem, "-trace.tsv")), interval = file.path(output, paste0(stem, "-interval.tsv")), receipt = file.path(output, paste0(stem, "-receipt.tsv")))
  if (any(file.exists(unlist(paths)))) stop_now("Retained path is not fresh.")
  adapters <- new.env(parent = globalenv()); sys.source(file.path(root, "tools/lane-b-animal-q2-slope-highinfo-adapters.R"), envir = adapters)
  started <- proc.time()[["elapsed"]]
  tryCatch({
    pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
    fixture <- adapters$lane_b_animal_q2_slope_fixture(parsed$cell, parsed[["target-id"]], parsed$seed, parsed$rung)
    if (!identical(fixture$truth$target_id, row$target_id[[1L]]) || !identical(fixture$truth$dgp_id, row$dgp_id[[1L]])) stop_now("Fixture differs from exact contract.")
    fit <- fixture$fit(fixture$data); target <- row$profile_parameter[[1L]]
    targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) stop_now("Target is not uniquely profile-ready.")
    profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    status <- unique(as.character(trace$conf.status)); msg <- unique(as.character(trace$profile.message)); low <- unique(as.numeric(trace$conf.low)); high <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (!nrow(trace) || length(status) != 1L || length(msg) != 1L || length(low) != 1L || length(high) != 1L || length(estimate) != 1L) stop_now("Trace lacks a unique profile result.")
    d <- drmTMB:::profile_interval_diagnostics(c(low, high), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    nuisance <- unname(fit$corpars$animal)
    if (length(nuisance) != 1L || !is.finite(nuisance)) stop_now("Animal endpoint-correlation nuisance is missing or nonfinite.")
    nuisance_boundary <- abs(nuisance) >= 0.995
    complete <- identical(status, "profile") && identical(msg, "ok")
    pass <- complete && !isTRUE(d$boundary) && !nuisance_boundary && is.finite(estimate) && is.finite(low) && is.finite(high) && low < high && estimate >= low && estimate <= high && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- parsed$cell; trace$target_id <- row$target_id; trace$seed <- parsed$seed; trace$information_rung <- parsed$rung
    interval <- data.frame(cell_id = parsed$cell, target_id = row$target_id, seed = parsed$seed, information_rung = parsed$rung, profile_parameter = target, level = .95, lower = low, upper = high, profile_engine = "tmbprofile")
    write_tsv(trace, paths$trace); write_tsv(interval, paths$interval)
    receipt <- data.frame(cell_id = parsed$cell, target_id = row$target_id, dgp_id = row$dgp_id, profile_parameter = target, target_truth = row$truth, seed = parsed$seed, information_rung = parsed$rung, group_count = row$group_count, within_group_replicates = row$within_group_replicates, source_sha = sha, conf_status = if (pass) "profile" else "profile_failed", profile_engine = "tmbprofile", estimate = estimate, lower = if (pass) low else NA_real_, upper = if (pass) high else NA_real_, convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(d$boundary), nuisance_correlation = nuisance, nuisance_boundary = nuisance_boundary, clamp_limited = identical(status, "clamp_limited"), trace_complete = complete, failure_reason = if (pass) NA_character_ else if (isTRUE(d$boundary)) d$message else if (nuisance_boundary) "endpoint-correlation nuisance is boundary-adjacent" else msg, elapsed_seconds = proc.time()[["elapsed"]] - started, runner_sha256 = hash(script), adapter_sha256 = hash(file.path(root, "tools/lane-b-animal-q2-slope-highinfo-adapters.R")), trace_path = normalizePath(paths$trace, mustWork = TRUE), interval_path = normalizePath(paths$interval, mustWork = TRUE), trace_sha256 = hash(paths$trace), interval_sha256 = hash(paths$interval), stringsAsFactors = FALSE)
    write_tsv(receipt, paths$receipt)
  }, error = function(e) {
    receipt <- data.frame(cell_id = parsed$cell, target_id = row$target_id, dgp_id = row$dgp_id, profile_parameter = row$profile_parameter, target_truth = row$truth, seed = parsed$seed, information_rung = parsed$rung, group_count = row$group_count, within_group_replicates = row$within_group_replicates, source_sha = sha, conf_status = "profile_failed", profile_engine = "tmbprofile", estimate = NA_real_, lower = NA_real_, upper = NA_real_, convergence = NA_integer_, pdHess = NA, profile_boundary = NA, nuisance_correlation = NA_real_, nuisance_boundary = NA, clamp_limited = NA, trace_complete = FALSE, failure_reason = conditionMessage(e), elapsed_seconds = proc.time()[["elapsed"]] - started, runner_sha256 = hash(script), adapter_sha256 = hash(file.path(root, "tools/lane-b-animal-q2-slope-highinfo-adapters.R")), trace_path = normalizePath(paths$trace, mustWork = FALSE), interval_path = normalizePath(paths$interval, mustWork = FALSE), trace_sha256 = NA_character_, interval_sha256 = NA_character_); write_tsv(receipt, paths$receipt); stop(e)
  })
}
if (sys.nframe() == 0L) main(args(commandArgs(trailingOnly = TRUE)))
