# 2026-11-11 — fix #1698 coef/fixef dpar exact match

## Goal

Align `coef()` / `fixef()` with `predict()` on exact `dpar` names; no `match.arg()` partial matching.

## Evidence

- Issue #1698 MRE: `coef(fit, dpar = "s")` silently returned sigma on pre-fix `main`.
- Added `tests/testthat/test-fix-1698-coef-dpar-exact.R`.
- Shared helpers in `R/utils.R`: `drm_resolve_fitted_dpar_name()`.

## Commands

```sh
export R_LIBS_USER=$HOME/R/x86_64-pc-linux-gnu-library/4.3
cd /agent/repos/drmTMB
Rscript -e '.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths())); pkgload::load_all(); testthat::test_file("tests/testthat/test-fix-1698-coef-dpar-exact.R")'
Rscript -e '.libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths())); pkgload::load_all(); testthat::test_file("tests/testthat/test-sd-selector-contract.R")'
```
