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

# ---- ordinal targets and the cutpoint-interval engine boundary (#1144) -----
#
# #1144 polished the constrained `stats::nlminb()` solve in
# `ordinal_cutpoint_profile_evaluator()` (R/profile.R) so a NATIVE
# `cumulative_logit()` fit reports honest `"ordinal:cutpoint:<label>"` profile
# intervals. `cumulative_logit` is an admitted bridge family, so the same
# question has to have an answer through `engine = "julia"`. Measured on the
# committed fixture at DRM.jl pin 430ef64cc, 2026-09-05, BEFORE this code:
#
#   * `fj$ordinal` already carried the right numbers -- cutpoints
#     (-0.9909812, 0.6237335), identical to the native slot;
#   * `profile_targets(fj)` listed ONLY `fixef:mu:x`, so neither ordinal row
#     was discoverable at all; and
#   * `confint(fj, parm = "ordinal:cutpoint:low|medium", ...)` answered
#     `Unknown confidence-interval target: "ordinal:cutpoint:low|medium".`
#     for method = "wald", "profile" AND "bootstrap" -- a name-not-found
#     diagnosis for a target that plainly exists on the fit, pointing the
#     user at `fixef:mu:x` as though they had made a typo.
#
# The interval itself cannot be routed: DRM.jl's `_bridge_parse_inference_parm`
# (src/bridge.jl at the pin) accepts only `fixef:<dpar>:<coef>` and
# `sd:<dpar>` targets, so there is no cutpoint inference target on the Julia
# side to call. The honest fix is therefore the one design 168 asks for -- be
# DISCOVERABLE and REFUSE EXPLICITLY -- not to invent a number:
#
#   (a) `drm_julia_cumulative_logit_targets()` puts the ordinal rows back into
#       the Julia inventory with `profile_ready = FALSE`, so `profile_targets()`
#       reports the same public rows as the native fit and says why they are
#       not ready (the `sigma` response-scale alias row, #460 item 3, is the
#       existing precedent for a discoverable not-ready row); and
#   (b) `drm_julia_ordinal_interval_refusal()` turns the "unknown target" reply
#       into a refusal that names ordered cutpoints and points at the engine
#       that does have them.

# The ordinal inventory rows for a Julia-engine fit, mirroring the native
# `drm_profile_targets()` block (R/profile.R) row for row: the internal
# `theta_ord` coordinates first, then the public cumulative cutpoints. Both
# are NOT ready, for different reasons -- the internal coordinates are not a
# public interval target on EITHER engine (`internal_ordinal_parameter`,
# the native note), and the public cutpoints have no bridge route
# (`julia_ordinal_cutpoint_native_only`). Returns an empty inventory for any
# fit without an `ordinal` slot, so the union call site stays unguarded.
drm_julia_cumulative_logit_targets <- function(object) {
  ordinal <- object$ordinal
  if (is.null(ordinal) || length(ordinal$theta_raw) == 0L) {
    return(empty_profile_targets())
  }
  theta <- ordinal$theta_raw
  cutpoints <- ordinal$cutpoints
  if (length(cutpoints) != length(theta)) {
    cli::cli_abort(
      "Internal error: Julia-engine ordinal slot has {length(cutpoints)} cutpoint{?s} for {length(theta)} raw coordinate{?s}."
    )
  }
  internal_rows <- lapply(seq_along(theta), function(i) {
    new_profile_target_row(
      parm = paste0("ordinal:theta_ord:", names(theta)[[i]]),
      target_class = "ordinal-cutpoint-internal",
      dpar = "ordinal",
      term = names(theta)[[i]],
      tmb_parameter = "theta_ord",
      index = i,
      estimate = unname(theta[[i]]),
      link_estimate = unname(theta[[i]]),
      scale = "internal",
      transformation = "ordered_cutpoint",
      target_type = "direct",
      profile_ready = FALSE,
      profile_note = "internal_ordinal_parameter"
    )
  })
  cutpoint_rows <- lapply(seq_along(cutpoints), function(i) {
    new_profile_target_row(
      parm = paste0("ordinal:cutpoint:", names(cutpoints)[[i]]),
      target_class = "ordinal-cutpoint",
      dpar = "ordinal",
      term = names(cutpoints)[[i]],
      tmb_parameter = "theta_ord",
      index = i,
      estimate = unname(cutpoints[[i]]),
      link_estimate = unname(theta[[i]]),
      scale = "cutpoint",
      transformation = "ordered_cutpoint",
      target_type = "constrained",
      profile_ready = FALSE,
      profile_note = "julia_ordinal_cutpoint_native_only"
    )
  })
  out <- do.call(rbind, c(internal_rows, cutpoint_rows))
  row.names(out) <- NULL
  out
}

# TRUE when `parm` names any ordinal target of this fit. Matched against the
# fit's OWN inventory rather than by string prefix, so a fit with no ordinal
# slot never triggers the refusal and a mistyped cutpoint label still gets the
# ordinary unknown-target message.
drm_julia_is_ordinal_parm <- function(object, parm) {
  if (!is.character(parm) || length(parm) == 0L) {
    return(FALSE)
  }
  inventory <- drm_julia_cumulative_logit_targets(object)
  any(parm %in% inventory$parm)
}

# The refusal itself. Called from ONE guarded line at the top of
# `confint.drmTMB_julia()`, so every method -- "wald", "profile" and
# "bootstrap" -- gives the same answer instead of three different ways of
# saying "unknown target".
drm_julia_ordinal_interval_refusal <- function(object, parm, method) {
  inventory <- drm_julia_cumulative_logit_targets(object)
  requested <- intersect(parm, inventory$parm)
  public <- inventory$parm[inventory$target_class == "ordinal-cutpoint"]
  internal_only <- setdiff(
    requested,
    inventory$parm[inventory$target_class == "ordinal-cutpoint"]
  )
  detail <- if (length(internal_only) == length(requested)) {
    # Every requested row is a raw `theta_ord` coordinate. That is refused on
    # BOTH engines (R/profile.R), so say so rather than blaming the bridge.
    paste0(
      "Raw \"ordinal:theta_ord:<label>\" coordinates are internal ordinal ",
      "diagnostics on either engine, not interval targets."
    )
  } else {
    paste0(
      "engine = \"julia\" has no cutpoint interval route: DRM.jl's bridge ",
      "inference accepts only fixed-effect and random-effect-SD targets, so ",
      "there is nothing to constrain the cutpoint against."
    )
  }
  # Each dynamic part is collapsed to ONE length-1 string and handed to cli as
  # a bare {var} interpolation. Two reasons, both measured on 2026-09-05:
  #
  #  * `requested` and `public` have different lengths, so leaving both as
  #    cli interpolations of VECTORS in one message aborts with "Multiple
  #    quantities for pluralization" -- an internal cli error would have
  #    replaced the very refusal this function exists to give; and
  #  * pasting the collapsed text into the format string instead is not safe
  #    either, because cli glue-expands the format string. An ordered factor
  #    level may legally contain a brace, and with the text pasted in, a
  #    "a{1}|b" cutpoint came back as "a1|b" -- the refusal quoted a target
  #    name that does not exist and told the user to use it. Interpolating the
  #    VARIABLE inserts its content literally and is expanded only once.
  requested_text <- paste0("\"", requested, "\"", collapse = ", ")
  public_text <- paste0("\"", public, "\"", collapse = ", ")
  requested_line <- paste0(
    "Requested: ", requested_text, " with method = \"", method, "\"."
  )
  native_line <- paste0(
    "Refit with engine = \"tmb\" and use method = \"profile\" -- the native ",
    "engine solves the constrained cutpoint profile (", public_text, ")."
  )
  cli::cli_abort(c(
    "Ordered-cutpoint confidence intervals are not available for {.code engine = \"julia\"} fits.",
    x = "{requested_line}",
    i = "{detail}",
    i = "{native_line}",
    i = "The fitted cutpoints themselves are already on this fit, in `fit$ordinal$cutpoints`."
  ))
}
