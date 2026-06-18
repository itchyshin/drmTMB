phase18_summarise_student_shape_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character(),
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  bootstrap_nsim = 0L,
  bootstrap_level = 0.70,
  bootstrap_seed = NULL,
  bootstrap_cores = 1L,
  bootstrap_backend = "none"
) {
  data <- truth
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

  out <- data.frame(
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
  if (length(profile_parameters) > 0L) {
    out <- phase18_profile_interval_columns(
      out,
      fit = fit,
      parameters = profile_parameters,
      conf.level = profile_level,
      interval_scale = "formula_coefficient",
      profile_args = profile_args
    )
  }
  out <- phase18_bootstrap_interval_columns(
    out,
    fit = fit,
    statistic_fun = phase18_student_shape_bootstrap_statistic,
    refit_fun = phase18_student_shape_bootstrap_refit(data),
    nsim = bootstrap_nsim,
    conf.level = bootstrap_level,
    seed = bootstrap_seed,
    interval_scale = "formula_coefficient",
    cores = bootstrap_cores,
    backend = bootstrap_backend
  )
  phase18_student_shape_attach_status(out, fit)
}

phase18_student_shape_bootstrap_statistic <- function(fit) {
  estimate <- c(
    stats::coef(fit, dpar = "mu"),
    stats::coef(fit, dpar = "sigma"),
    stats::coef(fit, dpar = "nu")
  )
  names(estimate) <- c(
    paste0("mu:", names(stats::coef(fit, dpar = "mu"))),
    paste0("sigma:", names(stats::coef(fit, dpar = "sigma"))),
    paste0("nu:", names(stats::coef(fit, dpar = "nu")))
  )
  estimate
}

phase18_student_shape_bootstrap_refit <- function(data) {
  force(data)
  function(fit, simulations, index) {
    data$y <- simulations[[paste0("sim_", index)]]
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ w),
      family = student(),
      data = data
    )
  }
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

phase18_student_shape_attach_status <- function(summary, fit) {
  diagnostics <- tryCatch(
    check_drm(fit),
    error = function(e) NULL
  )

  summary$fit_diagnostic_status <- "unavailable"
  summary$fit_diagnostic_message <- NA_character_
  summary$student_nu_status <- "unavailable"
  summary$student_nu_value <- NA_character_
  summary$student_nu_message <- NA_character_

  if (
    is.data.frame(diagnostics) &&
      all(c("check", "status", "message") %in% names(diagnostics))
  ) {
    nu <- phase18_student_shape_diagnostic_row(diagnostics, "student_nu")
    fit_rows <- diagnostics[
      diagnostics$check %in%
        c(
          "hessian_positive_definite",
          "standard_errors_finite",
          "positive_scale",
          "student_nu"
        ),
      ,
      drop = FALSE
    ]

    summary$student_nu_status <- nu$status
    summary$student_nu_value <- nu$value
    summary$student_nu_message <- nu$message
    summary$fit_diagnostic_status <-
      phase18_student_shape_diagnostic_rollup(fit_rows$status)
    summary$fit_diagnostic_message <-
      phase18_student_shape_diagnostic_message(fit_rows)
  }

  summary
}

phase18_student_shape_diagnostic_row <- function(diagnostics, check) {
  row <- diagnostics[diagnostics$check == check, , drop = FALSE]
  if (nrow(row) == 0L) {
    return(list(
      status = "missing",
      value = NA_character_,
      message = paste(check, "row missing")
    ))
  }
  value <- if ("value" %in% names(row)) as.character(row$value[[1L]]) else NA_character_
  list(
    status = row$status[[1L]],
    value = value,
    message = row$message[[1L]]
  )
}

phase18_student_shape_diagnostic_rollup <- function(status) {
  status <- as.character(status)
  if (length(status) == 0L) {
    return("unavailable")
  }
  if (any(status == "error", na.rm = TRUE)) {
    return("error")
  }
  if (any(status == "warning", na.rm = TRUE)) {
    return("warning")
  }
  if (any(status == "note", na.rm = TRUE)) {
    return("note")
  }
  if (all(status == "ok", na.rm = TRUE)) {
    return("ok")
  }
  "unavailable"
}

phase18_student_shape_diagnostic_message <- function(diagnostics) {
  if (nrow(diagnostics) == 0L) {
    return("Selected fit-level diagnostics are unavailable.")
  }
  flagged <- diagnostics[
    diagnostics$status %in% c("error", "warning", "note"),
    ,
    drop = FALSE
  ]
  if (nrow(flagged) == 0L) {
    return("Selected fit-level diagnostics are ok.")
  }
  paste(
    paste(flagged$check, flagged$message, sep = ": "),
    collapse = " | "
  )
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
