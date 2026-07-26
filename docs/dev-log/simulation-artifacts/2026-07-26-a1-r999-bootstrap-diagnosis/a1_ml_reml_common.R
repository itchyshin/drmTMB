# Pure accounting helpers for the scalar A1 ML-versus-REML diagnostic.  Keep
# these functions independent of a fitted model so the paired denominator and
# directional-miss contract have fast unit tests.

a1_ml_reml_cells <- function() {
  data.frame(
    cell_index = 1:3,
    cell_id = c("g10_n10_sd05", "g25_n10_sd05", "g50_n10_sd05"),
    n_groups = c(10L, 25L, 50L),
    n_per_group = 10L,
    truth_sd = 0.5,
    stringsAsFactors = FALSE
  )
}

a1_ml_reml_miss <- function(lower, upper, truth) {
  if (!is.finite(lower) || !is.finite(upper)) return("nonfinite")
  if (truth < lower) return("lower")
  if (truth > upper) return("upper")
  "covered"
}

a1_ml_reml_interval_row <- function(ci, target, truth, method) {
  out <- list(
    status = "not_run", lower = NA_real_, upper = NA_real_, width = NA_real_,
    covers = NA, miss_direction = NA_character_, profile_engine = NA_character_,
    profile_boundary = NA, profile_message = NA_character_
  )
  if (inherits(ci, "try-error")) {
    out$status <- "error"
    out$profile_message <- as.character(ci)
    return(out)
  }
  if (!is.data.frame(ci) || !all(c("parm", "lower", "upper") %in% names(ci))) {
    out$status <- "malformed"
    return(out)
  }
  hit <- ci[as.character(ci$parm) == target, , drop = FALSE]
  if (nrow(hit) != 1L) {
    out$status <- "target_missing"
    return(out)
  }
  out$lower <- as.numeric(hit$lower[[1L]])
  out$upper <- as.numeric(hit$upper[[1L]])
  if (is.finite(out$lower) && is.finite(out$upper)) {
    out$status <- "valid"
    out$width <- out$upper - out$lower
    out$covers <- out$lower <= truth && truth <= out$upper
    out$miss_direction <- a1_ml_reml_miss(out$lower, out$upper, truth)
  } else {
    out$status <- "nonfinite"
    out$miss_direction <- "nonfinite"
  }
  if (identical(method, "profile")) {
    out$profile_engine <- if ("profile.engine" %in% names(hit)) as.character(hit$profile.engine[[1L]]) else NA_character_
    out$profile_boundary <- if ("profile.boundary" %in% names(hit)) as.logical(hit$profile.boundary[[1L]]) else NA
    out$profile_message <- if ("profile.message" %in% names(hit)) as.character(hit$profile.message[[1L]]) else NA_character_
  }
  out
}

a1_ml_reml_validate_pairs <- function(x) {
  required <- c("cell_id", "seed", "attempt_id", "estimator")
  if (!all(required %in% names(x))) stop("Missing paired-estimator key columns.", call. = FALSE)
  if (anyDuplicated(x[required])) stop("Duplicate paired-estimator rows are not allowed.", call. = FALSE)
  keys <- interaction(x$cell_id, x$seed, x$attempt_id, drop = TRUE)
  arms <- split(as.character(x$estimator), keys)
  if (!all(vapply(arms, function(one) identical(sort(one), c("ML", "REML")), logical(1)))) {
    stop("Every paired dataset must retain exactly one ML and one REML row.", call. = FALSE)
  }
  invisible(TRUE)
}

a1_ml_reml_directional_summary <- function(x) {
  a1_ml_reml_validate_pairs(x)
  required <- c("profile_miss_direction", "profile_covers")
  if (!all(required %in% names(x))) stop("Missing profile outcome columns.", call. = FALSE)
  out <- do.call(rbind, lapply(split(x, interaction(x$cell_id, x$estimator, drop = TRUE)), function(one) {
    data.frame(
      cell_id = one$cell_id[[1L]], estimator = one$estimator[[1L]],
      n_attempted = nrow(one),
      n_profile_valid = sum(!is.na(one$profile_covers)),
      n_profile_unavailable = sum(is.na(one$profile_covers)),
      n_profile_covered = sum(one$profile_covers %in% TRUE),
      coverage_all_attempts = mean(one$profile_covers %in% TRUE),
      n_lower_miss = sum(one$profile_miss_direction == "lower", na.rm = TRUE),
      n_upper_miss = sum(one$profile_miss_direction == "upper", na.rm = TRUE),
      upper_miss_probability_all_attempts = sum(one$profile_miss_direction == "upper", na.rm = TRUE) / nrow(one),
      lower_miss_probability_all_attempts = sum(one$profile_miss_direction == "lower", na.rm = TRUE) / nrow(one),
      directional_gap = (sum(one$profile_miss_direction == "upper", na.rm = TRUE) -
        sum(one$profile_miss_direction == "lower", na.rm = TRUE)) / nrow(one),
      n_zero_lower_endpoint = sum(one$profile_boundary %in% TRUE, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out
}

a1_ml_reml_oracle_gate_pass <- function(status) {
  is.character(status) && length(status) > 0L && all(status == "pass")
}
