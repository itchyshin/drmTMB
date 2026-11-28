# After task: name the drmTMB constructor for a foreign imputation family (#1717)

Reader: someone who passed `glmmTMB::nbinom2()` or another stats `family`
object into `impute_model()`.

## Task goal

The imputation gate answered that family with "unsupported" and then listed
`nbinom2()` as supported. The message should say the object is not a drmTMB
family and name `drmTMB::nbinom2()` (or the matching constructor).

## Files

- `R/missing-data.R` (`drm_abort_foreign_impute_family`)
- `tests/testthat/test-fix-1717-foreign-impute-family.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-18-fix-1717-foreign-impute-family.md`

## Checks

`pkgload::load_all()` then
`testthat::test_file("tests/testthat/test-fix-1717-foreign-impute-family.R")`.

Before: FAIL 2, PASS 2. After: FAIL 0, WARN 0, PASS 5.

## Consistency

`drmTMB::nbinom2()` is still class `drm_family` and still returns
`"nbinom2"`. The response-family foreign-object guard is a separate open
change; this branch only covers the imputation classifier. No likelihood
or formula change.

## Tests of the tests

The new expectations ask for class `drmTMB_foreign_impute_family` and the
strings `not a drmTMB family` and `drmTMB::nbinom2()`. Those strings are
absent from the old unsupported-family abort, so the test failed before
the guard.

## What did not go smoothly

Nothing in the classifier. The helper that detects a namespace on
`variance()` lives on the open response-family branch, so this message uses
the no-namespace wording for every stats object, including one that came
from another package.

## Design, pkgdown, and issues

No design-doc or pkgdown change. The issue stays open (`refs #1717`).

## Limits

The message does not print `glmmTMB::` even when that package built the
object. It still names the drmTMB constructor to call.
