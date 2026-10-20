# After task: emmeans preflight contract tests

Reader: a maintainer changing the emmeans guards in `R/emmeans-preflight.R`.

- Problem: `drm_emmeans_complete_model_frame`, `drm_emmeans_model_frame`,
  `drm_emmeans_misc`, `drm_emmeans_has_transformed_response`,
  `drm_has_random_scale_models` and `drm_validate_emmeans_mu_target` were never
  called by name in tests, and several `cli_abort()` branches were untouched.
- Change: test-only. `tests/testthat/test-emmeans-preflight-contract.R` pins each
  helper (real Gaussian fits, n = 120, plus fabricated `drmTMB`-classed lists
  where a fit cannot reach the branch) and hits every `cli_abort()` in the file.
  `inst/extdata/env-skip-census.tsv` gains the new file's rows (regenerated with
  `tools/write-env-skip-census.R`).
- Result: every assertion passed against the unchanged R code, so no bug was
  found and nothing is skipped. The fit drops unused factor levels from its own
  retained frame, so recovery keeps the fitted levels, not the data's.
- Not done: no R code, NAMESPACE, NEWS or ledger edits.
