#!/usr/bin/env Rscript
# Retained local profile gate for ten exact production-DGP structured q2 targets.
# Each receipt is target-wise, while the static validator retains the complete
# two-component cell inventory.  This runner has no q4 or K=12 route.

q2_gate_stop <- function(...) stop(..., call. = FALSE)
q2_gate_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
q2_gate_script <- normalizePath(if (length(q2_gate_file)) sub("^--file=", "", q2_gate_file[[1L]]) else "tools/run-lane-b-structured-q2-production-profile-gate.R", mustWork = FALSE)
q2_gate_root <- normalizePath(file.path(dirname(q2_gate_script), ".."), mustWork = TRUE)

q2_gate_sha256 <- function(path) {
  if (!file.exists(path)) q2_gate_stop("Cannot hash missing file: ", path)
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  out <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) q2_gate_stop("Cannot hash file: ", path)
  sub("\\s.*$", "", out[[1L]])
}

q2_gate_git <- function(args) {
  out <- suppressWarnings(system2("git", c("-C", q2_gate_root, args), stdout = TRUE, stderr = TRUE))
  if ((attr(out, "status") %||% 0L) != 0L) return(NA_character_)
  paste(out, collapse = "\n")
}
`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x

q2_gate_args <- function(args) {
  out <- list(dry_run = FALSE)
  for (arg in args) {
    if (identical(arg, "--dry-run")) { out$dry_run <- TRUE; next }
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) q2_gate_stop("Arguments must use --name=value syntax (except --dry-run).")
    kv <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    if (!is.null(out[[kv[[1L]]]])) q2_gate_stop("Duplicate argument: --", kv[[1L]], ".")
    out[[kv[[1L]]]] <- paste(kv[-1L], collapse = "=")
  }
  required <- c("cell", "seed", "rung", "output-dir")
  missing <- required[vapply(required, function(x) is.null(out[[x]]) || !nzchar(out[[x]]), logical(1L))]
  if (length(missing)) q2_gate_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  extra <- setdiff(names(out), c(required, "goal-authorized", "dry_run"))
  if (length(extra)) q2_gate_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out$seed <- suppressWarnings(as.integer(out$seed))
  if (length(out$seed) != 1L || is.na(out$seed) || out$seed < 1L) q2_gate_stop("--seed must be a positive integer.")
  out
}

q2_gate_contract <- function(cell, seed, rung) {
  env <- new.env(parent = baseenv())
  sys.source(file.path(q2_gate_root, "tools", "validate-lane-b-structured-q2-production-whole-cell-contracts.R"), envir = env)
  partial <- utils::read.delim(
    file.path(q2_gate_root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-27-b1-recovered-subset.tsv"),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  proposed <- utils::read.delim(
    file.path(q2_gate_root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-28-structured-q2-production-whole-cell-proposed-registry.tsv"),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  authorization <- utils::read.delim(
    env$structured_q2_production_authorization_path(q2_gate_root),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  registry <- env$structured_q2_production_validate(partial, proposed, authorization)
  row <- registry[registry$cell_id == cell, , drop = FALSE]
  if (nrow(row) != 1L) q2_gate_stop("--cell is not one exact q2 production target.")
  if (!identical(as.integer(seed), 20260727L) || !identical(as.character(rung), "low")) q2_gate_stop("q2 production receipt requires frozen seed 20260727 and rung low.")
  row
}

q2_gate_paths <- function(output_dir, cell, seed, rung) {
  stem <- sprintf("lane-b-q2-production-profile-%s-%s-seed-%d", cell, rung, seed)
  list(trace = file.path(output_dir, paste0(stem, "-trace.tsv")), interval = file.path(output_dir, paste0(stem, "-interval.tsv")), receipt = file.path(output_dir, paste0(stem, "-receipt.tsv")))
}

q2_gate_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("q2-profile-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.table(x, tmp, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(tmp, path)) q2_gate_stop("Cannot write retained artifact: ", path)
}

q2_gate_fresh <- function(paths) {
  existing <- unlist(paths[file.exists(unlist(paths))], use.names = TRUE)
  if (length(existing)) q2_gate_stop("Refusing to replace retained q2 artifact(s): ", paste(names(existing), collapse = ", "))
}

q2_gate_failure <- function(row, cell, seed, rung, paths, stage, error) {
  receipt <- data.frame(
    cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, dgp_version = row$dgp_version,
    formula = row$formula, true_parameter_scale = row$true_parameter_scale, profile_parameter = row$profile_parameter,
    seed = seed, execution_information_rung = rung, whole_cell_component_inventory = row$whole_cell_component_inventory,
    source_sha = q2_gate_git(c("rev-parse", "HEAD")), recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    conf_status = "profile_failed", profile_engine = "tmbprofile", estimate = NA_real_, lower = NA_real_, upper = NA_real_,
    convergence = NA_integer_, pdHess = NA, profile_boundary = NA, clamp_limited = NA, trace_complete = FALSE,
    failure_reason = paste0(stage, ": ", conditionMessage(error)), promotion_eligible = FALSE,
    runner_sha256 = q2_gate_sha256(q2_gate_script), adapter_sha256 = q2_gate_sha256(file.path(q2_gate_root, "tools", "lane-b-structured-q2-production-adapters.R")),
    trace_path = normalizePath(paths$trace, mustWork = FALSE), interval_path = normalizePath(paths$interval, mustWork = FALSE),
    trace_sha256 = NA_character_, interval_sha256 = NA_character_, stringsAsFactors = FALSE
  )
  q2_gate_write(receipt, paths$receipt)
}

q2_gate_execute <- function(row, cell, seed, rung, output_dir) {
  paths <- q2_gate_paths(output_dir, cell, seed, rung); q2_gate_fresh(paths); stage <- "adapter"
  tryCatch({
    adapters <- new.env(parent = globalenv())
    sys.source(file.path(q2_gate_root, "tools", "lane-b-structured-q2-production-adapters.R"), envir = adapters)
    adapter <- adapters$lane_b_structured_q2_production_adapter_fixture(cell, seed, rung)
    if (!identical(adapter$truth$profile_parameter, row$profile_parameter[[1L]]) || !identical(adapter$truth$dgp_id, row$dgp_id[[1L]])) q2_gate_stop("Adapter truth differs from canonical q2 target contract.")
    stage <- "source_load"; pkgload::load_all(q2_gate_root, quiet = TRUE, export_all = FALSE)
    stage <- "fit"; fit <- adapter$fit(adapter$data)
    stage <- "target_check"; target <- row$profile_parameter[[1L]]; targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) q2_gate_stop("Frozen q2 target is not uniquely profile-ready: ", target)
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    if (!nrow(trace)) q2_gate_stop("tmbprofile returned an empty trace.")
    status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (length(status) != 1L || length(message) != 1L || length(lower) != 1L || length(upper) != 1L || length(estimate) != 1L) q2_gate_stop("q2 trace lacks one status/message/estimate/endpoint pair.")
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    passed <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- cell; trace$target_id <- row$target_id; trace$seed <- seed; trace$execution_information_rung <- rung
    interval <- data.frame(cell_id = cell, target_id = row$target_id, seed = seed, execution_information_rung = rung, profile_parameter = target, level = .95, lower = lower, upper = upper, profile_engine = "tmbprofile", stringsAsFactors = FALSE)
    q2_gate_write(trace, paths$trace); q2_gate_write(interval, paths$interval)
    receipt <- data.frame(
      cell_id = cell, target_id = row$target_id, dgp_id = row$dgp_id, dgp_version = row$dgp_version,
      formula = row$formula, true_parameter_scale = row$true_parameter_scale, profile_parameter = target,
      seed = seed, execution_information_rung = rung, whole_cell_component_inventory = row$whole_cell_component_inventory,
      source_sha = q2_gate_git(c("rev-parse", "HEAD")), recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
      conf_status = if (passed) "profile" else "profile_failed", profile_engine = "tmbprofile", estimate = estimate,
      lower = if (passed) lower else NA_real_, upper = if (passed) upper else NA_real_, convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess),
      profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"), trace_complete = complete,
      failure_reason = if (passed) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else message,
      promotion_eligible = FALSE, runner_sha256 = q2_gate_sha256(q2_gate_script), adapter_sha256 = q2_gate_sha256(file.path(q2_gate_root, "tools", "lane-b-structured-q2-production-adapters.R")),
      trace_path = normalizePath(paths$trace, mustWork = TRUE), interval_path = normalizePath(paths$interval, mustWork = TRUE),
      trace_sha256 = q2_gate_sha256(paths$trace), interval_sha256 = q2_gate_sha256(paths$interval), stringsAsFactors = FALSE
    )
    q2_gate_write(receipt, paths$receipt); invisible(paths)
  }, error = function(error) { q2_gate_failure(row, cell, seed, rung, paths, stage, error); stop(error) })
}

q2_gate_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- q2_gate_args(args); row <- q2_gate_contract(parsed$cell, parsed$seed, parsed$rung)
  if (isTRUE(parsed$dry_run)) { message("q2 production profile gate dry-run validated: ", parsed$cell); return(invisible(row)) }
  if (!identical(parsed[["goal-authorized"]], "lane-b-144-goal")) q2_gate_stop("Execution requires --goal-authorized=lane-b-144-goal.")
  q2_gate_execute(row, parsed$cell, parsed$seed, parsed$rung, parsed[["output-dir"]])
}

if (sys.nframe() == 0L) q2_gate_main()
