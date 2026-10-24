# Extract fitted coefficients for the individual log-SD submodels used by CMR
# recovery. These are parameters of the SD predictor, not profile targets for
# the realized SD curve.
cmr_sd_recovery_coefficients <- function(fit, process = c("phi", "p")) {
  process <- match.arg(process)
  if (!is.list(fit)) stop("fit must be a drm_cjs result list.", call. = FALSE)

  present <- fit$prediction_contract$sd_formula_present
  enabled <- if (is.null(present)) NA else unname(present[[process]])
  if (length(enabled) == 1L && !is.na(enabled) && !isTRUE(enabled)) return(NULL)

  parameters <- fit$random_effects$parameters
  parameter_name <- paste0("log_sd_", process)
  values <- if (is.list(parameters)) parameters[[parameter_name]] else NULL
  if (is.null(values)) {
    stop("fit is missing random_effects$parameters$", parameter_name,
         " for an enabled or unspecified SD formula.", call. = FALSE)
  }
  if (!is.numeric(values) || !length(values) || any(!is.finite(values))) {
    stop("fit random_effects$parameters$", parameter_name,
         " must be a nonempty finite numeric vector.", call. = FALSE)
  }

  # The actual fit retains its TMB data list. Its SD design matrix carries the
  # model.matrix column order, which is the order used by log_sd_phi/log_sd_p.
  design <- tryCatch(fit$obj$env$data[[paste0("cmr_sd_X_", process)]],
                     error = function(e) NULL)
  retained_design <- fit$random_effects$sd_design[[process]]
  columns <- if (is.list(retained_design)) retained_design$columns else NULL
  if (is.null(columns)) columns <- if (is.matrix(design)) colnames(design) else NULL
  if (!is.null(columns) && length(columns) == length(values) &&
      all(!is.na(columns)) && all(nzchar(columns))) {
    names(values) <- columns
  } else {
    # Preserve the verified model-matrix ordering without inventing predictor
    # labels when the fit object does not retain them.
    names(values) <- paste0(parameter_name, "[", seq_along(values), "]")
  }

  # The v6 M5 formulas are exactly ~1+x_phi and ~1+z_p. Only that ordered
  # intercept-plus-single-numeric-predictor design has the manifest's gamma0/
  # gamma1 interpretation. Offsets, interactions, and other designs keep their
  # model.matrix names (or the explicit ordered fallback above).
  predictor <- if (process == "phi") "x_phi" else "z_p"
  if (length(values) == 2L && identical(unname(columns), c("(Intercept)", predictor))) {
    names(values) <- paste0("gamma", 0:1, "_", process)
  }
  values
}
