# Check log: likelihood-ratio row identity (#1661)

**Date:** 2026-11-18
**Branch:** `cursor/fix-1661-lrt-row-identity-45e2`

## Change

`drm_lrtest()` and `lrt_boundary()` compared only `nobs`. Two fits that drop
different rows but the same number of rows produced a likelihood-ratio
statistic. Both now compare the row names stored on `fit$data` after
complete-case filtering and abort with class `drmTMB_lrt_row_mismatch` when
the sets differ. A different count still uses the existing count message.

## Verification

`tests/testthat/test-fix-1661-lrt-row-identity.R`

Before: FAIL 3. `anova()` and `lrt_boundary()` returned a statistic for
subset rows 1–5 versus 6–10, and for an `NA` in `x1` versus an `NA` in `x2`,
with matching `nobs`. PASS 7 on a shared row set and on a different count.

After: FAIL 0, WARN 0, PASS 10 on the new file. `test-anova-lrt.R` PASS 38.
`test-lrt-boundary.R` PASS 62, SKIP 3 (CRAN and the Julia engine).
