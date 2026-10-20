# After task: predict/marginal validator tests

## What changed

- New `tests/testthat/test-predict-marginal-parameter-validators.R`: fit-free
  characterisation tests (via `drmTMB:::`) for the argument validators in
  `R/predict-parameters.R` and `R/marginal-parameters.R`, and for the helpers
  that take plain vectors or data frames:
  `validate_predict_parameters_newdata`, `_include_newdata`, `_conf_int`,
  `_conf_level`, `validate_marginal_parameters_newdata`,
  `marginal_parameters_by_columns`, `marginal_parameter_group_mean`,
  `predict_parameters_clamp_bent` (minimal stand-in object, no fit),
  `predict_parameters_link_se`, `predict_parameters_interval_unavailable`.
- Helpers that need a fitted drmTMB are not covered here.

## Behaviour

None. No `R/`, `NEWS.md`, `DESCRIPTION`, census or existing-test change. No
behaviour looked like a bug, so nothing was left out of the assertions.

## Verification

`devtools::load_all()` then `testthat::test_file()` on the new file:
FAIL 0, WARN 0, SKIP 0, PASS 114. The tests use no `skip_*`, so the env-skip
census is unchanged.
