# 2026-11-20 — fix #1729 lognormal non-finite designs

## Scope

`drm_build_lognormal_ls_spec()` calls `drm_abort_if_nonfinite_fit_design()`
on `X_mu` and `X_sigma` immediately after those matrices are built.

## Evidence

`tests/testthat/test-fix-1729-lognormal-nonfinite.R`

Pre-fix: `Inf` in `mu` reached `lm.fit` (`NA/NaN/Inf in 'x'`).

Post-fix: file passes (3 tests, 11 expectations).