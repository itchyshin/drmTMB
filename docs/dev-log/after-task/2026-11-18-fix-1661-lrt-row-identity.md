# After task: compare likelihood-ratio rows, not only the count (#1661)

Reader: someone comparing two `drmTMB` fits with `anova()` or `lrt_boundary()`.

## Task goal

Two fits can drop different rows and still report the same `nobs`. The
likelihood ratio then compares different data. Both guards should refuse
that pair. A pair on one row set, and a pair with different counts, should
keep their current behaviour.

## Files

- `R/model-comparison.R`
- `R/lrt-boundary.R`
- `tests/testthat/test-fix-1661-lrt-row-identity.R`
- `NEWS.md`
- `docs/dev-log/check-log.d/2026-11-18-fix-1661-lrt-row-identity.md`

## Checks

`pkgload::load_all()` then `testthat::test_file()` on
`test-fix-1661-lrt-row-identity.R`, `test-anova-lrt.R`, and
`test-lrt-boundary.R`.

- `test-fix-1661-lrt-row-identity.R`: before, FAIL 3 / PASS 7; after, FAIL 0, PASS 10.
- `test-anova-lrt.R`: FAIL 0, PASS 38.
- `test-lrt-boundary.R`: FAIL 0, PASS 62, SKIP 3 (CRAN and the Julia engine).

## Consistency

The count messages are unchanged. Row names come from `fit$data`, which is
the data frame after the complete-case filter. Same names in a different
order are accepted. A fit with no data frame is not compared, so a bridge
object that does not store one keeps the count-only guard.

## Tests of the tests

Before the guard the three `expect_error(..., class = "drmTMB_lrt_row_mismatch")`
calls failed because `anova()` and `lrt_boundary()` returned a statistic.
The shared-data `anova()` and the different-count errors already passed.

## What did not go smoothly

An intercept-only fit does not drop a row whose `NA` sits in an unused
covariate, so that pair has different `nobs` and never reaches the new
guard. The regression test puts the `NA` columns in both formulas and adds
one extra slope on one fit, so `nobs` matches and `df` does not.

## Design, pkgdown, and issues

No design-doc or pkgdown change. The issue stays open (`refs #1661`).

## Limits

Row identity is the row-name set. Two data frames that were rebuilt with
rownames `1:n` after dropping different positions still look alike.
