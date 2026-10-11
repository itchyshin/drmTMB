# Observation-weight policy for mi() imputation.
#
# Until Shinichi decides #1459, a row weight multiplies the response term
# only. The continuous (and second-predictor, and nbinom2 x Gaussian)
# imputation prior is unweighted. These helpers warn, refuse, or pin that
# behaviour; they do not change the prior.

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
  evaluate_likelihood_weights_arg(call$weights, data, env)
}

drm_warn_mi_prior_ignores_weights <- function(weights, has_mi) {
  if (!isTRUE(has_mi) || drm_weights_are_unit(weights)) {
    return(invisible(FALSE))
  }
  cli::cli_warn(
    c(
      "The {.fn mi} imputation prior ignores observation weights.",
      i = "A row weight multiplies the response term only. Weight 2 is not the same as a duplicated row until a decision on #1459.",
      i = "Use {.code weights = NULL} or {.code weights = 1} when you want the prior and the response to use the same multiplier."
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

drm_abort_mi_weights_predict <- function(object, dots = list()) {
  has_mi <- is.list(object$missing_data$predictors) &&
    length(object$missing_data$predictors) > 0L
  if (!has_mi) {
    return(invisible(FALSE))
  }
  if ("weights" %in% names(dots)) {
    cli::cli_abort(
      c(
        "{.fn predict} and {.fn simulate} do not take {.arg weights} for a {.fn mi} model.",
        x = "DRModels.jl also refuses {.fn mi} plus non-unit weights.",
        i = "Refit with {.code engine = \"tmb\"} and omit {.arg weights} from {.fn predict} / {.fn simulate}. The methods use the fitted coefficients."
      ),
      class = "drmTMB_mi_weights_predict_unsupported"
    )
  }
  invisible(FALSE)
}
