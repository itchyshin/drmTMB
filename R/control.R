#' Control fitting and fitted-object storage
#'
#' `drm_control()` collects optimizer settings and storage choices for
#' [drmTMB()]. Use `optimizer` for settings passed to [stats::nlminb()]. Use the
#' storage flags when a fitted object should keep less R-side state, for
#' example during large-data experiments where the original data frame and TMB
#' automatic-differentiation object are expensive to retain.
#'
#' @param optimizer Named list passed to the `control` argument of
#'   [stats::nlminb()].
#' @param keep_data Logical; keep the complete-case model data in the fitted
#'   object. Set to `FALSE` to drop `fit$data` and `fit$model$data` after
#'   fitting. Prediction, fitted values, residuals, simulation, and basic
#'   summaries still use the stored model matrices and response vectors.
#' @param keep_model_frame Logical; currently must be `TRUE`. Dropping model
#'   frames is planned for a later large-data phase because it needs method-by-
#'   method fallbacks for response names, offsets, residuals, and prediction.
#' @param keep_tmb_object Logical; keep the TMB automatic-differentiation object
#'   in `fit$obj`. Set to `FALSE` to reduce fitted-object size after
#'   optimization. `check_drm()` will then report the fixed-gradient check as a
#'   note because it cannot re-evaluate the gradient without `fit$obj`.
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
#'     optimizer = list(eval.max = 100),
#'     keep_data = FALSE,
#'     keep_tmb_object = FALSE
#'   )
#' )
drm_control <- function(
  optimizer = list(),
  keep_data = TRUE,
  keep_model_frame = TRUE,
  keep_tmb_object = TRUE
) {
  if (
    !is.list(optimizer) ||
      (length(optimizer) > 0L &&
        (is.null(names(optimizer)) || any(names(optimizer) == "")))
  ) {
    cli::cli_abort("{.arg optimizer} must be a named list.")
  }
  keep_data <- drm_control_flag(keep_data, "keep_data")
  keep_model_frame <- drm_control_flag(keep_model_frame, "keep_model_frame")
  keep_tmb_object <- drm_control_flag(keep_tmb_object, "keep_tmb_object")
  if (!isTRUE(keep_model_frame)) {
    cli::cli_abort(c(
      "{.arg keep_model_frame} must be {.code TRUE} in the current release.",
      "i" = "Use {.code keep_data = FALSE} and {.code keep_tmb_object = FALSE} for the first memory-light path.",
      "i" = "Dropping model frames needs method fallbacks before it is safe for users."
    ))
  }
  structure(
    list(
      optimizer = optimizer,
      keep_data = keep_data,
      keep_model_frame = keep_model_frame,
      keep_tmb_object = keep_tmb_object
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
  drm_control(optimizer = control)
}

drm_apply_storage_control <- function(fit, control) {
  fit$control <- control
  if (!isTRUE(control$keep_data)) {
    fit$data <- NULL
    fit$model$data <- NULL
  }
  if (!isTRUE(control$keep_tmb_object)) {
    fit$obj <- NULL
  }
  fit
}

drm_control_flag <- function(x, name) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {name}} must be {.code TRUE} or {.code FALSE}.")
  }
  x
}
