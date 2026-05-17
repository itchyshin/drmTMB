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

  data.frame(
    surface = "meta_v",
    known_v_type = truth$known_v_type,
    cell_id = cell_id,
    replicate = replicate,
    parameter = names(estimate),
    truth = unname(truth_value),
    estimate = unname(estimate),
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
