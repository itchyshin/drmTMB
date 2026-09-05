#' Boundary-corrected likelihood-ratio test for variance components
#'
#' `chibar_pvalue()` and `lrt_boundary()` are the chi-bar-square (\eqn{\bar\chi^2})
#' boundary-corrected likelihood-ratio machinery for testing `q` **variance
#' components = 0**, ported term-for-term from `DRM.jl`'s `src/chibar.jl`
#' (`chibar_pvalue`, lines 83-95; `lrt_boundary`, lines 134-140, at DRM.jl
#' pin `430ef64cc`). Testing a variance at zero is a *boundary* problem: the
#' null value sits on the edge of the parameter space, so the usual
#' \eqn{\chi^2(q)} reference for `2 * (logLik(full) - logLik(reduced))` is
#' wrong and **conservative** (its p-values are too large, so the test loses
#' power). Under the regularity conditions of Self and Liang (1987) and Stram
#' and Lee (1994) the statistic follows a mixture of \eqn{\chi^2}
#' distributions instead:
#'
#' * `q = 1` (one boundary parameter, e.g. dropping one `(1 | g)`): the null
#'   is \eqn{0.5\,\chi^2_0 + 0.5\,\chi^2_1}, so `p = 0.5 * P(chisq_1 > stat)`.
#'   At `stat = 0` this is `0.5`; for `stat > 0` it is exactly half the naive
#'   \eqn{\chi^2_1} p-value.
#' * `q = 2` (two **independent** boundary parameters): the null is
#'   \eqn{0.25\,\chi^2_0 + 0.5\,\chi^2_1 + 0.25\,\chi^2_2}, so
#'   `p = 0.5 * P(chisq_1 > stat) + 0.25 * P(chisq_2 > stat)`. At `stat = 0`
#'   this is `0.75`.
#'
#' `drmTMB`'s `anova()` deliberately implements no likelihood-ratio
#' comparison, and `confint(method = "wald")` only *flags* a variance
#' component at its boundary (`conf.status = "wald_at_boundary"`); this pair
#' is the first drmTMB tool that computes a p-value that is correct there.
#'
#' @section Assumptions:
#' * The `q` parameters dropped between `full` and `reduced` are variances
#'   tested at the boundary `0`, and `reduced` is `full` with exactly those
#'   components removed (nested models, same data).
#' * For `q = 2` the two components are independent (zero information
#'   correlation). With correlated components the 0.25/0.5/0.25 weights
#'   depend on the information matrix and this mixture is only approximate.
#' * All other parameters are interior, so the standard asymptotic expansion
#'   holds for them.
#' * Maximum-likelihood fits. REML log-likelihoods are comparable only across
#'   variance structures with the same fixed effects, so `lrt_boundary()`
#'   aborts when either fit is REML and the two mean structures differ, or
#'   when one fit is REML and the other ML. A penalized (`penalty =
#'   drm_phylo_penalty(...)`, MAP) fit aborts too: its variance components
#'   are shrunk by the prior, so the likelihood ratio has no chi-square
#'   reference. Experimental MSPL fits abort as for every likelihood method.
#'
#' A negative statistic (the reduced model fit *better*, which signals
#' non-nested models or a fit that did not converge) is returned as-is but is
#' clamped to `0` inside both p-values, which then take their boundary values
#' (`0.5` for `q = 1`, `0.75` for `q = 2`; `1` for the naive p-value). Inspect
#' `statistic` directly in that case.
#'
#' @param statistic Likelihood-ratio statistic(s),
#'   `2 * (logLik(full) - logLik(reduced))`. Vectorised; `NA` propagates.
#' @param q Number of variance components tested at zero (the mixture
#'   order). Only `1` and `2` are supported; any other value aborts, as in
#'   `DRM.jl`.
#' @param full A `drmTMB` fit carrying the `q` variance component(s).
#' @param reduced The same model with those component(s) removed.
#'
#' @return `chibar_pvalue()` returns a numeric vector of upper-tail p-values
#'   the length of `statistic`.
#'
#'   `lrt_boundary()` returns a list of class `drm_lrt_boundary` with
#'   elements `statistic` (`2 * (logLik(full) - logLik(reduced))`), `q`,
#'   `pvalue` (`chibar_pvalue(statistic, q)`), `pvalue_naive` (the
#'   \eqn{\chi^2(q)} upper tail at `max(statistic, 0)`, for comparison; always
#'   `pvalue <= pvalue_naive`), and `df` (`df(full) - df(reduced)`, the number
#'   of extra parameters in `full`; `DRM.jl` does not report it). The two
#'   fits must be on the same observations; when `df` differs from `q` a
#'   `drmTMB_lrt_boundary_df_mismatch` warning says the mixture may not apply.
#'
#' @references
#' Self, S. G. and Liang, K.-Y. (1987). Asymptotic properties of maximum
#' likelihood estimators and likelihood ratio tests under nonstandard
#' conditions. *Journal of the American Statistical Association*, 82,
#' 605-610.
#'
#' Stram, D. O. and Lee, J. W. (1994). Variance components testing in the
#' longitudinal mixed effects model. *Biometrics*, 50, 1171-1177.
#'
#' @examples
#' chibar_pvalue(3.5, q = 1)
#' chibar_pvalue(3.5, q = 1) == 0.5 * pchisq(3.5, 1, lower.tail = FALSE)
#' chibar_pvalue(0, q = 1)   # 0.5, the boundary point mass
#' chibar_pvalue(0, q = 2)   # 0.75
#'
#' # Random intercept vs no random effect: dropping (1 | g) removes ONE
#' # variance, so q = 1.
#' set.seed(20260610)
#' G <- 30; m <- 12
#' g <- factor(rep(seq_len(G), each = m))
#' x <- rnorm(G * m)
#' b <- 0.8 * rnorm(G)
#' dat <- data.frame(y = 0.5 - 0.4 * x + b[g] + 0.7 * rnorm(G * m), x = x, g = g)
#' full <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat)
#' reduced <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
#' lrt_boundary(full, reduced, q = 1)
#' @name lrt-boundary
NULL

#' @rdname lrt-boundary
#' @export
chibar_pvalue <- function(statistic, q = 1L) {
  drm_validate_chibar_q(q)
  if (!is.numeric(statistic)) {
    cli::cli_abort("{.arg statistic} must be numeric.")
  }
  # Boundary clamp, as DRM.jl `chibar.jl:84`: a negative statistic returns the
  # boundary value. `pmax()` keeps NA as NA.
  s <- pmax(as.numeric(statistic), 0)
  p <- 0.5 * stats::pchisq(s, df = 1, lower.tail = FALSE)
  if (q == 2L) {
    p <- p + 0.25 * stats::pchisq(s, df = 2, lower.tail = FALSE)
  }
  p
}

#' @rdname lrt-boundary
#' @export
lrt_boundary <- function(full, reduced, q = 1L) {
  drm_validate_chibar_q(q)
  drm_validate_lrt_boundary_fit(full, "full")
  drm_validate_lrt_boundary_fit(reduced, "reduced")
  drm_lrt_boundary_map_guard(full, reduced)
  drm_lrt_boundary_reml_guard(full, reduced)

  ll_full <- as.numeric(stats::logLik(full))
  ll_reduced <- as.numeric(stats::logLik(reduced))
  df_full <- as.numeric(full$df)
  df_reduced <- as.numeric(reduced$df)
  if (isTRUE(df_full <= df_reduced)) {
    cli::cli_abort(c(
      "{.arg full} must have more parameters than {.arg reduced} (df {df_full} vs {df_reduced}).",
      "i" = "Did you pass the arguments as {.code lrt_boundary(reduced, full)}? The order is {.code lrt_boundary(full, reduced, q)}."
    ))
  }

  n_full <- as.numeric(stats::nobs(full))
  n_reduced <- as.numeric(stats::nobs(reduced))
  if (!isTRUE(all.equal(n_full, n_reduced))) {
    cli::cli_abort(c(
      "{.arg full} and {.arg reduced} must be fitted to the same observations (nobs {n_full} vs {n_reduced}).",
      "i" = "Nested models are compared on one data set; check for rows dropped by missing values in one fit only."
    ))
  }
  df <- df_full - df_reduced
  if (df != q) {
    cli::cli_warn(c(
      "{.arg full} has {df} more parameter{?s} than {.arg reduced}, but {.arg q} = {q}.",
      "i" = "The chi-bar-square mixture assumes the two fits differ in exactly {q} variance component{?s} tested at zero, with every other parameter shared. If the extra parameters include interior ones (a mean or scale coefficient, a random-effect correlation), the mixture and its p-value do not apply."
    ), class = "drmTMB_lrt_boundary_df_mismatch")
  }

  statistic <- 2 * (ll_full - ll_reduced)
  out <- list(
    statistic = statistic,
    q = as.integer(q),
    pvalue = chibar_pvalue(statistic, q),
    pvalue_naive = stats::pchisq(max(statistic, 0), df = q, lower.tail = FALSE),
    df = df
  )
  class(out) <- "drm_lrt_boundary"
  out
}

#' @export
print.drm_lrt_boundary <- function(x, ...) {
  cat("Boundary-corrected likelihood-ratio test (chi-bar-square mixture)\n")
  cat(sprintf(
    "  statistic = %.4f on %d boundary variance component%s (df = %g)\n",
    x$statistic, x$q, if (x$q == 1L) "" else "s", x$df
  ))
  cat(sprintf("  p-value (chi-bar-square) = %s\n", format.pval(x$pvalue, digits = 4)))
  cat(sprintf("  p-value (naive chisq_%d)   = %s\n", x$q, format.pval(x$pvalue_naive, digits = 4)))
  if (x$statistic < 0) {
    cat("  note: negative statistic clamped to 0 in both p-values; check that the models are nested and converged.\n")
  }
  invisible(x)
}

drm_validate_chibar_q <- function(q) {
  ok <- is.numeric(q) && length(q) == 1L && !is.na(q) && q %in% c(1, 2)
  if (!ok) {
    cli::cli_abort(c(
      "{.arg q} must be 1 or 2 (the number of boundary variance components).",
      "i" = "For q = 1 the mixture is 0.5 chisq_0 + 0.5 chisq_1; for q = 2 (independent components) it is 0.25 chisq_0 + 0.5 chisq_1 + 0.25 chisq_2."
    ))
  }
  invisible(TRUE)
}

drm_validate_lrt_boundary_fit <- function(fit, arg) {
  if (!inherits(fit, c("drmTMB", "drmTMB_julia"))) {
    cli::cli_abort("{.arg {arg}} must be a {.cls drmTMB} fit.")
  }
  drm_abort_mspl_inference(fit, "lrt_boundary")
  invisible(TRUE)
}

drm_lrt_boundary_estimator <- function(fit) {
  if (is.null(fit$estimator)) "ML" else as.character(fit$estimator)
}

# Penalized (MAP) fits shrink their variance components toward zero, so the
# likelihood ratio of two such fits has no chi-square (or chi-bar-square)
# reference. Mirrors DRM.jl's `_map_compare_guard` (src/comparison.jl:151-158),
# which `lrtest` applies; note DRM.jl's own `lrt_boundary` does not, so this
# is a deliberate tightening on the R side.
drm_lrt_boundary_map_guard <- function(full, reduced) {
  penalized <- vapply(
    list(full, reduced),
    function(f) identical(drm_lrt_boundary_estimator(f), "MAP") || !is.null(f$penalty),
    logical(1L)
  )
  if (any(penalized)) {
    cli::cli_abort(c(
      "{.fn lrt_boundary} cannot compare penalized (MAP) fits.",
      "i" = "A {.code penalty = drm_phylo_penalty(...)} fit shrinks its variance components, so the likelihood-ratio statistic has no chi-square reference. Refit both without {.arg penalty}."
    ))
  }
  invisible(TRUE)
}

# Mean-structure fingerprint for the REML guard: the coefficient names of every
# mean block (`mu`, or `mu1`/`mu2` for bivariate fits). Mirrors DRM.jl's
# `_mean_structure` (src/comparison.jl:117-125).
drm_lrt_boundary_mean_structure <- function(fit) {
  coefs <- fit$coefficients
  blocks <- names(coefs)[grepl("^mu", names(coefs))]
  unlist(lapply(blocks, function(b) paste(b, names(coefs[[b]]), sep = ":")))
}

# REML guard, as DRM.jl `_reml_compare_guard` (src/comparison.jl:133-142):
# restricted likelihoods are built on the error contrasts of the fixed-effect
# design, so they are comparable only across variance structures with the same
# mean structure. DRM.jl only checks the mean structure when either fit is
# REML; drmTMB additionally refuses an ML-vs-REML pair, whose likelihoods are
# on different scales whatever the mean structure.
drm_lrt_boundary_reml_guard <- function(full, reduced) {
  reml <- c(isTRUE(full$REML), isTRUE(reduced$REML))
  if (!any(reml)) {
    return(invisible(TRUE))
  }
  if (!all(reml)) {
    cli::cli_abort(c(
      "{.fn lrt_boundary} cannot compare an ML fit with a REML fit.",
      "i" = "Refit both with the same {.arg REML} setting."
    ))
  }
  if (!identical(
    drm_lrt_boundary_mean_structure(full),
    drm_lrt_boundary_mean_structure(reduced)
  )) {
    cli::cli_abort(c(
      "{.fn lrt_boundary} cannot compare REML fits with different fixed-effect (mean) structures.",
      "i" = "REML log-likelihoods are comparable only across variance structures with the same mean structure. Refit both with {.code REML = FALSE} for a cross-mean-structure test."
    ))
  }
  invisible(TRUE)
}
