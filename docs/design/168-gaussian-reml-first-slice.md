# Gaussian REML First Slice

This note records the first `drmTMB(..., REML = TRUE)` implementation contract.
It is an estimator slice for ordinary Gaussian mixed models, not a missing-data
engine and not a broad replacement for ML model selection.

## Purpose

REML is useful for Gaussian mixed-model variance-component estimation when the
mean structure is fixed. In the first slice, `drmTMB` supports REML for the
ordinary lme4-overlap and meta-analysis known-`V` surfaces:

- univariate `family = gaussian()`;
- dense full-rank `mu` fixed-effect design;
- ordinary `mu` random intercepts or numeric slopes;
- optional diagonal or dense known sampling covariance through `meta_V(V = V)`;
- intercept-only `sigma`;
- complete responses and unit likelihood weights.

This deliberately excludes bivariate Gaussian models, non-Gaussian models,
explicit missing-data routes, Gaussian row aggregation, sparse fixed-effect
matrices, structured effects, direct `sd()` or `sd_phylo()` scale formulae,
`sigma` random effects, predictor-dependent `sigma`, non-unit weights with
known dense `V`, and q > 2 labelled covariance blocks.

## Implementation

The TMB template still evaluates the ordinary Gaussian joint likelihood. The R
fit builder switches the estimator by passing

```r
random = c(spec$random_names, "beta_mu")
```

to `TMB::MakeADFun()` when `REML = TRUE`. TMB then integrates the location
fixed-effect vector together with the ordinary latent `mu` random effects. The
conditional modes from `obj$env$parList(opt$par)` still provide `coef(fit,
"mu")`, `ranef()`, `sigma()`, `sdpars`, and `corpars`.

Because `beta_mu` is integrated in the REML fit, it is not part of
`sdr$cov.fixed`. `vcov.drmTMB()` therefore reads the full `sdreport`
covariance matrix for REML coefficient rows. `logLik.drmTMB()` keeps `df`
aligned with `lme4::logLik()`: optimized variance parameters plus the
integrated fixed-effect coefficients.

## Comparator Evidence

Focused tests in `tests/testthat/test-comparators.R` compare the REML
random-intercept and correlated random-slope routes against
`lme4::lmer(..., REML = TRUE)`. They check convergence, fixed effects,
residual sigma, random-effect SDs, random-effect correlations where present,
restricted log-likelihood, and reported degrees of freedom.

Known-`V` REML tests compare diagonal `meta_V(V = vi)` and dense
`meta_V(V = V)` estimates against `metafor` REML fits. The `drmTMB`
restricted log likelihood is checked against an independent full Gaussian REML
calculation. `metafor` reports the same optimized estimates but a log-likelihood
convention shifted by `0.5 * log|X'X|`; the tests record that expected
fixed-design determinant shift rather than forcing the two conventions to be
identical.

ML remains the default and should be used for AIC/BIC comparisons across
different fixed-effect formulas. REML comparisons are meaningful for variance
structures inside a fixed mean structure.
