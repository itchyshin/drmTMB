phase18_summarise_student_shape_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "student_shape")) {
    stop(
      "`truth` must be a Student-t shape truth object.",
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
  std_error <- phase18_student_shape_fixed_effect_se(fit, names(estimate))

  data.frame(
    surface = "student_shape",
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

phase18_student_shape_fixed_effect_se <- function(fit, parameter) {
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

phase18_student_shape_grid_truth <- function(truth, grid) {
  if (!is.list(truth) || !identical(truth$surface, "student_shape")) {
    stop("`truth` must be a Student-t shape truth object.", call. = FALSE)
  }
  required <- c("x", "z", "w")
  missing <- setdiff(required, names(grid))
  if (length(missing) > 0L) {
    stop(
      "`grid` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  mu <- unname(
    truth$beta_mu[["(Intercept)"]] + truth$beta_mu[["x"]] * grid$x
  )
  sigma <- exp(unname(
    truth$beta_sigma[["(Intercept)"]] + truth$beta_sigma[["z"]] * grid$z
  ))
  eta_nu <- unname(
    truth$beta_nu[["(Intercept)"]] + truth$beta_nu[["w"]] * grid$w
  )
  data.frame(
    grid,
    mu = mu,
    sigma = sigma,
    eta_nu = eta_nu,
    nu = 2 + exp(eta_nu),
    stringsAsFactors = FALSE
  )
}
