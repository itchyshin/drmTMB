# After Task: Mu/Sigma Profile Interval

## Goal

Check that the implemented univariate Gaussian `mu`/`sigma`
random-intercept covariance slice can produce a direct profile-likelihood
interval for the fitted group-level correlation.

## Implemented

Added one focused `confint(..., method = "profile")` regression test for:

```r
drmTMB(
  bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
  family = gaussian(),
  data = dat
)
```

The test profiles:

```r
cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)
```

and checks that the result maps to `eta_cor_mu_sigma`, uses the response-scale
`tanh` transformation, stays finite and bounded inside `(-1, 1)`, and
surrounds the fitted `corpars$mu_sigma` estimate.

## Mathematical Contract

This task did not change likelihood code or profiling code. It verifies that
the existing direct profile path for random-effect correlations also applies to
the mean-scale `mu`/`sigma` covariance parameter.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-profile-interval.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 201
  expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'confint profile intervals transform mu/sigma|eta_cor_mu_sigma|corpars\$mu_sigma|residual rho12' tests/testthat/test-profile-targets.R docs/dev-log/after-task/2026-05-12-mu-sigma-profile-interval.md docs/dev-log/check-log.md`:
  confirmed the new interval test, optimized TMB parameter name, fitted
  `corpars$mu_sigma` check, and residual-`rho12` boundary wording.
- `git diff --check`: passed.

## Tests Of The Tests

The first smoke-test data set produced an `NA` upper interval, so it was not
used as a regression test. The committed test uses a deterministic, slightly
larger data set that returns finite lower and upper bounds, then checks that
the interval contains the fitted correlation.

## Consistency Audit

No user-facing documentation changed because this is coverage for an already
listed `profile_targets()` row. The test keeps the `mu_sigma` namespace
separate from residual `rho12` and checks the actual optimized TMB parameter
name.

## What Did Not Go Smoothly

The initial short simulated fit profiled one side of the interval to `NA`.
That was useful feedback: this test should not depend on a boundary-adjacent
profile. The final deterministic case keeps the same model but gives the
profile enough information to close both sides.

## Team Learning

- Ada kept the slice test-only.
- Curie used a deterministic finite-interval case rather than accepting a
  flaky profile boundary.
- Noether kept the `mu_sigma` group-level correlation distinct from residual
  `rho12`.

## Known Limitations

- The test covers one labelled intercept-only `mu`/`sigma` covariance block.
- It does not add new profile support for derived targets or larger structured
  covariance blocks.

## Next Actions

1. Add the same interval-level coverage for the bivariate `mu1`/`mu2`
   covariance target if it is not already covered.
2. Keep future profile interval tests small, deterministic, and explicitly
   bounded away from profile-boundary failures.
