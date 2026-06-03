phase18_summarise_biv_gaussian_q2_scale_fit <- function(
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
    !is.list(truth) || !identical(truth$surface, "biv_gaussian_q2_scale")
  ) {
    stop(
      "`truth` must be a bivariate Gaussian q2 scale truth object.",
      call. = FALSE
    )
  }

  mu1_truth <- truth$beta_mu1
  mu2_truth <- truth$beta_mu2
  sigma_truth <- truth$sigma
  sd_truth <- truth$sd_sigma
  cor_truth <- truth$cor_sigma
  residual_rho_truth <- truth$residual_rho

  mu1_est <- stats::coef(fit, dpar = "mu1")[names(mu1_truth)]
  mu2_est <- stats::coef(fit, dpar = "mu2")[names(mu2_truth)]
  sigma_est <- c(
    sigma1 = exp(unname(stats::coef(fit, dpar = "sigma1")[[1L]])),
    sigma2 = exp(unname(stats::coef(fit, dpar = "sigma2")[[1L]]))
  )
  sd_est <- fit$sdpars$sigma[names(sd_truth)]
  cor_est <- fit$corpars$sigma[names(cor_truth)]
  residual_rho_est <- c(rho12 = rho12(fit)[[1L]])

  estimate <- c(
    mu1_est,
    mu2_est,
    sigma_est,
    sd_est,
    cor_est,
    residual_rho_est
  )
  truth_value <- c(
    mu1_truth,
    mu2_truth,
    sigma_truth,
    sd_truth,
    cor_truth,
    residual_rho_truth
  )
  parameter <- c(
    paste0("mu1:", names(mu1_est)),
    paste0("mu2:", names(mu2_est)),
    names(sigma_est),
    paste0("sd:sigma:", names(sd_est)),
    paste0("cor:sigma:", names(cor_est)),
    "rho12"
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  data.frame(
    surface = "biv_gaussian_q2_scale",
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = c(
      rep("fixed_mu1", length(mu1_est)),
      rep("fixed_mu2", length(mu2_est)),
      rep("residual_sigma", length(sigma_est)),
      rep("random_sd", length(sd_est)),
      rep("derived_random_correlation", length(cor_est)),
      "residual_rho12"
    ),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(
      phase18_biv_gaussian_q2_scale_std_error(fit, parameter)
    ),
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

phase18_biv_gaussian_q2_scale_std_error <- function(fit, parameter) {
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
