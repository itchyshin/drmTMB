# #1108 / DRM.jl #569 (bridge #632): the drmTMB CONSUMER for the route-aware
# Julia convergence diagnostics. DRM.jl's `_bridge_flatten()` attaches a
# "gradient" (with an index-aligned "gradient_names") only for a fit whose
# internal route carries `fit.nllgrad` -- CONFIRMED present (verified
# 2026-09-05 against DRM.jl 430ef64c: `grep nllgrad src/*.jl`) on the
# bivariate structured q2/q4 route (src/gaussian_bivariate.jl) and the
# sparse-LSS ML route (src/gaussian_sparse_lss.jl, ML only -- its own comment
# reads "nllgrad!-only-for-ML"); CONFIRMED ABSENT on the base univariate
# Gaussian/GLMM route (src/gaussian_core.jl never assigns it) and the
# non-Gaussian phylo Laplace route (src/sparse_laplace_glmm.jl never
# mentions it) -- both live-tested here and returning NULL. Other routes omit
# the field rather than filling zeros/NaN. `new_drmTMB_julia()`
# (R/julia-bridge.R) stores that gradient, plus the route label and the
# `converged` flag, under `object$diagnostics`. This file is the only place
# that reads `object$diagnostics` back out, and it does so through the SAME
# accessor a native TMB fit already uses -- `check_drm()` -- rather than a
# Julia-only function nobody remembers to call.
#
# WHAT THIS FILE MUST NOT DO: present a DRM.jl fit as if TMB had produced it.
# A native fit's `check_drm()` runs ~40 rows; a bridge fit can only measure a
# handful, and the ones it can measure are produced by DIFFERENT machinery.
# Three consequences are carried explicitly below rather than left implied:
#
#   1. an `engine_route` row names the engine, the route and the estimator,
#      and states which native checks did NOT run, so a clean bridge table is
#      never mistaken for a clean native one;
#   2. the `fixed_gradient` row names WHICH PRODUCER made the number, in
#      DRM.jl's own `grad_source` vocabulary (DRM.jl PR #656) -- an exact
#      stored gradient, an approximate one, and no gradient at all are three
#      different claims and must not print identically;
#   3. the covariance DRM.jl marshalled back is checked, not assumed. Before
#      this file did so, a fit whose bridge covariance came back wholly
#      non-finite (`object$uncertainty$status == "unavailable"`, a state
#      R/julia-bridge.R constructs by design) still returned
#      `attr(check_drm(fit), "ok") == TRUE`.

#' @rdname check_drm
#' @export
check_drm.drmTMB_julia <- function(
  object,
  gradient_tolerance = 1e-3,
  ...
) {
  dots <- list(...)
  if (length(dots) > 0L) {
    cli::cli_abort(
      "{.arg ...} is reserved for future {.fn check_drm} diagnostic options."
    )
  }
  validate_check_scalar(gradient_tolerance, "gradient_tolerance", lower = 0)

  rows <- list(
    check_julia_engine_route(object),
    check_julia_optimizer_convergence(object),
    check_julia_fixed_gradient(object, gradient_tolerance = gradient_tolerance),
    check_julia_bridge_covariance(object),
    check_julia_bridge_standard_errors(object)
  )
  rows <- Filter(Negate(is.null), rows)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  class(out) <- c("drm_check", "data.frame")
  attr(out, "ok") <- !any(out$status %in% c("warning", "error"))
  out
}

# The engine/route/estimator header row. Always a NOTE, never a warning: it
# reports WHICH machinery ran, which is not by itself a fault, and a note does
# not flip `attr(x, "ok")` (the same register `check_fixed_gradient()` uses for
# `keep_tmb_object = FALSE`). Its job is to stop a five-row green bridge table
# from reading like a forty-row green native one.
check_julia_engine_route <- function(object) {
  route <- object$diagnostics$route %||% object$model$model_type %||% NA_character_
  estimator <- object$estimator %||% NA_character_
  check_row(
    "engine_route",
    "note",
    paste0(
      "engine=julia; route=", route,
      "; estimator=", estimator
    ),
    paste0(
      "This fit was produced by DRM.jl (engine = \"julia\") on its ", route,
      " route under ", estimator, ", not by TMB. The rows below are the only ",
      "diagnostics the bridge can measure for a DRM.jl fit. The native ",
      "engine = \"tmb\" checks that do NOT run here include the optimizer ",
      "evaluation budget, the finite-objective and log-sigma clamp checks, ",
      "sdreport status, Hessian positive-definiteness and conditioning, ",
      "inflated standard errors, dropped rows, and every random-effect, ",
      "rho12, phylogenetic, spatial, and family-parameter boundary check. A ",
      "clean table here is therefore a narrower claim than a clean ",
      "engine = \"tmb\" table on the same model."
    )
  )
}

# `object$diagnostics$converged` mirrors the same bridge `converged` field
# `object$opt$convergence` was already built from (R/julia-bridge.R); read the
# dedicated slot first and fall back to `opt$convergence` so a fit built
# without one (e.g. a sibling constructor that never populates `diagnostics`)
# still reports honestly instead of defaulting to "not converged".
check_julia_optimizer_convergence <- function(object) {
  converged <- object$diagnostics$converged
  if (is.null(converged)) {
    converged <- identical(as.integer(object$opt$convergence), 0L)
  }
  ok <- isTRUE(converged)
  check_row(
    "optimizer_convergence",
    if (ok) "ok" else "warning",
    if (ok) 0L else 1L,
    if (ok) {
      "DRM.jl reported the fit as converged."
    } else {
      "DRM.jl reported the fit as NOT converged; inspect the model before interpreting estimates."
    }
  )
}

# DRM.jl's own `grad_source` vocabulary (DRM.jl PR #656, `check_drm()` in
# src/inference.jl), reused verbatim so the two engines name the same thing the
# same way:
#   locscale    the canonical location-scale objective's exact analytic gradient
#   stored      the fit's own gradient callback (`fit.nllgrad`)
#   forward     ForwardDiff through the stored objective
#   finite      a central finite difference of the stored objective
#               (~1e-6 relative, NOT machine precision)
#   none        the fit stores no objective, so there is nothing to differentiate
#   unavailable an objective IS stored but no finite derivative came out of it
drm_julia_grad_source_vocabulary <- function() {
  c("locscale", "stored", "forward", "finite", "none", "unavailable")
}

# WHICH producer made the number this fit's `fixed_gradient` row reports.
#
# Measured at the pin (DRM.jl 430ef64cc, src/bridge.jl:1497): the payload's
# "gradient" key has exactly ONE producer, `if fit.nllgrad !== nothing`, which
# then calls that callback. So a gradient that crossed the bridge is DRM.jl's
# `:stored` and nothing else, and this function may assert that.
#
# When no gradient crossed, R genuinely cannot tell which of the remaining five
# DRM.jl sources applies -- the bridge sends no `grad_source` field (DRM.jl PR
# #656 changes src/inference.jl, test/, and NEWS.md ONLY; it does not touch
# src/bridge.jl, so `grad_source` does not cross the bridge even after it
# merges). Returning one of the five anyway would be a guess wearing a
# vocabulary term, so this returns "unknown" -- deliberately NOT one of DRM.jl's
# six values, so it can never be mistaken for one -- and the row says where the
# distinction can actually be made.
#
# If a later DRM.jl bridge DOES send `grad_source`, it is honoured here and
# validated against the vocabulary above; an unrecognised value aborts rather
# than being echoed into a diagnostic, because a diagnostic that reports an
# unknown provenance as though it understood it is worse than one that stops.
drm_julia_gradient_source <- function(object) {
  # Both spellings a future bridge could plausibly use: the payload's own
  # "gradient"/"gradient_names" convention would name it `gradient_source`,
  # while DRM.jl's report field is `grad_source`. Accepting either costs two
  # lines; accepting neither would silently report "unknown" for a fit whose
  # provenance the engine had in fact just told us.
  #
  # `[[` not `$`: `$` on a list PARTIALLY matches, so on a payload that has
  # `gradient_source` but no `gradient`, `payload$gradient` returns the source
  # string. Exact extraction here, and anywhere else that reads a raw DRM.jl
  # payload by a `gradient`-prefixed name, is what keeps a provenance label
  # from being read as a gradient.
  declared <- object$bridge[["gradient_source"]] %||% object$bridge[["grad_source"]]
  has_gradient <- !is.null(object$diagnostics[["gradient"]])
  if (!is.null(declared) && length(declared) > 0L) {
    declared <- sub("^:", "", as.character(declared)[[1L]])
    if (!declared %in% drm_julia_grad_source_vocabulary()) {
      cli::cli_abort(c(
        "DRM.jl returned an unrecognised gradient source {.val {declared}}.",
        i = "Known sources are {.val {drm_julia_grad_source_vocabulary()}} (DRM.jl {.fn check_drm}'s {.code grad_source}).",
        i = "Refusing to report a gradient whose provenance drmTMB does not understand."
      ))
    }
    # The declared source and the payload must tell the same story. DRM.jl
    # spells "no gradient was produced" as :none or :unavailable, and the
    # bridge omits the "gradient" key in exactly that case. A payload that
    # carries a number while declaring one of those two -- or that omits the
    # number while declaring a producer -- is self-contradictory, and echoing
    # either half would attach a provenance sentence to the wrong fact.
    produced <- !declared %in% c("none", "unavailable")
    if (!identical(produced, has_gradient)) {
      cli::cli_abort(c(
        "DRM.jl reported gradient source {.val {declared}} but {if (has_gradient) 'did send' else 'sent no'} gradient across the bridge.",
        x = "These contradict each other: {.val none} and {.val unavailable} mean no gradient was produced, and every other source means one was.",
        i = "Refusing to print a gradient provenance that does not match the payload."
      ))
    }
    return(declared)
  }
  if (has_gradient) "stored" else "unknown"
}

# Route-aware (DRM.jl #632): a missing gradient is a NOTE naming the route,
# never a fabricated NA that would read like a check that ran and found
# nothing wrong -- the same "absent, not a sentinel" contract the bridge
# itself uses. A present gradient names its producer, so an exact stored
# gradient is never confused with an approximation.
check_julia_fixed_gradient <- function(object, gradient_tolerance) {
  route <- object$diagnostics$route %||% NA_character_
  gradient <- object$diagnostics[["gradient"]]
  source <- drm_julia_gradient_source(object)
  if (is.null(gradient)) {
    return(check_row(
      "fixed_gradient",
      "note",
      paste0("route=", route, "; source=", source),
      paste0(
        "DRM.jl did not attach a gradient for this fit's route (", route,
        "), so stationarity was NOT scored and the overall \"ok\" attribute ",
        "does not reflect it. Only routes whose fitter stores a gradient ",
        "callback send one across the bridge (the bivariate structured q2/q4 ",
        "route and the sparse location-scale-scale ML route currently do; the ",
        "base Gaussian/GLMM and non-Gaussian phylogenetic Laplace routes do ",
        "not). ",
        # When the bridge itself declared a source, say what it said; only
        # fall back to the "we cannot tell" paragraph when it did not.
        drm_julia_gradient_source_gloss(source)
      )
    ))
  }
  if (length(gradient) == 0L || !all(is.finite(gradient))) {
    return(check_row(
      "fixed_gradient",
      "error",
      paste0("route=", route, "; source=", source),
      "At least one DRM.jl fixed-parameter gradient is not finite."
    ))
  }
  max_abs <- max(abs(gradient))
  max_index <- which.max(abs(gradient))
  max_component <- names(gradient)[[max_index]]
  ok <- max_abs <= gradient_tolerance
  check_row(
    "fixed_gradient",
    if (ok) "ok" else "warning",
    paste0(
      "route=", route,
      "; source=", source,
      "; max=", format_check_number(max_abs),
      "; component=", max_component
    ),
    paste0(
      "Maximum absolute DRM.jl gradient is ",
      if (ok) "<= " else "> ",
      gradient_tolerance,
      "; largest component is ", max_component, " (route: ", route, "). ",
      drm_julia_gradient_source_gloss(source)
    )
  )
}

# One sentence per source, so the number's precision is stated wherever it is
# printed rather than left to the reader to look up.
drm_julia_gradient_source_gloss <- function(source) {
  switch(
    source,
    stored = paste0(
      "The value came from the fitter's own stored gradient callback ",
      "(DRM.jl grad_source \"stored\"), evaluated at the reported estimates; ",
      "it is not TMB's sdreport gradient and the two engines are not claimed ",
      "to agree numerically."
    ),
    locscale = paste0(
      "The value came from DRM.jl's exact analytic location-scale outer ",
      "gradient (grad_source \"locscale\")."
    ),
    forward = paste0(
      "The value came from forward-mode automatic differentiation of DRM.jl's ",
      "stored objective (grad_source \"forward\")."
    ),
    finite = paste0(
      "The value came from a central FINITE DIFFERENCE of DRM.jl's stored ",
      "objective (grad_source \"finite\"), accurate to roughly 1e-6 relative, ",
      "NOT to machine precision; do not read it as an exact stationarity ",
      "measure."
    ),
    none = paste0(
      "DRM.jl reports grad_source \"none\": the fit stores no objective, so ",
      "there is nothing to differentiate."
    ),
    unavailable = paste0(
      "DRM.jl reports grad_source \"unavailable\": an objective is stored but ",
      "no finite derivative came out of it."
    ),
    paste0(
      "DRM.jl may still be able to produce a gradient internally by ",
      "automatic differentiation, a finite difference, or an analytic ",
      "location-scale formula, or may have none at all; the bridge does not ",
      "report which, so drmTMB records the source as \"unknown\" rather than ",
      "guessing. Call DRM.jl's own check_drm(fit) in Julia to see its ",
      "grad_source."
    )
  )
}

# What the engine actually returned for uncertainty. `new_drmTMB_julia()`
# already classifies the marshalled covariance as "ok", "partial" (some dpars
# finite, others not -- the sparse phylo fitter leaves the variance-component
# block NaN by design) or "unavailable", and stores its own message; this row
# is the first thing that READS that classification, so a fit with no usable
# covariance can no longer pass check_drm() silently. Named for the bridge, not
# for `sdreport_status`: nothing here ran TMB::sdreport().
check_julia_bridge_covariance <- function(object) {
  status <- drm_uncertainty_status(object)
  stored <- object$uncertainty$message
  message <- if (
    is.character(stored) && length(stored) == 1L && !is.na(stored) && nzchar(stored)
  ) {
    stored
  } else {
    paste0(
      "DRM.jl bridge covariance status is \"", status, "\"."
    )
  }
  dpars <- object$uncertainty$finite_dpars
  value <- paste0("status=", status)
  if (is.character(dpars) && length(dpars) > 0L && !identical(status, "ok")) {
    value <- paste0(value, "; finite_dpars=", paste(dpars, collapse = ","))
  }
  check_row(
    "bridge_covariance",
    switch(
      status,
      ok = "ok",
      skipped = "note",
      unsupported = "note",
      "warning"
    ),
    value,
    paste0(
      message,
      " This is the DRM.jl analogue of the native sdreport_status row; ",
      "TMB::sdreport() was not run for this fit."
    )
  )
}

# The covariance can be complete and still unusable: a finite but negative
# diagonal entry gives a NaN standard error, which `finite_vcov` (all entries
# finite) does not catch. This is the bridge analogue of the native
# standard_errors_finite row, and like it, it reads the covariance the fit
# actually stores. Returns NULL when there is no covariance matrix at all --
# the bridge_covariance row above already carries that story, and a second row
# repeating it would be noise.
check_julia_bridge_standard_errors <- function(object) {
  V <- object$vcov
  if (!is.matrix(V) || nrow(V) == 0L || ncol(V) == 0L) {
    return(NULL)
  }
  variances <- diag(V)
  standard_errors <- rep(NA_real_, length(variances))
  non_negative <- is.finite(variances) & variances >= 0
  standard_errors[non_negative] <- sqrt(variances[non_negative])
  bad <- !is.finite(standard_errors)
  n_bad <- sum(bad)
  finite_se <- standard_errors[!bad]
  range_part <- if (length(finite_se) == 0L) {
    ""
  } else {
    paste0(
      "; range=[", format_check_number(min(finite_se)),
      ",", format_check_number(max(finite_se)), "]"
    )
  }
  value <- paste0(
    "n=", length(variances), "; nonfinite=", n_bad, range_part
  )
  if (n_bad == 0L) {
    return(check_row(
      "bridge_standard_errors",
      "ok",
      value,
      paste0(
        "Every fixed-effect standard error implied by the covariance DRM.jl ",
        "returned is finite and real. This is the DRM.jl analogue of the ",
        "native standard_errors_finite row."
      )
    ))
  }
  labels <- names(variances)
  if (is.null(labels) || length(labels) != length(variances)) {
    labels <- colnames(V)
  }
  affected <- if (is.null(labels) || length(labels) != length(variances)) {
    paste0("index ", paste(which(bad), collapse = ","))
  } else {
    paste(labels[bad], collapse = ",")
  }
  check_row(
    "bridge_standard_errors",
    "warning",
    value,
    paste0(
      n_bad, " of ", length(variances), " fixed-effect standard error(s) ",
      "implied by the covariance DRM.jl returned are not finite real numbers ",
      "(a non-finite or negative variance on the diagonal): ", affected,
      ". Treat those coefficients' standard errors and Wald intervals as ",
      "unavailable. This is the DRM.jl analogue of the native ",
      "standard_errors_finite row."
    )
  )
}
