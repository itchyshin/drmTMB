#' Access Julia-bridge fit quantities
#'
#' These methods extract quantities retained on an existing Julia-backed fit
#' through familiar R generics. They do not broaden the fitting, prediction,
#' or inference routes described in the Julia engine vignette.
#'
#' @name julia-fit-methods
#' @aliases coef.drmTMB_julia fixef.drmTMB_julia vcov.drmTMB_julia
#' @aliases logLik.drmTMB_julia nobs.drmTMB_julia df.residual.drmTMB_julia
#' @aliases deviance.drmTMB_julia fitted.drmTMB_julia
#' @aliases residuals.drmTMB_julia sigma.drmTMB_julia rho12.drmTMB_julia
#' @aliases coef.drmTMB_julia_xfam fixef.drmTMB_julia_xfam
#' @aliases logLik.drmTMB_julia_xfam nobs.drmTMB_julia_xfam
#' @aliases df.residual.drmTMB_julia_xfam fitted.drmTMB_julia_xfam
#' @aliases residuals.drmTMB_julia_xfam
#' @usage
#' \method{coef}{drmTMB_julia}(object, dpar = NULL, ...)
#' \method{fixef}{drmTMB_julia}(object, ...)
#' \method{vcov}{drmTMB_julia}(object, ...)
#' \method{logLik}{drmTMB_julia}(object, ...)
#' \method{nobs}{drmTMB_julia}(object, ...)
#' \method{df.residual}{drmTMB_julia}(object, ...)
#' \method{deviance}{drmTMB_julia}(object, ...)
#' \method{fitted}{drmTMB_julia}(object, ...)
#' \method{residuals}{drmTMB_julia}(object, type = c("response"), ...)
#' \method{sigma}{drmTMB_julia}(object, ...)
#' \method{rho12}{drmTMB_julia}(object, ...)
#' \method{coef}{drmTMB_julia_xfam}(object, dpar = NULL, ...)
#' \method{fixef}{drmTMB_julia_xfam}(object, ...)
#' \method{logLik}{drmTMB_julia_xfam}(object, ...)
#' \method{nobs}{drmTMB_julia_xfam}(object, ...)
#' \method{df.residual}{drmTMB_julia_xfam}(object, ...)
#' \method{fitted}{drmTMB_julia_xfam}(object, ...)
#' \method{residuals}{drmTMB_julia_xfam}(object, type = c("response"), ...)
#' @param object An existing `drmTMB_julia` fit; the `_xfam` methods require
#'   an existing legacy `drmTMB_julia_xfam` fit.
#' @param dpar Optional coefficient block name. `NULL` returns all retained
#'   coefficient blocks; a name selects one block.
#' @param type Residual type. Only response residuals are available.
#' @param ... `fixef()` forwards these arguments to `coef()`, so `dpar` can
#'   select a coefficient block. The other accessors accept `...` for S3
#'   compatibility and currently ignore it.
#' @return `coef()` and `fixef()` return named coefficient vectors or named
#'   lists of coefficient blocks. `vcov()` returns the retained covariance
#'   value. `logLik()` returns a `logLik` object with `df` and `nobs`
#'   attributes. `nobs()`, `df.residual()`, and `deviance()` return scalars;
#'   `df.residual` is `nobs - df` and `deviance` is `-2 * logLik`. `fitted()`
#'   and `residuals()` return stored fitted values and response residuals.
#'   `sigma()` returns the stored fitted scale value(s), in the structure
#'   retained for that Julia-backed family. `rho12()` returns the stored
#'   residual-correlation vector and errors if the fit has no residual `rho12`
#'   block.
#' @details For `drmTMB_julia_xfam`, `coef()` may select a retained `mu1`,
#'   `mu2`, `sigma1`, or `sigma2` block; only blocks present on that fit are
#'   selectable. Its `logLik()` object does not assert that the bridge retains
#'   a covariance matrix. `vcov()` remains unavailable for `_xfam` fits; see
#'   [vcov.drmTMB_julia_xfam()]. This topic documents extraction behavior only
#'   and makes no additional inference or coverage claim.
#' @seealso [predict.drmTMB_julia()], [summary.drmTMB_julia()],
#'   [confint.drmTMB_julia()], [vcov.drmTMB_julia_xfam()]
#' @keywords models
NULL
