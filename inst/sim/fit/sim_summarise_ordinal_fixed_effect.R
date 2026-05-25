phase18_summarise_ordinal_fe_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "ordinal_fixed_effect")) {
    stop("`truth` must be an ordinal fixed-effect truth object.", call. = FALSE)
  }

  mu_estimate <- stats::coef(fit, dpar = "mu")[names(truth$beta_mu)]
  names(mu_estimate) <- paste0("mu:", names(mu_estimate))
  mu_truth <- truth$beta_mu
  names(mu_truth) <- names(mu_estimate)
  mu_se <- phase18_ordinal_fe_fixed_effect_se(fit, names(mu_estimate))

  cutpoint_estimate <- fit$ordinal$cutpoints[names(truth$cutpoints)]
  names(cutpoint_estimate) <- paste0("cutpoint:", names(cutpoint_estimate))
  cutpoint_truth <- truth$cutpoints
  names(cutpoint_truth) <- names(cutpoint_estimate)

  estimate <- c(mu_estimate, cutpoint_estimate)
  truth_value <- c(mu_truth, cutpoint_truth)
  std_error <- c(mu_se, rep(NA_real_, length(cutpoint_estimate)))
  parameter_class <- c(
    rep("fixef", length(mu_estimate)),
    rep("cutpoint", length(cutpoint_estimate))
  )

  data.frame(
    surface = "ordinal_fixed_effect",
    family = truth$family,
    n_category = truth$n_category,
    cutpoint_pattern = truth$cutpoint_pattern,
    cell_id = cell_id,
    replicate = replicate,
    parameter = names(estimate),
    parameter_class = parameter_class,
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
    min_cutpoint_gap = min(diff(fit$ordinal$cutpoints)),
    cutpoints_ordered = isTRUE(all(diff(fit$ordinal$cutpoints) > 0)),
    stringsAsFactors = FALSE
  )
}

phase18_ordinal_fe_fixed_effect_se <- function(fit, parameter) {
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
