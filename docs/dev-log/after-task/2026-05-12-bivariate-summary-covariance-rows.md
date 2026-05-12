# After Task: Bivariate Summary Covariance Rows

## Goal

Lock down the user-facing summary table for the first implemented bivariate
group-level covariance slice without adding new covariance machinery.

## Implemented

Added a focused `summary()` regression test for a bivariate Gaussian model with
matching labelled `mu1` and `mu2` random intercepts:

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

The test checks that `summary(fit)$parameters` includes the two group-level SD
rows, the group-level `mu1`/`mu2` correlation row, and the residual `rho12` row.
It also checks that the group-level correlation term does not contain `rho12`,
so the summary table keeps individual-average covariance separate from residual
response-response coupling.

## Files Changed

- `tests/testthat/test-summary.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-12-bivariate-summary-covariance-rows.md`

## Checks Run

- `air format tests/testthat/test-summary.R`: passed.
- `Rscript -e "devtools::test(filter = 'summary')"`: passed with 43
  expectations, 0 failures, 0 warnings, and 0 skips.

## Consistency Audit

No likelihood, parser, extractor, or documentation behavior changed. This slice
only adds coverage for a summary surface that already comes from
`profile_targets()` and the fitted `sdpars$mu`, `corpars$mu`, and residual
`rho12` values.

## Next Actions

1. Push this as a small PR and let the three-platform `R-CMD-check` matrix run.
2. Keep the next covariance implementation slice separate from this summary
   coverage slice.
