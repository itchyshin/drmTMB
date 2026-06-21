phase18_summarise_skew_normal_fe_fit <- function(
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
      !identical(truth$surface, "skew_normal_fixed_effect")
  ) {
    stop(
      "`truth` must be a skew-normal fixed-effect truth object.",
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
  std_error <- phase18_skew_normal_fe_fixed_effect_se(fit, names(estimate))
  fitted_nu <- tryCatch(
    stats::predict(fit, dpar = "nu"),
    error = function(e) NA_real_
  )
  fitted_nu <- as.numeric(fitted_nu)
  shape_check <- phase18_skew_normal_fe_check_row(fit)
  dpar <- sub(":.*$", "", names(estimate))
  term <- sub("^[^:]+:", "", names(estimate))

  data.frame(
    surface = "skew_normal_fixed_effect",
    skew_regime = truth$skew_regime,
    cell_id = cell_id,
    replicate = replicate,
    n = truth$n,
    rho_xz = truth$rho_xz,
    beta_sigma_z = truth$beta_sigma[["z"]],
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
    fitted_nu_min = phase18_skew_normal_fe_min_finite(fitted_nu),
    fitted_nu_max = phase18_skew_normal_fe_max_finite(fitted_nu),
    fitted_nu_max_abs = phase18_skew_normal_fe_max_finite(abs(fitted_nu)),
    skew_normal_nu_status = shape_check$status,
    skew_normal_nu_value = shape_check$value,
    skew_normal_nu_message = shape_check$message,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
}

phase18_skew_normal_fe_fixed_effect_se <- function(fit, parameter) {
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

phase18_skew_normal_fe_check_row <- function(fit) {
  checks <- tryCatch(check_drm(fit), error = function(e) e)
  if (inherits(checks, "error")) {
    return(data.frame(
      status = "warning",
      value = NA_character_,
      message = paste("Could not run check_drm():", conditionMessage(checks)),
      stringsAsFactors = FALSE
    ))
  }
  row <- checks[checks$check == "skew_normal_nu", , drop = FALSE]
  if (nrow(row) == 0L) {
    return(data.frame(
      status = "warning",
      value = NA_character_,
      message = "`check_drm()` did not return a skew_normal_nu row.",
      stringsAsFactors = FALSE
    ))
  }
  row[1L, c("status", "value", "message"), drop = FALSE]
}

phase18_skew_normal_fe_min_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  min(x)
}

phase18_skew_normal_fe_max_finite <- function(x) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(NA_real_)
  }
  max(x)
}
