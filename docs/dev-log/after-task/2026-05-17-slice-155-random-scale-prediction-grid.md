# After Task: Slice 155 random-effect scale prediction-grid chain

## Goal

Pin the helper chain from `prediction_grid()` through direct-SD
`predict_parameters()` and `marginal_parameters()`.

## Implemented

`prediction_grid()` now has explicit integration coverage for direct-SD
predictors. The test fits a Gaussian model with `sd(id) ~ w`, builds a grid over
`w`, passes that grid to `predict_parameters(..., dpar = "sd(id)")`, and then
averages the same grid with `marginal_parameters(..., by = "w")`.

NEWS, the Phase 17 roadmap, and
`docs/design/39-visualization-grammar.md` now describe the same helper-chain
contract.

## Mathematical Contract

This slice does not change the direct-SD model:

```text
log(sd_id,g) = W_g alpha,
sd_id,g = exp(W_g alpha).
```

It records the workflow contract: `prediction_grid()` may construct explicit
direct-SD predictor grids, `predict_parameters()` may turn those grids into
long point-estimate tables, and `marginal_parameters()` may average the already
predicted direct-SD rows over explicit grouping columns.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-155-random-scale-prediction-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-033432-codex-checkpoint.md`
- `tests/testthat/test-prediction-grid.R`

## Checks Run

- No-edit scout before the slice showed `prediction_grid()` already accepted
  direct-SD predictor `w` as a focal or conditioned predictor.
- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md tests/testthat/test-prediction-grid.R`:
  passed.
- `Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|marginal-parameters|reference-grid-link-scale-contract', reporter = 'summary')"`:
  passed.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed.
- Positive source/rendered scan for Slice 155 helper-chain wording found the
  expected entries in source files, tests, and rendered pkgdown NEWS/ROADMAP
  pages.
- Stale-claim scan for accidental random-effect scale `emmeans`, direct-SD
  confidence intervals, bivariate random-effect scale prediction,
  `sd_sigma*()` syntax, transformed-response support, or `prediction_grid()`
  uncertainty claims found no new false support claims; matches were existing
  Family B guardrails.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-033432-codex-checkpoint.md`.

## Tests Of The Tests

The test checks the whole point-estimate chain rather than only one helper:
`prediction_grid()` produces the `w` grid, `predict_parameters()` returns
direct-SD rows with component `random-effect-sd-model`, and
`marginal_parameters()` returns one averaged row per `w` value.

## Consistency Audit

The behavior was already available because `prediction_grid()` includes
predictors from fitted direct-SD terms and the table helpers delegate to
`predict()`. This slice makes that workflow visible in tests, NEWS, ROADMAP,
and the visualization-grammar note without changing formula grammar, likelihood
parameterization, fitted coefficients, or object structure.

## What Did Not Go Smoothly

Nothing material. The scout confirmed the helper chain before edits.

## Team Learning

Pat should keep direct-SD helper examples grid-first so users can inspect the
estimand before averaging. Curie should keep integration tests that cross helper
boundaries once individual helper contracts are pinned. Rose should keep point
prediction grids separate from unsupported uncertainty, `emmeans`, and bivariate
direct-SD claims.

## Known Limitations

- This slice pins point-estimate helper-chain support for direct-SD predictors.
- It does not add random-effect scale `emmeans`, direct-SD uncertainty
  intervals, bivariate random-effect scale prediction surfaces, empirical
  weighting beyond the existing marginal helper, `sd_sigma*()` syntax,
  transformed-response support, or new random-effect scale model families.

## Next Actions

Consider one short tutorial example only if the direct-SD prediction lane needs
reader-facing polish before moving to another validation area.
