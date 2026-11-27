# After-task — binomial zero-weight likelihood (#1904)

## Problem

A binomial fit with one `weights = 0` row still evaluated the row log-density
on the TMB tape as `weights(i) * loglik`, so `0 * (-Inf)` poisoned `fn`/`gr`
and coefficients diverged from `glm(..., weights = )` even though
`convergence_status` was already `"degenerate"`.

## Fix

In the binomial branch (`model_type == 18`), gate the main-loop density and the
missing-predictor `mi()` mixture on `asDouble(weights(i)) > 0`, consistent with
the documented weight-0 rule in `src/drmTMB.cpp` and Gaussian `#1459`. Weight-0
rows still report `mu` off-tape via `asDouble(eta)`.

`binomial_start()` now calls `glm.fit(..., weights = )` on positive-weight rows
only so `nlminb` starts on the same weighted GLM coefficients as `glm()`.

## Evidence

- Regression: `tests/testthat/test-binomial-zero-weight-1904.R` (issue fixture
  vs `glm()` on `logLik` and `coef`).

## Out of scope

Convergence thresholds, `nobs()` (#1699), ledger/fingerprint/estimand.