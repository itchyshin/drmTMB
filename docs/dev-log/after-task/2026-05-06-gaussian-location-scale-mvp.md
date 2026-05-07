# After Task: Gaussian Location-Scale MVP

Date: 2026-05-06

## Goal

Implement the first real model in `drmTMB`: a fixed-effect Gaussian
location-scale model using TMB.

Target syntax:

```r
drmTMB(
  bf(y ~ x, sigma ~ z),
  family = gaussian(),
  data = dat
)
```

## Created or Changed

- Added `src/drmTMB.cpp`, the first TMB template.
- Added `src/init.c` for native routine registration while keeping TMB dynamic
  symbols available.
- Updated `DESCRIPTION` with `LinkingTo: TMB, RcppEigen`.
- Replaced the scaffold abort in `drmTMB()` with a narrow Gaussian
  location-scale fitter.
- Added model-matrix construction, starting values, optimization with
  `nlminb()`, `sdreport()`, and a `drmTMB` fit object.
- Added S3 methods for `print()`, `coef()`, `vcov()`, `logLik()`, `predict()`,
  `simulate()`, `residuals()`, `sigma()`, and `summary()`.
- Added simulation recovery tests for `mu` and `sigma`.
- Updated README, roadmap, likelihood docs, family registry docs, vignette text,
  NEWS, and known limitations.

## Implemented Likelihood

```text
y_i ~ Normal(mu_i, sigma_i)
mu_i = X_mu beta_mu
log(sigma_i) = X_sigma beta_sigma
```

Positive `sigma` is modelled on the log scale. Phase 1 rejects random effects,
known covariance markers, phylogenetic terms, spatial terms, bivariate
parameters, and non-Gaussian families with explicit errors.

## Checks Run

- `Rscript -e "devtools::document()"`: clean on final run.
- `Rscript -e "devtools::test()"`: 30 passed, 0 failed.
- Interactive smoke test: fitted `bf(y ~ x, sigma ~ z)`, checked convergence,
  coefficients, prediction, `sigma()`, and `simulate()`.
- `Rscript -e "devtools::check(error_on = 'never')"`: 0 errors, 0 warnings,
  0 notes.
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`: no pkgdown
  problems; final site built successfully.

## Test of the Tests

The main test simulates from known `beta_mu = c(0.4, 0.7)` and
`beta_sigma = c(-0.2, 0.35)`, fits the TMB model, and checks both parameter
vectors within tolerance. Additional tests check factor predictors, default
intercept-only `sigma`, simulation output dimensions, and clear rejection of
unsupported Phase 1 syntax.

## Numerical and TMB Review

- Positive parameters are unconstrained internally through the log-sigma
  linear predictor.
- The likelihood includes normalizing constants via `dnorm(..., true)`.
- `nlminb()` convergence is checked in tests.
- `sdreport()` is called after optimization.
- Native routine registration is present; TMB dynamic symbol lookup remains
  enabled because `MakeADFun()` needs TMB template symbols from the package DLL.
- A local R 4.5 / Apple clang header warning is avoided with a source-level
  include-order workaround, not non-portable Makevars flags.

## Consistency Audit

- README now states the Gaussian MVP is implemented.
- ROADMAP marks Phase 1 as implemented and points to meta-analysis next.
- `docs/design/02-family-registry.md` records the implemented Gaussian family
  mapping.
- `docs/design/03-likelihoods.md` links the likelihood to `src/drmTMB.cpp` and
  the simulation test.
- `docs/dev-log/known-limitations.md` no longer says no fitting engine exists.
- Stale-syntax scan only found intentional guardrails against `meta_gaussian()`
  and `tau ~`.

## Known Limitations

- No random effects yet.
- No known covariance/meta-analysis implementation yet.
- No bivariate `rho12` likelihood yet.
- No non-Gaussian families yet.
- Formula validation is intentionally conservative and Phase 1 specific.

## Next Task

Harden the Gaussian path before expanding:

- add missing-data tests;
- add stronger factor/newdata prediction tests;
- add a small benchmark or recovery script outside CRAN tests;
- then implement diagonal `meta_known_V(V = vi)` for Gaussian meta-analysis.
