# 2026-11-18 — fix #1730 non-finite designs outside Gaussian, Student-t, and skew-normal

## Scope

`drm_abort_if_nonfinite_fit_design()` now runs on the fixed-effect matrices
for Gamma, Tweedie, beta, zero-one beta, beta-binomial, binomial,
cumulative logit, Poisson, nbinom2, and truncated nbinom2, immediately
after each matrix is built. Optional `zi` and `hu` matrices are unchanged.
`NA` predictors are still removed before this check.

## Evidence

`tests/testthat/test-fix-1730-family-nonfinite.R` before the calls: FAIL 22,
ERR 1, PASS 8. `Inf` in `mu` reached the `nlminb` preset abort for the
families in the issue title, and a zero-one beta fit returned instead of
aborting. `Inf` in a Gamma `sigma` predictor did not name `z`.

After the calls: FAIL 0, ERR 0, PASS 45. No exported default, estimand, or
convergence rule changed.
