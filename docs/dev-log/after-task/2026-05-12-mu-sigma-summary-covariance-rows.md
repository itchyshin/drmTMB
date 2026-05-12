# After Task: Mu/Sigma Summary Covariance Rows

## Goal

Lock down the `summary()` parameter table for the implemented univariate
Gaussian `mu`/`sigma` random-intercept covariance slice.

## Implemented

Added a focused regression test for:

```r
drmTMB(
  bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
  family = gaussian(),
  data = dat
)
```

The test checks that `summary(fit)$parameters` includes:

- `sd:mu:(1 | p | id)`;
- `sd:sigma:(1 | p | id)`;
- `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`.

It also checks that no residual `rho12` row appears for this one-response
model, so the summary table keeps group-level mean-scale covariance separate
from bivariate residual correlation.

## Mathematical Contract

The summary rows report already fitted quantities from `sdpars$mu`,
`sdpars$sigma`, and `corpars$mu_sigma`. This task did not change the likelihood
or add new covariance parameters.

## Files Changed

- `tests/testthat/test-summary.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-mu-sigma-summary-covariance-rows.md`

## Checks Run

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 53
  expectations, 0 failures, 0 warnings, and 0 skips.

## Tests Of The Tests

The test fits a model with both labelled `mu` and `sigma` random intercepts,
then checks exact row names, components, estimates, and term labels. It also
asserts that `rho12` is absent, which guards against conflating one-response
group-level mean-scale covariance with two-response residual correlation.

## Consistency Audit

No user-facing documentation needed to change because `summary()` already
builds these rows from `profile_targets()`. This slice only adds coverage for
the existing summary surface.

## What Did Not Go Smoothly

Nothing unusual. The existing summary machinery already handled
`corpars$mu_sigma`; the missing piece was a regression test.

## Team Learning

- Ada kept this as a coverage slice after the likelihood and diagnostic slices.
- Noether kept residual `rho12` out of the one-response summary table.
- Curie pinned exact row names so future extractor changes cannot drift
  silently.

## Known Limitations

- This test covers summary reporting only, not profile interval recovery for
  `corpars$mu_sigma`.
- Larger covariance blocks remain planned and will need their own summary-row
  tests when implemented.

## Next Actions

1. Add profile-interval coverage for `corpars$mu_sigma` if the next slice
   focuses on confidence intervals.
2. Keep bivariate and structured covariance summary rows in separate tests so
   their parameter namespaces stay distinct.
