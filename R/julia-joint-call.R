# Joint routes use the same prepared likelihood as direct Julia. Keep R's
# formula preparation here and pass only versioned primitive data to Julia.
drm_julia_joint_requested <- function(formula, impute, missing) {
  !is.null(impute) ||
    (is.list(missing) && identical(missing$predictor, "model")) ||
    any(vapply(formula$entries, function(entry) {
      length(drm_find_mi_calls(entry$rhs)) > 0L
    }, logical(1)))
}

drm_julia_require_joint_capability <- function(
  available = isTRUE(JuliaCall::julia_eval("isdefined(DRM, :drm_bridge_joint)"))
) {
  if (!isTRUE(available)) {
    cli::cli_abort(c(
      "Your DRM.jl checkout is too old for this joint missing-predictor model.",
      i = "The loaded checkout does not provide {.code DRM.drm_bridge_joint}.",
      i = "Update the checkout referenced by {.envvar DRM_JL_PATH}, restart R, and retry."
    ))
  }
  invisible(TRUE)
}

drm_julia_call_joint <- function(payload) {
  if (!requireNamespace("JuliaCall", quietly = TRUE)) {
    cli::cli_abort(c(
      "{.code engine = \"julia\"} requires the {.pkg JuliaCall} package.",
      i = "Install it with {.code install.packages(\"JuliaCall\")}, then retry."
    ))
  }
  drm_julia_setup()
  drm_julia_require_joint_capability()
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
    i = "Supported: Gaussian response with one Gaussian/Bernoulli/ordinal/categorical predictor or two Gaussian predictors, each with a bare additive mi() term and fixed-effect impute model."
  ), parent = cnd))
  result <- drm_julia_call_joint(prepared$payload)
  drm_julia_joint_result(result, prepared, call, formula, family)
}
