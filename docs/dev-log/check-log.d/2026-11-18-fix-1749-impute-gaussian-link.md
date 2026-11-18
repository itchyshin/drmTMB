# Check log: Gaussian imputation link (#1749)

**Date:** 2026-11-18
**Branch:** `cursor/fix-1749-impute-gaussian-link-45e2`

## Change

`drm_impute_family_type()` aborted only the binomial, Gamma, and Poisson
imputation links. `gaussian(link = "log")` and `gaussian(link = "inverse")`
returned `"gaussian"` and were fitted on the identity scale. They now abort
with the identity-link message. `gaussian()` and `gaussian(link = "identity")`
still return `"gaussian"`.

## Verification

`tests/testthat/test-fix-1749-impute-gaussian-link.R`

Before the guard, with the rejection expectations in place: FAIL 2. Both
`impute_model(..., family = gaussian(link = "log"))` and
`drm_impute_family_type(gaussian(link = "inverse"))` returned without error.
The identity-link fit in that first run also failed, because the example
omitted `miss_control(predictor = "model")`; that call was corrected before
the after-fix run and is not part of the link bug.

After the guard: FAIL 0, WARN 0, PASS 6. The identity-link `mi(x)` fit converged.
