phase18_summarise_phylo_mu_slope_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "phylo_mu_slope")) {
    stop("`truth` must be a phylo mu slope truth object.", call. = FALSE)
  }

  mu_truth <- truth$beta_mu
  sigma_truth <- c(sigma = truth$sigma)
  sd_truth <- truth$sd

  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- c(sigma = exp(unname(stats::coef(fit, dpar = "sigma")[[1L]])))
  sd_est <- fit$sdpars$mu[names(sd_truth)]

  estimate <- c(mu_est, sigma_est, sd_est)
  truth_value <- c(mu_truth, sigma_truth, sd_truth)
  parameter <- c(
    paste0("mu:", names(mu_est)),
    "sigma",
    paste0("sd:mu:", names(sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  data.frame(
    surface = "phylo_mu_slope",
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = c(
      rep("fixed_mu", length(mu_est)),
      "residual_sigma",
      rep("phylo_sd", length(sd_est))
    ),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(phase18_phylo_mu_slope_std_error(fit, parameter)),
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

phase18_phylo_mu_slope_std_error <- function(fit, parameter) {
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
