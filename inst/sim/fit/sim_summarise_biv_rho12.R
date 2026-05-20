phase18_summarise_biv_rho12_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "biv_rho12")) {
    stop(
      "`truth` must be a bivariate rho12 truth object.",
      call. = FALSE
    )
  }

  truth_value <- c(
    truth$beta_mu1,
    truth$beta_mu2,
    truth$beta_sigma1,
    truth$beta_sigma2,
    truth$beta_rho12
  )
  names(truth_value) <- c(
    paste0("mu1:", names(truth$beta_mu1)),
    paste0("mu2:", names(truth$beta_mu2)),
    paste0("sigma1:", names(truth$beta_sigma1)),
    paste0("sigma2:", names(truth$beta_sigma2)),
    paste0("rho12:", names(truth$beta_rho12))
  )

  estimate <- c(
    stats::coef(fit, dpar = "mu1")[names(truth$beta_mu1)],
    stats::coef(fit, dpar = "mu2")[names(truth$beta_mu2)],
    stats::coef(fit, dpar = "sigma1")[names(truth$beta_sigma1)],
    stats::coef(fit, dpar = "sigma2")[names(truth$beta_sigma2)],
    stats::coef(fit, dpar = "rho12")[names(truth$beta_rho12)]
  )
  names(estimate) <- names(truth_value)
  std_error <- phase18_biv_rho12_fixed_effect_se(fit, names(estimate))

  out <- data.frame(
    surface = "biv_rho12",
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
  phase18_bootstrap_interval_columns(
    out,
    fit = fit,
    statistic_fun = phase18_biv_rho12_bootstrap_statistic,
    refit_fun = phase18_biv_rho12_bootstrap_refit(data),
    nsim = bootstrap_nsim,
    conf.level = bootstrap_level,
    seed = bootstrap_seed,
    interval_scale = "formula_coefficient",
    cores = bootstrap_cores,
    backend = bootstrap_backend
  )
}

phase18_biv_rho12_bootstrap_statistic <- function(fit) {
  estimate <- c(
    stats::coef(fit, dpar = "mu1"),
    stats::coef(fit, dpar = "mu2"),
    stats::coef(fit, dpar = "sigma1"),
    stats::coef(fit, dpar = "sigma2"),
    stats::coef(fit, dpar = "rho12")
  )
  names(estimate) <- c(
    paste0("mu1:", names(stats::coef(fit, dpar = "mu1"))),
    paste0("mu2:", names(stats::coef(fit, dpar = "mu2"))),
    paste0("sigma1:", names(stats::coef(fit, dpar = "sigma1"))),
    paste0("sigma2:", names(stats::coef(fit, dpar = "sigma2"))),
    paste0("rho12:", names(stats::coef(fit, dpar = "rho12")))
  )
  estimate
}

phase18_biv_rho12_bootstrap_refit <- function(data) {
  force(data)
  function(fit, simulations, index) {
    data$y1 <- simulations[[paste0("sim_", index, "_y1")]]
    data$y2 <- simulations[[paste0("sim_", index, "_y2")]]
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~z1,
        sigma2 = ~z2,
        rho12 = ~w
      ),
      family = biv_gaussian(),
      data = data
    )
  }
}

phase18_biv_rho12_fixed_effect_se <- function(fit, parameter) {
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

phase18_biv_rho12_grid_truth <- function(truth, grid) {
  if (!is.list(truth) || !identical(truth$surface, "biv_rho12")) {
    stop("`truth` must be a bivariate rho12 truth object.", call. = FALSE)
  }
  required <- c("x", "z1", "z2", "w")
  missing <- setdiff(required, names(grid))
  if (length(missing) > 0L) {
    stop(
      "`grid` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  mu1 <- unname(
    truth$beta_mu1[["(Intercept)"]] + truth$beta_mu1[["x"]] * grid$x
  )
  mu2 <- unname(
    truth$beta_mu2[["(Intercept)"]] + truth$beta_mu2[["x"]] * grid$x
  )
  sigma1 <- exp(unname(
    truth$beta_sigma1[["(Intercept)"]] +
      truth$beta_sigma1[["z1"]] * grid$z1
  ))
  sigma2 <- exp(unname(
    truth$beta_sigma2[["(Intercept)"]] +
      truth$beta_sigma2[["z2"]] * grid$z2
  ))
  rho12 <- 0.99999999 *
    tanh(unname(
      truth$beta_rho12[["(Intercept)"]] +
        truth$beta_rho12[["w"]] * grid$w
    ))
  data.frame(
    grid,
    mu1 = mu1,
    mu2 = mu2,
    sigma1 = sigma1,
    sigma2 = sigma2,
    rho12 = rho12,
    residual_covariance = rho12 * sigma1 * sigma2,
    stringsAsFactors = FALSE
  )
}
