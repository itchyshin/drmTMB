# Check log: factor location responses (#1481)

**Date:** 2026-11-18
**Branch:** `cursor/fix-1481-factor-response-45e2`

## Change

`drm_build_gaussian_ls_spec()`, `drm_build_student_ls_spec()`, and
`drm_build_skew_normal_ls_spec()` passed a factor response through
`as.numeric()`, which uses the integer level codes. They now abort with
class `drmTMB_factor_response` and name the column. Ordered factors are
factors, so they take the same abort. A numeric response is unchanged.

## Verification

`tests/testthat/test-fix-1481-factor-response.R`

Before: FAIL 4. Gaussian, Student-t, skew-normal, and an ordered Gaussian
response each fitted with no error. PASS 2 on a numeric Gaussian fit.

After: FAIL 0, WARN 0, PASS 6.
