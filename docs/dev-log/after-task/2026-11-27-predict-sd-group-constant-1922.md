# After-task: predict SD group-constant check (#1922)

Applied ecologists fitting `sd(id, dpar = "sigma") ~ w` need `predict()` to enforce the same within-`id` constancy rule as `drmTMB()` at fit time.

`predict_random_scale_dpar()` now reuses `validate_sd_mu_group_constant()` when `newdata` carries the grouping column. Predictor-only grids without `id` are unchanged.

Evidence: `tests/testthat/test-zi-nbinom2-sigma-sd-regression.R` (issue #1922 repro plus one valid group-level row).