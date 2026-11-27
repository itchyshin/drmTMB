# 2026-11-27 — predict SD within-id constancy (#1922)

- **Change:** `predict_random_scale_dpar()` calls `validate_sd_mu_group_constant()` when `newdata` includes the random-effect grouping column.
- **Test:** `test-zi-nbinom2-sigma-sd-regression.R` — rejects observation-level varying `w` within `id`; group-constant row still predicts.
- **Local:** `testthat::test_file("tests/testthat/test-zi-nbinom2-sigma-sd-regression.R")` — FAIL 0, PASS 27.