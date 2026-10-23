#!/usr/bin/env Rscript
q4_scale_stop <- function(...) stop(..., call. = FALSE)
q4_scale_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
q4_scale_script <- normalizePath(if (length(q4_scale_file)) sub("^--file=", "", q4_scale_file[[1L]]) else "tools/run-lane-b-phylo-q4-scale-profile-gate.R", mustWork = FALSE)
q4_scale_root <- normalizePath(file.path(dirname(q4_scale_script), ".."), mustWork = TRUE)
q4_scale_hash <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  out <- system2(cmd, if (identical(cmd, "sha256sum")) path else c("-a", "256", path), stdout = TRUE, stderr = TRUE)
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) q4_scale_stop("Cannot hash ", path)
  sub("\\s.*$", "", out[[1L]])
}
q4_scale_head <- function() paste(system2("git", c("-C", q4_scale_root, "rev-parse", "HEAD"), stdout = TRUE), collapse = "")
q4_scale_write <- function(x, path) { dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE); utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "") }
q4_scale_args <- function(args) {
  if (identical(args, "--dry-run")) return(list(dry = TRUE))
  value <- as.list(sub("^[^=]+=", "", args)); names(value) <- sub("^--([^=]+)=.*$", "\\1", args)
  required <- c("cell", "seed", "rung", "output-dir", "goal-authorized")
  if (!setequal(names(value), required) || !identical(value[["goal-authorized"]], "lane-b-144-goal")) q4_scale_stop("Requires exact --cell, --seed, --rung, --output-dir, and --goal-authorized=lane-b-144-goal.")
  list(dry = FALSE, value = value)
}
q4_scale_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- q4_scale_args(args); validation <- new.env(parent = baseenv())
  sys.source(file.path(q4_scale_root, "tools", "validate-lane-b-phylo-q4-scale-contracts.R"), envir = validation)
  registry <- validation$lane_b_phylo_q4_scale_validate(q4_scale_root)
  if (parsed$dry) { message("Validated q4 phylo scale contract: ", nrow(registry), " targets."); return(invisible(registry)) }
  value <- parsed$value; cell <- value$cell; seed <- as.integer(value$seed); rung <- value$rung
  row <- registry[registry$cell_id == cell, , drop = FALSE]
  if (nrow(row) != 1L || !identical(seed, 3L) || !identical(rung, "high")) q4_scale_stop("Only an exact high-rung q4 scale target is executable.")
  stem <- sprintf("lane-b-phylo-q4-scale-profile-%s-high-seed-3", cell)
  paths <- list(trace = file.path(value[["output-dir"]], paste0(stem, "-trace.tsv")), interval = file.path(value[["output-dir"]], paste0(stem, "-interval.tsv")), receipt = file.path(value[["output-dir"]], paste0(stem, "-receipt.tsv")))
  if (any(file.exists(unlist(paths)))) q4_scale_stop("Refusing to replace retained artifact.")
  stage <- "adapter"
  tryCatch({
    adapter <- new.env(parent = globalenv()); sys.source(file.path(q4_scale_root, "tools", "lane-b-phylo-q4-scale-adapters.R"), envir = adapter)
    fixture <- adapter$lane_b_phylo_q4_scale_fixture(cell, seed, rung)
    if (!identical(fixture$truth$profile_parameter, row$profile_parameter[[1L]]) || !identical(fixture$truth$dgp_id, row$dgp_id[[1L]])) q4_scale_stop("Adapter differs from frozen q4 scale contract.")
    stage <- "load"; pkgload::load_all(q4_scale_root, quiet = TRUE, export_all = FALSE)
    stage <- "fit"; fit <- fixture$fit(fixture$data); target <- row$profile_parameter[[1L]]; targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) q4_scale_stop("Q4 scale target is not uniquely profile-ready.")
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    if (!nrow(trace)) q4_scale_stop("Empty profile trace.")
    one <- function(name) { x <- unique(trace[[name]]); if (length(x) != 1L) q4_scale_stop("Trace has non-unique ", name); x[[1L]] }
    status <- as.character(one("conf.status")); message <- as.character(one("profile.message")); lower <- as.numeric(one("conf.low")); upper <- as.numeric(one("conf.high")); estimate <- as.numeric(one("estimate"))
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = as.character(one("transformation")), estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    pass <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && all(is.finite(c(estimate, lower, upper))) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- cell; trace$target_id <- row$target_id; trace$seed <- seed; trace$execution_information_rung <- rung
    interval <- data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, seed = seed, lower = lower, upper = upper, profile_engine = "tmbprofile")
    q4_scale_write(trace, paths$trace); q4_scale_write(interval, paths$interval)
    receipt <- data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, dgp_version = row$dgp_version, formula = row$formula, true_parameter_scale = row$true_parameter_scale, profile_parameter = target, seed = seed, execution_information_rung = rung, source_sha = q4_scale_head(), recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE), conf_status = if (pass) "profile" else "profile_failed", profile_engine = "tmbprofile", estimate = estimate, lower = if (pass) lower else NA_real_, upper = if (pass) upper else NA_real_, convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete, failure_reason = if (pass) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else message, promotion_eligible = FALSE, runner_sha256 = q4_scale_hash(q4_scale_script), adapter_sha256 = q4_scale_hash(file.path(q4_scale_root, "tools", "lane-b-phylo-q4-scale-adapters.R")), trace_path = normalizePath(paths$trace, mustWork = TRUE), interval_path = normalizePath(paths$interval, mustWork = TRUE), trace_sha256 = q4_scale_hash(paths$trace), interval_sha256 = q4_scale_hash(paths$interval), stringsAsFactors = FALSE)
    q4_scale_write(receipt, paths$receipt); message("Q4 phylo scale receipt: ", cell, " / ", receipt$conf_status)
  }, error = function(error) {
    q4_scale_write(data.frame(cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, source_sha = q4_scale_head(), conf_status = "profile_failed", profile_engine = "tmbprofile", trace_complete = FALSE, failure_reason = paste0(stage, ": ", conditionMessage(error)), promotion_eligible = FALSE), paths$receipt)
    stop(error)
  })
}
if (sys.nframe() == 0L) q4_scale_main()
