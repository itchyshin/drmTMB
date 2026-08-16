#!/usr/bin/env Rscript
# Retained, targetwise tmbprofile receipt gate for the two spatial q2 slopes.

stop_gate <- function(...) stop(..., call. = FALSE)
`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
script <- normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1L] %||% "tools/run-lane-b-spatial-q2-slope-profile-gate.R"), mustWork = FALSE)
root <- normalizePath(file.path(dirname(script), ".."), mustWork = TRUE)
hash_file <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"; args <- if (identical(cmd, "sha256sum")) path else c("-a", "256", path)
  out <- system2(cmd, args, stdout = TRUE, stderr = TRUE); if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[1L])) stop_gate("Cannot hash ", path); sub("\\s.*$", "", out[1L])
}
git_head <- function() paste(system2("git", c("-C", root, "rev-parse", "HEAD"), stdout = TRUE), collapse = "")
parse <- function(args) {
  v <- as.list(sub("^[^=]+=", "", args)); names(v) <- sub("^--([^=]+)=.*$", "\\1", args)
  if ("--dry-run" %in% args) return(list(dry = TRUE, values = v))
  required <- c("cell", "seed", "rung", "output-dir", "goal-authorized")
  if (!setequal(names(v), required)) stop_gate("Usage: --cell= --seed= --rung= --output-dir= --goal-authorized=.")
  if (!identical(v[["goal-authorized"]], "lane-b-144-goal")) stop_gate("Requires --goal-authorized=lane-b-144-goal.")
  list(dry = FALSE, values = v)
}
paths_for <- function(out, cell, seed) {
  stem <- sprintf("lane-b-spatial-q2-slope-profile-%s-low-seed-%s", cell, seed)
  list(trace = file.path(out, paste0(stem, "-trace.tsv")), interval = file.path(out, paste0(stem, "-interval.tsv")), receipt = file.path(out, paste0(stem, "-receipt.tsv")))
}
write_tsv <- function(x, p) { dir.create(dirname(p), recursive = TRUE, showWarnings = FALSE); utils::write.table(x, p, sep = "\t", quote = FALSE, row.names = FALSE, na = "") }
main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- parse(args)
  env <- new.env(parent = baseenv()); sys.source(file.path(root, "tools", "validate-lane-b-spatial-q2-slope-contracts.R"), envir = env)
  registry <- env$lane_b_spatial_q2_slope_validate(root)
  if (parsed$dry) { message("Spatial q2 slope static contract validated: ", nrow(registry), " targets."); return(invisible(registry)) }
  v <- parsed$values; cell <- v$cell; seed <- as.integer(v$seed); rung <- v$rung
  row <- registry[registry$cell_id == cell, , drop = FALSE]
  if (nrow(row) != 1L || !identical(seed, 302L) || !identical(rung, "low")) stop_gate("Only the exact frozen spatial q2 slope contract is executable.")
  paths <- paths_for(v[["output-dir"]], cell, seed); if (any(file.exists(unlist(paths)))) stop_gate("Refusing to replace retained artifact.")
  adapters <- new.env(parent = globalenv()); sys.source(file.path(root, "tools", "lane-b-spatial-q2-slope-adapters.R"), envir = adapters)
  stage <- "adapter"
  tryCatch({
    fixture <- adapters$lane_b_spatial_q2_slope_fixture(cell, seed, rung)
    if (!identical(fixture$truth$profile_parameter, row$profile_parameter[[1L]]) || !identical(fixture$truth$dgp_id, row$dgp_id[[1L]])) stop_gate("Fixture differs from exact contract.")
    stage <- "load"; pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
    stage <- "fit"; fit <- fixture$fit(fixture$data); target <- row$profile_parameter[[1L]]
    targets <- drmTMB::profile_targets(fit); if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) stop_gate("Target is not uniquely profile-ready.")
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    if (!nrow(trace)) stop_gate("Empty tmbprofile trace.")
    one <- function(field) { z <- unique(trace[[field]]); if (length(z) != 1L) stop_gate("Trace has non-unique ", field); z[[1L]] }
    status <- as.character(one("conf.status")); msg <- as.character(one("profile.message")); lo <- as.numeric(one("conf.low")); hi <- as.numeric(one("conf.high")); est <- as.numeric(one("estimate"))
    diag <- drmTMB:::profile_interval_diagnostics(c(lo, hi), transformation = as.character(one("transformation")), estimate = est)
    complete <- identical(status, "profile") && identical(msg, "ok")
    passed <- complete && !isTRUE(diag$boundary) && !identical(status, "clamp_limited") && all(is.finite(c(est, lo, hi))) && lo < hi && est >= lo && est <= hi && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- cell; trace$target_id <- row$target_id; trace$seed <- seed; trace$execution_information_rung <- rung
    interval <- data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, seed = seed, lower = lo, upper = hi, profile_engine = "tmbprofile")
    write_tsv(trace, paths$trace); write_tsv(interval, paths$interval)
    receipt <- data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, dgp_version = row$dgp_version, formula = row$formula, true_parameter_scale = row$true_parameter_scale, profile_parameter = target, seed = seed, execution_information_rung = rung, source_sha = git_head(), recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE), conf_status = if (passed) "profile" else "profile_failed", profile_engine = "tmbprofile", estimate = est, lower = if (passed) lo else NA_real_, upper = if (passed) hi else NA_real_, convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diag$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete, failure_reason = if (passed) NA_character_ else if (isTRUE(diag$boundary)) diag$message else msg, promotion_eligible = FALSE, runner_sha256 = hash_file(script), adapter_sha256 = hash_file(file.path(root, "tools", "lane-b-spatial-q2-slope-adapters.R")), trace_path = normalizePath(paths$trace, mustWork = TRUE), interval_path = normalizePath(paths$interval, mustWork = TRUE), trace_sha256 = hash_file(paths$trace), interval_sha256 = hash_file(paths$interval), stringsAsFactors = FALSE)
    write_tsv(receipt, paths$receipt); message("Spatial q2 slope profile receipt: ", cell, " / ", receipt$conf_status); invisible(paths)
  }, error = function(e) { write_tsv(data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, source_sha = git_head(), conf_status = "profile_failed", profile_engine = "tmbprofile", trace_complete = FALSE, failure_reason = paste0(stage, ": ", conditionMessage(e)), promotion_eligible = FALSE), paths$receipt); stop(e) })
}
if (sys.nframe() == 0L) main()
