# After Task: Dense Known-V `metafor::rma.mv()` Comparator

## Goal

Add an independent comparator for dense full known sampling covariance in
Gaussian meta-analysis.

## Implemented

- Added a small `metafor::rma.mv()` comparator test in
  `tests/testthat/test-comparators.R`.
- Updated `docs/design/05-testing-strategy.md` so the dense known-`V`
  comparator is listed as implemented.

## Mathematical Contract

The overlapping model is:

```text
y ~ Normal(X beta, V + sigma^2 I)
```

where `V` is a dense known sampling covariance matrix and `sigma^2` is the
unknown residual heterogeneity variance. In `metafor`, the same overlap is:

```r
metafor::rma.mv(
  yi = yi,
  V = V,
  mods = ~ x,
  random = ~ 1 | obs,
  method = "ML"
)
```

with one observation-level random-effect level per row.

## Files Changed

- `tests/testthat/test-comparators.R`
- `docs/design/05-testing-strategy.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-dense-known-v-metafor-comparator.md`

## Checks Run

- Ad hoc `drmTMB` versus `metafor::rma.mv()` smoke comparison for fixed effects,
  heterogeneity variance, and log-likelihood.
- `Rscript -e "devtools::test(filter = 'comparators|meta-known-v')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg -n 'rma\\.mv|dense known sampling covariance|metafor::rma\\.mv' docs/design/05-testing-strategy.md tests/testthat/test-comparators.R docs/dev-log/check-log.md`

## Tests Of The Tests

- The test compares fixed-effect coefficients, residual heterogeneity variance,
  and ML log-likelihood against `metafor::rma.mv()`.
- The known `V` matrix includes off-diagonal covariance, so it exercises the
  dense covariance path rather than the diagonal `rma.uni()` overlap.
- The test uses `skip_if_not_installed("metafor")`, keeping package checks
  portable when `metafor` is absent.

## Consistency Audit

- `docs/design/05-testing-strategy.md` now lists this comparator under
  implemented comparator smoke tests.
- The bivariate meta-analysis comparator remains planned because this task only
  covered univariate dense known `V`.
- No user-facing syntax changed.

## What Did Not Go Smoothly

The first `rg` scan for `rma.mv` failed because the shell interpreted backticks
inside the pattern. The successful command uses single quotes and is recorded
above.

## Team Learning

Comparator tests should check the full log-likelihood whenever possible, not
only point estimates. That catches likelihood-constant and covariance-combining
mistakes that coefficient comparisons alone can miss.

## Known Limitations

This does not validate bivariate meta-analysis against `metafor::rma.mv()` yet.
It also does not cover `glmmTMB::equalto()`; that remains a separate comparator
task.

## Next Actions

- Add a bivariate known-`V` comparator or documented reason for the nearest
  comparable `metafor` parameterization.
- Turn the `testing-likelihoods` article from a placeholder into a developer
  guide that explains independent likelihood checks, simulations, and
  comparator tests.
