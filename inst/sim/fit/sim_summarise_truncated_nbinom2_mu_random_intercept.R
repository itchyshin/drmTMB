phase18_summarise_truncated_nbinom2_mu_ri_fit <- function(
  fit,
  truth,
  cell_id = NA_character_,
  replicate = NA_integer_,
  elapsed = NA_real_,
  warnings = character(),
  profile_random_sd = TRUE,
  profile_level = 0.70
) {
  if (is.data.frame(truth)) {
    truth <- attr(truth, "truth", exact = TRUE)
  }
  if (
    !is.list(truth) ||
      !identical(truth$surface, "truncated_nbinom2_mu_random_intercept")
  ) {
    stop(
      "`truth` must be a truncated NB2 mu random-intercept truth object.",
      call. = FALSE
    )
  }

  mu_truth <- truth$beta_mu
  sigma_truth <- truth$beta_sigma
  sd_truth <- truth$sd

  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- stats::coef(fit, dpar = "sigma")[names(sigma_truth)]
  sd_est <- fit$sdpars$mu[names(sd_truth)]

  estimate <- c(mu_est, sigma_est, sd_est)
  truth_value <- c(mu_truth, sigma_truth, sd_truth)
  parameter <- c(
    paste0("mu:", names(mu_est)),
    paste0("sigma:", names(sigma_est)),
    paste0("sd:mu:", names(sd_est))
  )
  names(estimate) <- parameter
  names(truth_value) <- parameter

  out <- data.frame(
    surface = "truncated_nbinom2_mu_random_intercept",
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
    std.error = unname(
      phase18_truncated_nbinom2_mu_ri_std_error(fit, parameter)
    ),
    error = unname(estimate - truth_value),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    nobs = stats::nobs(fit),
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
  phase18_truncated_nbinom2_mu_ri_attach_profiles(
    out,
    fit = fit,
    profile_random_sd = profile_random_sd,
    profile_level = profile_level
  )
}

phase18_truncated_nbinom2_mu_ri_attach_profiles <- function(
  summary,
  fit,
  profile_random_sd,
  profile_level
) {
  if (
    !is.logical(profile_random_sd) ||
      length(profile_random_sd) != 1L ||
      is.na(profile_random_sd)
  ) {
    stop("`profile_random_sd` must be TRUE or FALSE.", call. = FALSE)
  }
  if (
    !is.numeric(profile_level) ||
      length(profile_level) != 1L ||
      !is.finite(profile_level) ||
      profile_level <= 0 ||
      profile_level >= 1
  ) {
    stop("`profile_level` must be one number between 0 and 1.", call. = FALSE)
  }

  summary$profile.conf.low <- NA_real_
  summary$profile.conf.high <- NA_real_
  summary$profile.conf.level <- profile_level
  summary$profile.method <- NA_character_
  summary$profile.status <- "not_requested"
  summary$profile.message <- ""
  if (!profile_random_sd) {
    return(summary)
  }

  rows <- which(summary$parameter_class == "random_sd")
  for (row in rows) {
    ci <- tryCatch(
      stats::confint(
        fit,
        parm = summary$parameter[[row]],
        method = "profile",
        level = profile_level,
        trace = FALSE,
        ystep = 0.50
      ),
      error = function(e) e
    )
    summary$profile.method[[row]] <- "profile"
    if (inherits(ci, "error")) {
      summary$profile.status[[row]] <- "failed"
      summary$profile.message[[row]] <- conditionMessage(ci)
      next
    }
    summary$profile.conf.low[[row]] <- ci$lower[[1L]]
    summary$profile.conf.high[[row]] <- ci$upper[[1L]]
    summary$profile.status[[row]] <- ci$conf.status[[1L]]
    summary$profile.message[[row]] <- ci$profile.message[[1L]]
  }
  summary
}

phase18_truncated_nbinom2_mu_ri_std_error <- function(fit, parameter) {
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
