# Pure helpers shared by the scalar A1 profile-versus-bootstrap runner and its
# test.  They intentionally contain no drmTMB/TMB calls, so the interval
# accounting contract can be checked without compiling the package.

a1_shard_file_pattern <- function() {
  "^g(10|25|50)_n10_sd05_o[0-9]{4}\\.csv$"
}

a1_exact_binomial <- function(covered) {
  if (!is.logical(covered)) {
    stop("`covered` must be a logical vector.", call. = FALSE)
  }
  n <- length(covered)
  if (n < 1L) {
    stop("`covered` must contain at least one attempt.", call. = FALSE)
  }
  # An unavailable or non-finite interval fails to cover on the primary,
  # all-attempt estimand. `valid_interval` retains the availability diagnostic
  # so it cannot be mistaken for complete-case coverage.
  valid_interval <- !is.na(covered)
  covered_all_attempts <- !is.na(covered) & covered
  ci <- stats::binom.test(sum(covered_all_attempts), n)$conf.int
  data.frame(
    n = n,
    n_valid_interval = sum(valid_interval),
    n_unavailable_interval = sum(!valid_interval),
    covered = sum(covered_all_attempts),
    coverage = mean(covered_all_attempts),
    coverage_lo = ci[[1L]],
    coverage_hi = ci[[2L]],
    stringsAsFactors = FALSE
  )
}

# The paired outcome D = I(R999 covers) - I(R199 covers) is in {-1, 0, 1}.
# Its sample variance estimates the variance of the paired mean difference.
# This is deliberately labelled a normal-approximation CI; the two marginal
# coverages retain their exact binomial intervals separately.
a1_paired_difference <- function(covered_199, covered_999, level = 0.95) {
  if (!is.logical(covered_199) || !is.logical(covered_999) ||
      anyNA(covered_199) || anyNA(covered_999) ||
      length(covered_199) != length(covered_999) || length(covered_199) < 2L) {
    stop("Coverage vectors must be complete logical vectors of equal length >= 2.",
         call. = FALSE)
  }
  d <- as.integer(covered_999) - as.integer(covered_199)
  n <- length(d)
  delta <- mean(d)
  se <- sqrt(stats::var(d) / n)
  z <- stats::qnorm((1 + level) / 2)
  data.frame(
    n = n,
    r199_only = sum(d == -1L),
    r999_only = sum(d == 1L),
    difference = delta,
    difference_lo = delta - z * se,
    difference_hi = delta + z * se,
    ci_method = "paired normal approximation",
    stringsAsFactors = FALSE
  )
}

a1_interval_row <- function(ci, target, truth, method) {
  empty <- list(
    status = "not_run", lower = NA_real_, upper = NA_real_, width = NA_real_,
    covers = NA, miss_direction = NA_character_, profile_engine = NA_character_,
    profile_boundary = NA, profile_conf_status = NA_character_,
    profile_message = NA_character_
  )
  if (inherits(ci, "try-error")) {
    empty$status <- "error"
    empty$profile_message <- as.character(ci)
    return(empty)
  }
  if (!is.data.frame(ci) || !all(c("parm", "lower", "upper") %in% names(ci))) {
    empty$status <- "malformed"
    return(empty)
  }
  hit <- ci[as.character(ci$parm) == target, , drop = FALSE]
  if (nrow(hit) != 1L) {
    empty$status <- "target_missing"
    return(empty)
  }
  lower <- as.numeric(hit$lower[[1L]])
  upper <- as.numeric(hit$upper[[1L]])
  finite <- is.finite(lower) && is.finite(upper)
  empty$lower <- lower
  empty$upper <- upper
  empty$width <- if (finite) upper - lower else NA_real_
  empty$covers <- if (finite) lower <= truth && truth <= upper else NA
  empty$miss_direction <- if (!finite) "nonfinite" else if (truth < lower) "lower" else if (truth > upper) "upper" else "covered"
  empty$status <- if (finite) "valid" else "nonfinite"
  if (identical(method, "profile")) {
    empty$profile_engine <- if ("profile.engine" %in% names(hit)) as.character(hit$profile.engine[[1L]]) else NA_character_
    empty$profile_boundary <- if ("profile.boundary" %in% names(hit)) as.logical(hit$profile.boundary[[1L]]) else NA
    empty$profile_conf_status <- if ("conf.status" %in% names(hit)) as.character(hit$conf.status[[1L]]) else NA_character_
    empty$profile_message <- if ("profile.message" %in% names(hit)) as.character(hit$profile.message[[1L]]) else NA_character_
  }
  empty
}

a1_validate_r999_inputs <- function(old, new, expected_counts = c(c01 = 1000L, c03 = 1000L)) {
  required <- c("cell_id", "seed", "R_boot")
  if (!all(required %in% names(old)) || !all(required %in% names(new))) {
    stop("Both inputs must contain cell_id, seed, and R_boot.", call. = FALSE)
  }
  if (anyDuplicated(old[c("cell_id", "seed")]) || anyDuplicated(new[c("cell_id", "seed")])) {
    stop("Duplicate (cell_id, seed) rows prevent a one-to-one paired comparison.", call. = FALSE)
  }
  if (length(unique(old$R_boot)) != 1L || unique(old$R_boot) != 199 ||
      length(unique(new$R_boot)) != 1L || unique(new$R_boot) != 999) {
    stop("Expected historical R_boot = 199 and diagnostic R_boot = 999 only.", call. = FALSE)
  }
  old_counts <- table(old$cell_id)
  new_counts <- table(new$cell_id)
  if (!identical(names(old_counts), names(expected_counts)) ||
      !identical(names(new_counts), names(expected_counts)) ||
      any(as.integer(old_counts) != as.integer(expected_counts)) ||
      any(as.integer(new_counts) != as.integer(expected_counts))) {
    stop("Unexpected unique target-row counts by cell.", call. = FALSE)
  }
  invisible(TRUE)
}
