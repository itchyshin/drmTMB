drm_model_frame_primary_dpar <- function(object) {
  frames <- object$model$model_frame
  if (!is.list(frames)) {
    cli::cli_abort(c(
      "This {.cls drmTMB} fit has no model frames.",
      i = "Refit with {.fn drmTMB} and check {.code miss_control()} row selection."
    ))
  }
  if (!is.null(frames$mu1) && is.data.frame(frames$mu1)) {
    return("mu1")
  }
  if (!is.null(frames$mu) && is.data.frame(frames$mu)) {
    return("mu")
  }
  for (dpar in drm_location_dpars()) {
    mf <- frames[[dpar]]
    if (is.data.frame(mf)) {
      return(dpar)
    }
  }
  cli::cli_abort(c(
    "Could not find a location formula model frame on this {.cls drmTMB} fit.",
    i = "Available frames: {.val {names(frames)}}."
  ))
}

drm_model_frame_location_frame <- function(object) {
  dpar <- drm_model_frame_primary_dpar(object)
  mf <- object$model$model_frame[[dpar]]
  if (!is.data.frame(mf)) {
    cli::cli_abort(c(
      "The {.val {dpar}} model frame is not a data frame.",
      i = "This usually means the fit object is incomplete or from an unsupported route."
    ))
  }
  mf
}

#' @describeIn model-fit-extractors Return the primary location formula data frame (`mu` or `mu1`).
#' @param formula A `drmTMB` fit (the generic passes the fit as its first argument).
#' @export
model.frame.drmTMB <- function(formula, ...) {
  drm_model_frame_location_frame(formula)
}

#' @describeIn model-fit-extractors Return `terms` for the primary location formula.
#' @param x A `drmTMB` fit.
#' @param use.offset Passed to [stats::terms()].
#' @export
terms.drmTMB <- function(x, use.offset = TRUE, ...) {
  mf <- drm_model_frame_location_frame(x)
  stats::terms(mf, use.offset = use.offset)
}

#' @describeIn model-fit-extractors Return the model matrix for the primary location formula.
#' @export
model.matrix.drmTMB <- function(object, ...) {
  mf <- drm_model_frame_location_frame(object)
  stats::model.matrix(stats::terms(mf), data = mf, ...)
}