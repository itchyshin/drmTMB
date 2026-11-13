# Check log: unknown nlminb control warning (#1734)

**Date:** 2026-11-12  
**Branch:** `cursor/unknown-control-warning-6813`

## Change

- `drm_suggest_closest_name()` and `drm_nlminb_control_names()` in `R/utils.R`.
- `drm_sanitize_nlminb_controls()` in `R/control.R`; called from `drm_control()` for `optimizer_method = "nlminb"`.
- Unknown optimizer settings are dropped before `nlminb()` so only the classed drmTMB warning fires.
- Tests: `tests/testthat/test-fix-1734-unknown-optimizer-control.R`.

## Verification

```sh
export R_LIBS_USER=~/R-library
Rscript -e '
.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
pkgload::load_all("/agent/repos/drmTMB", quiet = TRUE)
testthat::test_file("tests/testthat/test-fix-1734-unknown-optimizer-control.R")
'
```

| Tree | Result |
| --- | --- |
| `main` (pre-fix) | `expect_warning(..., class = "drmTMB_unknown_optimizer_control")` **fails**; only `nlminb` generic warning |
| branch | **3 tests, 7 expectations, 0 failures** |

Capability ledger: not touched (`R/drmTMB.R` unchanged).
