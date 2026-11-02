#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: summarize-bernoulli-phylo-calibration-pilot.R ATTEMPTS_RDS OUTPUT_CSV")
}

attempts <- readRDS(args[[1L]])
required <- c(
  "seed", "cell", "alpha1_true", "alpha1_hat", "ci_lower", "ci_upper",
  "interval_contains_truth", "profile_status", "profile_boundary",
  "fit_convergence", "covariance_delta", "elapsed_seconds", "error"
)
missing <- setdiff(required, names(attempts))
if (length(missing)) stop("Missing attempt field(s): ", paste(missing, collapse = ", "))
if (!nrow(attempts) || anyNA(attempts$seed) || anyDuplicated(
  paste(attempts$seed, attempts$cell, sep = "::")
)) {
  stop("Attempt rows must be non-empty and unique by seed and cell")
}

bootstrap_rmse_se <- function(errors) {
  n <- length(errors)
  if (n < 2L) return(NA_real_)
  index_grid <- do.call(expand.grid, rep(list(seq_len(n)), n))
  boot_rmse <- apply(index_grid, 1L, function(index) {
    sqrt(mean(errors[index]^2))
  })
  stats::sd(boot_rmse)
}

summaries <- lapply(split(attempts, attempts$cell), function(x) {
  errors <- x$alpha1_hat - x$alpha1_true
  valid_error <- is.finite(errors)
  errors <- errors[valid_error]
  n_error <- length(errors)
  fit_ok <- is.na(x$error)
  profile_ok <- x$profile_status == "profile" &
    !is.na(x$profile_boundary) & !x$profile_boundary &
    is.finite(x$ci_lower) & is.finite(x$ci_upper)
  fit_times <- x$elapsed_seconds[is.finite(x$elapsed_seconds)]
  data.frame(
    cell = x$cell[[1L]],
    n_attempted = nrow(x),
    n_fit_succeeded = sum(fit_ok),
    fit_completion_fraction = mean(fit_ok),
    n_slope_estimates = n_error,
    slope_bias = if (n_error) mean(errors) else NA_real_,
    slope_bias_mcse = if (n_error > 1L) stats::sd(errors) / sqrt(n_error) else NA_real_,
    slope_rmse = if (n_error) sqrt(mean(errors^2)) else NA_real_,
    slope_rmse_bootstrap_se = bootstrap_rmse_se(errors),
    n_profile_available = sum(profile_ok),
    profile_available_fraction = mean(profile_ok),
    n_truth_inside_returned_interval = sum(x$interval_contains_truth %in% TRUE),
    median_fit_seconds = if (length(fit_times)) stats::median(fit_times) else NA_real_,
    fit_seconds_min = if (length(fit_times)) min(fit_times) else NA_real_,
    fit_seconds_max = if (length(fit_times)) max(fit_times) else NA_real_,
    total_worker_seconds = sum(fit_times),
    max_covariance_delta = max(x$covariance_delta, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
})
summary <- do.call(rbind, summaries)
utils::write.csv(summary, args[[2L]], row.names = FALSE, na = "")
print(summary, row.names = FALSE)
