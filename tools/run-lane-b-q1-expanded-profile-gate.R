#!/usr/bin/env Rscript
# Target-wise retained local profile gate for the reviewed expanded q1 cohort.
# It accepts only one frozen cell::target::DGP contract at a time; a cell with
# multiple targets is promotable only after every registered target has a pass.

`%||%` <- function(x, y) if (is.null(x) || !length(x)) y else x
q1_expanded_gate_stop <- function(...) stop(..., call. = FALSE)
q1_expanded_gate_batch <- "q1-expanded-whole-cell"
q1_expanded_gate_file <- grep("^--file=", commandArgs(FALSE), value = TRUE)
q1_expanded_gate_script <- normalizePath(
  if (length(q1_expanded_gate_file)) sub("^--file=", "", q1_expanded_gate_file[[1L]]) else
    "tools/run-lane-b-q1-expanded-profile-gate.R",
  mustWork = FALSE
)
q1_expanded_gate_root <- local({
  candidates <- c(file.path(dirname(q1_expanded_gate_script), ".."), ".", "..", "../..")
  roots <- candidates[file.exists(file.path(candidates, "tools", "run-lane-b-q1-expanded-profile-gate.R"))]
  if (!length(roots)) q1_expanded_gate_stop("Cannot locate the expanded q1 profile-gate root.")
  normalizePath(roots[[1L]], mustWork = TRUE)
})

q1_expanded_gate_sha256 <- function(path) {
  if (!file.exists(path)) q1_expanded_gate_stop("Cannot hash missing file: ", path)
  command <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(command, "sha256sum")) path else c("-a", "256", path)
  out <- suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE))
  if (!length(out) || !grepl("^[0-9a-f]{64}\\s", out[[1L]])) q1_expanded_gate_stop("Cannot hash file: ", path)
  sub("\\s.*$", "", out[[1L]])
}

q1_expanded_gate_git <- function(args) {
  out <- suppressWarnings(system2("git", c("-C", q1_expanded_gate_root, args), stdout = TRUE, stderr = TRUE))
  if ((attr(out, "status") %||% 0L) != 0L) return(NA_character_)
  paste(out, collapse = "\n")
}

q1_expanded_gate_args <- function(args) {
  out <- list(dry_run = FALSE)
  for (arg in args) {
    if (identical(arg, "--dry-run")) { out$dry_run <- TRUE; next }
    if (!grepl("^--[A-Za-z][A-Za-z-]*=.+$", arg)) q1_expanded_gate_stop("Arguments must use --name=value syntax (except --dry-run).")
    kv <- strsplit(substring(arg, 3L), "=", fixed = TRUE)[[1L]]
    if (!is.null(out[[kv[[1L]]]])) q1_expanded_gate_stop("Duplicate argument: --", kv[[1L]], ".")
    out[[kv[[1L]]]] <- paste(kv[-1L], collapse = "=")
  }
  required <- c("cell", "target-id", "seed", "rung", "output-dir")
  missing <- required[vapply(required, function(x) is.null(out[[x]]) || !nzchar(out[[x]]), logical(1L))]
  if (length(missing)) q1_expanded_gate_stop("Missing required argument(s): --", paste(missing, collapse = ", --"), "=.")
  extra <- setdiff(names(out), c(required, "goal-authorized", "dry_run"))
  if (length(extra)) q1_expanded_gate_stop("Unsupported argument(s): --", paste(extra, collapse = ", --"), ".")
  out$seed <- suppressWarnings(as.integer(out$seed))
  if (length(out$seed) != 1L || is.na(out$seed) || out$seed < 1L) q1_expanded_gate_stop("--seed must be a positive integer.")
  out
}

q1_expanded_gate_contract <- function(cell, target_id, seed, rung) {
  validator <- new.env(parent = globalenv())
  sys.source(file.path(q1_expanded_gate_root, "tools", "validate-lane-b-q1-expanded-whole-cell-contracts.R"), envir = validator)
  registry <- validator$lane_b_q1_expanded_read_validate(q1_expanded_gate_root)
  adapters <- new.env(parent = globalenv())
  sys.source(file.path(q1_expanded_gate_root, "tools", "lane-b-q1-expanded-production-adapters.R"), envir = adapters)
  row <- adapters$lane_b_q1_expanded_production_row(cell, target_id, seed, rung)
  authorization <- registry[registry$cell_id == cell & registry$target_id == target_id, , drop = FALSE]
  if (nrow(authorization) != 1L || !isTRUE(authorization$execution_authority[[1L]])) {
    q1_expanded_gate_stop("This exact q1 contract has no execution authority; retained review is required before a profile attempt.")
  }
  list(row = row, authorization = authorization, adapters = adapters)
}

q1_expanded_gate_expected_dir <- function(cell, source_sha = q1_expanded_gate_git(c("rev-parse", "HEAD"))) {
  file.path(q1_expanded_gate_root, "docs", "dev-log", "interval-feasibility", "results", source_sha, q1_expanded_gate_batch, cell)
}

q1_expanded_gate_normalize_dir <- function(path) {
  if (!grepl("^/", path)) path <- file.path(q1_expanded_gate_root, path)
  normalizePath(path, mustWork = FALSE)
}

q1_expanded_gate_paths <- function(output_dir, cell, target_id, seed, rung) {
  safe_target <- gsub("[^A-Za-z0-9]+", "-", sub("^[^:]+::", "", target_id))
  stem <- sprintf("lane-b-q1-expanded-profile-%s-%s-%s-seed-%d", cell, safe_target, rung, seed)
  list(trace = file.path(output_dir, paste0(stem, "-trace.tsv")), interval = file.path(output_dir, paste0(stem, "-interval.tsv")), receipt = file.path(output_dir, paste0(stem, "-receipt.tsv")))
}

q1_expanded_gate_write <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile("q1-expanded-", tmpdir = dirname(path), fileext = ".tsv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.table(x, tmp, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!file.rename(tmp, path)) q1_expanded_gate_stop("Cannot write retained artifact: ", path)
}

q1_expanded_gate_fresh <- function(paths) {
  existing <- unlist(paths[file.exists(unlist(paths))], use.names = TRUE)
  if (length(existing)) q1_expanded_gate_stop("Refusing to replace retained q1 artifact(s): ", paste(names(existing), collapse = ", "))
}

q1_expanded_gate_receipt <- function(row, cell, target_id, seed, rung, paths, fields) {
  cbind(data.frame(
    cell_id = cell, target_id = target_id, dgp_id = row$dgp_id,
    dgp_version = "q1-expanded-source-lift-2026-07-28", formula = row$formula,
    true_parameter_scale = "latent log-SD", profile_parameter = sub("^[^:]+::", "", target_id),
    information_rung = rung, requested_rung = rung, seed = seed,
    execution_information_rung = rung, binding_source = row$source_module,
    receipt_id = paste(cell, target_id, row$dgp_id, seed, sep = "::"),
    source = file.path(q1_expanded_gate_root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-28-q1-expanded-whole-cell-canonical-contracts.tsv"),
    source_sha = q1_expanded_gate_git(c("rev-parse", "HEAD")), recorded_at = format(Sys.time(), tz = "UTC", usetz = TRUE),
    structure_provider = sub("^.*:([^:(]+)\\(.*$", "\\1", sub("^[^:]+::", "", target_id)),
    q_gate = "q1", profile_engine = "tmbprofile", negative_control = FALSE,
    promotion_eligible = FALSE,
    runner_sha256 = q1_expanded_gate_sha256(q1_expanded_gate_script),
    adapter_sha256 = q1_expanded_gate_sha256(file.path(q1_expanded_gate_root, "tools", "lane-b-q1-expanded-production-adapters.R")),
    trace_path = normalizePath(paths$trace, mustWork = FALSE), interval_path = normalizePath(paths$interval, mustWork = FALSE),
    stringsAsFactors = FALSE
  ), as.data.frame(fields, stringsAsFactors = FALSE))
}

q1_expanded_gate_failure <- function(row, cell, target_id, seed, rung, paths, stage, error) {
  receipt <- q1_expanded_gate_receipt(row, cell, target_id, seed, rung, paths, list(
    conf_status = "profile_failed", estimate = NA_real_, lower = NA_real_, upper = NA_real_,
    convergence = NA_integer_, pdHess = NA, profile_boundary = NA, clamp_limited = NA,
    trace_complete = FALSE, clamp_reason = NA_character_, failure_reason = paste0(stage, ": ", conditionMessage(error)),
    trace_sha256 = NA_character_, interval_sha256 = NA_character_
  ))
  q1_expanded_gate_write(receipt, paths$receipt)
}

q1_expanded_gate_execute <- function(contract, cell, target_id, seed, rung, output_dir) {
  row <- contract$row
  expected <- q1_expanded_gate_normalize_dir(q1_expanded_gate_expected_dir(cell))
  output_dir <- q1_expanded_gate_normalize_dir(output_dir)
  if (!identical(output_dir, expected)) q1_expanded_gate_stop("--output-dir must be the source-SHA receipt path: ", expected)
  paths <- q1_expanded_gate_paths(output_dir, cell, target_id, seed, rung)
  q1_expanded_gate_fresh(paths); stage <- "source_load"
  tryCatch({
    if (!requireNamespace("pkgload", quietly = TRUE)) q1_expanded_gate_stop("pkgload is required for the exact source checkout.")
    pkgload::load_all(q1_expanded_gate_root, quiet = TRUE, export_all = FALSE)
    if (!identical(normalizePath(getNamespaceInfo(asNamespace("drmTMB"), "path"), mustWork = TRUE), q1_expanded_gate_root)) q1_expanded_gate_stop("Loaded package is not the exact source checkout.")
    stage <- "adapter"; adapter <- contract$adapters$lane_b_q1_expanded_production_adapter_fixture(cell, target_id, seed, rung)
    if (!identical(adapter$truth$target_id, target_id) || !identical(adapter$truth$dgp_id, row$dgp_id[[1L]]) || !identical(as.numeric(adapter$truth$target_truth), as.numeric(row$truth[[1L]]))) q1_expanded_gate_stop("Adapter truth differs from frozen q1 contract.")
    stage <- "fit"; started <- proc.time()[["elapsed"]]; fit <- adapter$fit(adapter$data)
    target <- sub("^[^:]+::", "", target_id)
    stage <- "target_check"; targets <- drmTMB::profile_targets(fit)
    if (nrow(targets[targets$parm == target & targets$profile_ready %in% TRUE, , drop = FALSE]) != 1L) q1_expanded_gate_stop("Frozen q1 target is not uniquely profile-ready: ", target)
    stage <- "profile"; profile <- stats::profile(fit, parm = target, trace = TRUE); trace <- as.data.frame(profile, stringsAsFactors = FALSE)
    status <- unique(as.character(trace$conf.status)); message <- unique(as.character(trace$profile.message)); lower <- unique(as.numeric(trace$conf.low)); upper <- unique(as.numeric(trace$conf.high)); estimate <- unique(as.numeric(trace$estimate))
    if (!nrow(trace) || length(status) != 1L || length(message) != 1L || length(lower) != 1L || length(upper) != 1L || length(estimate) != 1L) q1_expanded_gate_stop("q1 trace lacks one status/message/estimate/endpoint pair.")
    diagnostics <- drmTMB:::profile_interval_diagnostics(c(lower, upper), transformation = unique(trace$transformation)[[1L]], estimate = estimate)
    complete <- identical(status, "profile") && identical(message, "ok")
    passed <- complete && !isTRUE(diagnostics$boundary) && !identical(status, "clamp_limited") && is.finite(estimate) && is.finite(lower) && is.finite(upper) && lower < upper && estimate >= lower && estimate <= upper && fit$opt$convergence == 0L && isTRUE(fit$sdr$pdHess)
    trace$cell_id <- cell; trace$target_id <- target_id; trace$seed <- seed; trace$information_rung <- rung
    interval <- data.frame(cell_id = cell, target_id = target_id, seed = seed, information_rung = rung, profile_parameter = target, level = .95, lower = lower, upper = upper, profile_engine = "tmbprofile", stringsAsFactors = FALSE)
    q1_expanded_gate_write(trace, paths$trace); q1_expanded_gate_write(interval, paths$interval)
    receipt <- q1_expanded_gate_receipt(row, cell, target_id, seed, rung, paths, list(
      conf_status = if (passed) "profile" else "profile_failed", estimate = estimate,
      lower = if (passed) lower else NA_real_, upper = if (passed) upper else NA_real_,
      convergence = as.integer(fit$opt$convergence), pdHess = isTRUE(fit$sdr$pdHess),
      profile_boundary = isTRUE(diagnostics$boundary), clamp_limited = identical(status, "clamp_limited"),
      trace_complete = complete, clamp_reason = if (identical(status, "clamp_limited")) message else NA_character_, failure_reason = if (passed) NA_character_ else if (isTRUE(diagnostics$boundary)) diagnostics$message else message,
      elapsed_seconds = proc.time()[["elapsed"]] - started, trace_sha256 = q1_expanded_gate_sha256(paths$trace), interval_sha256 = q1_expanded_gate_sha256(paths$interval)
    ))
    q1_expanded_gate_write(receipt, paths$receipt); invisible(paths)
  }, error = function(error) { q1_expanded_gate_failure(row, cell, target_id, seed, rung, paths, stage, error); stop(error) })
}

q1_expanded_gate_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  parsed <- q1_expanded_gate_args(args)
  contract <- q1_expanded_gate_contract(parsed$cell, parsed[["target-id"]], parsed$seed, parsed$rung)
  if (isTRUE(parsed$dry_run)) { message("q1 expanded profile gate dry-run validated: ", parsed[["target-id"]]); return(invisible(contract$row)) }
  if (!identical(parsed[["goal-authorized"]], "lane-b-144-goal")) q1_expanded_gate_stop("Execution requires --goal-authorized=lane-b-144-goal.")
  q1_expanded_gate_execute(contract, parsed$cell, parsed[["target-id"]], parsed$seed, parsed$rung, parsed[["output-dir"]])
}

if (sys.nframe() == 0L) q1_expanded_gate_main()
