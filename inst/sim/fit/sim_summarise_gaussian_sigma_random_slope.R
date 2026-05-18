phase18_summarise_gaussian_sigma_rs_fit <- function(
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
  if (
    !is.list(truth) ||
      !identical(truth$surface, "gaussian_sigma_random_slope")
  ) {
    stop(
      "`truth` must be a Gaussian sigma random-slope truth object.",
      call. = FALSE
    )
  }

  mu_truth <- truth$beta_mu
  sigma_truth <- truth$beta_sigma
  sd_truth <- truth$sd_sigma

  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- stats::coef(fit, dpar = "sigma")[names(sigma_truth)]
  sd_est <- fit$sdpars$sigma[names(sd_truth)]

  estimate <- c(mu_est, sigma_est, sd_est)
  truth_value <- c(mu_truth, sigma_truth, sd_truth)
  parameter <- c(
    paste0("mu:", names(mu_est)),
    paste0("sigma:", names(sigma_est)),
    paste0("sd:sigma:", names(sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  data.frame(
    surface = "gaussian_sigma_random_slope",
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = c(
      rep("fixed_mu", length(mu_est)),
      rep("fixed_sigma", length(sigma_est)),
      rep("scale_random_sd", length(sd_est))
    ),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(phase18_gaussian_sigma_rs_std_error(fit, parameter)),
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

phase18_gaussian_sigma_rs_std_error <- function(fit, parameter) {
  out <- rep(NA_real_, length(parameter))
  names(out) <- parameter
  coefficients <- tryCatch(
    summary(fit)$coefficients,
    error = function(e) NULL
  )
  if (
    is.null(coefficients) ||
      !"std_error" %in% names(coefficients) ||
      is.null(row.names(coefficients))
  ) {
    return(out)
  }
  matched <- match(parameter, row.names(coefficients))
  ok <- !is.na(matched)
  out[ok] <- coefficients$std_error[matched[ok]]
  out
}
