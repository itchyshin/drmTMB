# After Task: Bivariate Mu Profile Interval

## Goal

Check that the implemented bivariate Gaussian `mu1`/`mu2` random-intercept
covariance slice can produce a direct profile-likelihood interval for the
fitted group-level correlation.

## Implemented

Added one focused `confint(..., method = "profile")` regression test for:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x + (1 | p | id),
    mu2 = y2 ~ x + (1 | p | id),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  ),
  family = biv_gaussian(),
  data = dat
)
```

The test profiles:

```r
cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)
```

and checks that the result maps to `eta_cor_mu`, uses the response-scale
`tanh` transformation, stays finite and bounded inside `(-1, 1)`, and
surrounds the fitted `corpars$mu` estimate.

## Mathematical Contract

This task did not change likelihood code or profiling code. It verifies that
the direct random-effect correlation profile path applies to the bivariate
mean-model covariance parameter and remains distinct from residual `rho12`.

## Files Changed

- `tests/testthat/test-profile-targets.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-bivariate-mu-profile-interval.md`

## Checks Run

- `air format tests/testthat/test-profile-targets.R`: passed.
- `Rscript -e "devtools::test(filter = 'profile-targets')"`: passed with 211
  expectations, 0 failures, 0 warnings, and 0 skips.
- `rg -n 'confint profile intervals transform bivariate mu|eta_cor_mu|corpars\$mu|residual rho12' tests/testthat/test-profile-targets.R docs/dev-log/after-task/2026-05-12-bivariate-mu-profile-interval.md docs/dev-log/check-log.md`:
  confirmed the new bivariate interval test, optimized TMB parameter name,
  fitted `corpars$mu` check, and residual-`rho12` boundary wording.
- `git diff --check`: passed.

## Tests Of The Tests

The test uses the existing deterministic bivariate group-data helper that was
already stable for profile-target inventory coverage. It checks interval
metadata, finite response-scale bounds, and containment of the fitted
`corpars$mu` estimate.

## Consistency Audit

No user-facing documentation changed because this is coverage for an already
listed `profile_targets()` row. The new test checks `eta_cor_mu` and keeps the
group-level `mu1`/`mu2` covariance target separate from residual `rho12`.

## What Did Not Go Smoothly

Nothing unusual. A smoke test confirmed finite interval bounds before the test
was committed.

## Team Learning

- Ada kept this as the bivariate sibling of the `mu_sigma` interval slice.
- Curie reused the deterministic helper instead of inventing a new simulation.
- Noether kept the group-level covariance and residual `rho12` namespaces
  separate.

## Known Limitations

- The test covers one labelled intercept-only bivariate `mu1`/`mu2` covariance
  block.
- It does not add profile support for larger structured covariance blocks or
  derived covariance summaries.

## Next Actions

1. Avoid adding more profile interval tests until a new implemented target
   exists or a real bug appears.
2. Use the next slice for documentation/status cleanup or a full checkpoint,
   not another adjacent profile test.
