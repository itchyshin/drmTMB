# After task: meta_vcov_bivariate() validator tests

Reader: a maintainer changing `R/meta-vcov.R` who needs its abort branches
pinned.

- Problem: `validate_meta_variance_vector()` and `validate_meta_pair_vector()`
  were exercised by no test directly, and several abort branches
  (non-numeric, matrix input, `Inf`, length-zero, zero variance with nonzero
  covariance) had no assertion.
- Fix: none. Test-only; `R/` is untouched.
- Tests: `tests/testthat/test-meta-vcov-validators.R` (validator pass-through
  and each abort message; cor12-to-cov12 conversion to 1e-12; size-1 and
  size-2 inputs; zero cov12 and cor12 give a block-diagonal matrix).
- Not done: no skips were needed, so the skip census is unchanged.
