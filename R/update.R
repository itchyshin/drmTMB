#' Refit a drmTMB model with a new formula or arguments
#'
#' Re-evaluates the call that created `object`, optionally with a new
#' [bf()] / [drm_formula()] formula and any other [drmTMB()] argument
#' replaced. This is the `drmTMB` method for [stats::update()].
#'
#' @param object A fitted `drmTMB` object.
#' @param formula. Optional replacement model formula, created with [bf()] or
#'   [drm_formula()]. It replaces the whole formula (all distributional
#'   parameters); relative `. ~ . + x` updates are not supported. If omitted,
#'   the original formula is reused.
#' @param ... Other [drmTMB()] arguments to replace (for example `data`,
#'   `family`, `weights`, `REML`). Use `NULL` to drop an argument.
#' @param evaluate If `TRUE` (default) refit and return the new fit; if
#'   `FALSE` return the unevaluated call.
#'
#' @details Arguments that were given as variables in the original call (for
#'   example `data = dat`) are looked up again in the calling environment, so
#'   they must still exist there or be supplied in `...`.
#'
#' @return A new fitted `drmTMB` object, or a call when `evaluate = FALSE`.
#' @seealso [drmTMB()]
#' @examples
#' \dontrun{
#' fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
#' update(fit, bf(y ~ 1, sigma ~ 1))
#' }
#' @importFrom stats update
#' @export
update.drmTMB <- function(object, formula., ..., evaluate = TRUE) {
  call <- object$call
  if (is.null(call)) {
    cli::cli_abort("{.arg object} has no stored call, so it cannot be updated.")
  }
  if (!missing(formula.)) {
    if (!inherits(formula., "drm_formula")) {
      cli::cli_abort(
        "{.arg formula.} must be created with {.fn bf} or {.fn drm_formula}."
      )
    }
    call$formula <- formula.
  }
  extras <- match.call(expand.dots = FALSE)$...
  if (length(extras) > 0L) {
    if (is.null(names(extras)) || any(!nzchar(names(extras)))) {
      cli::cli_abort("Extra arguments to {.fn update} must be named.")
    }
    for (nm in names(extras)) {
      call[[nm]] <- extras[[nm]]
    }
    call <- as.call(Filter(Negate(is.null), as.list(call)))
  }
  if (!evaluate) {
    return(call)
  }
  eval(call, parent.frame())
}
