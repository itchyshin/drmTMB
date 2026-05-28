phase18_summarise_tweedie_fe_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character()
) {
  data <- truth
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (!is.list(truth) || !identical(truth$surface, "tweedie_fixed_effect")) {
    stop(
      "`truth` must be a Tweedie fixed-effect truth object.",
      call. = FALSE
    )
  }

  truth_value <- c(truth$beta_mu, truth$beta_sigma, truth$beta_nu)
  names(truth_value) <- c(
    paste0("mu:", names(truth$beta_mu)),
    paste0("sigma:", names(truth$beta_sigma)),
    paste0("nu:", names(truth$beta_nu))
  )
  estimate <- c(
    stats::coef(fit, dpar = "mu")[names(truth$beta_mu)],
    stats::coef(fit, dpar = "sigma")[names(truth$beta_sigma)],
    stats::coef(fit, dpar = "nu")[names(truth$beta_nu)]
  )
  names(estimate) <- names(truth_value)
  std_error <- phase18_tweedie_fe_fixed_effect_se(fit, names(estimate))
  dpar <- sub(":.*", "", names(estimate))
  term <- sub("^[^:]+:", "", names(estimate))
  observed_zero_fraction <- if (is.data.frame(data)) {
    mean(data$y == 0)
  } else {
    NA_real_
  }
  power_estimate <- unique(as.numeric(predict(fit, dpar = "nu")))
  if (length(power_estimate) != 1L) {
    power_estimate <- NA_real_
  }

  data.frame(
    surface = "tweedie_fixed_effect",
    cell_id = cell_id,
    replicate = replicate,
    n = truth$n,
    n_used = stats::nobs(fit),
    target_zero_fraction = truth$target_zero_fraction,
    observed_zero_fraction = observed_zero_fraction,
    zero_regime = truth$zero_regime,
    power = truth$power,
    power_estimate = power_estimate,
    rho_xz = truth$rho_xz,
    sigma_baseline = truth$sigma_baseline,
    parameter = names(estimate),
    dpar = dpar,
    term = term,
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(std_error),
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

phase18_tweedie_fe_fixed_effect_se <- function(fit, parameter) {
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
