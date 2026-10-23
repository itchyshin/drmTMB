#!/usr/bin/env Rscript
# One retained local profile attempt for an authorised B2 E0 q2 tuple.

b2_e0_q2_stop <- function(...) stop(..., call. = FALSE)
b2_e0_q2_root <- function() normalizePath(".", mustWork = TRUE)
b2_e0_q2_hash <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(cmd, "sha256sum")) path else c("-a", "256", path)
  sub("\\s.*$", "", system2(cmd, args, stdout = TRUE))
}
b2_e0_q2_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
}
b2_e0_q2_paths <- function(root, source_sha, cell, seed) {
  d <- file.path(root, "docs", "dev-log", "interval-feasibility", "results", source_sha, "b2-e0-q2-high", cell)
  stem <- sprintf("b2-e0-q2-%s-high-seed-%d", cell, seed)
  list(dir = d, started = file.path(d, paste0(stem, "-attempt-started.tsv")), trace = file.path(d, paste0(stem, "-trace.tsv")), interval = file.path(d, paste0(stem, "-interval.tsv")), receipt = file.path(d, paste0(stem, "-receipt.tsv")))
}
b2_e0_q2_authorization <- function(root, path) {
  registry_path <- file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-30-b2-e0-q2-admission-registry.tsv")
  registry <- utils::read.delim(registry_path, check.names = FALSE, stringsAsFactors = FALSE)
  x <- utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
  fields <- c(names(registry), "execution_scope", "authorization_state")
  if (!identical(names(x), fields) || anyDuplicated(x$cell_id) || nrow(x) != 8L) b2_e0_q2_stop("Authorization must contain the exact eight-row E0 q2 cohort once each.")
  if (!identical(x[, names(registry), drop = FALSE], registry) || !all(x$execution_scope == "local_only") || !all(x$authorization_state == "approved_for_local_profile")) b2_e0_q2_stop("Authorization differs from the frozen non-authorising E0 q2 registry.")
  x
}
b2_e0_q2_assert_source <- function(root, source_sha) {
  paths <- c("R/drmTMB.R", "tools/b2-majority-gaussian-q2-fixtures.R", "tools/validate-b2-majority-high-q2-slope-contract.R", "docs/dev-log/interval-campaign-bindings/2026-07-30-b2-majority-high-q2-slope-8-contract.tsv")
  if (system2("git", c("-C", root, "merge-base", "--is-ancestor", source_sha, "HEAD")) != 0L || system2("git", c("-C", root, "diff", "--quiet", source_sha, "--", paths)) != 0L) b2_e0_q2_stop("Package source, fixture, or contract differs from the frozen source SHA.")
}
b2_e0_q2_failure <- function(row, paths, stage, error) {
  b2_e0_q2_write(data.frame(cell_id = row$cell_id, target_id = row$target_id, dgp_id = row$dgp_id, seed = row$seed, information_rung = row$information_rung, source_sha = row$source_sha, profile_engine = "tmbprofile", conf_status = "profile_failed", estimate = NA_real_, lower = NA_real_, upper = NA_real_, convergence = NA_integer_, pdHess = NA, profile_boundary = NA, clamp_limited = NA, trace_complete = FALSE, failure_reason = paste0(stage, ": ", conditionMessage(error)), trace_sha256 = NA_character_, interval_sha256 = NA_character_, stringsAsFactors = FALSE), paths$receipt)
}
b2_e0_q2_run <- function(root, row, dry_run = FALSE) {
  paths <- b2_e0_q2_paths(root, row$source_sha, row$cell_id, row$seed)
  if (dry_run) return(invisible(paths))
  if (any(file.exists(unlist(paths[c("started", "trace", "interval", "receipt")])))) b2_e0_q2_stop("Retained attempt already exists; refusing retry or overwrite for ", row$cell_id, ".")
  b2_e0_q2_write(data.frame(cell_id = row$cell_id, target_id = row$target_id, dgp_id = row$dgp_id, seed = row$seed, information_rung = row$information_rung, source_sha = row$source_sha, attempt_state = "started", stringsAsFactors = FALSE), paths$started)
  stage <- "source_load"
  tryCatch({
    pkgload::load_all(root, quiet = TRUE, export_all = FALSE)
    source(file.path(root, "tools", "b2-majority-gaussian-q2-fixtures.R"))
    stage <- "fixture"; fixture <- b2_majority_q2_fixture(root, row$cell_id, row$target_id, row$seed, row$information_rung)
    stage <- "fit"; fit <- fixture$fit(fixture$data)
    stage <- "sdreport"; if (is.null(fit$sdr) || is.null(fit$sdr$pdHess)) b2_e0_q2_stop("A real sdreport is required before evaluating pdHess.")
    target <- sub("^[^:]+::", "", row$target_id); targets <- drmTMB::profile_targets(fit)
    stage <- "target_check"; if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) b2_e0_q2_stop("Exact target is not uniquely profile-ready.")
    stage <- "profile"; trace <- as.data.frame(stats::profile(fit, parm = target, trace = TRUE), stringsAsFactors = FALSE)
    status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (!nrow(trace) || length(status) != 1L || length(message) != 1L || length(lower) != 1L || length(upper) != 1L || length(estimate) != 1L) b2_e0_q2_stop("Profile trace lacks one complete endpoint/status record.")
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    passed <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- row$cell_id; trace$target_id <- row$target_id; trace$seed <- row$seed; trace$information_rung <- row$information_rung; b2_e0_q2_write(trace, paths$trace)
    b2_e0_q2_write(data.frame(cell_id = row$cell_id, target_id = row$target_id, seed = row$seed, information_rung = row$information_rung, level = .95, lower = lower, upper = upper, estimate = estimate, profile_engine = "tmbprofile", stringsAsFactors = FALSE), paths$interval)
    reason <- if (passed) NA_character_ else if (!complete) paste("incomplete profile:", message) else if (isTRUE(diagnostics$boundary)) diagnostics$message else if (!isTRUE(fit$sdr$pdHess)) "pdHess is FALSE" else "profile did not satisfy the unclamped endpoint contract"
    b2_e0_q2_write(data.frame(cell_id = row$cell_id, target_id = row$target_id, dgp_id = row$dgp_id, seed = row$seed, information_rung = row$information_rung, source_sha = row$source_sha, profile_engine = "tmbprofile", conf_status = if (passed) "profile" else "profile_failed", estimate = estimate, lower = if (passed) lower else NA_real_, upper = if (passed) upper else NA_real_, convergence = fit$opt$convergence, pdHess = isTRUE(fit$sdr$pdHess), profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete, failure_reason = reason, trace_sha256 = b2_e0_q2_hash(paths$trace), interval_sha256 = b2_e0_q2_hash(paths$interval), stringsAsFactors = FALSE), paths$receipt)
    invisible(paths)
  }, error = function(error) { b2_e0_q2_failure(row, paths, stage, error); invisible(paths) })
}
b2_e0_q2_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  vals <- strsplit(sub("^--", "", args[grepl("^--", args)]), "=", fixed = TRUE)
  p <- stats::setNames(vapply(vals, function(x) paste(x[-1L], collapse = "="), character(1)), vapply(vals, `[`, character(1), 1L))
  if (!all(c("cell", "authorization") %in% names(p)) || any(!nzchar(p[c("cell", "authorization")]))) b2_e0_q2_stop("Use --cell=<exact cell> --authorization=<exact TSV> [--dry-run].")
  root <- b2_e0_q2_root(); x <- b2_e0_q2_authorization(root, p[["authorization"]]); row <- x[x$cell_id == p[["cell"]], , drop = FALSE]
  if (nrow(row) != 1L) b2_e0_q2_stop("Cell is not in the exact approved cohort.")
  b2_e0_q2_assert_source(root, row$source_sha)
  b2_e0_q2_run(root, row, dry_run = "dry-run" %in% names(p))
}
if (sys.nframe() == 0L) b2_e0_q2_main()
