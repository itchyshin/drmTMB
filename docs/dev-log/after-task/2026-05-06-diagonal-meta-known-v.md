# After Task: Diagonal `meta_known_V()` Gaussian Meta-Analysis

Date: 2026-05-06

## Goal

Implement the first meta-analysis path as ordinary Gaussian distributional
regression with diagonal known sampling variance:

```r
drmTMB(
  bf(
    yi ~ moderator + meta_known_V(V = vi),
    sigma ~ moderator
  ),
  family = gaussian(),
  data = dat
)
```

## Created or Changed

- Extended the TMB likelihood in `src/drmTMB.cpp` with `V_known`.
- Updated `R/drmTMB.R` to extract one valid `meta_known_V(V = ...)` marker from
  the location formula, remove it before model-matrix construction, validate
  known variances, and pass them to TMB.
- Updated `R/methods.R` so Pearson residuals and `simulate()` use
  `sqrt(V_known + sigma^2)`, while `predict(..., dpar = "sigma")` and
  `sigma()` still return unknown heterogeneity SD.
- Added `tests/testthat/test-meta-known-v.R`.
- Reconciled README, roadmap, NEWS, likelihood docs, meta-analysis design,
  distribution roadmap, vignettes, and known limitations.
- Integrated subagent contributions:
  - test worker hardened Gaussian MVP tests;
  - docs worker improved interpretation and caveats;
  - reviewer flagged stale tests, near-zero starts, marker parsing, and docs
    drift.

## Implemented Likelihood

```text
yi_i ~ Normal(mu_i, sqrt(vi_i + sigma_i^2))
mu_i = X_mu beta_mu
log(sigma_i) = X_sigma beta_sigma
```

The diagonal known variance is not a predictor. It is a covariance marker that
is removed before constructing `X_mu`.

## Checks Run

- `Rscript -e "devtools::document(); devtools::test()"`: 73 passed, 0 failed.
- Interactive smoke test for diagonal `meta_known_V(V = vi)` fit, coefficients,
  Pearson residuals, and simulation.
- Stale-status scan for `not implemented`, `meta_gaussian()`, `tau ~`,
  `rho ~`, and malformed `meta_known_V(...)` examples.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no pkgdown
  problems and final site built successfully.
- `Rscript -e "devtools::check(error_on = 'never')"`: 0 errors, 0 warnings,
  0 notes.

## Test of the Tests

Added tests for:

- parameter recovery with known `vi`;
- diagonal matrix input;
- full covariance rejection;
- missing known-variance row alignment;
- malformed marker calls such as `meta_known_V(bad = vi)` and extra arguments;
- `meta_known_V()` in the scale formula;
- near-zero heterogeneity start behaviour.

The previous unsupported-syntax test expected `meta_known_V()` to fail. That
was intentionally updated because diagonal known variance is now implemented.

## Numerical and TMB Review

- `sigma` remains on an unconstrained log scale.
- The observation likelihood uses `obs_sigma = sqrt(V_known + sigma^2)`.
- Starting values now use a practical positive floor instead of starting
  essentially at machine zero when known sampling variance explains most
  residual variance.
- Full or block-diagonal covariance is rejected until an MVN likelihood path is
  implemented.
- Native registration remains enabled while TMB dynamic symbols remain
  available for `MakeADFun()`.

## Consistency Audit

- README now says diagonal `meta_known_V(V = vi)` is implemented.
- ROADMAP Phase 2 is marked implemented for diagonal known variance.
- `docs/design/03-likelihoods.md` and `docs/design/08-meta-analysis.md` now
  describe the implemented diagonal path, not only a planned feature.
- Vignettes no longer claim that diagonal `meta_known_V()` is marker-only.
- Remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## Known Limitations

- Full and block-diagonal known covariance matrices are not implemented.
- Random effects are not implemented.
- Bivariate `rho12` models are not implemented.
- Exact zero heterogeneity is approximated by a very small positive `sigma`
  because the current parameterization is log-SD.

## Next Task

The next large feature should be bivariate Gaussian:

1. constant `rho12`;
2. then `rho12 ~ predictors`;
3. then simulation recovery tests across negative, zero, and positive
   correlations.
