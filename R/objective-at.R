# Objective-At-A-Point (docs/design/35-optimizer-start-map-multistart.md,
# "Objective At A Point"). `start=` and `objective_at()` share one public
# label vocabulary ("fixef:<dpar>:<column>", "sd:<dpar>:<term>",
# "cor:<dpar>:<term>"): the translation from label to internal TMB slot lives
# in `drm_parse_public_start_label()` / `drm_resolve_public_start_target()`
# (R/drmTMB.R), and is reused here rather than reimplemented. The evaluation
# itself reuses the pattern already used for profile-CI endpoints
# (`profile_endpoint_evaluator()`, `profile_lincomb()` in R/profile.R): pin
# the object to its optimum, substitute the requested slots into a copy of
# `fit$opt$par`, call `fit$obj$fn()`, then re-pin so the fitted object is left
# exactly as it was found.

#' Evaluate the fitted objective at a supplied point
#'
#' Evaluates a fitted model's TMB objective (negative log-likelihood) at a
#' point supplied on the public label vocabulary also used by
#' `drm_control(start = ...)`, without refitting. This is a diagnostic: it
#' selects nothing, reports no uncertainty, and does not change any fitted
#' quantity or mutate the fitted object.
#'
#' @param object A fitted `drmTMB` object.
#' @param ... Passed to methods.
#' @return A single number: the TMB objective (negative log-likelihood) at
#'   `at`.
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
        "x" = "Labels must use the {.code fixef:<dpar>:<column>}, {.code sd:<dpar>:<term>}, or {.code cor:<dpar>:<term>} format."
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
  value <- unname(as.numeric(object$obj$fn(full)))
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
