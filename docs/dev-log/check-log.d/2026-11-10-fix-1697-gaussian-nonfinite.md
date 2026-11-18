# Check log: Gaussian non-finite guards (#1697)

**Date:** 2026-11-10  
**Branch:** `cursor/fix-1697-gaussian-nonfinite-0a44`

## Change

- `drm_build_gaussian_ls_spec()`: `is.finite()` check on observed responses (matches Student-t wording).
- After `X_mu` / `X_sigma`: `drm_abort_if_nonfinite_fit_design()` names offending design columns before `gaussian_ls_start()` / TMB.
- Tests: `tests/testthat/test-fix-1697-gaussian-nonfinite.R`.

## Verification

```sh
R_LIBS_USER=~/R/x86_64-pc-linux-gnu-library/4.3 Rscript -e '
.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
pkgload::load_all("/agent/repos/drmTMB", quiet = TRUE)
testthat::test_file("tests/testthat/test-fix-1697-gaussian-nonfinite.R")
'
```

Pre-fix (main behaviour): 2 FAIL — Inf in `y` / `x` surfaced `stats::lm.fit` `simpleError`, not `rlang_error` with drmTMB wording; 3 PASS on NA/NaN drop.

Post-fix: all 5 expectations PASS; typed `class = "rlang_error"`.
