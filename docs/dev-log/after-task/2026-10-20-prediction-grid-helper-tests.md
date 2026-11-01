# After task: prediction-grid helper tests

Reader: a maintainer changing `R/prediction-grid.R`.

- Added `tests/testthat/test-prediction-grid-helpers.R`: fit-free direct tests
  (`drmTMB:::`) of `validate_prediction_grid_n/terms/named_terms/list`,
  `prediction_grid_cast_values` (factor, Date, POSIXct, integer, numeric,
  logical, character branches), `prediction_grid_tz`,
  `prediction_grid_predictors` (fit-like list), `prediction_grid_values` and
  `prediction_grid_auto_values`.
- No fitted model is used; no `R/` change. Characterisation only.
- Not covered: `prediction_grid_reference_value`, `_expand`, `_mean_reference`,
  `_empirical`, `_condition_value`, `_attach_metadata`, and the exported
  `prediction_grid()` (they are outside this helper group or need a fit).
