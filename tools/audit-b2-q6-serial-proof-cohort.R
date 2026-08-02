#!/usr/bin/env Rscript
# Independent, recommendation-only audit for the executed q6 serial proof cohort.
# It deliberately derives the result root from runner_source_sha: the frozen
# authorization's profile_receipt_root predates the supervised runner and is
# retained as historical provenance rather than followed as an execution path.

b2_q6_audit_stop <- function(...) stop(..., call. = FALSE)

b2_q6_audit_hash <- function(path) {
  cmd <- if (nzchar(Sys.which("sha256sum"))) "sha256sum" else "shasum"
  args <- if (identical(cmd, "sha256sum")) path else c("-a", "256", path)
  sub("\\s.*$", "", system2(cmd, args, stdout = TRUE))
}

b2_q6_audit_one_file <- function(dir, suffix, cell) {
  found <- list.files(dir, pattern = paste0("-", suffix, "\\.tsv$"), full.names = TRUE)
  if (length(found) != 1L) b2_q6_audit_stop("Expected exactly one ", suffix, " artifact for ", cell, ".")
  found[[1L]]
}

b2_q6_audit_result_dir <- function(root, row) {
  file.path(root, "docs", "dev-log", "interval-feasibility", "results",
            row$runner_source_sha, "b2-q6-proof-profile", row$cell_id)
}

b2_q6_audit_source_enforces_serial <- function(root, sha) {
  cohort <- paste(system2("git", c("-C", root, "show", paste0(sha, ":tools/run-b2-q6-proof-profile-cohort.R")), stdout = TRUE), collapse = "\n")
  barrier <- paste(system2("git", c("-C", root, "show", paste0(sha, ":tools/b2-retained-profile-serial.R")), stdout = TRUE), collapse = "\n")
  grepl("b2_serial_run", cohort, fixed = TRUE) &&
    grepl("b2_serial_wait_for_terminal", barrier, fixed = TRUE) &&
    grepl("if (!isTRUE(state$alive))", barrier, fixed = TRUE) &&
    grepl("file.exists(receipts)", barrier, fixed = TRUE)
}

b2_q6_audit_run <- function(root, authorization, output) {
  auth <- utils::read.delim(authorization, check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character")
  expected <- c("mc-0102", "mc-0124", "mc-0146", "mc-0168")
  if (nrow(auth) != 4L || !identical(auth$cell_id, expected) || anyDuplicated(auth$cell_id) ||
      !all(auth$execution_authorized == "TRUE") || !all(auth$profile_execution == "APPROVED") ||
      !all(auth$canonical_ledger_change == "NOT_AUTHORIZED")) {
    b2_q6_audit_stop("Authorization is not the exact approved q6 proof cohort.")
  }
  if (length(unique(auth$runner_source_sha)) != 1L || length(unique(auth$runner_source_tree_sha)) != 1L) {
    b2_q6_audit_stop("Authorization lacks one frozen runner source/tree identity.")
  }
  sha <- auth$runner_source_sha[[1L]]
  tree <- trimws(system2("git", c("-C", root, "rev-parse", paste0(sha, "^{tree}")), stdout = TRUE))
  if (!identical(tree, auth$runner_source_tree_sha[[1L]])) b2_q6_audit_stop("Runner tree does not match authorization.")
  source_serial <- b2_q6_audit_source_enforces_serial(root, sha)
  auth_hash <- b2_q6_audit_hash(authorization)
  previous_receipt_time <- as.POSIXct(NA)
  rows <- lapply(seq_len(nrow(auth)), function(i) {
    row <- auth[i, , drop = FALSE]
    dir <- b2_q6_audit_result_dir(root, row)
    started <- b2_q6_audit_one_file(dir, "attempt-started", row$cell_id)
    trace_path <- b2_q6_audit_one_file(dir, "trace", row$cell_id)
    interval_path <- b2_q6_audit_one_file(dir, "interval", row$cell_id)
    receipt_path <- b2_q6_audit_one_file(dir, "receipt", row$cell_id)
    receipt <- utils::read.delim(receipt_path, check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character")
    interval <- utils::read.delim(interval_path, check.names = FALSE, stringsAsFactors = FALSE, colClasses = "character")
    trace <- utils::read.delim(trace_path, check.names = FALSE, stringsAsFactors = FALSE)
    values <- as.numeric(c(receipt$estimate, receipt$lower, receipt$upper))
    identity <- nrow(receipt) == 1L && nrow(interval) == 1L && nrow(trace) > 0L &&
      identical(receipt$cell_id, row$cell_id) && identical(receipt$target_id, row$target_id) &&
      identical(receipt$dgp_id, row$dgp_id) && identical(receipt$seed, row$seed) &&
      identical(receipt$information_rung, row$information_rung) && identical(receipt$runner_source_sha, sha) &&
      identical(interval$target_id, row$target_id)
    interval_ok <- all(is.finite(values)) && values[[2L]] < values[[3L]] &&
      values[[1L]] >= values[[2L]] && values[[1L]] <= values[[3L]]
    artifacts_ok <- identical(receipt$trace_sha256, b2_q6_audit_hash(trace_path)) &&
      identical(receipt$interval_sha256, b2_q6_audit_hash(interval_path))
    accepted <- identity && artifacts_ok && interval_ok && identical(receipt$conf_status, "profile") &&
      identical(receipt$convergence, "0") && identical(receipt$pdHess, "TRUE") &&
      identical(receipt$profile_boundary, "FALSE") && identical(receipt$clamp_limited, "FALSE") &&
      identical(receipt$trace_complete, "TRUE") && !nzchar(receipt$failure_reason)
    started_time <- file.info(started)$mtime
    receipt_time <- file.info(receipt_path)$mtime
    chronology_ok <- is.na(previous_receipt_time) || started_time >= previous_receipt_time
    previous_receipt_time <<- receipt_time
    data.frame(
      cell_id = row$cell_id, target_id = row$target_id, runner_source_sha = sha,
      runner_source_tree_sha = tree, authorization_sha256 = auth_hash,
      declared_profile_receipt_root = row$profile_receipt_root,
      resolved_receipt_root = dir, declared_root_is_stale = normalizePath(row$profile_receipt_root, mustWork = FALSE) != normalizePath(dir, mustWork = FALSE),
      attempt_started_utc = format(started_time, tz = "UTC", usetz = TRUE),
      terminal_receipt_utc = format(receipt_time, tz = "UTC", usetz = TRUE),
      source_enforces_serial = source_serial, artifact_chronology_ok = chronology_ok,
      identity_ok = identity, artifacts_ok = artifacts_ok, endpoint_ok = interval_ok,
      acceptance_ok = accepted, recommendation_eligible = accepted && source_serial && chronology_ok,
      stringsAsFactors = FALSE
    )
  })
  audit <- do.call(rbind, rows)
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(audit, output, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
  if (!all(audit$recommendation_eligible)) b2_q6_audit_stop("Q6 serial proof cohort is not eligible for a recommendation.")
  invisible(audit)
}

b2_q6_audit_main <- function(args = commandArgs(trailingOnly = TRUE)) {
  values <- strsplit(sub("^--", "", args[grepl("^--", args)]), "=", fixed = TRUE)
  options <- stats::setNames(vapply(values, function(x) paste(x[-1L], collapse = "="), character(1)), vapply(values, `[`, character(1), 1L))
  root <- normalizePath(".", mustWork = TRUE)
  authorization <- if ("authorization" %in% names(options)) normalizePath(options[["authorization"]], mustWork = TRUE) else file.path(root, "docs", "dev-log", "interval-campaign-bindings", "2026-07-31-b2-q6-proof-serial-approved-execution-authorization.tsv")
  output <- if ("output" %in% names(options)) options[["output"]] else file.path(root, "docs", "dev-log", "interval-feasibility", "results", "a8d068e641105473b3f30723a92c909467a46fac", "b2-q6-proof-profile", "independent-serial-receipt-audit.tsv")
  audit <- b2_q6_audit_run(root, authorization, output)
  print(audit, row.names = FALSE)
  message("Independent q6 serial receipt audit passed: 4/4 exact receipts; recommendation-only eligibility established.")
}

if (sys.nframe() == 0L) b2_q6_audit_main()
