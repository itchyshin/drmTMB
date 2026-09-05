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
    check_julia_optimizer_convergence(object),
    check_julia_fixed_gradient(object, gradient_tolerance = gradient_tolerance)
  )
  rows <- Filter(Negate(is.null), rows)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  class(out) <- c("drm_check", "data.frame")
  attr(out, "ok") <- !any(out$status %in% c("warning", "error"))
  out
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

# Route-aware (DRM.jl #632): a missing gradient is a NOTE naming the route,
# never a fabricated NA that would read like a check that ran and found
# nothing wrong -- the same "absent, not a sentinel" contract the bridge
# itself uses.
check_julia_fixed_gradient <- function(object, gradient_tolerance) {
  route <- object$diagnostics$route %||% NA_character_
  gradient <- object$diagnostics$gradient
  if (is.null(gradient)) {
    return(check_row(
      "fixed_gradient",
      "note",
      paste0("route=", route),
      paste0(
        "DRM.jl did not attach a gradient for this fit's route (", route, "); ",
        "only some DRM.jl routes carry one internally (the bivariate ",
        "structured q2/q4 route, and the sparse location-scale-scale ML ",
        "route currently do; the base Gaussian/GLMM and non-Gaussian phylo ",
        "Laplace routes do not)."
      )
    ))
  }
  if (length(gradient) == 0L || !all(is.finite(gradient))) {
    return(check_row(
      "fixed_gradient",
      "error",
      paste0("route=", route),
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
      "; max=", format_check_number(max_abs),
      "; component=", max_component
    ),
    if (ok) {
      paste0(
        "Maximum absolute DRM.jl gradient is <= ", gradient_tolerance,
        "; largest component is ", max_component, " (route: ", route, ")."
      )
    } else {
      paste0(
        "Maximum absolute DRM.jl gradient is > ", gradient_tolerance,
        "; largest component is ", max_component, " (route: ", route, ")."
      )
    }
  )
}
