# Joint routes use the same prepared likelihood as direct Julia. Keep R's
# formula preparation here and pass only versioned primitive data to Julia.
drm_julia_joint_requested <- function(formula, impute, missing) {
  !is.null(impute) ||
    (is.list(missing) && identical(missing$predictor, "model")) ||
    any(vapply(formula$entries, function(entry) {
      length(drm_find_mi_calls(entry$rhs)) > 0L
    }, logical(1)))
}

drm_julia_call_joint <- function(payload) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  drm_julia_setup()
  JuliaCall::julia_call("DRM.drm_bridge_joint", payload)
}

drmTMB_julia_joint_bridge <- function(
  formula, family, data, env, weights_missing, control, impute, missing,
  REML = FALSE, call
) {
  prepared <- tryCatch(drm_julia_joint_prepare(
    formula = formula, family = family, data = data, env = env,
    weights_missing = weights_missing, control = control, impute = impute,
    missing = missing, REML = REML
  ), error = function(cnd) cli::cli_abort(c(
    "Could not prepare the Julia joint missing-predictor model.",
    i = "Supported: Gaussian response, one additive mi() predictor, and a fixed Gaussian or Bernoulli impute model."
  ), parent = cnd))
  result <- drm_julia_call_joint(prepared$payload)
  drm_julia_joint_result(result, prepared, call, formula, family)
}
