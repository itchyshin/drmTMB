phase18_summarise_meta_v_fit <- function(
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
  if (!is.list(truth) || !identical(truth$surface, "meta_v")) {
    stop("`truth` must be a meta_V truth object.", call. = FALSE)
  }

  mu_truth <- truth$beta_mu
  mu_est <- stats::coef(fit, dpar = "mu")[names(mu_truth)]
  sigma_est <- unique(as.numeric(stats::sigma(fit)))
  if (length(sigma_est) != 1L) {
    stop("`fit` must have one constant residual sigma estimate.", call. = FALSE)
  }

  estimate <- c(mu_est, sigma = sigma_est)
  truth_value <- c(mu_truth, sigma = truth$sigma)
  names(estimate) <- c(paste0("mu:", names(mu_est)), "sigma")
  names(truth_value) <- names(estimate)
  std_error <- phase18_meta_v_standard_errors(fit, names(estimate))

  data.frame(
    surface = "meta_v",
    known_v_type = truth$known_v_type,
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

phase18_meta_v_standard_errors <- function(fit, parameter) {
  out <- rep(NA_real_, length(parameter))
  names(out) <- parameter
  fit_summary <- tryCatch(
    summary(fit),
    error = function(e) NULL
  )
  if (is.null(fit_summary)) {
    return(out)
  }

  coefficients <- fit_summary$coefficients
  if (
    !is.null(coefficients) &&
      "std_error" %in% names(coefficients) &&
      !is.null(row.names(coefficients))
  ) {
    matched <- match(parameter, row.names(coefficients))
    ok <- !is.na(matched)
    out[ok] <- coefficients$std_error[matched[ok]]
  }

  parameters <- fit_summary$parameters
  if (
    "sigma" %in%
      parameter &&
      is.data.frame(parameters) &&
      all(c("parm", "std_error") %in% names(parameters))
  ) {
    sigma_row <- which(parameters$parm == "sigma")
    if (length(sigma_row) >= 1L) {
      out[["sigma"]] <- parameters$std_error[[sigma_row[[1L]]]]
    }
  }
  out
}
