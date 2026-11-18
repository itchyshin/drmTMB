# Check log: Student-t and skew-normal non-finite designs (#1710)

**Date:** 2026-11-12
**Branch:** `cursor/fix-1710-student-skew-nonfinite-9b36`

## Change

`drm_abort_if_nonfinite_fit_design()` now takes `family`, default
`"Gaussian"`. The Gaussian sentence is still "Gaussian models require
finite fixed-effect design values." Student-t and skew-normal call it on
`X_mu`, `X_sigma`, and `X_nu` immediately after those matrices are built,
before starting values and `nlminb`. `NA` predictors are still removed by
`complete.cases()` / `na.omit` and never reach this check.

## Failure on main

`R/drmTMB.R` at `98717b68c`, file
`tests/testthat/test-fix-1710-student-skew-nonfinite.R`.

| Test | Result on main |
| --- | --- |
| student #1710: Inf in a mu predictor aborts and names the column | `stats::lm.fit`: `NA/NaN/Inf in 'x'` (simpleError, not `rlang_error`) |
| student #1710: Inf in a sigma predictor aborts and names the column | `drmTMB()` failed in all `nlminb()` optimizer preset attempts (`NA/NaN gradient evaluation`); the message does not name `z` or `sigma` |
| student #1710: Inf in a nu predictor aborts and names the column | same optimizer abort; the message does not name `z` or `nu` |
| skew-normal #1710: Inf in a mu predictor aborts and names the column | `stats::lm.fit`: `NA/NaN/Inf in 'x'` |
| skew-normal #1710: Inf in a sigma predictor aborts and names the column | same optimizer abort |
| skew-normal #1710: Inf in a nu predictor aborts and names the column | same optimizer abort |
| student #1710: NA in a predictor stays dropped | passed (`nobs` 19) |
| skew-normal #1710: NA in a predictor stays dropped | passed (`nobs` 19) |

## Verification with the fix

R 4.3.3, TMB 1.9.25, `pkgload::load_all(compile = FALSE)`.

- New file: 8 tests, 0 failures, 0 errors, 26 expectations.
- `test-fix-1697-gaussian-nonfinite.R`: 3 tests, 0 failures, 5 expectations.
- A Gaussian `Inf` predictor still aborts with "Gaussian models require finite fixed-effect design values." and names column `x` for `dpar = "mu"`.

No exported function, default, or formula token changed. No C++ rebuild.
