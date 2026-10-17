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
# `drm_lrtest()` is deliberately NOT exported. `anova.drmTMB()` (R/methods.R)
# calls it through `drm_anova_lrt()` below (#1240); `anova()` on an
# `engine = "julia"` fit still refuses.

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
#' @param test Present only so `anova.drmTMB_julia()` matches the signature of
#'   [stats::anova()]; it is never consulted, because that method refuses.
#'
#' @return A single number. When \eqn{n - k - 1 \le 0} (too few observations
#'   for the correction to be defined -- a saturated or near-saturated model)
#'   the value is `Inf`, as in DRM.jl.
#'
#' @details
#' On a REML fit the same caveat as [AIC()] applies and the same warning is
#' emitted: the restricted likelihood is comparable only across models with
#' identical fixed effects. This holds for both engines: `engine = "julia"`
#' fits have their own `aicc()`, [AIC()] and [BIC()] methods that run the same
#' REML guard before computing the value. Experimental MSPL fits do not expose a likelihood
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

#' @rdname model-comparison
#' @export
aicc.drmTMB_julia <- function(object, ...) {
  drm_warn_information_criterion(list(object), "AICc")
  NextMethod()
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
# test = "bootstrap" (FX6b / #1559 / #1560) replaces the reference p-value
# with a parametric bootstrap from the reduced (null) fit.
drm_lrtest <- function(reduced, full, test = NULL, nsim = 199L, seed = NULL) {
  drm_abort_mspl_inference(reduced, "lrtest")
  drm_abort_mspl_inference(full, "lrtest")
  kind <- drm_lrt_test_kind(test)
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
  if (identical(kind, "bootstrap")) {
    boot <- drm_lrt_bootstrap(
      reduced,
      full,
      statistic = statistic,
      nsim = nsim,
      seed = seed
    )
    return(list(
      statistic = statistic,
      df = df,
      p.value = boot$p.value,
      nsim = boot$nsim,
      seed = boot$seed,
      failed = boot$failed
    ))
  }
  p.value <- stats::pchisq(max(statistic, 0), df = df, lower.tail = FALSE)
  list(statistic = statistic, df = df, p.value = p.value)
}

# Parse the LRT reference: default chi-square (anova may then swap in chi-bar)
# or a parametric bootstrap from the reduced fit.
drm_lrt_test_kind <- function(test) {
  if (is.null(test)) {
    return("default")
  }
  if (!(is.character(test) && length(test) == 1L && !is.na(test))) {
    cli::cli_abort(c(
      "{.arg test} must be {.val Chisq}, {.val LRT}, {.val bootstrap}, or {.code NULL}.",
      "i" = "The default is the usual likelihood-ratio reference; {.code test = \"bootstrap\"} simulates from the reduced (null) fit."
    ))
  }
  key <- tolower(test)
  if (key %in% c("chisq", "lrt", "chi-square", "chi-squared")) {
    return("default")
  }
  if (key %in% c("bootstrap", "parametric", "parametric_bootstrap")) {
    return("bootstrap")
  }
  cli::cli_abort(c(
    "{.arg test} must be {.val Chisq}, {.val LRT}, {.val bootstrap}, or {.code NULL}.",
    "i" = "The default is the usual likelihood-ratio reference; {.code test = \"bootstrap\"} simulates from the reduced (null) fit."
  ))
}

drm_validate_lrt_nsim <- function(nsim) {
  if (
    !is.numeric(nsim) ||
      length(nsim) != 1L ||
      is.na(nsim) ||
      !is.finite(nsim) ||
      nsim < 1L ||
      nsim != as.integer(nsim)
  ) {
    cli::cli_abort("{.arg nsim} must be a positive whole number.")
  }
  as.integer(nsim)
}

# Refit one model on a bootstrap data set. Mirrors bootstrap_refit_one() but
# returns the fit (or an error) so the likelihood-ratio can be recomputed.
drm_lrt_bootstrap_refit <- function(object, data, refit_control) {
  tryCatch(
    {
      arguments <- list(
        formula = object$formula,
        family = object$family,
        data = data,
        control = refit_control,
        REML = isTRUE(object$REML)
      )
      if (!identical(object$model$model_type, "biv_lognormal") &&
          !identical(object$model$model_type, "biv_student")) {
        arguments$weights <- object$model$weights
      }
      refit_missing <- bootstrap_refit_missing_control(object)
      if (!is.null(refit_missing)) {
        arguments$missing <- refit_missing
      }
      do.call(drmTMB, arguments)
    },
    error = function(err) err
  )
}

drm_lrt_bootstrap_fit_ok <- function(fit) {
  !inherits(fit, "error") &&
    isTRUE(tryCatch(is_converged(fit), error = function(e) {
      isTRUE(fit$opt$convergence == 0L)
    }))
}

# Parametric bootstrap under the reduced (null) fit: simulate new responses,
# refit both models, and return the Davison–Hinkley p-value
#   (1 + #{T* >= T_obs}) / (1 + n_ok)
# plus nsim, the caller seed, and the number of failed refits.
drm_lrt_bootstrap <- function(
  reduced,
  full,
  statistic,
  nsim = 199L,
  seed = NULL,
  refit_control = NULL
) {
  nsim <- drm_validate_lrt_nsim(nsim)
  if (is.null(reduced$data)) {
    cli::cli_abort(c(
      "Parametric bootstrap LRT requires the fitted model data on the reduced (null) fit.",
      "i" = "Refit the reduced model with {.code drm_control(keep_data = TRUE)}."
    ))
  }
  if (is.null(full$data)) {
    cli::cli_abort(c(
      "Parametric bootstrap LRT requires the fitted model data on the full fit.",
      "i" = "Refit the full model with {.code drm_control(keep_data = TRUE)}."
    ))
  }
  refit_control <- bootstrap_refit_control(refit_control)
  simulations <- stats::simulate(reduced, nsim = nsim, seed = seed)
  stats_star <- rep(NA_real_, nsim)
  ok <- logical(nsim)
  for (i in seq_len(nsim)) {
    data_reduced <- bootstrap_response_data(reduced, simulations, i)
    data_full <- bootstrap_response_data(full, simulations, i)
    fit_reduced <- drm_lrt_bootstrap_refit(reduced, data_reduced, refit_control)
    fit_full <- drm_lrt_bootstrap_refit(full, data_full, refit_control)
    if (!drm_lrt_bootstrap_fit_ok(fit_reduced) ||
        !drm_lrt_bootstrap_fit_ok(fit_full)) {
      next
    }
    ll_r <- tryCatch(as.numeric(stats::logLik(fit_reduced)), error = function(e) NA_real_)
    ll_f <- tryCatch(as.numeric(stats::logLik(fit_full)), error = function(e) NA_real_)
    if (!is.finite(ll_r) || !is.finite(ll_f)) {
      next
    }
    stats_star[[i]] <- 2 * (ll_f - ll_r)
    ok[[i]] <- TRUE
  }
  n_ok <- sum(ok)
  failed <- nsim - n_ok
  if (n_ok < 1L) {
    cli::cli_abort(c(
      "Parametric bootstrap LRT: every one of {nsim} refit pair{?s} failed.",
      "i" = "Inspect the original fits with {.fn check_drm}, or try a larger {.arg nsim}."
    ))
  }
  list(
    p.value = (1 + sum(stats_star[ok] >= statistic)) / (1 + n_ok),
    nsim = nsim,
    seed = seed,
    failed = as.integer(failed),
    n_ok = as.integer(n_ok)
  )
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
# Family-dispersion nests (Poisson ⊂ NB2, #1557) use the same warning: the extra
# `sigma` is tested at 0. The pairwise helper still reports the naive p-value;
# `anova.drmTMB()` swaps in the chi-bar mixture when the nest is clean.
drm_lrtest_boundary_warn <- function(reduced, full, df) {
  dropped <- setdiff(drm_lrtest_vc_labels(full), drm_lrtest_vc_labels(reduced))
  if (length(dropped) > 0L) {
    cli::cli_warn(
      c(
        "{.fn lrtest}: {.arg full} adds variance component{?s} {.val {dropped}} that {.arg reduced} lacks, so this tests a variance against 0: a boundary null.",
        "!" = "The chi-square({df}) p-value is conservative there (too large; the test loses power); the correct reference is a chi-bar-square mixture.",
        "i" = "Use {.fn lrt_boundary} or a parametric bootstrap for a valid p-value."
      ),
      class = "drmTMB_lrtest_boundary_warning"
    )
    return(invisible(NULL))
  }
  nest <- drm_family_boundary_nest(
    drm_anova_family_type(reduced),
    drm_anova_family_type(full)
  )
  if (is.null(nest)) {
    return(invisible(NULL))
  }
  cli::cli_warn(
    c(
      "{.fn lrtest}: {.arg full} is {.val {drm_anova_family_type(full)}} and {.arg reduced} is {.val {drm_anova_family_type(reduced)}}, so this tests the extra {.val {nest$added}} at 0: a boundary null.",
      "!" = "The chi-square({df}) p-value is conservative there (too large; the test loses power); the correct reference is a chi-bar-square mixture.",
      "i" = "Use {.fn lrt_boundary} (q = {nest$q}) or a parametric bootstrap for a valid p-value."
    ),
    class = "drmTMB_lrtest_boundary_warning"
  )
  invisible(NULL)
}

# ---------------------------------------------------------------------------
# anova.drmTMB(): likelihood-ratio table (#1240, owner decision 2026-10-11).
#
# `anova(reduced, full, ...)` runs `drm_lrtest()` on each consecutive pair of
# fits ordered by parameter count, so every guard that function carries (same
# observations, REML mean-structure, MAP) applies. Two additions the pairwise
# helper does not make:
#   * ML and REML fits are never mixed (as `lrt_boundary()`);
#   * when `full` adds one or two variance components (random-effect SDs) and
#     nothing else, OR when `full` is nbinom2 and `reduced` is poisson with
#     only the extra `sigma` intercept (#1557), the reported p-value is the
#     chi-bar-square mixture from `lrt_boundary()`, because the null sits on
#     the boundary; any other boundary case keeps the naive chi-square
#     p-value and says it is conservative. A boundary warning is always
#     signalled.
# The 50:50 chi-bar default is conservative with few groups: type-I at
# α = 0.05 is at most 5% and has no lower bound. t10 recorded 3.0% (NB2 vs
# Poisson) and 3.4% ((1 | g)). Those rates are expected. `test = "bootstrap"`
# (FX6b) replaces the reference with a parametric null from the reduced fit.

drm_anova_vc_labels <- function(object, slot) {
  block <- object[[slot]]
  as.character(unlist(
    lapply(names(block), function(d) paste0(d, ":", names(block[[d]]))),
    use.names = FALSE
  ))
}

drm_anova_family_type <- function(object) {
  mt <- object$model$model_type
  if (is.null(mt) || length(mt) == 0L) {
    return(NA_character_)
  }
  as.character(mt[[1L]])
}

# Nested family pairs whose extra distributional parameter is tested at 0.
# Only the filed t10 pair is wired: poisson ⊂ nbinom2 (sigma → 0, size → ∞).
# Sibling nests (poisson ⊂ zi_poisson, binomial ⊂ beta_binomial, nbinom2 ⊂
# zi_nbinom2) stay on the naive chi-square path; see the FX6 methods note.
drm_family_boundary_nest <- function(reduced_type, full_type) {
  if (identical(reduced_type, "poisson") && identical(full_type, "nbinom2")) {
    return(list(added = "sigma", q = 1L))
  }
  NULL
}

# Family-dispersion analogue of `drm_anova_boundary()`: chi-bar applies when
# the pair is a wired nest, no RE SD/correlation changed, and the extra
# parameter count equals q (so the only new term is the boundary dpar).
drm_anova_family_boundary <- function(reduced, full) {
  nest <- drm_family_boundary_nest(
    drm_anova_family_type(reduced),
    drm_anova_family_type(full)
  )
  added_sd <- setdiff(
    drm_anova_vc_labels(full, "sdpars"),
    drm_anova_vc_labels(reduced, "sdpars")
  )
  removed_sd <- setdiff(
    drm_anova_vc_labels(reduced, "sdpars"),
    drm_anova_vc_labels(full, "sdpars")
  )
  changed_cor <- c(
    setdiff(
      drm_anova_vc_labels(full, "corpars"),
      drm_anova_vc_labels(reduced, "corpars")
    ),
    setdiff(
      drm_anova_vc_labels(reduced, "corpars"),
      drm_anova_vc_labels(full, "corpars")
    )
  )
  df <- as.numeric(full$df) - as.numeric(reduced$df)
  list(
    added_dpar = if (is.null(nest)) character() else nest$added,
    q = if (is.null(nest)) 0L else nest$q,
    applies = !is.null(nest) &&
      length(added_sd) == 0L &&
      length(removed_sd) == 0L &&
      length(changed_cor) == 0L &&
      isTRUE(df == nest$q)
  )
}

# Which p-value applies to the comparison `reduced` -> `full`: the chi-bar
# mixture needs exactly q = 1 or 2 added SDs, no added or removed correlation,
# and an extra-parameter count equal to q (so every other parameter is shared).
drm_anova_boundary <- function(reduced, full) {
  added_sd <- setdiff(
    drm_anova_vc_labels(full, "sdpars"),
    drm_anova_vc_labels(reduced, "sdpars")
  )
  removed_sd <- setdiff(
    drm_anova_vc_labels(reduced, "sdpars"),
    drm_anova_vc_labels(full, "sdpars")
  )
  changed_cor <- c(
    setdiff(
      drm_anova_vc_labels(full, "corpars"),
      drm_anova_vc_labels(reduced, "corpars")
    ),
    setdiff(
      drm_anova_vc_labels(reduced, "corpars"),
      drm_anova_vc_labels(full, "corpars")
    )
  )
  q <- length(added_sd)
  df <- as.numeric(full$df) - as.numeric(reduced$df)
  list(
    added_sd = added_sd,
    q = q,
    applies = q %in% c(1L, 2L) &&
      length(removed_sd) == 0L &&
      length(changed_cor) == 0L &&
      isTRUE(df == q)
  )
}

drm_anova_lrt <- function(fits, labels, test = NULL, nsim = 199L, seed = NULL) {
  mspl <- vapply(fits, drm_is_mspl, logical(1L))
  if (any(mspl)) {
    drm_abort_mspl_inference(fits[[which(mspl)[[1L]]]], "anova")
  }
  kind <- drm_lrt_test_kind(test)
  native <- vapply(fits, inherits, logical(1L), what = "drmTMB")
  if (!all(native)) {
    cli::cli_abort(c(
      "{.fn anova} compares {.cls drmTMB} fits fitted with {.code engine = \"tmb\"}.",
      "x" = "Argument{?s} {.val {labels[!native]}} {?is/are} not {?a/} native {.cls drmTMB} fit{?s}.",
      "i" = "Fit every model with the same engine; {.code engine = \"julia\"} fits do not support {.fn anova}."
    ))
  }
  if (length(fits) < 2L) {
    cli::cli_abort(c(
      "{.fn anova} needs at least two nested {.cls drmTMB} fits.",
      "i" = "Call {.code anova(reduced, full)}. For a single fit, or for non-nested models, compare with {.fn AIC} or {.fn BIC}."
    ))
  }
  estimators <- vapply(fits, drm_fit_estimator, character(1L))
  if (length(unique(estimators)) > 1L) {
    cli::cli_abort(
      c(
        "{.fn anova} cannot mix fits with different estimators ({.val {unique(estimators)}}).",
        "i" = "Refit all models with the same {.arg REML}/{.arg estimator} setting."
      ),
      class = "drmTMB_anova_estimator_error"
    )
  }

  npar <- vapply(fits, function(f) as.numeric(f$df), numeric(1L))
  ord <- order(npar)
  fits <- fits[ord]
  labels <- labels[ord]
  npar <- npar[ord]
  if (any(diff(npar) <= 0)) {
    cli::cli_abort(c(
      "{.fn anova} needs fits with strictly increasing numbers of parameters to form nested comparisons.",
      "x" = "Models {.val {labels[c(FALSE, diff(npar) <= 0)]}} have as many parameters as the model before {?it/them}.",
      "i" = "A likelihood-ratio test compares a model with a larger one that contains it; use {.fn AIC} for models of equal size."
    ))
  }

  k <- length(fits)
  loglik <- vapply(fits, function(f) as.numeric(stats::logLik(f)), numeric(1L))
  chisq <- df <- p <- rep(NA_real_, k)
  p_method <- rep(NA_character_, k)
  boot_nsim <- boot_failed <- rep(NA_integer_, k)
  boot_seed <- rep(NA_character_, k)
  for (i in seq.int(2L, k)) {
    reduced <- fits[[i - 1L]]
    full <- fits[[i]]
    res <- withCallingHandlers(
      drm_lrtest(reduced, full, test = test, nsim = nsim, seed = seed),
      drmTMB_lrtest_boundary_warning = function(w) invokeRestart("muffleWarning")
    )
    chisq[[i]] <- res$statistic
    df[[i]] <- res$df
    p[[i]] <- res$p.value
    p_method[[i]] <- if (identical(kind, "bootstrap")) "bootstrap" else "chisq"
    if (identical(kind, "bootstrap")) {
      boot_nsim[[i]] <- as.integer(res$nsim)
      boot_seed[[i]] <- bootstrap_seed_label(res$seed)
      boot_failed[[i]] <- as.integer(res$failed)
    }
    bd <- drm_anova_boundary(reduced, full)
    fam <- drm_anova_family_boundary(reduced, full)
    if (length(bd$added_sd) > 0L) {
      pair <- paste0(labels[[i - 1L]], " -> ", labels[[i]])
      if (identical(kind, "bootstrap")) {
        cli::cli_warn(
          c(
            "{pair}: {.val {labels[[i]]}} adds variance component{?s} {.val {bd$added_sd}}, so the test puts {?a variance/variances} on the boundary at 0.",
            "i" = "The reported p-value is the parametric bootstrap under the reduced (null) fit ({res$nsim} draw{?s}; {res$failed} failed refit{?s})."
          ),
          class = "drmTMB_anova_boundary_warning"
        )
      } else if (bd$applies) {
        p[[i]] <- lrt_boundary(full, reduced, q = bd$q)$pvalue
        p_method[[i]] <- "chibar"
        cli::cli_warn(
          c(
            "{pair}: {.val {labels[[i]]}} adds variance component{?s} {.val {bd$added_sd}}, so the test puts {?a variance/variances} on the boundary at 0.",
            "i" = "The reported p-value is the 50:50 chi-bar-square mixture from {.fn lrt_boundary}. That default is conservative with few groups: type-I at 5% is at most 5% with no lower bound (t10 recorded 3.0% and 3.4%).",
            "i" = "Use {.code test = \"bootstrap\"} to simulate from the reduced fit.",
            "i" = if (bd$q == 2L) "For two added components the mixture assumes they are independent; confirm with {.code test = \"bootstrap\"} if in doubt."
          ),
          class = "drmTMB_anova_boundary_warning"
        )
      } else {
        cli::cli_warn(
          c(
            "{pair}: {.val {labels[[i]]}} adds variance component{?s} {.val {bd$added_sd}}, a boundary test, but the chi-bar-square mixture does not apply to this pair.",
            "x" = "It needs exactly one or two added standard deviations and no other new parameters (here {res$df} extra parameter{?s}).",
            "i" = "The reported chi-square p-value is conservative (too large). Use {.code test = \"bootstrap\"} for a parametric null."
          ),
          class = "drmTMB_anova_boundary_warning"
        )
      }
    } else if (length(fam$added_dpar) > 0L) {
      pair <- paste0(labels[[i - 1L]], " -> ", labels[[i]])
      if (identical(kind, "bootstrap")) {
        cli::cli_warn(
          c(
            "{pair}: {.val {labels[[i]]}} is {.val {drm_anova_family_type(full)}} and {.val {labels[[i - 1L]]}} is {.val {drm_anova_family_type(reduced)}}, so the test puts {.val {fam$added_dpar}} on the boundary at 0.",
            "i" = "The reported p-value is the parametric bootstrap under the reduced (null) fit ({res$nsim} draw{?s}; {res$failed} failed refit{?s})."
          ),
          class = "drmTMB_anova_boundary_warning"
        )
      } else if (fam$applies) {
        p[[i]] <- lrt_boundary(full, reduced, q = fam$q)$pvalue
        p_method[[i]] <- "chibar"
        cli::cli_warn(
          c(
            "{pair}: {.val {labels[[i]]}} is {.val {drm_anova_family_type(full)}} and {.val {labels[[i - 1L]]}} is {.val {drm_anova_family_type(reduced)}}, so the test puts {.val {fam$added_dpar}} on the boundary at 0.",
            "i" = "The reported p-value is the 50:50 chi-bar-square mixture from {.fn lrt_boundary}. That default is conservative with few groups: type-I at 5% is at most 5% with no lower bound (t10 recorded 3.0% and 3.4%).",
            "i" = "Use {.code test = \"bootstrap\"} to simulate from the reduced fit."
          ),
          class = "drmTMB_anova_boundary_warning"
        )
      } else {
        cli::cli_warn(
          c(
            "{pair}: {.val {labels[[i]]}} adds distributional parameter{?s} {.val {fam$added_dpar}} on the boundary at 0, but the chi-bar-square mixture does not apply to this pair.",
            "x" = "It needs exactly {fam$q} extra parameter{?s} and no new random-effect terms (here {res$df} extra parameter{?s}).",
            "i" = "The reported chi-square p-value is conservative (too large). Use {.code test = \"bootstrap\"} for a parametric null."
          ),
          class = "drmTMB_anova_boundary_warning"
        )
      }
    }
  }

  out <- data.frame(
    npar = npar,
    logLik = loglik,
    deviance = -2 * loglik,
    Chisq = chisq,
    Df = df,
    `Pr(>Chisq)` = p,
    row.names = labels,
    check.names = FALSE
  )
  heading <- c(
    sprintf(
      "Likelihood-ratio comparison of %d drmTMB fits (%s)",
      k, estimators[[1L]]
    ),
    "Each model is tested against the one before it, ordered by number of parameters."
  )
  if (identical(kind, "bootstrap")) {
    heading <- c(
      heading,
      sprintf(
        "P-values use a parametric bootstrap from the reduced fit (nsim = %d).",
        as.integer(nsim)
      )
    )
  }
  attrs <- list(
    heading = heading,
    p.method = p_method,
    estimator = estimators[[1L]],
    class = c("anova", "data.frame")
  )
  if (identical(kind, "bootstrap")) {
    attrs$bootstrap.nsim <- boot_nsim
    attrs$bootstrap.seed <- boot_seed
    attrs$bootstrap.failed <- boot_failed
  }
  do.call(structure, c(list(out), attrs))
}

# ---------------------------------------------------------------------------
# engine = "julia" methods (parity leaf `uncited-accessors`, 2026-09-05).
#
# What was MEASURED on the bridge axis for this suite (DRM.jl aee371cc9, one
# Gaussian random-intercept pair, n = 360, G = 30; see
# docs/dev-log/evidence/julia-r-parity/uncited-accessors/):
#
#   * `aicc()`   REACHES an `engine = "julia"` fit through `aicc.default()`,
#                because `logLik.drmTMB_julia()` reports both `df` and `nobs`.
#                It equals DRM.jl's own `aicc(fit)` on the same payload to
#                0.000e+00 (856.6308350330), and `aicc(tmb_fit)` to 1.9e-11.
#                The value is the default's; `aicc.drmTMB_julia()` (above)
#                only adds the REML/MAP guard first (#1498).
#   * `lrtest`   `drm_lrtest()` likewise runs on two `drmTMB_julia` fits and
#                reproduces DRM.jl's `lrtest(reduced, full)` exactly
#                (statistic 277.6900074326, df 1, p 2.393265e-62). It stays
#                unexported and unwired, as the file header says.
#   * `anova()`  had NO method for `drmTMB_julia`, so it failed with a bare
#                `UseMethod` error while `anova(tmb_fit)` gave drmTMB's own
#                refusal. Same refusal now, whichever engine fitted the model.
#   * `weights()` fell through to `stats:::weights.default`, which returns
#                `object$weights` -- absent on a bridge fit -- so it returned
#                NULL SILENTLY, where `weights(tmb_fit)` on the same unweighted
#                model returns a length-360 vector of ones and DRM.jl's own
#                `weights(fit)` returns `ones(nobs(fit))` (measured: length
#                360, all one). That silent divergence is what the method below
#                closes.

#' @rdname model-comparison
#' @export
anova.drmTMB_julia <- function(object, ..., test = NULL) {
  cli::cli_abort(
    "{.fn anova} likelihood-ratio comparisons are not implemented for {.cls drmTMB_julia} fits."
  )
}

# AIC()/BIC() for engine = "julia" fits (#1498). A bridge fit does not inherit
# "drmTMB", so without these methods AIC()/BIC() fell through to
# stats::AIC.default()/BIC.default() and skipped the REML/MAP guard that
# AIC.drmTMB()/BIC.drmTMB() run, although the julia route fits REML and records
# `estimator = "REML"`. The guard runs first; NextMethod() then computes the
# values with the stats defaults, which keep the caller's object names as row
# names. Native fits mixed into `...` are read through their logLik() method.

#' @rdname model-comparison
#' @param k Penalty per parameter, as in [stats::AIC()].
#' @export
AIC.drmTMB_julia <- function(object, ..., k = 2) {
  drm_warn_information_criterion(c(list(object), list(...)), "AIC")
  NextMethod()
}

#' @rdname model-comparison
#' @export
BIC.drmTMB_julia <- function(object, ...) {
  drm_warn_information_criterion(c(list(object), list(...)), "BIC")
  NextMethod()
}

#' Prior weights of an `engine = "julia"` fit
#'
#' `engine = "julia"` refuses the `weights` argument at fit time
#' (`drmTMB_julia_bridge()` and its structured counterparts in
#' `R/julia-bridge.R` abort on a non-missing `weights`), so a bridge fit is unweighted by construction and its
#' prior weights are all one. Without this method `weights()` fell through to
#' `stats:::weights.default()` and returned `NULL` silently, while
#' `weights()` on the same model fitted with `engine = "tmb"` returns a vector
#' of ones. This reports the ones, matching both the native engine and
#' `DRM.jl`'s own `weights(fit) = ones(nobs(fit))` (`src/comparison.jl`).
#'
#' These are PRIOR (per-observation) weights, not Akaike model weights.
#'
#' The length comes from [nobs()], not from `object$nobs`: a joint
#' (`drmTMB_julia_joint`) fit counts only its OBSERVED rows
#' (`nobs.drmTMB_julia_joint()` is `sum(observed_y)`), so reading the raw field
#' would return a weight vector longer than the data the fit actually used.
#'
#' @param object A `drmTMB_julia` fit (including the `_xfam` and `_joint`
#'   subclasses, which inherit this method).
#' @param ... Unused; present for S3 consistency.
#' @return A numeric vector of ones, one per observation.
#' @export
weights.drmTMB_julia <- function(object, ...) {
  rep(1, stats::nobs(object))
}
