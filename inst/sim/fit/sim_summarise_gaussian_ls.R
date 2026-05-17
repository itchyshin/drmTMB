phase18_summarise_gaussian_ls_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character()
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (!is.list(truth) || !identical(truth$surface, "gaussian_ls")) {
    stop(
      "`truth` must be a Gaussian location-scale truth object.",
      call. = FALSE
    )
  }

  mu_truth <- truth$beta_mu
  sigma_truth <- truth$beta_sigma
  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- stats::coef(fit, dpar = "sigma")[names(sigma_truth)]
  estimate <- c(mu_est, sigma_est)
  truth_value <- c(mu_truth, sigma_truth)
  names(estimate) <- c(
    paste0("mu:", names(mu_est)),
    paste0("sigma:", names(sigma_est))
  )
  names(truth_value) <- names(estimate)

  data.frame(
    surface = "gaussian_ls",
    cell_id = cell_id,
    replicate = replicate,
    parameter = names(estimate),
    truth = unname(truth_value),
    estimate = unname(estimate),
    error = unname(estimate - truth_value),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
}
