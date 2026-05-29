phase18_summarise_count_structured_q1_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "count_structured_q1")) {
    stop("`truth` must be a count structured q1 truth object.", call. = FALSE)
  }
  if (!inherits(fit, "drmTMB")) {
    stop("`fit` must be a drmTMB object.", call. = FALSE)
  }

  mu_truth <- truth$beta_mu
  sigma_truth <- if (identical(truth$family, "nbinom2")) {
    truth$beta_sigma
  } else {
    numeric()
  }
  sd_truth <- truth$sd

  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- if (identical(truth$family, "nbinom2")) {
    stats::coef(fit, dpar = "sigma")[names(sigma_truth)]
  } else {
    numeric()
  }
  sd_est <- fit$sdpars$mu[names(sd_truth)]

  estimate <- c(mu_est, sigma_est, sd_est)
  truth_value <- c(mu_truth, sigma_truth, sd_truth)
  sigma_parameter <- if (length(sigma_est) > 0L) {
    paste0("sigma:", names(sigma_est))
  } else {
    character()
  }
  parameter <- c(
    paste0("mu:", names(mu_est)),
    sigma_parameter,
    paste0("sd:mu:", names(sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter
  parameter_class <- c(
    rep("fixed_mu", length(mu_est)),
    rep("fixed_sigma", length(sigma_est)),
    rep("structured_sd", length(sd_est))
  )

  out <- data.frame(
    surface = "count_structured_q1",
    family = truth$family,
    structured_type = truth$structured_type,
    group = truth$group,
    cell_id = cell_id,
    replicate = replicate,
    parameter = parameter,
    parameter_class = parameter_class,
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(phase18_count_structured_q1_std_error(fit, parameter)),
    error = unname(estimate - truth_value),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    n_level = truth$n_level,
    n_per_level = truth$n_per_level,
    mean_count = truth$mean_count,
    sigma_baseline = truth$sigma_baseline,
    geometry = truth$geometry,
    matrix_decay = truth$matrix_decay,
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
  profile_map <- phase18_count_structured_q1_profile_parameter_map(
    truth = truth,
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
  phase18_count_structured_q1_attach_status(out, fit, truth$structured_type)
}

phase18_count_structured_q1_profile_parameter_map <- function(
  truth,
  parameters = character()
) {
  if (!is.list(truth) || !identical(truth$surface, "count_structured_q1")) {
    stop("`truth` must be a count structured q1 truth object.", call. = FALSE)
  }
  if (!is.character(parameters) || any(!nzchar(parameters))) {
    stop("`parameters` must be a character vector.", call. = FALSE)
  }
  if (length(parameters) == 0L) {
    return(character())
  }

  public_target <- paste0("sd:mu:", names(truth$sd))
  aliases <- stats::setNames(
    c(public_target, public_target),
    c(public_target, "log_sd_phylo")
  )
  requested <- aliases[intersect(parameters, names(aliases))]
  targets <- unique(unname(requested))
  stats::setNames(targets, targets)
}

phase18_count_structured_q1_attach_status <- function(
  summary,
  fit,
  structured_type
) {
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
      all(c("parm", "profile_ready", "tmb_parameter") %in% names(targets))
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
    diagnostic_rows <- diagnostics$check %in%
      c(
        paste0(structured_type, "_mu_replication"),
        paste0(structured_type, "_mu_diagnostics")
      )
    status <- paste(diagnostics$status[diagnostic_rows], collapse = " | ")
    message <- paste(diagnostics$message[diagnostic_rows], collapse = " | ")
    if (!nzchar(status)) {
      status <- "missing"
      message <- paste0(structured_type, " mu diagnostic row not found")
    }
    summary$diagnostic_status[summary$parameter_class == "structured_sd"] <-
      status
    summary$diagnostic_message[summary$parameter_class == "structured_sd"] <-
      message
  }

  summary
}

phase18_count_structured_q1_std_error <- function(fit, parameter) {
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
