# 2026-11-26 residuals invalid `type` cli validation

- **Issue:** refs #1869
- **Change:** `residuals.drmTMB()` wraps `match.arg(type)` so invalid `type` values abort with `{.arg type} must be one of {.val ...}` (same pattern as #1864 / PR #1865 `predict()`).
- **Test:** `tests/testthat/test-residuals-type-invalid.R` (cbpp binomial reproducer; `deviance` / `working`).
- **Local:** `testthat::test_file("tests/testthat/test-residuals-type-invalid.R")` — 5 PASS.