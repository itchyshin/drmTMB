phase18_summarise_spatial_q2_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character(),
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50)
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (!is.list(truth) || !identical(truth$surface, "spatial_q2")) {
    stop("`truth` must be a spatial q2 truth object.", call. = FALSE)
  }

  sigma_estimate <- stats::sigma(fit)
  sigma1 <- sigma_estimate$sigma1[[1L]]
  sigma2 <- sigma_estimate$sigma2[[1L]]
  sd_estimate <- unname(fit$sdpars$mu)
  cor_estimate <- unname(fit$corpars$spatial)

  truth_value <- c(
    truth$beta_mu1,
    truth$beta_mu2,
    sigma1 = truth$sigma[["sigma1"]],
    sigma2 = truth$sigma[["sigma2"]],
    spatial_sd1 = truth$sd_spatial[["mu1"]],
    spatial_sd2 = truth$sd_spatial[["mu2"]],
    spatial_cor = truth$rho_spatial,
    rho12 = truth$rho12
  )
  names(truth_value) <- c(
    paste0("mu1:", names(truth$beta_mu1)),
    paste0("mu2:", names(truth$beta_mu2)),
    "sigma1",
    "sigma2",
    "spatial:sd1",
    "spatial:sd2",
    "spatial:cor",
    "rho12"
  )

  estimate <- c(
    stats::coef(fit, dpar = "mu1")[names(truth$beta_mu1)],
    stats::coef(fit, dpar = "mu2")[names(truth$beta_mu2)],
    sigma1 = sigma1,
    sigma2 = sigma2,
    spatial_sd1 = sd_estimate[[1L]],
    spatial_sd2 = sd_estimate[[2L]],
    spatial_cor = cor_estimate[[1L]],
    rho12 = rho12(fit)[[1L]]
  )
  names(estimate) <- names(truth_value)
  std_error <- phase18_spatial_q2_fixed_effect_se(fit, names(estimate))

  out <- data.frame(
    surface = "spatial_q2",
    geometry = truth$geometry,
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
  profile_map <- phase18_spatial_q2_profile_parameter_map(
    fit,
    parameters = profile_parameters
  )
  phase18_profile_interval_columns(
    out,
    fit = fit,
    parameters = profile_map,
    conf.level = profile_level,
    interval_scale = "response",
    profile_args = profile_args
  )
}

phase18_spatial_q2_fixed_effect_se <- function(fit, parameter) {
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

phase18_spatial_q2_profile_parameter_map <- function(
  fit,
  parameters = character()
) {
  if (!is.character(parameters) || any(!nzchar(parameters))) {
    stop("`parameters` must be a character vector.", call. = FALSE)
  }

  sd_names <- names(fit$sdpars$mu)
  cor_names <- names(fit$corpars$spatial)
  map <- c(
    setNames(
      paste0("sd:mu:", sd_names[seq_len(min(2L, length(sd_names)))]),
      paste0("spatial:sd", seq_len(min(2L, length(sd_names))))
    ),
    setNames(
      paste0("cor:spatial:", cor_names[[1L]]),
      "spatial:cor"
    ),
    rho12 = "rho12"
  )
  map <- map[!is.na(map)]
  if (length(parameters) == 0L) {
    return(map[0L])
  }
  map[intersect(parameters, names(map))]
}
