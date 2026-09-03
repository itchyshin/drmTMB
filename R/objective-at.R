# Objective-At-A-Point (docs/design/35-optimizer-start-map-multistart.md,
# "Objective At A Point"). `start=` and `objective_at()` share one public
# label vocabulary ("fixef:<dpar>:<column>", "sd:<dpar>:<term>",
# "cor:<dpar>:<term>", "phylo_sd:<axis>", "phylo_cor:<axis1>:<axis2>"): the
# translation from label to internal TMB slot lives
# in `drm_parse_public_start_label()` / `drm_resolve_public_start_target()`
# (R/drmTMB.R), and is reused here rather than reimplemented. The evaluation
# itself reuses the pattern already used for profile-CI endpoints
# (`profile_endpoint_evaluator()`, `profile_lincomb()` in R/profile.R): pin
# the object to its optimum, substitute the requested slots into a copy of
# `fit$opt$par`, call `fit$obj$fn()`, then re-pin so the fitted object is left
# exactly as it was found.
#
# Convention (adversarial-pass fix, 2026-09-01): `fit$logLik` is stored on the
# *unpenalized* convention (`-opt$objective + phylo_penalty`, R/drmTMB.R),
# while `obj$fn()` returns the *penalized* objective for MAP/penalized fits.
# `objective_at()` reports on the SAME (unpenalized) convention as `logLik()`
# -- chosen over erroring on penalized fits -- because the whole point of this
# verb is a cross-engine, cross-point comparison, and a return value that
# silently changes meaning by fit type defeats that. The cost: the returned
# number is not literally what the optimizer minimised at that point; use
# `fit$obj$fn()` directly if the raw penalized objective is what is wanted.
# The penalty is re-evaluated AT the queried point (`obj$report()$phylo_penalty`
# after `fn()`), not frozen at the fit's own optimum, so the convention holds
# away from the optimum too, not only at it.

#' Evaluate the fitted objective at a supplied point
#'
#' Evaluates a fitted model's negative log-likelihood at a point supplied on
#' the public label vocabulary also used by `drm_control(start = ...)`,
#' without refitting. This is a diagnostic: it selects nothing, reports no
#' uncertainty, and does not change any fitted quantity or mutate the fitted
#' object. For penalized (MAP) fits the returned value is on the same
#' *unpenalized* convention as [logLik()] (any phylogenetic penalty is
#' subtracted back out, re-evaluated at the queried point), so
#' `objective_at(fit, <fit's own optimum>) == -logLik(fit)` holds for every
#' fit type; it is therefore not literally what the optimizer minimised at
#' that point for a penalized fit -- use `fit$obj$fn()` directly for that.
#' Errors for experimental MSPL fits, matching [logLik()].
#'
#' @param object A fitted `drmTMB` object.
#' @param ... Passed to methods.
#' @return A single number: the unpenalized negative log-likelihood
#'   (same convention as `-logLik(fit)`) at `at`.
#' @export
objective_at <- function(object, ...) {
  UseMethod("objective_at")
}

#' @rdname objective_at
#' @param at A named list of values keyed by public start labels (see
#'   `drm_control(start = ...)`), e.g.
#'   `list("fixef:mu:(Intercept)" = 0.2, "sd:mu:(1 | id)" = 0.3)`. `sd:`
#'   values are given on the natural (positive) scale and `cor:` values on
#'   the natural correlation scale, exactly as for `start=`.
#' @export
objective_at.drmTMB <- function(object, at, ...) {
  drm_abort_mspl_inference(object, "objective_at")
  if (is.null(object$obj) || is.null(object$opt)) {
    cli::cli_abort(c(
      "{.fn objective_at} requires the TMB object retained in {.code fit$obj}.",
      "i" = "Refit with {.code drm_control(keep_tmb_object = TRUE)} before using {.fn objective_at}."
    ))
  }
  at <- drm_objective_at_validate_at(at)

  spec <- object$model
  full <- object$opt$par
  par_names <- names(full)
  labels <- names(at)
  for (i in seq_along(at)) {
    label <- labels[[i]]
    parsed <- drm_parse_public_start_label(label)
    if (is.null(parsed) || identical(parsed$family, "u")) {
      cli::cli_abort(c(
        "Unknown {.arg at} label {.val {label}}.",
        "x" = "Labels must use the {.code fixef:<dpar>:<column>}, {.code sd:<dpar>:<term>}, {.code cor:<dpar>:<term>}, {.code phylo_sd:<axis>}, or {.code phylo_cor:<axis1>:<axis2>} format."
      ))
    }
    resolved <- drm_resolve_public_start_target(spec, parsed, at[[i]], label)
    positions <- which(par_names == resolved$component)
    if (length(positions) < resolved$index) {
      cli::cli_abort(c(
        "{.arg at} label {.val {label}} cannot be mapped to an optimized parameter.",
        "i" = "Expected index {resolved$index} in TMB parameter {.val {resolved$component}}."
      ))
    }
    full[[positions[[resolved$index]]]] <- resolved$value
  }

  drm_pin_tmb_object_to_optimum(object$obj, object$opt, object$tmb_state)
  raw <- unname(as.numeric(object$obj$fn(full)))
  # Re-evaluate the penalty AT `full`, not the frozen optimum value cached on
  # `object$phylo_penalty` -- the queried point is generally not the optimum,
  # and `fn()` above already re-solved the inner Laplace problem for `full`,
  # so a bare `report()` now reads back the matching state.
  penalty_report <- object$obj$report()$phylo_penalty
  penalty <- if (is.null(penalty_report)) 0 else as.numeric(penalty_report)
  value <- raw - penalty
  drm_pin_tmb_object_to_optimum(object$obj, object$opt, object$tmb_state)
  value
}

drm_objective_at_validate_at <- function(at) {
  if (!is.list(at) || is.data.frame(at) || length(at) == 0L) {
    cli::cli_abort("{.arg at} must be a non-empty named list of public start labels.")
  }
  labels <- names(at)
  if (
    is.null(labels) ||
      length(labels) != length(at) ||
      anyNA(labels) ||
      any(labels == "")
  ) {
    cli::cli_abort(
      "{.arg at} must name every element with a public start label, e.g. {.val fixef:mu:(Intercept)}."
    )
  }
  for (i in seq_along(at)) {
    value <- at[[i]]
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
      cli::cli_abort(c(
        "{.arg at} values must be single finite numbers.",
        "x" = "Label {.val {labels[[i]]}} has a non-scalar or non-finite value."
      ))
    }
  }
  at
}
