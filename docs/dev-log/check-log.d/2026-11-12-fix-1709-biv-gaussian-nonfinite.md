# Check log: bivariate Gaussian non-finite responses and designs (#1709)

**Date:** 2026-11-12
**Branch:** `cursor/fix-1709-biv-gaussian-nonfinite-9b36`

## Change

After the bivariate Gaussian responses are built, an observed `y1` or `y2`
that is not finite aborts with "Gaussian models require finite observed
response values." and names `y1` or `y2`. After `X_mu1`, `X_mu2`,
`X_sigma1`, `X_sigma2`, and `X_rho12` are built, each matrix goes through
`drm_abort_if_nonfinite_fit_design()`. `NA` and `NaN` responses stay on the
complete-case path. The univariate Gaussian sentences and calls are
unchanged.

## Failure on main

`R/drmTMB.R` at `98717b68c`. Direct probes and
`tests/testthat/test-fix-1709-biv-gaussian-nonfinite.R`:

| Case | Result on main |
| --- | --- |
| `Inf` in `y1` | `simpleError`: `NA/NaN/Inf in 'y'` |
| `-Inf` in `y2` | `simpleError`: `NA/NaN/Inf in 'y'` |
| `Inf` in predictor `x` | `simpleError`: `NA/NaN/Inf in 'x'` |
| `Inf` in `sigma1` predictor `z` | `drmTMB()` failed in all `nlminb()` optimizer preset attempts (`NA/NaN gradient evaluation`); the message does not name `z` or `sigma1` |
| `NA` and `NaN` in `y1` | passed (`nobs` 19) |

The three `Inf` tests in the file errored on main because the condition was
not `rlang_error`. The `NA`/`NaN` test passed.

## Verification with the fix

R 4.3.3, TMB 1.9.25, `pkgload::load_all(compile = FALSE)`.

- New file: 5 tests, 0 failures, 0 errors, 16 expectations.
- `test-fix-1697-gaussian-nonfinite.R`: 3 tests, 0 failures, 5 expectations.

No exported function, default, or formula token changed. No C++ rebuild.
