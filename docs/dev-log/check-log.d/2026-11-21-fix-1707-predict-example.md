# Check log — 2026-11-21 — fix #1707 predict.drmTMB Rd example

## Change

- `R/methods.R`: replace pathological six-row `predict.drmTMB` / `sigma.drmTMB` examples with seeded `n = 120` Gaussian location-scale simulation (`set.seed(20261110)`).

## Verification

- `testthat::test_file("tests/testthat/test-fix-1707-predict-example.R")`