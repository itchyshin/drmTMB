#!/usr/bin/env Rscript
# One exact direct dense-q4 SD target per invocation.  Correlations remain
# diagnostic-only and any boundary-adjacent fitted correlation fails closed.

stop_now <- function(...) stop(..., call. = FALSE)
file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script <- if (length(file_arg)) sub("^--file=", "", file_arg[[1L]]) else "tools/run-lane-b-phylo-dense-q4-highinfo-profile-gate.R"
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
hash <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  result <- system2(cmd, if (identical(cmd, "sha256sum")) path else c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!length(result) || !grepl("^[0-9a-f]{64}\\s", result[[1L]])) stop_now("Cannot hash ", path)
  sub("\\s.*$", "", result[[1L]])
}
write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (file.exists(path)) stop_now("Refusing to replace retained artifact: ", path)
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
}
parse_args <- function(args) {
  values <- sub("^[^=]+=", "", args)
  names(values) <- sub("^--([^=]+)=.*$", "\\1", args)
  required <- c("cell", "target-id", "seed", "rung", "output-dir", "goal-authorized")
  if (!setequal(names(values), required)) stop_now("Requires only exact --cell, --target-id, --seed, --rung, --output-dir, --goal-authorized arguments.")
  if (!identical(values[["goal-authorized"]], "lane-b-144-goal")) stop_now("Requires --goal-authorized=lane-b-144-goal.")
  values
}
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  values <- parse_args(args)
  validator <- new.env(parent = baseenv())
  sys.source(file.path(root, "tools", "validate-lane-b-phylo-dense-q4-highinfo-contracts.R"), envir = validator)
  contracts <- validator$lane_b_dense_q4_validate(root)
  row <- contracts[contracts$cell_id == values[["cell"]] & contracts$target_id == values[["target-id"]], , drop = FALSE]
  if (nrow(row) != 1L || as.integer(values[["seed"]]) != row$seed[[1L]] || !identical(values[["rung"]], row$information_rung[[1L]])) stop_now("No frozen dense-q4 exact target contract for the requested cell, seed, and rung.")
  sha <- paste(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE), collapse = "")
  expected <- normalizePath(file.path(root, "docs", "dev-log", "interval-feasibility", "results", sha, "phylo-dense-q4-highinfo", row$cell_id[[1L]]), mustWork = FALSE)
  output <- normalizePath(values[["output-dir"]], mustWork = FALSE)
  if (!identical(output, expected)) stop_now("Output directory must be the source-SHA retained path: ", expected)
  stem <- paste0("lane-b-phylo-dense-q4-", row$cell_id[[1L]], "-seed-", row$seed[[1L]])
  paths <- list(trace = file.path(output, paste0(stem, "-trace.tsv")), interval = file.path(output, paste0(stem, "-interval.tsv")), receipt = file.path(output, paste0(stem, "-receipt.tsv")))
  if (any(file.exists(unlist(paths)))) stop_now("Retained source-SHA artifact path is not fresh.")
  adapters <- new.env(parent = globalenv())
  sys.source(file.path(root, "tools", "lane-b-phylo-q4-dense-highinfo-adapters.R"), envir = adapters)
  started <- proc.time()[["elapsed"]]
  tryCatch({
    pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
    fixture <- adapters$lane_b_phylo_q4_dense_fixture(row$seed[[1L]])
    fit <- fixture$fit(fixture$data)
    target <- row$profile_parameter[[1L]]
    target_rows <- drmTMB::profile_targets(fit)
    if (nrow(target_rows[target_rows$parm == target & target_rows$profile_ready %in% TRUE, , drop = FALSE]) != 1L) stop_now("The exact dense-q4 target is not uniquely profile-ready.")
    profile <- stats::profile(fit, parm = target, trace = TRUE)
    trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    one <- function(name) { z <- unique(trace[[name]]); if (!nrow(trace) || length(z) != 1L) stop_now("Profile trace has no unique ", name); z[[1L]] }
    status <- as.character(one("conf.status")); message <- as.character(one("profile.message")); estimate <- as.numeric(one("estimate")); lower <- as.numeric(one("conf.low")); upper <- as.numeric(one("conf.high"))
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = as.character(one("transformation")), estimate = estimate)
    correlations <- unname(fit$corpars$phylo)
    if (!length(correlations) || any(!is.finite(correlations))) stop_now("Dense-q4 correlation diagnostics are absent or nonfinite.")
    correlation_boundary <- any(abs(correlations) >= .995)
    complete <- identical(status, "profile") && identical(message, "ok")
    pass <- complete && !isTRUE(diagnostics$boundary) && !correlation_boundary && all(is.finite(c(estimate, lower, upper))) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- row$cell_id; trace$target_id <- row$target_id; trace$seed <- row$seed; trace$information_rung <- row$information_rung
    interval <- data.frame(cell_id = row$cell_id, target_id = row$target_id, dgp_id = row$dgp_id, seed = row$seed, lower = lower, upper = upper, profile_engine = "tmbprofile", stringsAsFactors = FALSE)
    write_tsv(trace, paths$trace); write_tsv(interval, paths$interval)
    receipt <- data.frame(cell_id = row$cell_id, target_id = row$target_id, dgp_id = row$dgp_id, dgp_version = row$dgp_version, profile_parameter = target, target_truth = row$truth, seed = row$seed, information_rung = row$information_rung, group_count = row$group_count, within_group_replicates = row$within_group_replicates, source_sha = sha, conf_status = if (pass) "profile" else "profile_failed", profile_engine = "tmbprofile", estimate = estimate, lower = if (pass) lower else NA_real_, upper = if (pass) upper else NA_real_, convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diagnostics$boundary), max_abs_correlation = max(abs(correlations)), correlation_boundary = correlation_boundary, clamp_limited = identical(status, "clamp_limited"), trace_complete = complete, failure_reason = if (pass) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else if (correlation_boundary) "a dense-q4 correlation nuisance is boundary-adjacent" else message, elapsed_seconds = proc.time()[["elapsed"]] - started, runner_sha256 = hash(script), adapter_sha256 = hash(file.path(root, "tools", "lane-b-phylo-q4-dense-highinfo-adapters.R")), trace_path = normalizePath(paths$trace, mustWork = TRUE), interval_path = normalizePath(paths$interval, mustWork = TRUE), trace_sha256 = hash(paths$trace), interval_sha256 = hash(paths$interval), stringsAsFactors = FALSE)
    write_tsv(receipt, paths$receipt)
    message("Dense q4 receipt ", row$cell_id, ": ", receipt$conf_status)
  }, error = function(error) {
    write_tsv(data.frame(cell_id = row$cell_id, target_id = row$target_id, dgp_id = row$dgp_id, source_sha = sha, conf_status = "profile_failed", profile_engine = "tmbprofile", trace_complete = FALSE, failure_reason = conditionMessage(error), stringsAsFactors = FALSE), paths$receipt)
    stop(error)
  })
}
if (sys.nframe() == 0L) main()
