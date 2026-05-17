# After Task: Slice 154 random-effect scale parameter tables

## Goal

Pin the long-table helper contract for fitted random-effect scale model names
such as `sd(id)`.

## Implemented

`predict_parameters()` now has explicit coverage for `dpar = "sd(id)"`. The
test checks component `random-effect-sd-model`, row-label preservation,
response and link estimates, supplied `newdata` columns, and interval provenance
columns.

`marginal_parameters()` now has explicit coverage for averaging supplied
direct-SD prediction rows over an explicit grouping column. Roxygen and
generated Rd docs now name fitted random-effect scale model names such as
`sd(id)` as supported `dpar` values for the table helpers.

NEWS, the Phase 17 roadmap, and
`docs/design/39-visualization-grammar.md` now describe the same table-helper
contract.

## Mathematical Contract

This slice does not change the direct-SD model:

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha).
```

It records the table contract: `predict_parameters()` delegates the estimate to
`predict()`, stores direct-SD rows as component `random-effect-sd-model`, and
keeps interval provenance explicit. `marginal_parameters()` averages those
already-predicted direct-SD rows over supplied grouping columns.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/marginal-parameters.R`
- `R/predict-parameters.R`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-154-random-scale-parameter-tables.md`
- `man/marginal_parameters.Rd`
- `man/predict_parameters.Rd`
- `tests/testthat/test-marginal-parameters.R`
- `tests/testthat/test-predict-parameters.R`

## Checks Run

- No-edit scout before the slice showed that `predict_parameters()` and
  `marginal_parameters()` already worked with `dpar = "sd(id)"`, produced
  component `random-effect-sd-model`, preserved row labels, respected
  link/response scale, and averaged supplied rows.
- `air format R/predict-parameters.R R/marginal-parameters.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md tests/testthat/test-predict-parameters.R tests/testthat/test-marginal-parameters.R`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/predict_parameters.Rd` and `man/marginal_parameters.Rd`.
- `Rscript -e "devtools::test(filter = 'predict-parameters|marginal-parameters', reporter = 'summary')"`:
  initially failed because the test compared unnamed long-table estimates to
  named `predict()` vectors; after comparing numeric values and checking row
  labels separately, it passed.
- `Rscript -e "devtools::test(filter = 'predict-parameters|marginal-parameters|prediction-grid|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 154 direct-SD table-helper wording
  found expected entries in source, tests, generated Rd files, rendered
  reference pages, NEWS, ROADMAP, and rendered pkgdown NEWS/ROADMAP pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, direct-SD
  confidence intervals, bivariate random-effect scale prediction,
  `sd_sigma*()` syntax, or transformed-response support found no new false
  support claims; matches were existing Family B guardrails.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-032001-codex-checkpoint.md`.

## Tests Of The Tests

The `predict_parameters()` test checks both response and link rows against
direct `predict()` calls and separately checks row labels because the long-table
estimate column is intentionally numeric, not named. The `marginal_parameters()`
test compares the returned grouped means to an independent aggregation of the
long prediction table.

## Consistency Audit

The behavior was already available through `predict_parameters()` delegating to
`predict()` and `drm_dpar_component()` classifying `sd(...)` names. This slice
makes the contract visible in tests, Rd docs, NEWS, ROADMAP, and the
visualization-grammar note without changing formula grammar, likelihood
parameterization, fitted coefficients, or object structure.

## What Did Not Go Smoothly

The first focused test run failed because the test compared unnamed long-table
estimates with named vectors returned by `predict()`. The fix was to compare
numeric estimates with `unname()` and keep row-label checks explicit.

## Team Learning

Pat should keep row labels explicit in long prediction tables. Curie should
expect table helpers to drop vector names from numeric estimate columns and test
labels in their own column. Rose should keep point-estimate table support
separate from unsupported direct-SD uncertainty intervals and random-effect
scale `emmeans`.

## Known Limitations

- This slice pins point-estimate table helpers for fitted direct-SD model names.
- It does not add random-effect scale `emmeans`, direct-SD uncertainty
  intervals, bivariate random-effect scale prediction surfaces, empirical
  weighting beyond the existing marginal helper, `sd_sigma*()` syntax,
  transformed-response support, or new random-effect scale model families.

## Next Actions

Consider a small reader-facing example for `predict_parameters(..., dpar =
"sd(id)")` only if the direct-SD prediction lane needs tutorial polish before
moving on.
