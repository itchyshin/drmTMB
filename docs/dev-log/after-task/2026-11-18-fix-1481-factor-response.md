# After task: refuse a factor response for Gaussian, Student-t, and skew-normal (#1481)

Reader: someone who passed a factor or ordered column as `y`.

## Task goal

Those three builders fitted the integer level codes and did not say so.
Binomial already refuses a factor response. These three should abort and
name the column. A numeric response should still fit.

## Files

- `R/drmTMB.R` (`drm_abort_factor_location_response` and three call sites)
- `tests/testthat/test-fix-1481-factor-response.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-18-fix-1481-factor-response.md`

## Checks

`pkgload::load_all()` then
`testthat::test_file("tests/testthat/test-fix-1481-factor-response.R")`.

Before: FAIL 4, PASS 2. After: FAIL 0, WARN 0, PASS 6.

## Consistency

The abort is only in the three builders named in the issue. Cumulative
logit still accepts an ordered factor. Poisson and the other families are
unchanged. No likelihood or formula-grammar change for numeric responses.

## Tests of the tests

The expectations require class `drmTMB_factor_response` and, for Gaussian,
the column name `y`. Before the abort those fits returned a `drmTMB` object,
so `expect_error` failed.

## What did not go smoothly

Nothing. The four factor fits completed on `main` with no error, which is
the bug.

## Design, pkgdown, and issues

No design-doc or pkgdown change. The issue stays open (`refs #1481`).

## Limits

A character response still follows the existing numeric-coercion path.
Other families are not covered by this change.
