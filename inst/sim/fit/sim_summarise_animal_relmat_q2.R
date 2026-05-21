phase18_summarise_animal_relmat_q2_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "animal_relmat_q2")) {
    stop("`truth` must be an animal/relmat q2 truth object.", call. = FALSE)
  }
  structured_surface <- truth$structured_surface
  if (!structured_surface %in% c("animal", "relmat")) {
    stop("`truth$structured_surface` must be animal or relmat.", call. = FALSE)
  }

  sigma_estimate <- stats::sigma(fit)
  sigma1 <- sigma_estimate$sigma1[[1L]]
  sigma2 <- sigma_estimate$sigma2[[1L]]
  sd_estimate <- unname(fit$sdpars$mu)
  cor_estimate <- unname(fit$corpars[[structured_surface]])

  truth_value <- c(
    truth$beta_mu1,
    truth$beta_mu2,
    sigma1 = truth$sigma[["sigma1"]],
    sigma2 = truth$sigma[["sigma2"]],
    structured_sd1 = truth$sd_struct[["mu1"]],
    structured_sd2 = truth$sd_struct[["mu2"]],
    structured_cor = truth$rho_struct,
    rho12 = truth$rho12
  )
  names(truth_value) <- c(
    paste0("mu1:", names(truth$beta_mu1)),
    paste0("mu2:", names(truth$beta_mu2)),
    "sigma1",
    "sigma2",
    paste0(structured_surface, ":sd1"),
    paste0(structured_surface, ":sd2"),
    paste0(structured_surface, ":cor"),
    "rho12"
  )

  estimate <- c(
    stats::coef(fit, dpar = "mu1")[names(truth$beta_mu1)],
    stats::coef(fit, dpar = "mu2")[names(truth$beta_mu2)],
    sigma1 = sigma1,
    sigma2 = sigma2,
    structured_sd1 = sd_estimate[[1L]],
    structured_sd2 = sd_estimate[[2L]],
    structured_cor = cor_estimate[[1L]],
    rho12 = rho12(fit)[[1L]]
  )
  names(estimate) <- names(truth_value)
  std_error <- phase18_animal_relmat_q2_fixed_effect_se(
    fit,
    names(estimate)
  )

  data.frame(
    surface = "animal_relmat_q2",
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
}

phase18_animal_relmat_q2_fixed_effect_se <- function(fit, parameter) {
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
