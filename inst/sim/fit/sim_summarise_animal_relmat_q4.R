phase18_summarise_animal_relmat_q4_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "animal_relmat_q4")) {
    stop("`truth` must be an animal/relmat q4 truth object.", call. = FALSE)
  }
  structured_surface <- truth$structured_surface
  if (!structured_surface %in% c("animal", "relmat")) {
    stop("`truth$structured_surface` must be animal or relmat.", call. = FALSE)
  }

  sd_estimate <- unname(fit$sdpars$mu)
  cor_estimate <- unname(fit$corpars[[structured_surface]])
  cor_truth <- phase18_animal_relmat_q4_cor_vector(truth$cor_struct)

  truth_value <- c(
    truth$beta_mu1,
    truth$beta_mu2,
    truth$beta_sigma1,
    truth$beta_sigma2,
    structured_sd_mu1 = truth$sd_struct[["mu1"]],
    structured_sd_mu2 = truth$sd_struct[["mu2"]],
    structured_sd_sigma1 = truth$sd_struct[["sigma1"]],
    structured_sd_sigma2 = truth$sd_struct[["sigma2"]],
    cor_truth,
    rho12 = truth$rho12
  )
  names(truth_value) <- c(
    paste0("mu1:", names(truth$beta_mu1)),
    paste0("mu2:", names(truth$beta_mu2)),
    paste0("sigma1:", names(truth$beta_sigma1)),
    paste0("sigma2:", names(truth$beta_sigma2)),
    paste0(structured_surface, ":sd_", names(truth$sd_struct)),
    paste0(structured_surface, ":cor_", names(cor_truth)),
    "rho12"
  )

  estimate <- c(
    stats::coef(fit, dpar = "mu1")[names(truth$beta_mu1)],
    stats::coef(fit, dpar = "mu2")[names(truth$beta_mu2)],
    stats::coef(fit, dpar = "sigma1")[names(truth$beta_sigma1)],
    stats::coef(fit, dpar = "sigma2")[names(truth$beta_sigma2)],
    structured_sd_mu1 = sd_estimate[[1L]],
    structured_sd_mu2 = sd_estimate[[2L]],
    structured_sd_sigma1 = sd_estimate[[3L]],
    structured_sd_sigma2 = sd_estimate[[4L]],
    stats::setNames(cor_estimate, names(cor_truth)),
    rho12 = rho12(fit)[[1L]]
  )
  names(estimate) <- names(truth_value)
  std_error <- phase18_animal_relmat_q4_fixed_effect_se(
    fit,
    names(estimate)
  )

  out <- data.frame(
    surface = "animal_relmat_q4",
    structured_surface = structured_surface,
    matrix_argument = truth$matrix_argument,
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
  profile_map <- phase18_animal_relmat_q4_profile_parameter_map(
    fit,
    structured_surface = structured_surface,
    parameters = profile_parameters
  )
  out <- phase18_profile_interval_columns(
    out,
    fit = fit,
    parameters = profile_map,
    conf.level = profile_level,
    interval_scale = "response",
    profile_args = profile_args
  )
  phase18_animal_relmat_q4_mark_derived_profiles(
    out,
    structured_surface = structured_surface,
    requested = profile_parameters
  )
}

phase18_animal_relmat_q4_fixed_effect_se <- function(fit, parameter) {
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

phase18_animal_relmat_q4_profile_parameter_map <- function(
  fit,
  structured_surface,
  parameters = character()
) {
  if (!structured_surface %in% c("animal", "relmat")) {
    stop(
      "`structured_surface` must be animal or relmat.",
      call. = FALSE
    )
  }
  if (!is.character(parameters) || any(!nzchar(parameters))) {
    stop("`parameters` must be a character vector.", call. = FALSE)
  }

  endpoint <- c("mu1", "mu2", "sigma1", "sigma2")
  sd_names <- names(fit$sdpars$mu)
  map <- c(
    setNames(
      paste0("sd:mu:", sd_names[seq_len(min(4L, length(sd_names)))]),
      paste0(
        structured_surface,
        ":sd_",
        endpoint[seq_len(
          min(4L, length(sd_names))
        )]
      )
    ),
    rho12 = "rho12"
  )
  map <- map[!is.na(map)]
  if (length(parameters) == 0L) {
    return(map[0L])
  }
  map[intersect(parameters, names(map))]
}

phase18_animal_relmat_q4_mark_derived_profiles <- function(
  summary,
  structured_surface,
  requested
) {
  if (!is.character(requested) || length(requested) == 0L) {
    return(summary)
  }
  cor_parameters <- paste0(
    structured_surface,
    ":cor_",
    names(phase18_animal_relmat_q4_cor_vector(
      phase18_animal_relmat_q4_cor_matrix()
    ))
  )
  rows <- summary$parameter %in% intersect(requested, cor_parameters)
  if (!any(rows)) {
    return(summary)
  }
  summary$profile.status[rows] <- "derived_interval_unavailable"
  summary$profile.message[rows] <- paste(
    "q4 structured correlations are derived from an unstructured",
    "correlation parameterization; direct profile intervals are unavailable"
  )
  summary
}

phase18_animal_relmat_q4_cor_vector <- function(cor_struct) {
  cor_struct <- phase18_animal_relmat_q4_validate_cor(cor_struct)
  stats::setNames(
    c(
      cor_struct["mu1", "mu2"],
      cor_struct["mu1", "sigma1"],
      cor_struct["mu1", "sigma2"],
      cor_struct["mu2", "sigma1"],
      cor_struct["mu2", "sigma2"],
      cor_struct["sigma1", "sigma2"]
    ),
    c(
      "mu1_mu2",
      "mu1_sigma1",
      "mu1_sigma2",
      "mu2_sigma1",
      "mu2_sigma2",
      "sigma1_sigma2"
    )
  )
}
