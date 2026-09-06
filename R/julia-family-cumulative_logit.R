# Family-specific bridge code for `cumulative_logit()` through engine = "julia"
# (A4, 2026-09-05; design 258 section 8.9). The generic bridge in
# R/julia-bridge.R assumes a family whose every coefficient block is a
# fixed-effect dpar with base-R `model.matrix()` column names. Cumulative logit
# breaks that assumption in three places, each measured live against DRM.jl
# 430ef64cc on the `tests/testthat/test-cumulative-logit.R` fixture before any
# of this was written:
#
#   1. DATA. drmTMB's response is an ordered factor. Sent as is, JuliaCall
#      marshals it as a CategoricalArray and DRM.jl's `_coerce_response_column`
#      aborts (`no method matching Float64(::CategoricalValue{String})`).
#      DRM.jl's `drm(::CumulativeLogit)` wants integer categories 1, ..., K
#      (src/cumulative.jl: "requires ordered integer categories coded
#      1, 2, ..., K") -- the SAME coding the native TMB engine builds in
#      `prepare_ordinal_response()`, so that function is reused unchanged.
#   2. LABELS. DRM.jl drops the location intercept (the cutpoints absorb it)
#      and reports a SECOND block, `cutpoints`, with raw names
#      `theta1..theta{K-1}`. Its coef_labels echo demands exactly one label
#      per column of EVERY block, so `mu` must be sent WITHOUT "(Intercept)"
#      and `cutpoints` must be labelled. drmTMB's own spelling for a cutpoint
#      is `ordinal_cutpoint_names()`'s "<level_k>|<level_k+1>" (R/drmTMB.R).
#   3. FIT OBJECT. Cutpoints are NOT a dpar on the R side: the native engine
#      keeps them in `fit$ordinal` (`ordinal_fit_info()`), never in `coef()`
#      or `vcov()`. DRM.jl returns the raw increment coordinates
#      (theta_1 = delta_1, theta_k = theta_{k-1} + exp(delta_k),
#      src/cumulative.jl `_cumulative_cuts`) -- the SAME parameterisation as
#      TMB's `theta_ord`, so `ordinal_cutpoints_from_raw()` is the one
#      transform and `theta_raw` compares directly with the native slot.
#
# Each helper below is called from ONE guarded line in R/julia-bridge.R
# (`if (identical(family_type, "cumulative_logit")) ...`); nothing here runs
# for any other family. The registry row (R/julia-family-registry.R) marks the
# family `dispersionless`, so the generic label defaulter adds no `sigma`
# block and a user-written `sigma ~` formula is refused before Julia starts.

# The response variable of the single `mu` entry, as a column name.
drm_julia_cumulative_logit_response <- function(formula) {
  mu <- Filter(function(entry) identical(entry$dpar, "mu"), formula$entries)
  if (length(mu) != 1L || is.na(mu[[1L]]$response)) {
    cli::cli_abort(
      "A {.fn cumulative_logit} model requires exactly one location formula with a response."
    )
  }
  as.character(mu[[1L]]$response)
}

# The validated ordinal coding of the response in `data` -- the SAME
# `prepare_ordinal_response()` the native TMB engine uses, so an unordered
# factor, a non-integer score, fewer than three categories, or an empty
# category is refused with the native engine's own message.
drm_julia_cumulative_logit_ordinal <- function(data, formula) {
  response <- drm_julia_cumulative_logit_response(formula)
  if (!response %in% names(data)) {
    cli::cli_abort(
      "{.code engine = \"julia\"} could not find the ordinal response {.val {response}} in {.arg data}."
    )
  }
  prepare_ordinal_response(data[[response]], response = response)
}

# (1) DATA: replace the ordered-factor response by its integer codes 1..K.
# Called AFTER the coefficient labels were built from the ordered factor, so
# the levels are still available to (2).
drm_julia_cumulative_logit_bridge_data <- function(data, formula) {
  ordinal <- drm_julia_cumulative_logit_ordinal(data, formula)
  data[[ordinal$response]] <- as.integer(ordinal$y)
  data
}

# (2) LABELS: drop the location intercept from `mu` and label the `cutpoints`
# block with drmTMB's own "<level_k>|<level_k+1>" spelling.
drm_julia_cumulative_logit_coef_labels <- function(labels, formula, data) {
  ordinal <- drm_julia_cumulative_logit_ordinal(data, formula)
  if (!is.null(labels$mu)) {
    labels$mu <- labels$mu[labels$mu != "(Intercept)"]
  }
  labels$cutpoints <- ordinal_cutpoint_names(ordinal$levels)
  labels
}

# (3) FIT OBJECT: move DRM.jl's `cutpoints` block out of the fixed-effect
# surface (`coefficients`, `coef_vector`, `vcov`, `model$dpars`,
# `uncertainty$finite_dpars`) into a `fit$ordinal` slot shaped exactly like
# the native engine's `ordinal_fit_info()`. Fails closed if the block is
# absent or its echoed labels are not drmTMB's own, in order.
drm_julia_cumulative_logit_ordinal_slot <- function(out) {
  ordinal <- drm_julia_cumulative_logit_ordinal(out$data, out$formula)
  expected <- ordinal_cutpoint_names(ordinal$levels)
  raw <- out$coefficients$cutpoints
  got <- names(raw)
  if (is.null(raw) || !identical(got, expected)) {
    cli::cli_abort(c(
      "DRM.jl returned cutpoint labels that do not match drmTMB's ordered levels.",
      x = paste0(
        "drmTMB expects (", paste(expected, collapse = ", "),
        "); DRM.jl returned (", paste(got, collapse = ", "), ")."
      ),
      i = "Report this: the bridge's cutpoint label echo (design 258 section 8.9) is out of step."
    ), call. = FALSE)
  }
  cutpoints <- ordinal_cutpoints_from_raw(unname(raw))
  names(cutpoints) <- expected
  out$ordinal <- list(
    response = ordinal$response,
    levels = ordinal$levels,
    n_categories = ordinal$n_categories,
    cutpoints = cutpoints,
    theta_raw = stats::setNames(unname(raw), expected)
  )
  out$coefficients$cutpoints <- NULL
  out$model$dpars <- names(out$coefficients)
  is_cutpoint <- startsWith(names(out$coef_vector), "cutpoints_")
  out$coef_vector <- out$coef_vector[!is_cutpoint]
  keep <- !startsWith(rownames(out$vcov), "cutpoints_")
  out$vcov <- out$vcov[keep, keep, drop = FALSE]
  out$uncertainty$finite_dpars <- setdiff(out$uncertainty$finite_dpars, "cutpoints")
  out
}
