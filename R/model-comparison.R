# model-comparison.R -- AICc and the nested likelihood-ratio test.
#
# Ported from DRM.jl `src/comparison.jl` at pin 430ef64cc (#1117):
#   * `aicc()`       <- comparison.jl:209-215 (`aicc(fit)`), with `aic` from
#                       gaussian_core.jl:1940-1944 and `dof` from
#                       gaussian_core.jl:1897 (`dof(fit) = length(fit.theta)`).
#   * `drm_lrtest()` <- comparison.jl:65-78 (`lrtest(reduced, full)`), its REML
#                       guard (:133-142), MAP guard (:151-158), and the boundary
#                       variance-component warning (:101-114).
#
# `weights()` needs no port: `weights.drmTMB()` (R/methods.R) already returns
# the prior observation weights, which DRM.jl's `weights(fit)` (comparison.jl:231)
# only approximates with `ones(nobs(fit))`. DRM.jl's `_marginal_compare_guard`
# (comparison.jl:162-168, VA vs Laplace) has no counterpart because drmTMB fits
# carry no variational marginal.
#
# `drm_lrtest()` is deliberately NOT exported and NOT wired into
# `anova.drmTMB()`: that method lives in R/methods.R, outside this file's scope.
# Wiring it up is a one-line follow-up once that file is in scope.

#' Corrected Akaike information criterion (AICc)
#'
#' Small-sample (second-order) correction to [AIC()]:
#'
#' \deqn{\mathrm{AICc} = \mathrm{AIC} + \frac{2k(k + 1)}{n - k - 1}}
#'
#' with \eqn{k} the number of estimated parameters (the `"df"` attribute of
#' [logLik()]) and \eqn{n} the number of observations (the `"nobs"` attribute).
#' The correction is strictly positive, so `aicc(fit) > AIC(fit)`, and it
#' vanishes as \eqn{n \to \infty}. Prefer AICc over AIC when \eqn{n / k} is
#' small (a common rule of thumb is \eqn{n / k < 40}). Like AIC, AICc compares
#' models fit by maximum likelihood on the same data; lower is better.
#'
#' This is the R port of DRM.jl's `aicc(fit)` (`src/comparison.jl`); the two
#' agree to `1e-8` on the same fit.
#'
#' @param object A fitted `drmTMB` model (either engine), or any object whose
#'   [logLik()] method reports `"df"` and `"nobs"` attributes.
#' @param ... Unused; present for S3 consistency.
#'
#' @return A single number. When \eqn{n - k - 1 \le 0} (too few observations
#'   for the correction to be defined -- a saturated or near-saturated model)
#'   the value is `Inf`, as in DRM.jl.
#'
#' @details
#' On a REML fit the same caveat as [AIC()] applies and the same warning is
#' emitted: the restricted likelihood is comparable only across models with
#' identical fixed effects. Experimental MSPL fits do not expose a likelihood
#' and error, as they do for [AIC()].
#'
#' @seealso [AIC()], [BIC()], [logLik()]
#'
#' @examples
#' \donttest{
#' set.seed(1)
#' n <- 60
#' x <- rnorm(n)
#' dat <- data.frame(y = 0.5 - 0.8 * x + exp(-0.3 + 0.4 * x) * rnorm(n), x = x)
#' fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
#' aicc(fit) > AIC(fit)   # the correction is strictly positive
#' }
#' @name model-comparison
#' @export
aicc <- function(object, ...) {
  UseMethod("aicc")
}

#' @rdname model-comparison
#' @export
aicc.default <- function(object, ...) {
  ll <- stats::logLik(object)
  drm_aicc_from_loglik(
    as.numeric(ll),
    attr(ll, "df"),
    attr(ll, "nobs"),
    what = class(object)[[1L]]
  )
}

#' @rdname model-comparison
#' @export
aicc.drmTMB <- function(object, ...) {
  drm_abort_mspl_inference(object, "aicc")
  drm_warn_information_criterion(list(object), "AICc")
  drm_aicc_from_loglik(object$logLik, object$df, object$nobs, what = "drmTMB")
}

# AICc from its three ingredients. DRM.jl comparison.jl:209-215:
#   k = dof(fit); n = nobs(fit)
#   n - k - 1 > 0 || return Inf
#   aic(fit) + 2 * k * (k + 1) / (n - k - 1)
drm_aicc_from_loglik <- function(loglik, k, n, what = "object") {
  if (is.null(k) || is.null(n)) {
    cli::cli_abort(
      "{.fn aicc} needs a {.fn logLik} method that reports {.code df} and {.code nobs} attributes; {.cls {what}} does not."
    )
  }
  loglik <- as.numeric(loglik)
  k <- as.numeric(k)
  n <- as.numeric(n)
  aic <- -2 * loglik + 2 * k
  if (n - k - 1 <= 0) {
    return(Inf)
  }
  aic + 2 * k * (k + 1) / (n - k - 1)
}

# Nested likelihood-ratio test for two ML fits on the same data.
# DRM.jl comparison.jl:65-78:
#   dof     = dof(full) - dof(reduced)          (must be > 0)
#   statistic = 2 * (loglik(full) - loglik(reduced))
#   pvalue  = ccdf(Chisq(dof), max(statistic, 0))
# Returns list(statistic, df, p.value) -- DRM.jl's (statistic, dof, pvalue).
# A negative statistic (the reduced fit is better: not nested, or one fit did
# not converge) is returned as-is; only the p-value clamps it at zero.
drm_lrtest <- function(reduced, full) {
  drm_abort_mspl_inference(reduced, "lrtest")
  drm_abort_mspl_inference(full, "lrtest")
  ll_reduced <- stats::logLik(reduced)
  ll_full <- stats::logLik(full)
  n_reduced <- attr(ll_reduced, "nobs")
  n_full <- attr(ll_full, "nobs")
  if (!identical(as.numeric(n_reduced), as.numeric(n_full))) {
    cli::cli_abort(
      "{.fn lrtest}: the two fits use different numbers of observations ({n_reduced} vs {n_full}); a likelihood ratio needs the same data."
    )
  }
  drm_lrtest_reml_guard(reduced, full)
  drm_lrtest_map_guard(reduced, full)
  df <- as.numeric(attr(ll_full, "df")) - as.numeric(attr(ll_reduced, "df"))
  if (!isTRUE(df > 0)) {
    cli::cli_abort(
      c(
        "{.fn lrtest}: {.arg full} must have more parameters than {.arg reduced}.",
        "i" = "df(full) = {attr(ll_full, 'df')}, df(reduced) = {attr(ll_reduced, 'df')}; did you pass the arguments as (reduced, full)?"
      )
    )
  }
  drm_lrtest_boundary_warn(reduced, full, df)
  statistic <- 2 * (as.numeric(ll_full) - as.numeric(ll_reduced))
  p.value <- stats::pchisq(max(statistic, 0), df = df, lower.tail = FALSE)
  list(statistic = statistic, df = df, p.value = p.value)
}

# "ML" when the fit records no estimator (TMB fits always do; keep the same
# default `drm_warn_information_criterion()` uses).
drm_fit_estimator <- function(object) {
  if (is.null(object$estimator)) "ML" else object$estimator
}

# Mean-structure fingerprint (DRM.jl `_mean_structure`, comparison.jl:117-126):
# the coefficient names of every mean (`mu`, or `mu1`/`mu2`) block.
drm_lrtest_mean_structure <- function(object) {
  coefs <- object$coefficients
  mu <- coefs[grepl("^mu", names(coefs))]
  unlist(lapply(names(mu), function(d) paste(d, names(mu[[d]]))), use.names = FALSE)
}

# DRM.jl `_reml_compare_guard` (comparison.jl:133-142): REML likelihoods are
# built on different error-contrast bases when the mean structures differ, so
# the ratio is meaningless. Same mean, different variance structure is fine.
drm_lrtest_reml_guard <- function(reduced, full) {
  if (!("REML" %in% c(drm_fit_estimator(reduced), drm_fit_estimator(full)))) {
    return(invisible(NULL))
  }
  if (!identical(drm_lrtest_mean_structure(reduced), drm_lrtest_mean_structure(full))) {
    cli::cli_abort(
      c(
        "{.fn lrtest}: cannot compare REML fits with different fixed-effect (mean) structures.",
        "i" = "REML log-likelihoods are comparable only across variance structures; refit both with {.code REML = FALSE} for a cross-mean-structure test."
      ),
      class = "drmTMB_lrtest_reml_error"
    )
  }
  invisible(NULL)
}

# DRM.jl `_map_compare_guard` (comparison.jl:151-158): a penalized (MAP) fit
# shrinks its variance components, so the likelihood ratio has no chi-square
# reference; refuse rather than report a silently wrong p-value.
drm_lrtest_map_guard <- function(reduced, full) {
  if (!("MAP" %in% c(drm_fit_estimator(reduced), drm_fit_estimator(full)))) {
    return(invisible(NULL))
  }
  cli::cli_abort(
    c(
      "{.fn lrtest}: cannot compare penalized (MAP) fits.",
      "i" = "A penalized fit shrinks its variance components, so the likelihood-ratio statistic does not have the usual chi-square distribution; refit both without the penalty."
    ),
    class = "drmTMB_lrtest_map_error"
  )
}

# Variance-component labels (DRM.jl `_variance_component_blocks`,
# comparison.jl:89-92): every random-effect SD and correlation the fit
# estimates, tagged by distributional parameter so `mu:(1 | g)` and
# `sigma:(1 | g)` are distinct components.
drm_lrtest_vc_labels <- function(object) {
  lab <- function(block) {
    unlist(
      lapply(names(block), function(d) paste0(d, ":", names(block[[d]]))),
      use.names = FALSE
    )
  }
  as.character(c(lab(object$sdpars), lab(object$corpars)))
}

# DRM.jl `_boundary_vc_warn` (comparison.jl:101-114, issue #304): when `full`
# adds a variance component `reduced` lacks, the null (variance = 0) sits on the
# boundary of the parameter space and the chi-square(df) reference is invalid
# (the p-value is conservative). Warn; do not silently swap the reference.
drm_lrtest_boundary_warn <- function(reduced, full, df) {
  dropped <- setdiff(drm_lrtest_vc_labels(full), drm_lrtest_vc_labels(reduced))
  if (length(dropped) == 0L) {
    return(invisible(NULL))
  }
  cli::cli_warn(
    c(
      "{.fn lrtest}: {.arg full} adds variance component{?s} {.val {dropped}} that {.arg reduced} lacks, so this tests a variance against 0: a boundary null.",
      "!" = "The chi-square({df}) p-value is conservative there (too large; the test loses power); the correct reference is a chi-bar-square mixture.",
      "i" = "Use a boundary-corrected test or a parametric bootstrap for a valid p-value."
    ),
    class = "drmTMB_lrtest_boundary_warning"
  )
  invisible(NULL)
}
