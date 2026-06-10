phase18_summarise_skew_normal_fe_fit <- function(
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
  dpar <- sub(":.*", "", names(estimate))
  term <- sub("^[^:]+:", "", names(estimate))

  out <- data.frame(
    surface = "skew_normal_fixed_effect",
    cell_id = cell_id,
    replicate = replicate,
    n = truth$n,
    n_used = stats::nobs(fit),
    rho_xw = truth$rho_xw,
    sigma_baseline = truth$sigma_baseline,
    nu_baseline = truth$nu_baseline,
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
    statistic_fun = phase18_skew_normal_fe_bootstrap_statistic,
    refit_fun = phase18_skew_normal_fe_bootstrap_refit(data),
    nsim = bootstrap_nsim,
    conf.level = bootstrap_level,
    seed = bootstrap_seed,
    interval_scale = "formula_coefficient",
    cores = bootstrap_cores,
    backend = bootstrap_backend
  )
}

phase18_skew_normal_fe_bootstrap_statistic <- function(fit) {
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

phase18_skew_normal_fe_bootstrap_refit <- function(data) {
  force(data)
  function(fit, simulations, index) {
    data$y <- simulations[[paste0("sim_", index)]]
    drmTMB(
      bf(y ~ x, sigma ~ z, nu ~ w),
      family = skew_normal(),
      data = data,
      control = drm_control(optimizer_preset = "careful")
    )
  }
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

phase18_skew_normal_fe_grid_truth <- function(truth, grid) {
  if (
    !is.list(truth) ||
      !identical(truth$surface, "skew_normal_fixed_effect")
  ) {
    stop(
      "`truth` must be a skew-normal fixed-effect truth object.",
      call. = FALSE
    )
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
  nu <- unname(
    truth$beta_nu[["(Intercept)"]] + truth$beta_nu[["w"]] * grid$w
  )
  data.frame(
    grid,
    mu = mu,
    sigma = sigma,
    nu = nu,
    stringsAsFactors = FALSE
  )
}
