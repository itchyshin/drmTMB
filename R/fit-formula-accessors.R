drm_fit_primary_location_dpar <- function(object) {
  if (!is.list(object$model) || !is.list(object$model$terms)) {
    cli::cli_abort("Internal error: fitted model has no terms list.")
  }
  terms <- object$model$terms
  if (!is.null(terms$mu)) {
    return("mu")
  }
  if (!is.null(terms$mu1)) {
    return("mu1")
  }
  cli::cli_abort(c(
    "Could not determine a location formula for this fit.",
    "i" = "Use {.code fit$model$terms$<dpar>} for a specific distributional parameter."
  ))
}

#' @rdname model-fit-extractors
#' @param x A fitted `drmTMB` model.
#' @param dpar Optional location parameter name (`"mu"` or `"mu1"`). Defaults to
#'   the primary location formula for this fit.
#' @param ... Not used.
#' @export
terms.drmTMB <- function(x, dpar = NULL, ...) {
  if (is.null(dpar)) {
    dpar <- drm_fit_primary_location_dpar(x)
  }
  terms_obj <- x$model$terms[[dpar]]
  if (is.null(terms_obj)) {
    cli::cli_abort(c(
      "This fit has no {.code {dpar}} formula terms.",
      "i" = "Available distributional parameters: {.val {names(x$model$terms)}}."
    ))
  }
  terms_obj
}