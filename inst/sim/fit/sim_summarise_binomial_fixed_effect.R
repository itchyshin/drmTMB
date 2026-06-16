phase18_summarise_binomial_fe_fit <- function(
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
  if (
    !is.list(truth) ||
      !identical(truth$surface, "binomial_fixed_effect")
  ) {
    stop(
      "`truth` must be a binomial fixed-effect truth object.",
      call. = FALSE
    )
  }

  target_fit <- phase18_binomial_fe_target_fit(fit)
  glm_fit <- phase18_binomial_fe_glm_fit(fit)
  truth_value <- truth$beta_mu
  estimate <- stats::coef(target_fit, dpar = "mu")[names(truth_value)]
  glm_estimate <- stats::coef(glm_fit)[names(truth_value)]
  names(estimate) <- paste0("mu:", names(estimate))
  names(glm_estimate) <- names(estimate)
  names(truth_value) <- names(estimate)
  std_error <- phase18_binomial_fe_fixed_effect_se(
    target_fit,
    names(estimate)
  )
  glm_std_error <- phase18_binomial_fe_glm_se(glm_fit, names(estimate))
  loglik <- as.numeric(stats::logLik(target_fit))
  glm_loglik <- as.numeric(stats::logLik(glm_fit))
  aic <- stats::AIC(target_fit)
  glm_aic <- stats::AIC(glm_fit)
  bic <- stats::BIC(target_fit)
  glm_bic <- stats::BIC(glm_fit)

  data.frame(
    surface = "binomial_fixed_effect",
    encoding = truth$encoding,
    cell_id = cell_id,
    replicate = replicate,
    parameter = names(estimate),
    truth = unname(truth_value),
    estimate = unname(estimate),
    std.error = unname(std_error),
    error = unname(estimate - truth_value),
    glm_estimate = unname(glm_estimate),
    glm_std.error = unname(glm_std_error),
    glm_error = unname(glm_estimate - truth_value),
    drmtmb_glm_diff = unname(estimate - glm_estimate),
    drmtmb_glm_se_diff = unname(std_error - glm_std_error),
    logLik = loglik,
    glm_logLik = glm_loglik,
    logLik_diff = loglik - glm_loglik,
    AIC = aic,
    glm_AIC = glm_aic,
    AIC_diff = aic - glm_aic,
    BIC = bic,
    glm_BIC = glm_bic,
    BIC_diff = bic - glm_bic,
    converged = isTRUE(target_fit$opt$convergence == 0),
    pdHess = isTRUE(target_fit$sdr$pdHess),
    nobs = stats::nobs(target_fit),
    mean_trials = mean(stats::weights(glm_fit, type = "prior")),
    elapsed = elapsed,
    warning_count = length(warnings),
    warnings = paste(warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
}

phase18_binomial_fe_target_fit <- function(fit) {
  if (inherits(fit, "drmTMB")) {
    return(fit)
  }
  if (is.list(fit) && inherits(fit$target, "drmTMB")) {
    return(fit$target)
  }
  stop(
    "`fit` must be a drmTMB fit or a binomial fixed-effect fit bundle.",
    call. = FALSE
  )
}

phase18_binomial_fe_glm_fit <- function(fit) {
  if (is.list(fit) && inherits(fit$glm, "glm")) {
    return(fit$glm)
  }
  stop(
    "`fit` must be a binomial fixed-effect fit bundle with a `glm` comparator.",
    call. = FALSE
  )
}

phase18_binomial_fe_fixed_effect_se <- function(fit, parameter) {
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

phase18_binomial_fe_glm_se <- function(fit, parameter) {
  out <- rep(NA_real_, length(parameter))
  names(out) <- parameter
  coefficients <- tryCatch(
    summary(fit)$coefficients,
    error = function(e) NULL
  )
  if (is.null(coefficients) || is.null(row.names(coefficients))) {
    return(out)
  }
  glm_parameter <- sub("^mu:", "", parameter)
  matched <- match(glm_parameter, row.names(coefficients))
  ok <- !is.na(matched)
  out[ok] <- coefficients[matched[ok], "Std. Error"]
  out
}

phase18_binomial_fe_comparator_parity <- function(summary, by = NULL) {
  phase18_assert_summary_columns(
    summary,
    c(
      "parameter",
      "drmtmb_glm_diff",
      "drmtmb_glm_se_diff",
      "logLik_diff",
      "AIC_diff",
      "BIC_diff"
    )
  )
  if (is.null(by)) {
    by <- intersect(
      c("surface", "encoding", "cell_id", "parameter"),
      names(summary)
    )
  }
  phase18_assert_group_columns(summary, by)

  split_key <- interaction(summary[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(summary, split_key)
  rows <- lapply(pieces, function(x) {
    coef_diff <- abs(as.numeric(x$drmtmb_glm_diff))
    se_diff <- abs(as.numeric(x$drmtmb_glm_se_diff))
    loglik_diff <- abs(as.numeric(x$logLik_diff))
    aic_diff <- abs(as.numeric(x$AIC_diff))
    bic_diff <- abs(as.numeric(x$BIC_diff))
    data.frame(
      x[1L, by, drop = FALSE],
      n_replicate = nrow(x),
      artifact_grain = "aggregate",
      comparator = "stats::glm",
      max_abs_coef_diff = max(coef_diff),
      mean_abs_coef_diff = mean(coef_diff),
      max_abs_se_diff = max(se_diff),
      max_abs_logLik_diff = max(loglik_diff),
      max_abs_AIC_diff = max(aic_diff),
      max_abs_BIC_diff = max(bic_diff),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}
