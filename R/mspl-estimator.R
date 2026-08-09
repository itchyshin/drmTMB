# Internal adapter for the experimental maximum softly-penalized likelihood
# (MSPL) binomial-logit mixed-model route. The numerical atoms live in
# `R/mspl.R`; this file owns admission, fit diagnostics, and method fences.

drm_match_estimator <- function(estimator) {
  match.arg(estimator, c("ml", "mspl"))
}

drm_is_mspl <- function(x) {
  if (inherits(x, "drmTMB")) {
    return(identical(x$estimator, "MSPL"))
  }
  identical(x, "mspl") || identical(x, "MSPL")
}

drm_abort_mspl_inference <- function(object, what) {
  if (!drm_is_mspl(object)) {
    return(invisible(FALSE))
  }
  cli::cli_abort(
    c(
      "{.fn {what}} is not available for experimental MSPL fits.",
      "i" = "MSPL Phase 3 validates point estimation and objective diagnostics only.",
      "i" = "Use the point estimates, point predictions, and {.code fit$mspl} diagnostics; refit with {.code estimator = \"ml\"} for ordinary likelihood inference."
    ),
    class = "drmTMB_mspl_inference_unsupported"
  )
}

drm_mspl_filter_frequency_rows <- function(data, weights, estimator) {
  if (!drm_is_mspl(estimator) || is.null(weights)) {
    return(list(data = data, weights = weights, kept = seq_len(nrow(data))))
  }
  tolerance <- sqrt(.Machine$double.eps)
  bad <- !is.finite(weights) | weights < 0 |
    abs(weights - round(weights)) > tolerance
  if (any(bad)) {
    cli::cli_abort(c(
      "Experimental MSPL requires non-negative integer frequency weights.",
      "x" = "{sum(bad)} supplied weight{?s} are negative, non-integer, missing, or non-finite."
    ))
  }
  keep <- weights > 0
  if (!any(keep)) {
    cli::cli_abort(
      "Experimental MSPL requires at least one row with a positive frequency weight."
    )
  }
  list(
    data = data[keep, , drop = FALSE],
    weights = as.numeric(round(weights[keep])),
    kept = which(keep)
  )
}

drm_validate_mspl_request <- function(
  estimator,
  engine,
  family,
  family_type,
  REML,
  penalty,
  impute,
  missing_control,
  control
) {
  if (!drm_is_mspl(estimator)) {
    return(invisible(NULL))
  }
  if (!identical(engine, "tmb")) {
    cli::cli_abort("Experimental MSPL is implemented only for {.code engine = \"tmb\"}.")
  }
  if (!identical(family_type, "binomial") ||
      !is.list(family) || !identical(family$link, "logit")) {
    cli::cli_abort(
      "Experimental MSPL requires {.code family = binomial(link = \"logit\")} exactly."
    )
  }
  if (isTRUE(REML)) {
    cli::cli_abort("Experimental MSPL cannot be combined with {.arg REML}.")
  }
  if (!is.null(penalty)) {
    cli::cli_abort(
      "Experimental MSPL cannot be combined with the existing {.arg penalty} interface."
    )
  }
  if (!is.null(impute) ||
      identical(missing_control$response, "include") ||
      identical(missing_control$predictor, "model")) {
    cli::cli_abort(
      "Experimental MSPL does not support missing-data integration or {.fn mi} predictor models."
    )
  }
  if (isTRUE(control$sparse_fixed) || isTRUE(control$aggregate_gaussian)) {
    cli::cli_abort(
      "Experimental MSPL requires the ordinary dense fixed-design route."
    )
  }
  invisible(NULL)
}

drm_validate_mspl_spec <- function(spec) {
  if (!identical(spec$model_type, "binomial")) {
    cli::cli_abort("Internal MSPL error: the fitted specification is not binomial.")
  }
  X <- spec$X$mu
  if (!is.matrix(X) || !is.numeric(X) || any(!is.finite(X))) {
    cli::cli_abort("Experimental MSPL requires a finite dense numeric fixed-effect design matrix.")
  }
  rank_x <- qr(X)$rank
  if (rank_x != ncol(X)) {
    cli::cli_abort(c(
      "Experimental MSPL requires a full-column-rank fixed-effect design.",
      "x" = "The design has {ncol(X)} columns but numerical rank {rank_x}."
    ))
  }
  if (any(!is.finite(spec$offset$mu))) {
    cli::cli_abort("Experimental MSPL requires finite fixed offsets.")
  }
  tolerance <- sqrt(.Machine$double.eps)
  frequency <- spec$weights
  bad_frequency <- !is.finite(frequency) | frequency <= 0 |
    abs(frequency - round(frequency)) > tolerance
  if (any(bad_frequency)) {
    cli::cli_abort(
      "Experimental MSPL requires positive integer frequency weights on every retained row."
    )
  }
  trials <- spec$trials
  bad_trials <- !is.finite(trials) | trials <= 0 |
    abs(trials - round(trials)) > tolerance
  if (any(bad_trials)) {
    cli::cli_abort(
      "Experimental MSPL requires positive integer binomial trial totals on every retained row."
    )
  }

  re <- spec$random$mu
  one_group <- length(unique(re$group_names)) == 1L
  q1 <- re$n_terms == 1L && re$n_cors == 0L && one_group &&
    identical(re$coef_names, "(Intercept)")
  q2 <- re$n_terms == 2L && re$n_cors == 1L && one_group &&
    identical(re$coef_names[[1L]], "(Intercept)")
  if (!q1 && !q2) {
    cli::cli_abort(c(
      "Experimental MSPL requires exactly one ordinary q = 1 or correlated q = 2 grouping block.",
      "i" = "Use {.code (1 | group)} or {.code (1 + x | group)} with one grouping factor.",
      "i" = "Split independent terms, pure slopes, labels, multiple groups, q >= 3, and structured effects are outside Phase 3."
    ))
  }
  q <- if (q2) 2L else 1L
  p <- ncol(X)
  n_eff <- sum(round(frequency) * round(trials))
  scaling <- mspl_c_n(p, n_eff)
  if (!isTRUE(scaling$ok)) {
    cli::cli_abort("Experimental MSPL could not compute a finite softness scale.")
  }
  initial <- mspl_logit_jeffreys(
    X = X,
    beta = rep(0, p),
    offset = spec$offset$mu,
    trials = round(trials),
    frequency = round(frequency)
  )
  if (!isTRUE(initial$ok)) {
    cli::cli_abort(c(
      "Experimental MSPL requires positive-definite fixed-effect information at the declared start.",
      "x" = "Clean-room Jeffreys check failed with code {.val {initial$code}}."
    ))
  }
  list(
    q = q,
    p = p,
    n_row = nrow(X),
    n_eff = as.numeric(n_eff),
    c_n = scaling$c_n,
    initial_half_logdet = initial$half_logdet,
    initial_information = initial$diagnostics,
    frequency = as.numeric(round(frequency)),
    trials = as.numeric(round(trials))
  )
}

drm_binomial_correlated_q2 <- function(spec) {
  if (!identical(spec$model_type, "binomial")) return(FALSE)
  re <- spec$random$mu
  isTRUE(re$n_terms == 2L && re$n_cors == 1L) &&
    length(unique(re$group_names)) == 1L &&
    identical(re$coef_names[[1L]], "(Intercept)")
}

drm_validate_binomial_q2_context <- function(spec, REML = FALSE) {
  if (!drm_binomial_correlated_q2(spec)) return(invisible(spec))
  if (isTRUE(REML)) {
    cli::cli_abort(c(
      "Correlated q = 2 binomial random effects are not implemented with {.arg REML}.",
      "i" = "Use {.code REML = FALSE}, or use the separately validated q = 1 binomial REML route."
    ))
  }
  observed <- spec$missing_data$observed_y
  if (length(observed) && any(!observed)) {
    cli::cli_abort(c(
      "Correlated q = 2 binomial random effects are not implemented with missing-response integration.",
      "i" = "Use complete responses or an independently validated q = 1 route."
    ))
  }
  invisible(spec)
}

drm_mspl_detector <- function(
  spec,
  detector_available = requireNamespace("detectseparation", quietly = TRUE)
) {
  if (!isTRUE(detector_available)) {
    return(list(
      available = FALSE,
      status = "unavailable",
      message = "Install the suggested detectseparation package to record the fixed-X separation screen."
    ))
  }
  y <- cbind(spec$y, spec$trials - spec$y)
  out <- tryCatch(
    detectseparation::detect_separation(
      x = spec$X$mu,
      y = y,
      weights = spec$weights,
      offset = spec$offset$mu,
      family = stats::binomial(link = "logit"),
      intercept = FALSE,
      singular.ok = FALSE
    ),
    error = function(e) e
  )
  if (inherits(out, "error")) {
    return(list(
      available = TRUE,
      status = "failed",
      message = conditionMessage(out)
    ))
  }
  directions <- as.numeric(out$coefficients)
  names(directions) <- colnames(spec$X$mu)
  list(
    available = TRUE,
    status = if (isTRUE(out$outcome)) "separation" else "finite",
    outcome = isTRUE(out$outcome),
    directions = directions,
    detector_class = out$class,
    package_version = as.character(utils::packageVersion("detectseparation"))
  )
}

drm_mspl_report_components <- function(report) {
  fields <- c(
    "mspl_jeffreys", "mspl_variance_negative_huber",
    "mspl_log_objective_bonus", "mspl_nll_penalty",
    "mspl_rho", "mspl_sech", "mspl_log_sech",
    "mspl_L11", "mspl_L21", "mspl_L22"
  )
  stats::setNames(
    lapply(fields, function(field) {
      value <- report[[field]]
      if (is.null(value)) NA_real_ else as.numeric(value)
    }),
    fields
  )
}

drm_mspl_hessian_diagnostics <- function(obj, opt) {
  gradient <- tryCatch(obj$gr(opt$par), error = function(e) e)
  hessian <- tryCatch(
    stats::optimHess(opt$par, obj$fn, obj$gr),
    error = function(e) e
  )
  gradient_ok <- !inherits(gradient, "error") && all(is.finite(gradient))
  hessian_ok <- !inherits(hessian, "error") && all(is.finite(hessian))
  eigenvalues <- if (hessian_ok) {
    tryCatch(
      eigen((hessian + t(hessian)) / 2, symmetric = TRUE, only.values = TRUE)$values,
      error = function(e) numeric()
    )
  } else {
    numeric()
  }
  list(
    gradient = if (gradient_ok) as.numeric(gradient) else NULL,
    gradient_max_abs = if (gradient_ok) max(abs(gradient)) else Inf,
    gradient_message = if (inherits(gradient, "error")) conditionMessage(gradient) else NA_character_,
    hessian = if (hessian_ok) hessian else NULL,
    hessian_eigenvalues = eigenvalues,
    hessian_positive_definite = length(eigenvalues) == length(opt$par) &&
      length(eigenvalues) > 0L && min(eigenvalues) > 0,
    hessian_min_eigenvalue = if (length(eigenvalues)) min(eigenvalues) else NA_real_,
    hessian_message = if (inherits(hessian, "error")) conditionMessage(hessian) else NA_character_
  )
}

drm_mspl_unpenalized_objective <- function(spec, opt) {
  data <- spec$tmb_data
  data$use_mspl <- 0L
  obj <- TMB::MakeADFun(
    data = data,
    parameters = spec$start,
    map = spec$map,
    random = spec$tmb_random_names,
    DLL = "drmTMB",
    silent = TRUE
  )
  value <- obj$fn(opt$par)
  list(objective = as.numeric(value), object = obj)
}

drm_finalize_mspl_fit <- function(spec, obj, opt, report) {
  unpenalized <- drm_mspl_unpenalized_objective(spec, opt)
  numerical <- drm_mspl_hessian_diagnostics(obj, opt)
  components <- drm_mspl_report_components(report)
  par_list <- obj$env$parList(opt$par)
  log_sd <- as.numeric(par_list$log_sd_mu)
  eta_cor <- as.numeric(par_list$eta_cor_mu)
  rho <- if (length(eta_cor)) tanh(eta_cor) else numeric()
  list(
    active = TRUE,
    route = "binomial-logit-ordinary-q1-q2",
    family = "binomial",
    link = "logit",
    q = spec$mspl$q,
    p = spec$mspl$p,
    n_row = spec$mspl$n_row,
    frequency = spec$mspl$frequency,
    trials = spec$mspl$trials,
    n_eff = spec$mspl$n_eff,
    c_n = spec$mspl$c_n,
    initial_half_logdet = spec$mspl$initial_half_logdet,
    initial_logdet_fixed_information = 2 * spec$mspl$initial_half_logdet,
    final_logdet_fixed_information = 2 * components$mspl_jeffreys,
    fixed_information_finite_positive = is.finite(components$mspl_jeffreys),
    eligibility = list(
      dense_full_rank_X = TRUE,
      finite_offset = TRUE,
      positive_integer_frequency = TRUE,
      positive_integer_trials = TRUE,
      one_ordinary_q1_q2_block = TRUE,
      no_missing_integration = TRUE,
      no_reml_map_or_structured_effect = TRUE
    ),
    detector = drm_mspl_detector(spec),
    penalized_objective = as.numeric(opt$objective),
    penalized_log_objective = -as.numeric(opt$objective),
    unpenalized_laplace_objective = unpenalized$objective,
    unpenalized_laplace_logLik = -unpenalized$objective,
    objective_identity_error = as.numeric(opt$objective) -
      (unpenalized$objective + components$mspl_nll_penalty),
    components = components,
    fixed_penalty = components$mspl_jeffreys,
    variance_penalty = components$mspl_variance_negative_huber,
    log_objective_bonus = components$mspl_log_objective_bonus,
    nll_penalty = components$mspl_nll_penalty,
    cholesky = list(
      L11 = components$mspl_L11,
      L21 = components$mspl_L21,
      L22 = components$mspl_L22,
      penalty_coordinates = c(
        log_L11 = log(components$mspl_L11),
        log_L22 = log(components$mspl_L22),
        L21 = components$mspl_L21
      )[seq_len(if (spec$mspl$q == 1L) 1L else 3L)],
      rho = components$mspl_rho,
      sech = components$mspl_sech,
      log_sech = components$mspl_log_sech
    ),
    numerical = numerical,
    boundary = list(
      log_sd = log_sd,
      sd = exp(log_sd),
      eta_rho = eta_cor,
      rho = rho,
      min_sd = if (length(log_sd)) min(exp(log_sd)) else NA_real_,
      max_abs_rho = if (length(rho)) max(abs(rho)) else 0,
      optimizer_bound_contact = FALSE,
      logsigma_clamp_active = FALSE
    ),
    provenance = list(
      implementation = "clean-room from published equations",
      v8_code_copied = FALSE,
      source_doi = "10.1007/s11222-023-10217-3"
    )
  )
}
