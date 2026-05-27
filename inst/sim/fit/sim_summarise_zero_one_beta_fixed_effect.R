phase18_summarise_zero_one_beta_fe_fit <- function(
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
      !identical(truth$surface, "zero_one_beta_fixed_effect")
  ) {
    stop(
      "`truth` must be a zero-one beta fixed-effect truth object.",
      call. = FALSE
    )
  }

  truth_value <- c(
    truth$beta_mu,
    truth$beta_sigma,
    truth$beta_zoi,
    truth$beta_coi
  )
  names(truth_value) <- c(
    paste0("mu:", names(truth$beta_mu)),
    paste0("sigma:", names(truth$beta_sigma)),
    paste0("zoi:", names(truth$beta_zoi)),
    paste0("coi:", names(truth$beta_coi))
  )
  estimate <- c(
    stats::coef(fit, dpar = "mu")[names(truth$beta_mu)],
    stats::coef(fit, dpar = "sigma")[names(truth$beta_sigma)],
    stats::coef(fit, dpar = "zoi")[names(truth$beta_zoi)],
    stats::coef(fit, dpar = "coi")[names(truth$beta_coi)]
  )
  names(estimate) <- names(truth_value)
  std_error <- phase18_zero_one_beta_fe_fixed_effect_se(fit, names(estimate))

  data.frame(
    surface = "zero_one_beta_fixed_effect",
    cell_id = cell_id,
    replicate = replicate,
    parameter = names(estimate),
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

phase18_zero_one_beta_fe_fixed_effect_se <- function(fit, parameter) {
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
