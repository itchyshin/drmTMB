# Check log: formula NaNs drop response rows but not weights (#1725)

**Date:** 2026-11-12
**Branch:** `cursor/fix-modelframe-weight-rows-9b36`

## Change

`complete.cases()` only sees columns named in the formula. `log(x)` or
`sqrt(x)` of a non-positive value becomes `NaN` inside
`model.frame(..., na.action = na.omit)`, so the response and design lose
those rows while the weight vector, known sampling covariance, and random-effect
data stayed at the pre-transformation length. The likelihood then used
`head(weights, nobs)`.

`drm_apply_model_frame_rows()` runs after each family's model frames and before
the response is extracted. When every distributional frame keeps the same
rows, it subsets `data_model`, `weights_model`, `keep`, and, for Gaussian and
bivariate Gaussian, the known sampling covariance. When the frames keep
different rows, it aborts with class `drmTMB_model_frame_rows`. The existing
"Internal model-frame mismatch" checks stay in place.

## Failure on main

`R/drmTMB.R` at `98717b68c`, test file
`tests/testthat/test-fix-modelframe-weight-rows.R`.

The six-row Poisson fixture in #1725 (`count` 1, 0, 3, 2, 1, 4; `x` 0.5, -1,
1.2, 0.8, -0.3, 1.5; weights 4, 1, 0.25, 1, 1, 2) gives `nobs` 4, weight
length 6, and log-likelihood -7.457925 against the retained-row `dpois`
reference -8.95574. `is_converged()` errors with
`(subscript) logical subscript too long`. The issue body matches that
reprex; no correction comment was needed.

On that same `R/drmTMB.R`, the new file reported:

| Test | Result on main |
| --- | --- |
| poisson log() rows keep the weights of the retained rows | failed (weight length 6 vs 4; logLik -7.5 vs -9.0) and `is_converged()` errored |
| gaussian log() on both formulas uses retained-row weights | failed (stored weights are not the retained-row weights) |
| formulas that drop different transformed rows abort with a row-count error | errored with `Internal model-frame mismatch between mu and sigma` |
| a random intercept follows rows dropped by log() | errored in `aggregate.data.frame`: arguments must have same length |
| gaussian meta_V follows rows dropped by log() | failed (known `V` and log-likelihood do not match the pre-dropped fit) |
| log() of strictly positive x still weights every row | passed |

## Verification with the fix

`pkgload::load_all(compile = FALSE)` on R 4.3.3, TMB 1.9.25. The new file:
6 tests, 0 failures, 0 errors, 18 expectations passed.

Nearby files, 0 failures and 0 errors:

- `test-fix-1697-gaussian-nonfinite.R` (3 tests, 5 expectations)
- `test-missing-response-gaussian.R` (4 tests, 52 expectations)
- `test-binomial-response.R` (5 tests, 60 expectations)
- `test-student-location-scale.R` (6 tests, 47 expectations)
- `test-missing-response-continuous.R` (6 tests, 181 expectations)
- `test-gamma-location-scale.R` (7 tests, 76 expectations)
- `test-meta-known-v.R` (15 tests, 84 expectations)
- `test-poisson-mean.R` (14 tests, 138 expectations)
- `test-gaussian-location-scale.R` with `NOT_CRAN=true` (11 tests, 80 expectations, 0 skipped)
- `test-offset-families.R` with `NOT_CRAN=true` (9 tests, 29 expectations, 0 skipped)

No C++ rebuild. No exported function, default, or formula token changed.
