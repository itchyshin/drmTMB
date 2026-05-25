phase18_summarise_nbinom2_sigma_re_fit <- function(
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
  if (
    !is.list(truth) ||
      !identical(truth$surface, "nbinom2_sigma_random_effect")
  ) {
    stop(
      "`truth` must be an NB2 sigma random-effect truth object.",
      call. = FALSE
    )
  }

  mu_truth <- truth$beta_mu
  sigma_truth <- truth$beta_sigma
  sd_truth <- truth$sd

  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- stats::coef(fit, dpar = "sigma")[names(sigma_truth)]
  sd_est <- fit$sdpars$sigma[names(sd_truth)]

  estimate <- c(mu_est, sigma_est, sd_est)
  truth_value <- c(mu_truth, sigma_truth, sd_truth)
  parameter <- c(
    paste0("mu:", names(mu_est)),
    paste0("sigma:", names(sigma_est)),
    paste0("sd:sigma:", names(sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  out <- data.frame(
    surface = "nbinom2_sigma_random_effect",
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = c(
      rep("fixed_mu", length(mu_est)),
      rep("fixed_sigma", length(sigma_est)),
      rep("random_sd", length(sd_est))
    ),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(phase18_nbinom2_sigma_re_std_error(fit, parameter)),
    error = unname(estimate - truth_value),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    n_group = truth$n_group,
    n_per_group = truth$n_per_group,
    mean_count = truth$mean_count,
    sigma_baseline = truth$sigma_baseline,
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
  profile_map <- phase18_nbinom2_sigma_re_profile_parameter_map(
    parameters = profile_parameters
  )
  out <- phase18_profile_interval_columns(
    out,
    fit = fit,
    parameters = profile_map,
    conf.level = profile_level,
    interval_scale = "public_sd",
    profile_args = profile_args
  )
  phase18_nbinom2_sigma_re_attach_status(out, fit)
}

phase18_nbinom2_sigma_re_profile_parameter_map <- function(
  parameters = character()
) {
  if (!is.character(parameters) || any(!nzchar(parameters))) {
    stop("`parameters` must be a character vector.", call. = FALSE)
  }
  if (length(parameters) == 0L) {
    return(character())
  }

  public_target <- "sd:sigma:(1 | id)"
  aliases <- stats::setNames(
    c(public_target, public_target),
    c(public_target, "log_sd_sigma")
  )
  requested <- aliases[intersect(parameters, names(aliases))]
  targets <- unique(unname(requested))
  stats::setNames(targets, targets)
}

phase18_nbinom2_sigma_re_attach_status <- function(summary, fit) {
  targets <- tryCatch(
    profile_targets(fit),
    error = function(e) NULL
  )
  diagnostics <- tryCatch(
    check_drm(fit),
    error = function(e) NULL
  )

  summary$profile_target_status <- "unavailable"
  summary$profile_target_parameter <- NA_character_
  summary$diagnostic_status <- NA_character_
  summary$diagnostic_message <- NA_character_

  if (
    is.data.frame(targets) &&
      all(c("parm", "profile_ready") %in% names(targets))
  ) {
    matched <- match(summary$parameter, targets$parm)
    ok <- !is.na(matched)
    summary$profile_target_status[ok] <- ifelse(
      targets$profile_ready[matched[ok]],
      "ready",
      "not_ready"
    )
    summary$profile_target_parameter[ok] <- targets$tmb_parameter[matched[ok]]
  }

  if (
    is.data.frame(diagnostics) &&
      all(c("check", "status", "message") %in% names(diagnostics))
  ) {
    sigma_rows <- diagnostics$check %in%
      c("sigma_random_effect_replication")
    status <- paste(diagnostics$status[sigma_rows], collapse = " | ")
    message <- paste(diagnostics$message[sigma_rows], collapse = " | ")
    summary$diagnostic_status[summary$parameter_class == "random_sd"] <- status
    summary$diagnostic_message[
      summary$parameter_class == "random_sd"
    ] <- message
  }

  summary
}

phase18_nbinom2_sigma_re_std_error <- function(fit, parameter) {
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
