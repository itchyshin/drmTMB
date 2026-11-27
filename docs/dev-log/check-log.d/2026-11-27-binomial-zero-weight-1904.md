# Check log — 2026-11-27 — binomial weight 0 off AD tape (#1904)

## Change

- `src/drmTMB.cpp` (`model_type == 18`): skip the row likelihood and the
  binomial `mi()` two-point mixture when `asDouble(weights(i)) == 0`, matching
  the Gaussian `#1459` pattern (`0 * (-Inf)` must not enter the tape).
- `R/drmTMB.R` (`binomial_start()`): `stats::glm.fit()` now uses
  `weights = weights_model` on positive-weight observed rows only (fixes bad
  `nlminb` starts when a zero-weight row was still in the unweighted GLM start).

## Verification

- `testthat::test_file("tests/testthat/test-binomial-zero-weight-1904.R")`