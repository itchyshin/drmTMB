#!/usr/bin/env Rscript
# Fail-closed campaign collector.  It reads only atomically committed task
# directories and never turns an absent receipt into a successful observation.
# Source prepare-s7-campaign-manifest.R, prepare-s7-campaign-bundle.R,
# s7-attempt-contract.R, and s7-run-task.R before calling these functions.

r071_s7_wilson <- function(success, total, level = 0.95) {
  if (length(success) != 1L || length(total) != 1L || total < 1L ||
      success < 0L || success > total) {
    stop("S7 Wilson interval needs one valid binomial count", call. = FALSE)
  }
  z <- stats::qnorm(1 - (1 - level) / 2)
  p <- success / total
  denom <- 1 + z^2 / total
  centre <- (p + z^2 / (2 * total)) / denom
  half <- z * sqrt((p * (1 - p) + z^2 / (4 * total)) / total) / denom
  c(lower = max(0, centre - half), upper = min(1, centre + half))
}

r071_s7_coverage_summary <- function(attempts) {
  required <- c("fixture", "engine", "parm", "truth", "profile_status")
  if (!is.data.frame(attempts) || !all(required %in% names(attempts))) {
    stop("S7 coverage summary needs reconciled attempt receipts", call. = FALSE)
  }
  key <- interaction(attempts$fixture, attempts$engine, attempts$parm,
                     drop = TRUE, lex.order = TRUE)
  rows <- lapply(split(attempts, key), function(x) {
    if (length(unique(x$truth)) != 1L) {
      stop("S7 coverage target has inconsistent truth", call. = FALSE)
    }
    total <- nrow(x)
    unconditional_covered <- sum(x$profile_status == "profile")
    finite_endpoint <- x$profile_status %in% c("profile", "truth_outside")
    finite_endpoint_count <- sum(finite_endpoint)
    conditional_covered <- unconditional_covered
    unconditional_ci <- r071_s7_wilson(unconditional_covered, total)
    conditional_ci <- if (finite_endpoint_count > 0L) {
      r071_s7_wilson(conditional_covered, finite_endpoint_count)
    } else c(lower = NA_real_, upper = NA_real_)
    data.frame(
      fixture = x$fixture[[1L]], engine = x$engine[[1L]], parm = x$parm[[1L]],
      truth = x$truth[[1L]], attempt_count = total,
      unconditional_covered = unconditional_covered,
      unconditional_coverage = unconditional_covered / total,
      unconditional_mcse = sqrt((unconditional_covered / total) *
                                   (1 - unconditional_covered / total) / total),
      unconditional_wilson_lower = unname(unconditional_ci[["lower"]]),
      unconditional_wilson_upper = unname(unconditional_ci[["upper"]]),
      finite_endpoint_count = finite_endpoint_count,
      conditional_covered = conditional_covered,
      conditional_coverage = if (finite_endpoint_count > 0L) conditional_covered / finite_endpoint_count else NA_real_,
      conditional_mcse = if (finite_endpoint_count > 0L) sqrt((conditional_covered / finite_endpoint_count) *
                                                                  (1 - conditional_covered / finite_endpoint_count) /
                                                                  finite_endpoint_count) else NA_real_,
      conditional_wilson_lower = unname(conditional_ci[["lower"]]),
      conditional_wilson_upper = unname(conditional_ci[["upper"]]),
      fit_failed_count = sum(x$profile_status == "fit_failed"),
      profile_failed_count = sum(x$profile_status == "profile_failed"),
      nonfinite_endpoint_count = sum(x$profile_status == "nonfinite_endpoint"),
      truth_outside_count = sum(x$profile_status == "truth_outside"),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out[order(out$fixture, out$engine, out$parm), , drop = FALSE]
}

r071_s7_verify_task_checksums <- function(path) {
  required <- c("planned-task.tsv", "attempts.tsv", "SHA256SUMS", "COMMITTED")
  absent <- required[!file.exists(file.path(path, required))]
  if (length(absent)) {
    stop("S7 committed task receipt is incomplete: ", basename(path), ": ",
         paste(absent, collapse = ", "), call. = FALSE)
  }
  lines <- readLines(file.path(path, "SHA256SUMS"), warn = FALSE)
  fields <- strsplit(trimws(lines), "[[:space:]]+", perl = TRUE)
  hashes <- vapply(fields, function(x) if (length(x) == 2L) x[[1L]] else NA_character_, character(1L))
  files <- vapply(fields, function(x) if (length(x) == 2L) x[[2L]] else NA_character_, character(1L))
  expected_files <- c("planned-task.tsv", "attempts.tsv")
  if (length(lines) != 2L || anyNA(hashes) || anyNA(files) || anyDuplicated(files) ||
      !setequal(files, expected_files) || any(!grepl("^[0-9a-fA-F]{64}$", hashes))) {
    stop("S7 committed task checksum schema drift: ", basename(path), call. = FALSE)
  }
  observed <- vapply(files, function(file) r071_s7_sha256(file.path(path, file)), character(1L))
  if (!identical(tolower(unname(hashes)), tolower(unname(observed)))) {
    stop("S7 committed task checksum mismatch: ", basename(path), call. = FALSE)
  }
  invisible(TRUE)
}

r071_s7_equal_task_plan <- function(observed, expected) {
  required <- c("logical_task_id", "fixture", "dgp_seed", "engine", "parm", "target_class", "truth")
  if (!is.data.frame(observed) || !identical(names(observed), required)) return(FALSE)
  observed$logical_task_id <- as.integer(observed$logical_task_id)
  observed$dgp_seed <- as.integer(observed$dgp_seed)
  observed$truth <- as.numeric(observed$truth)
  isTRUE(all.equal(observed, expected, tolerance = 1e-12, check.attributes = FALSE))
}

r071_s7_collect_campaign <- function(campaign_root) {
  required_functions <- c("r071_s7_read_campaign_bundle", "r071_s7_task_attempt_plan",
                          "r071_s7_reconcile_attempts", "r071_s7_sha256")
  helpers <- environment(r071_s7_collect_campaign)
  if (!all(vapply(required_functions, exists, logical(1), envir = helpers,
                  mode = "function", inherits = TRUE))) {
    stop("source S7 manifest, bundle, attempt contract, and task-runner helpers first", call. = FALSE)
  }
  campaign_root <- normalizePath(campaign_root, mustWork = TRUE)
  bundle <- r071_s7_read_campaign_bundle(file.path(campaign_root, "bundle"))
  task_ids <- seq_len(nrow(bundle$manifest))
  task_paths <- file.path(campaign_root, "tasks", as.character(task_ids))
  incomplete <- task_ids[!vapply(task_paths, function(path) {
    dir.exists(path) && file.exists(file.path(path, "COMMITTED"))
  }, logical(1L))]
  if (length(incomplete)) {
    stop("S7 campaign has missing committed S7 task receipts: ",
         paste(utils::head(incomplete, 20L), collapse = ", "),
         if (length(incomplete) > 20L) " ..." else "", call. = FALSE)
  }
  attempts <- lapply(task_ids, function(id) {
    path <- task_paths[[id]]
    r071_s7_verify_task_checksums(path)
    plan <- utils::read.delim(file.path(path, "planned-task.tsv"), stringsAsFactors = FALSE,
                              check.names = FALSE)
    expected <- r071_s7_task_attempt_plan(bundle, id)
    if (!r071_s7_equal_task_plan(plan, expected)) {
      stop("S7 committed task plan drift: ", id, call. = FALSE)
    }
    utils::read.delim(file.path(path, "attempts.tsv"), stringsAsFactors = FALSE,
                      check.names = FALSE)
  })
  attempts <- do.call(rbind, attempts)
  row.names(attempts) <- NULL
  reconciliation <- r071_s7_reconcile_attempts(bundle$manifest, bundle$profile_plan, attempts)
  list(
    reconciliation = reconciliation,
    attempts = attempts,
    coverage = r071_s7_coverage_summary(attempts)
  )
}
