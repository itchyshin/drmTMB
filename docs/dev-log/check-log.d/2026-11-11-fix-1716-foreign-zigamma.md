# 2026-11-11 — fix #1716 foreign ziGamma refusal

## Scope

`drm_family_type()` calls `drm_maybe_abort_foreign_inflation_family()` before
base stats-family routing so `glmmTMB::ziGamma()` and other foreign
zero-inflated / hurdle / truncated stats `family` objects cannot be silently
coerced to plain `Gamma(link = "log")` (or similar).

## Evidence

```text
export R_LIBS_USER=~/R/library
R CMD INSTALL . && Rscript -e 'library(testthat); library(drmTMB); test_file("tests/testthat/test-fix-1716-foreign-zigamma.R")'
fix-1716-foreign-zigamma: .......
PASS (2 tests, 7 expectations)
```
