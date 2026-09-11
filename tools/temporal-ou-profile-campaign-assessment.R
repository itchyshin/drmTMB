# Pure assessment for the retained temporal-OU profile campaign summary.
#
# The campaign records profile endpoints rather than a reported standard error.
# Dividing their mean 95% interval width by 2 * qnorm(.975) supplies the
# prespecified normal-reference SE analogue for calibration reporting.

temporal_ou_profile_campaign_assess <- function(summary, level = 0.95) {
  required <- c(
    "n_attempted", "availability", "coverage_all", "coverage_mcse",
    "bias", "empirical_sd", "mean_interval_width"
  )
  if (!is.data.frame(summary) || !all(required %in% names(summary))) {
    stop("Campaign summary lacks fields required for calibration assessment.", call. = FALSE)
  }
  if (!is.numeric(level) || length(level) != 1L || !is.finite(level) ||
      level <= 0 || level >= 1) {
    stop("`level` must be one finite number strictly between zero and one.", call. = FALSE)
  }

  z <- stats::qnorm((1 + level) / 2)
  out <- summary
  out$coverage_lower_mcse <- out$coverage_all - out$coverage_mcse
  out$coverage_upper_mcse <- out$coverage_all + out$coverage_mcse
  out$mean_profile_se_analogue <- out$mean_interval_width / (2 * z)
  out$profile_se_analogue_ratio <- out$mean_profile_se_analogue / out$empirical_sd

  finite <- function(...) {
    Reduce(`&`, lapply(list(...), is.finite))
  }
  out$criterion_availability <- finite(out$availability) & out$availability >= 0.99
  out$criterion_coverage <- finite(out$coverage_lower_mcse, out$coverage_upper_mcse) &
    out$coverage_lower_mcse >= 0.925 & out$coverage_upper_mcse <= 0.975
  out$criterion_bias <- finite(out$bias, out$empirical_sd) &
    abs(out$bias) <= 0.10 * out$empirical_sd
  out$criterion_profile_se <- finite(out$profile_se_analogue_ratio) &
    out$profile_se_analogue_ratio >= 0.90 & out$profile_se_analogue_ratio <= 1.10
  out$qualification <- ifelse(
    out$criterion_availability & out$criterion_coverage &
      out$criterion_bias & out$criterion_profile_se,
    "qualified_in_simulated_cell", "unqualified_in_simulated_cell"
  )
  out
}
