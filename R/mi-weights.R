# Observation-weight policy for mi() imputation.
#
# Until Shinichi decides #1459, the Gaussian imputation prior is unweighted.
# Audited C++ paths that do `nll -= dnorm(...)` with no weights(i):
#   mi_family == 0 gaussian LS          src/drmTMB.cpp:1301
#   has_mi2 == 1 second Gaussian        src/drmTMB.cpp:1342
#   mi_family == 0 nbinom2 x Gaussian   src/drmTMB.cpp:4556
# Every other family block from :1357 multiplies the prior by weights(i)
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
  isTRUE(first_gaussian) || isTRUE(second)
}

drm_warn_mi_prior_ignores_weights <- function(weights, unweighted_prior) {
  if (!isTRUE(unweighted_prior) || drm_weights_are_unit(weights)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(
    c(
      "The Gaussian {.fn mi} imputation prior ignores observation weights.",
      i = "A row weight multiplies the response term only on the unweighted Gaussian prior paths (src/drmTMB.cpp:1301, :1342, and the nbinom2 x Gaussian copy at :4556). Weight 2 is not the same as a duplicated row until a decision on #1459.",
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
  msg <- conditionMessage(e)
  if (grepl("drmTMB_mi_quadrature_nonfinite", msg, fixed = TRUE)) {
    drm_abort_mi_quadrature_nonfinite(msg)
  }
  stop(e)
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
