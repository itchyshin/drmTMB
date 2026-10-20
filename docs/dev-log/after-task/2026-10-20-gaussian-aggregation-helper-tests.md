# After task: direct tests for Gaussian aggregation helpers

## What changed

- New `tests/testthat/test-gaussian-aggregation-helpers.R` calls the internal
  helpers in `R/gaussian-aggregation.R` directly (`drmTMB:::`). Before this,
  only `drm_gaussian_aggregation_parity()` was called by name; the other
  helpers were reached only through `drmTMB()`.
- Coverage: aggregated vs full-row log-likelihood at four coefficient points
  (1e-8); `row_to_cell`, `cell_first_row`, `n`, `sum_y`, `mean_y`, `css`
  against `tapply`/`aggregate`; first-appearance cell order; offsets splitting
  cells that share `X`; every `cli_abort` branch of the input and weight
  validators; parity coefficient-length errors; `empty_gaussian_aggregation()`;
  `drm_gaussian_aggregation_summary()`; `drm_gaussian_aggregation_tmb_data()`.
- Non-unit weights: the aggregation path refuses them (unit weights only), so
  the test asserts that refusal rather than weighted equivalence.
- No end-to-end fit is added: `test-gaussian-aggregation.R` already asserts
  logLik (1e-6), coefficients and vcov agreement between the default and
  `aggregate_gaussian = TRUE` fits.

## Behaviour

No R/, C++, NAMESPACE, NEWS or snapshot change. No `skip_*` is used, so the
env-skip census is unchanged.

## Verification

- `devtools::test(filter = "gaussian-aggregation")`: FAIL 0, WARN 0, SKIP 0,
  PASS 136.
- No helper bug was found, so no characterisation test is skipped.
