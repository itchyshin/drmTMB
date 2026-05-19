#' Control fitting and fitted-object storage
#'
#' `drm_control()` collects optimizer settings and storage choices for
#' [drmTMB()]. Use `optimizer` for settings passed to [stats::nlminb()], or
#' `optimizer_preset` for named `nlminb()` budgets that keep ordinary defaults
#' fast while making complex refits easier to write. Use the storage flags when
#' a fitted object should keep less R-side state, for
#' example during large-data experiments where the original data frame and TMB
#' automatic-differentiation object are expensive to retain.
#'
#' For optimizer-only settings, `control = list(eval.max = 1000)` remains
#' valid. When using `drm_control()`, put optimizer arguments inside
#' `optimizer = list(...)`; do not pass `eval.max` directly to `drm_control()`.
#' Presets `"careful"` and `"robust"` expand to explicit `iter.max` and
#' `eval.max` controls for `nlminb()`. Values in `optimizer` override values from
#' the selected preset.
#'
#' @param optimizer Named list passed to the `control` argument of
#'   [stats::nlminb()].
#' @param se Logical; compute standard errors and fixed-effect covariance with
#'   [TMB::sdreport()] after optimization. Set to `FALSE` to keep fitted
#'   coefficients, fitted values, residuals, predictions, simulations, and
#'   profile-likelihood paths while skipping Wald standard errors,
#'   [stats::vcov()], and Wald confidence intervals.
#' @param keep_data Logical; keep the complete-case model data in the fitted
#'   object. Set to `FALSE` to drop `fit$data` and `fit$model$data` after
#'   fitting. Prediction, fitted values, residuals, simulation, and basic
#'   summaries still use the stored model matrices and response vectors.
#' @param keep_model_frame Logical; keep model frames in the fitted object. Set
#'   to `FALSE` to drop `fit$model$model_frame` and random-effect scale model
#'   frames after fitting. Prediction, fitted values, residuals, simulation,
#'   `sigma()`, `rho12()`, `corpairs()`, and `check_drm()` use stored model
#'   matrices, terms, response vectors, offsets, and response-name metadata.
#' @param keep_tmb_object Logical; keep the TMB automatic-differentiation object
#'   in `fit$obj`. Set to `FALSE` to reduce fitted-object size after
#'   optimization. `check_drm()` will then report the fixed-gradient check as a
#'   note because it cannot re-evaluate the gradient without `fit$obj`.
#' @param sparse_fixed Logical; experimental opt-in for sparse fixed-effect
#'   design matrices. The first fitted path is limited to univariate Gaussian
#'   `mu` fixed effects with no random effects and intercept-only `sigma`.
#' @param aggregate_gaussian Logical; experimental opt-in for sufficient-
#'   statistic row aggregation in univariate Gaussian fixed-effect models. The
#'   first fitted path rejects random effects, structured effects, known
#'   sampling covariance, bivariate models, non-Gaussian families, non-unit
#'   likelihood weights, and combined sparse fixed-effect matrices.
#' @param optimizer_preset Optimizer-budget preset. `"default"` adds no
#'   optimizer controls, `"careful"` sets `iter.max = 1000` and
#'   `eval.max = 1000`, and `"robust"` sets `iter.max = 5000` and
#'   `eval.max = 5000`.
#'
#' @return A `drm_control` object.
#' @export
#'
#' @examples
#' dat <- data.frame(y = rnorm(20), x = rnorm(20))
#' fit <- drmTMB(
#'   bf(y ~ x, sigma ~ 1),
#'   data = dat,
#'   control = drm_control(
#'     optimizer_preset = "careful",
#'     se = FALSE,
#'     keep_data = FALSE,
#'     keep_model_frame = FALSE,
#'     keep_tmb_object = FALSE
#'   )
#' )
drm_control <- function(
  optimizer = list(),
  se = TRUE,
  keep_data = TRUE,
  keep_model_frame = TRUE,
  keep_tmb_object = TRUE,
  sparse_fixed = FALSE,
  aggregate_gaussian = FALSE,
  optimizer_preset = c("default", "careful", "robust")
) {
  optimizer_preset <- match.arg(optimizer_preset)
  if (
    !is.list(optimizer) ||
      (length(optimizer) > 0L &&
        (is.null(names(optimizer)) || any(names(optimizer) == "")))
  ) {
    cli::cli_abort("{.arg optimizer} must be a named list.")
  }
  optimizer_reserved <- intersect(
    names(optimizer),
    drm_control_reserved_names()
  )
  if (length(optimizer_reserved) > 0L) {
    cli::cli_abort(c(
      "{.arg optimizer} contains reserved {.pkg drmTMB} control name{?s}: {.arg {optimizer_reserved}}.",
      "i" = "Use {.arg optimizer} only for {.fn stats::nlminb} control settings.",
      "i" = "Future start, map, fixed-parameter, fallback-optimizer, and multi-start controls will use explicit {.pkg drmTMB} arguments after their contract is implemented."
    ))
  }
  optimizer <- drm_control_optimizer(optimizer, optimizer_preset)
  se <- drm_control_flag(se, "se")
  keep_data <- drm_control_flag(keep_data, "keep_data")
  keep_model_frame <- drm_control_flag(keep_model_frame, "keep_model_frame")
  keep_tmb_object <- drm_control_flag(keep_tmb_object, "keep_tmb_object")
  sparse_fixed <- drm_control_flag(sparse_fixed, "sparse_fixed")
  aggregate_gaussian <- drm_control_flag(
    aggregate_gaussian,
    "aggregate_gaussian"
  )
  structure(
    list(
      optimizer = optimizer,
      se = se,
      keep_data = keep_data,
      keep_model_frame = keep_model_frame,
      keep_tmb_object = keep_tmb_object,
      sparse_fixed = sparse_fixed,
      aggregate_gaussian = aggregate_gaussian,
      optimizer_preset = optimizer_preset
    ),
    class = "drm_control"
  )
}

drm_parse_control <- function(control) {
  if (inherits(control, "drm_control")) {
    return(control)
  }
  if (is.null(control)) {
    control <- list()
  }
  if (!is.list(control)) {
    cli::cli_abort(c(
      "{.arg control} must be a list or a {.cls drm_control} object.",
      "i" = "Use {.code control = list(eval.max = 1000)} for optimizer-only settings.",
      "i" = "Use {.code control = drm_control(...)} for storage controls."
    ))
  }
  reserved <- intersect(names(control), drm_control_reserved_names())
  if (length(reserved) > 0L) {
    cli::cli_abort(c(
      "{.arg control} contains reserved {.pkg drmTMB} control name{?s}: {.arg {reserved}}.",
      "i" = "{.code control = list(...)} is only for {.fn stats::nlminb} optimizer settings.",
      "i" = "Use {.code control = drm_control(...)} for implemented {.pkg drmTMB} controls such as {.arg se}, {.arg keep_data}, and {.arg keep_tmb_object}.",
      "i" = "Use {.code control = list(eval.max = 1000)} only for optimizer settings."
    ))
  }
  drm_control(optimizer = control)
}

drm_control_reserved_names <- function() {
  unique(c(
    setdiff(names(formals(drm_control)), "optimizer"),
    "start",
    "starts",
    "map",
    "fixed",
    "fallback_optimizer",
    "multi_start",
    "multistart"
  ))
}

drm_control_optimizer <- function(optimizer, optimizer_preset) {
  preset <- drm_control_optimizer_preset(optimizer_preset)
  c(preset[setdiff(names(preset), names(optimizer))], optimizer)
}

drm_control_optimizer_preset <- function(optimizer_preset) {
  switch(
    optimizer_preset,
    default = list(),
    careful = list(iter.max = 1000L, eval.max = 1000L),
    robust = list(iter.max = 5000L, eval.max = 5000L)
  )
}

drm_apply_storage_control <- function(fit, control) {
  fit$control <- control
  if (!isTRUE(control$keep_data)) {
    fit$data <- NULL
    fit$model$data <- NULL
  }
  if (!isTRUE(control$keep_model_frame)) {
    fit <- drm_drop_model_frames(fit)
  }
  if (!isTRUE(control$keep_tmb_object)) {
    fit$obj <- NULL
  }
  fit
}

drm_drop_model_frames <- function(fit) {
  fit$model$model_frame <- NULL
  if (!is.null(fit$model$random_scale)) {
    fit$model$random_scale <- lapply(
      fit$model$random_scale,
      drm_drop_model_frame_components
    )
  }
  if (!is.null(fit$model$random$mu$cor_model)) {
    fit$model$random$mu$cor_model <- drm_drop_model_frame_components(
      fit$model$random$mu$cor_model
    )
  }
  fit
}

drm_drop_model_frame_components <- function(x) {
  if (!is.list(x)) {
    return(x)
  }
  if (!is.null(x$model_frame)) {
    x$model_frame <- NULL
  }
  if (!is.null(x$model_frame_list)) {
    x$model_frame_list <- NULL
  }
  x
}

drm_control_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {name}} must be {.code TRUE} or {.code FALSE}.")
  }
  x
}
