# [bug][julia] `drmTMB_julia_xfam` extractors silently return NULL instead of erroring or working

**Labels:** `bug`, `julia`
**Milestone:** post-0.6.0

## Summary

For a bivariate cross-family Julia-engine fit (`engine = "julia"`, class
`drmTMB_julia_xfam`, produced by `drmTMB_julia_xfam_bridge()` /
`new_drmTMB_julia_xfam()`), several standard extractors dispatch to the
generic `drmTMB_julia` methods and return an empty or `NULL` result instead
of either working correctly or raising a clear error. A user has no signal
that the value is missing rather than legitimately empty.

Affected, confirmed by reading the constructor and the dispatched generics:

- `vcov(fit)` -> `vcov.drmTMB_julia()` reads `object$vcov`, which
  `new_drmTMB_julia_xfam()` never sets -> `NULL`.
- `fitted(fit)` -> `fitted.drmTMB_julia()` reads `object$fitted`, unset ->
  `NULL`.
- `residuals(fit)` -> `residuals.drmTMB_julia()` reads `object$residuals`,
  unset -> `NULL`.
- `predict(fit, dpar = ...)` (no `newdata`) -> falls through to
  `object$fitted`-based branches, unset -> `NULL`/misleading result.
- `summary(fit)`'s coefficient table -> `drm_julia_summary_coefficients()`
  and the Wald-CI helper (`drm_julia_wald_confint()`) read
  `object$coef_vector`, `object$vcov`, `object$aic`, `object$bic`, and
  `object$df`, none of which are set for an xfam fit -> an empty or
  incomplete coefficient table with no explanatory message.

## Root cause

`new_drmTMB_julia_xfam()` (`R/julia-bridge.R`, roughly lines 4200-4235)
builds its `out` list with `call`, `formula`, `family`, `families`, `data`,
`engine`, `estimator`, `REML`/`requested_REML`/`effective_REML`, `model`,
`bridge`, `coefficients`, `sigma_coef`, `loadings`, `sigma`, `rho_latent`,
`rho_ci_wald`, `rho_ci_profile`, `logLik`, `nobs`, and `opt`. It does not
set `$vcov`, `$fitted`, `$residuals`, `$coef_vector`, `$aic`, `$bic`, or
`$df`. Because `class(out) <- c("drmTMB_julia_xfam", "drmTMB_julia")`, any
extractor without an `*.drmTMB_julia_xfam`-specific method (only `print`,
`coef`, `logLik`, `nobs`, `is_converged`, `rho_latent`, and `confint` exist
today, per `R/julia-bridge.R`) silently falls back to the `drmTMB_julia`
generic and reads a field that is simply absent, returning `NULL` rather
than failing loudly.

`sigma()` is not affected -- `new_drmTMB_julia_xfam()` does set `$sigma`
(as `c(sigma1 = ..., sigma2 = ...)`), so `sigma.drmTMB_julia()` works
correctly for xfam fits.

## Why this matters

A user calling `vcov(fit)`, `fitted(fit)`, `residuals(fit)`,
`predict(fit, dpar = "mu1")`, or reading `summary(fit)`'s coefficient table
on a cross-family Julia fit gets a quiet `NULL`/empty result with no
indication that the route is unsupported, which can silently propagate into
downstream code (e.g. `NULL %in% ...` checks, empty data frames treated as
"no significant effects").

## Proposed fix (either is acceptable; needs a decision)

1. **Wire it up.** Populate `$vcov`, `$fitted`, `$residuals`,
   `$coef_vector`, `$aic`, `$bic`, `$df` in `new_drmTMB_julia_xfam()` from
   the DRM.jl bridge result, the same way the non-cross-family Julia bridge
   does, so the generic `drmTMB_julia` methods work as-is for xfam fits.
2. **Error clearly.** Add `*.drmTMB_julia_xfam`-specific methods for
   `vcov`, `fitted`, `residuals`, `predict`, and the `summary()` coefficient
   path that `cli::cli_abort()` with a message naming the unsupported route
   and pointing the user at the native TMB engine (the package default) or
   a same-family Julia fit as the workaround.

Either closes the silent-NULL gap; (1) is more work but gives full parity,
(2) is a fast, honest stopgap.

## Workaround (documented in `vignette("capability-and-limits")`, 0.6.0)

Use the native TMB engine (`drmTMB`'s default) for these extractors, or fit
the non-cross-family Julia route instead. `confint()` and `predict()` (with
`newdata` on `mu`/`mu1`/`mu2`) on native fits are unaffected by this gap.

## Provenance

Raised during the drmTMB 0.6.0 CRAN release-prep documentation pass
(2026-07-20), item (d) of
`docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md`
§5. Not yet filed to GitHub -- this is a scratch draft for maintainer
review before filing.
