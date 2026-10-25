# Pure assessment for the retained marginal homogeneous Toeplitz profile campaign.
# It reads summaries only; it never fits a model or launches a task.

temporal_homtoep_profile_campaign_assess <- function(summary) {
  required <- c(
    "cell", "role", "parm", "n_attempted", "availability", "coverage_all",
    "coverage_mcse", "bias", "empirical_sd", "mean_interval_width"
  )
  if (!is.data.frame(summary) || !all(required %in% names(summary))) {
    stop("Campaign summary lacks fields required for Toeplitz calibration assessment.", call. = FALSE)
  }
  primary <- summary$role == "primary"
  finite <- function(...) Reduce(`&`, lapply(list(...), is.finite))
  out <- summary
  out$coverage_lower_mcse <- out$coverage_all - out$coverage_mcse
  out$coverage_upper_mcse <- out$coverage_all + out$coverage_mcse
  out$criterion_availability <- finite(out$availability) & out$availability >= 0.99
  out$criterion_coverage <- finite(out$coverage_all) &
    out$coverage_all >= 0.925 & out$coverage_all <= 0.975
  out$criterion_bias <- finite(out$bias, out$empirical_sd) &
    abs(out$bias) <= 0.10 * out$empirical_sd
  out$qualification <- ifelse(
    !primary, "stress_descriptive",
    ifelse(out$criterion_availability & out$criterion_coverage & out$criterion_bias,
      "qualified_in_simulated_cell", "unqualified_in_simulated_cell")
  )
  out
}
