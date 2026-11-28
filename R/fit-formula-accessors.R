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

drm_formula_primary_location_entry <- function(x) {
  if (!inherits(x, "drm_formula")) {
    cli::cli_abort("{.arg x} must inherit from class {.cls drm_formula}.")
  }
  entries <- x$entries
  dpars <- vapply(entries, `[[`, character(1L), "dpar")
  if ("mu" %in% dpars) {
    return(entries[[which(dpars == "mu")[1L]]])
  }
  if ("mu1" %in% dpars) {
    return(entries[[which(dpars == "mu1")[1L]]])
  }
  cli::cli_abort(c(
    "No location formula found in this {.cls drm_formula} object.",
    "i" = "Use {.code fit$model$terms$<dpar>} on a fitted model instead."
  ))
}

#' @rdname model-fit-extractors
#' @param x A fitted `drmTMB` model.
#' @param ... Not used.
#' @export
formula.drmTMB <- function(x, ...) {
  dpar <- drm_fit_primary_location_dpar(x)
  stats::formula(x$model$terms[[dpar]])
}

#' @export
as.formula.drm_formula <- function(x, ...) {
  drm_entry_formula(drm_formula_primary_location_entry(x), response = TRUE)
}
