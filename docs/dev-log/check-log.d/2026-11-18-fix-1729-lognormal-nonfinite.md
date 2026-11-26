# 2026-11-18 — fix #1729 lognormal non-finite designs

## Scope

`drm_build_lognormal_ls_spec()` calls `drm_abort_if_nonfinite_fit_design()`
on `X_mu` and `X_sigma` immediately after those matrices are built. `NA`
predictors are still removed before this check.

## Evidence

`tests/testthat/test-fix-1729-lognormal-nonfinite.R` before the calls:

- `Inf` in `mu` reached `stats::lm.fit`: `NA/NaN/Inf in 'x'` (not `rlang_error`).
- `Inf` in `sigma` reached the `nlminb` preset abort and did not name `z`.
- `NA` in a predictor still reported `nobs` 23.

After the calls the file passes. No exported default, estimand, or
convergence rule changed.
