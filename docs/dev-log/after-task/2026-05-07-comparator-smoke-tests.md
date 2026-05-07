# After Task: Comparator Smoke Tests

Date: 2026-05-07

## Task

Add the first Tier 1 validation checks against established packages, while
keeping the tests small and optional.

## Created Or Changed

- Added `tests/testthat/test-comparators.R`.
- Added `lme4` and `metafor` to `Suggests` in `DESCRIPTION`.
- Updated `docs/design/05-testing-strategy.md` to record implemented comparator
  smoke tests.
- Updated `docs/dev-log/check-log.md`.

## Checks Implemented

- `drmTMB()` Gaussian random intercepts are compared with
  `lme4::lmer(..., REML = FALSE)` for fixed effects, random-effect SD, residual
  SD, and log likelihood.
- `drmTMB()` Gaussian meta-analysis with `meta_known_V(V = vi)` is compared with
  `metafor::rma.uni(..., method = "ML")` for fixed effects, `tau2`, and log
  likelihood.
- Both tests use `skip_if_not_installed()` so missing comparator packages do not
  block lightweight environments.

## Checks Performed

- Interactive smoke comparisons against `lme4` and `metafor`.
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::test()"`
- `air format .`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Outcomes

- Comparator tests: 9 passed, 0 failed.
- Full test suite: 148 passed, 0 failed.
- `air format .` was attempted but is not installed locally.
- pkgdown check: no problems found.
- pkgdown site: built successfully.
- R CMD check with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors, 0 warnings,
  0 notes.

## Consistency Review

- The new tests implement the documented two-tier validation strategy.
- `glmmTMB` was not used because it emitted a local TMB version mismatch
  warning.
- `gamlss` was not used because it is not installed locally.
- The comparator tests are intentionally smoke tests; broad sweeps remain
  scheduled or local long-test work.

## Remaining Limitations

- No comparator tests exist yet for bivariate `rho12`, Student-t, shape,
  phylogenetic A-inverse, or SPDE spatial models.
- The comparator tests use simple overlapping likelihoods only.
