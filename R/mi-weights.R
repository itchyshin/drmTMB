# Observation-weight policy for mi() imputation.
#
# Until Shinichi decides #1459, the Gaussian imputation prior is unweighted.
# Audited C++ paths that do `nll -= dnorm(...)` with no weights(i):
#   mi_family == 0 gaussian LS          src/drmTMB.cpp:1434
#   has_mi2 == 1 second Gaussian        src/drmTMB.cpp:1475
#   mi_family == 0 nbinom2 x Gaussian   src/drmTMB.cpp:4678
# Every other family block multiplies the prior by weights(i)
# (Dinnage M1). The nbinom2 x Gaussian copy is the same Gaussian prior
# (family "gaussian") on the nbinom2 response model_type, not a separate
# R family name. These helpers warn only on those unweighted paths.

drm_weights_are_unit <- function(weights) {
  if (is.null(weights)) {
    return(TRUE)
  }
  is.numeric(weights) &&
    length(weights) > 0L &&
    all(is.finite(weights)) &&
    isTRUE(all(weights == 1))
}

drm_eval_call_weights <- function(call, data, env) {
  if (is.null(call) || !("weights" %in% names(as.list(call)))) {
    return(NULL)
  }
  # The Julia mi() gate must see a scalar such as weights = 2 as non-unit
  # before the generic "one value per row" abort, and before the family
  # check. Recycle is not applied; a length-1 numeric is already enough
  # to refuse the Julia route.
  value <- tryCatch(
    eval(call$weights, envir = data, enclos = env),
    error = function(e) NULL
  )
  if (is.numeric(value) && !is.matrix(value) && !is.array(value) &&
        length(value) > 0L) {
    return(as.numeric(value))
  }
  evaluate_likelihood_weights_arg(call$weights, data, env)
}

drm_mi_prior_path_unweighted <- function(missing_predictor,
                                         missing_predictor2 = NULL) {
  first <- is.list(missing_predictor) && isTRUE(missing_predictor$enabled)
  first_gaussian <- first && (
    is.null(missing_predictor$family) ||
      identical(missing_predictor$family, "gaussian")
  )
  second <- is.list(missing_predictor2) && isTRUE(missing_predictor2$enabled)
  second_gaussian <- second && (
    is.null(missing_predictor2$family) ||
      identical(missing_predictor2$family, "gaussian")
  )
  isTRUE(first_gaussian) || isTRUE(second_gaussian)
}

drm_warn_mi_prior_ignores_weights <- function(weights, unweighted_prior) {
  if (!isTRUE(unweighted_prior) || drm_weights_are_unit(weights)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(
    c(
      "The Gaussian {.fn mi} imputation prior ignores observation weights.",
      i = "A row weight multiplies the response term only on the unweighted Gaussian prior paths (src/drmTMB.cpp:1434, :1475, and the nbinom2 x Gaussian copy at :4678). Weight 2 is not the same as a duplicated row until a decision on #1459.",
      i = "Beta, Gamma, and the other M1 families already multiply the prior by the row weight. Use {.code weights = NULL} or {.code weights = 1} when you want the Gaussian prior and the response to use the same multiplier."
    ),
    class = "drmTMB_mi_weights_prior_unweighted"
  )
  invisible(TRUE)
}

drm_abort_mi_zero_weight_missing <- function(weights, observed_x, variable) {
  if (is.null(weights) || is.null(observed_x)) {
    return(invisible(FALSE))
  }
  if (length(weights) != length(observed_x)) {
    return(invisible(FALSE))
  }
  missing_x <- !as.logical(observed_x)
  bad <- missing_x & (is.na(weights) | !is.finite(weights) | weights == 0)
  if (!any(bad)) {
    return(invisible(FALSE))
  }
  cli::cli_abort(
    c(
      "{.arg weights} of 0 or NA are not allowed on a row whose {.fn mi} predictor is missing.",
      x = "{sum(bad)} row{?s} {?has/have} a missing {.val {variable}} value and a zero or missing weight.",
      i = "This is a named error, not a silent drop. Give that row a positive weight, or drop it before fitting."
    ),
    class = "drmTMB_mi_zero_weight_missing"
  )
}

drm_abort_mi_zero_weight_missing_in_data <- function(data, weights, impute) {
  if (is.null(weights) || is.null(impute) || !is.list(impute) || !length(impute)) {
    return(invisible(FALSE))
  }
  vars <- names(impute)
  vars <- vars[!is.na(vars) & nzchar(vars)]
  for (variable in vars) {
    if (!variable %in% names(data)) {
      next
    }
    observed <- !is.na(data[[variable]])
    drm_abort_mi_zero_weight_missing(weights, observed, variable)
  }
  invisible(FALSE)
}

drm_abort_julia_mi_nonunit_weights <- function(weights) {
  if (drm_weights_are_unit(weights)) {
    return(invisible(FALSE))
  }
  cli::cli_abort(
    c(
      "{.code engine = \"julia\"} does not apply observation weights to {.fn mi} models.",
      x = "DRModels.jl ignores weights on the response term and on the imputation prior.",
      i = "Use {.code engine = \"tmb\"} for a weighted {.fn mi} fit, or omit {.arg weights}."
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
}

drm_abort_mi_quadrature_nonfinite <- function(detail = NULL) {
  extra <- if (length(detail) == 1L && nzchar(detail)) {
    c(x = detail)
  } else {
    character()
  }
  cli::cli_abort(
    c(
      "The {.fn mi} quadrature marginal is not finite.",
      extra,
      x = "A missing-predictor row produced a NaN or -Inf log-likelihood contribution.",
      i = "Check the predictor family, the response scale, and extreme missing-x rows. This is a named error, not a silent drop."
    ),
    class = "drmTMB_mi_quadrature_nonfinite"
  )
}

drm_rethrow_mi_quadrature_error <- function(e) {
  if (inherits(e, "drmTMB_mi_quadrature_nonfinite")) {
    stop(e)
  }
  msg <- conditionMessage(e)
  if (grepl("drmTMB_mi_quadrature_nonfinite", msg, fixed = TRUE)) {
    drm_abort_mi_quadrature_nonfinite(msg)
  }
  stop(e)
}

drm_mi_quadrature_abort_families <- function() {
  c("gamma", "beta", "zero_one_beta")
}

drm_mi_term_uses_quadrature_abort <- function(mp) {
  is.list(mp) &&
    isTRUE(mp$enabled) &&
    is.character(mp$family) &&
    length(mp$family) == 1L &&
    mp$family %in% drm_mi_quadrature_abort_families()
}

drm_spec_uses_mi_quadrature_abort <- function(spec) {
  drm_mi_term_uses_quadrature_abort(spec[["missing_predictor"]]) ||
    drm_mi_term_uses_quadrature_abort(spec[["missing_predictor2"]])
}

# Post-fit accuracy guard for the frozen 15-node Beta / zero-one-Beta rule and
# for Gamma mi() at high CV. Thresholds are the measured leftover vs
# integrate(), not a new quadrature rule:
#   Beta/ZOB missing-row prior mean at or inside 0.10 of 0 or 1, because
#   |logLik - log integrate()| is 4.65e-3 at mu = 0.10, sigma = 1 and
#   4.81e-3 at mu = 0.02, sigma = 1 on the 15-node Gauss-Legendre rule.
#   Mid-range mu = 0.50, sigma = 0.5 stays near 2.6e-5; a pinched
#   mu = 0.10, sigma = 0.2 case is also inside 2.6e-5, so a mu-only
#   threshold is conservative at that pin.
#   Gamma CV >= 3: 12% of an 80-row (mu, y) scan exceed 1e-4, worst 1.47.
drm_mi_quadrature_inaccurate_beta_mu_boundary <- function() 0.10
drm_mi_quadrature_inaccurate_gamma_cv <- function() 3

drm_mi_quadrature_slot_names <- function(slot) {
  if (identical(as.integer(slot), 2L)) {
    list(beta = "beta_mi2", log_sigma = "log_sigma_mi2")
  } else {
    list(beta = "beta_mi", log_sigma = "log_sigma_mi")
  }
}

drm_mi_quadrature_inaccurate_hits <- function(mp, par_list, slot) {
  if (!is.list(mp) || !isTRUE(mp$enabled)) {
    return(character())
  }
  family <- mp$family
  if (!is.character(family) || length(family) != 1L) {
    return(character())
  }
  variable <- mp$variable
  if (!is.character(variable) || length(variable) != 1L || !nzchar(variable)) {
    variable <- sprintf("mi() slot %s", slot)
  }
  names <- drm_mi_quadrature_slot_names(slot)
  if (family %in% c("beta", "zero_one_beta")) {
    beta <- as.numeric(par_list[[names$beta]])
    X <- mp$X
    if (!is.matrix(X) || !length(beta) || length(beta) != ncol(X)) {
      return(character())
    }
    eta <- as.vector(X %*% beta)
    mu <- drm_beta_missing_predictor_inverse_link(eta)
    idx <- as.integer(mp$missing_index)
    if (length(idx) > 0L) {
      idx <- idx[idx >= 1L & idx <= length(mu)]
      if (length(idx) > 0L) {
        mu <- mu[idx]
      }
    }
    mu <- mu[is.finite(mu)]
    boundary <- drm_mi_quadrature_inaccurate_beta_mu_boundary()
    bad <- mu <= boundary | mu >= (1 - boundary)
    if (!length(mu) || !any(bad)) {
      return(character())
    }
    mu_hit <- mu[bad][[1L]]
    sprintf(
      "Beta/zero-one-Beta prior for %s has a missing-row mean of %.3g (threshold %.2f from 0 or 1).",
      variable,
      mu_hit,
      boundary
    )
  } else if (identical(family, "gamma")) {
    log_sigma <- as.numeric(par_list[[names$log_sigma]])
    if (!length(log_sigma) || !is.finite(log_sigma[[1L]])) {
      return(character())
    }
    cv <- exp(log_sigma[[1L]])
    threshold <- drm_mi_quadrature_inaccurate_gamma_cv()
    if (!is.finite(cv) || cv < threshold) {
      return(character())
    }
    sprintf(
      "Gamma prior for %s has CV %.3g (threshold %s).",
      variable,
      cv,
      threshold
    )
  } else {
    character()
  }
}

drm_warn_mi_quadrature_inaccurate <- function(spec, par_list) {
  if (!is.list(spec) || !is.list(par_list)) {
    return(invisible(FALSE))
  }
  hits <- c(
    drm_mi_quadrature_inaccurate_hits(
      spec[["missing_predictor"]],
      par_list,
      slot = 1L
    ),
    drm_mi_quadrature_inaccurate_hits(
      spec[["missing_predictor2"]],
      par_list,
      slot = 2L
    )
  )
  if (!length(hits)) {
    return(invisible(FALSE))
  }
  extra <- stats::setNames(hits, rep("x", length(hits)))
  cli::cli_warn(
    c(
      "The {.fn mi} quadrature marginal is inaccurate at the fitted prior.",
      extra,
      i = "The fit is returned. Missing-x rows used the frozen 15-node Gauss-Legendre rule (Beta / zero-one-Beta) or the 51-node log-x rule (Gamma). Move the Beta prior mean away from 0 and 1, or bring Gamma CV below 3, if you need the documented 1e-4 logLik accuracy (refs #1476 / #1477 / #1531)."
    ),
    class = "drmTMB_mi_quadrature_inaccurate"
  )
  invisible(TRUE)
}

drm_probe_mi_quadrature_objective <- function(obj, par, stage) {
  err <- NULL
  nll <- tryCatch(
    obj$fn(par),
    error = function(e) {
      err <<- e
      NULL
    }
  )
  if (!is.null(err)) {
    drm_rethrow_mi_quadrature_error(err)
  }
  if (!is.finite(nll)) {
    drm_abort_mi_quadrature_nonfinite(
      sprintf("The %s objective is not finite.", stage)
    )
  }
  err <- NULL
  gr <- tryCatch(
    obj$gr(par),
    error = function(e) {
      err <<- e
      NULL
    }
  )
  if (!is.null(err)) {
    drm_rethrow_mi_quadrature_error(err)
  }
  if (!all(is.finite(gr))) {
    drm_abort_mi_quadrature_nonfinite(
      sprintf("The %s gradient is not finite.", stage)
    )
  }
  invisible(nll)
}

drm_abort_mi_weights_predict <- function(object, dots = list()) {
  has_mi <- is.list(object$missing_data$predictors) &&
    length(object$missing_data$predictors) > 0L
  if (!has_mi) {
    return(invisible(FALSE))
  }
  if (!("weights" %in% names(dots))) {
    return(invisible(FALSE))
  }
  if (drm_weights_are_unit(dots$weights)) {
    return(invisible(FALSE))
  }
  cli::cli_abort(
    c(
      "{.fn predict} and {.fn simulate} do not take non-unit {.arg weights} for a {.fn mi} model.",
      i = "Omit {.arg weights} from {.fn predict} / {.fn simulate}, or pass {.code weights = 1}. The methods use the fitted coefficients."
    ),
    class = "drmTMB_mi_weights_predict_unsupported"
  )
}
