#' Build a drmTMB formula object
#'
#' `bf()` captures the formulae that define a `drmTMB` model. The family
#' decides which distributional parameters are valid; `bf()` only records the
#' user's intended formulas.
#'
#' @param ... Formulae or named formulae. The unnamed response formula is
#'   interpreted as the location formula for a univariate model. For bivariate
#'   models, prefer explicit `mu1 = y1 ~ ...` and `mu2 = y2 ~ ...` formulas.
#'
#' @return A `drm_formula` object.
#' @export
#'
#' @examples
#' bf(y ~ x, sigma ~ z)
#' bf(
#'   mu1 = y1 ~ x1 + x2,
#'   mu2 = y2 ~ x1,
#'   sigma1 = ~ x1,
#'   sigma2 = ~ x2,
#'   rho12 = ~ x1 + x2
#' )
bf <- function(...) {
  calls <- as.list(substitute(list(...)))[-1L]
  if (length(calls) == 0L) {
    cli::cli_abort("{.fn bf} requires at least one formula.")
  }
  names <- names(calls)
  if (is.null(names)) {
    names <- rep("", length(calls))
  }
  names[is.na(names)] <- ""

  out <- list(
    calls = calls,
    names = names,
    entries = parse_drm_formula_entries(calls, names)
  )
  class(out) <- "drm_formula"
  out
}

#' @export
print.drm_formula <- function(x, ...) {
  cli::cli_text("<drm_formula>")
  for (i in seq_along(x$calls)) {
    nm <- x$names[[i]]
    label <- if (nzchar(nm)) paste0(nm, " = ") else ""
    cli::cli_text("  {label}{deparse1(x$calls[[i]])}")
  }
  invisible(x)
}
