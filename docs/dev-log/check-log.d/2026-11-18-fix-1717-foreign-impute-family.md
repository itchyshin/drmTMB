# Check log: foreign imputation family (#1717)

**Date:** 2026-11-18
**Branch:** `cursor/fix-1717-foreign-impute-family-45e2`

## Change

`drm_impute_family_type()` sent a stats `family` object named `nbinom2` or
`beta` to the generic unsupported-family abort, which then listed
`nbinom2()` and `beta_family()` as supported. `drm_abort_foreign_impute_family()`
now names `drmTMB::<constructor>()` and uses class
`drmTMB_foreign_impute_family`. `nbinom2()` (a `drm_family`) is unchanged.

## Verification

`tests/testthat/test-fix-1717-foreign-impute-family.R`

Before: FAIL 2. The abort was `Unsupported missing-predictor family "nbinom2"`
(and `"beta"`), and the hint listed `nbinom2()` as supported. Class was not
`drmTMB_foreign_impute_family`. PASS 2 on `nbinom2()`.

After: FAIL 0, WARN 0, PASS 5.
