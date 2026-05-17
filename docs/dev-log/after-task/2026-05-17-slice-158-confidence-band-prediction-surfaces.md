# After Task: Slice 158 Confidence-Band Prediction Surfaces

## Goal

Add the first table-first confidence-band path for fitted distributional
parameter surfaces without making the plotting helper estimate uncertainty.

## Implemented

`predict_parameters(conf.int = TRUE)` now adds Wald fixed-effect intervals for
explicit `newdata` grids when the requested distributional parameter has an
ordinary fixed-effect basis. Supported rows receive `std.error`, `conf.low`,
`conf.high`, `conf.level`, `conf.status = "wald"`, and
`interval_source = "wald"`. Fitted-row requests that need a supplied grid report
`newdata_required`, and direct random-effect SD surfaces report
`wald_unavailable`.

`plot_parameter_surface()` now consumes explicit interval columns. It draws
confidence bands for continuous x-values, interval bars for discrete x-values,
and leaves rows without finite supported intervals as line or point estimates
only.

The model-workflow and model-map articles now show the table-first route:
`prediction_grid()` -> `predict_parameters(conf.int = TRUE)` ->
`plot_parameter_surface()`.

## Mathematical Contract

For supported fixed-effect prediction rows, the interval is a Wald interval on
the link scale:

```text
eta_hat_i = X_i beta_hat
se_eta_i = sqrt(X_i V_beta X_i')
eta_low_i = eta_hat_i - z_(1 - alpha/2) se_eta_i
eta_high_i = eta_hat_i + z_(1 - alpha/2) se_eta_i
```

For response-scale output, the endpoints are transformed through the fitted
inverse link. The reported `std.error` is a delta-method local standard error
on the output scale. These intervals are population-level fixed-effect
intervals for the supplied grid. They do not include random-effect mode
uncertainty, profile-likelihood uncertainty, bootstrap uncertainty, or derived
quantity uncertainty.

## Files Changed

- `R/predict-parameters.R`
- `R/plot-parameter-surface.R`
- `tests/testthat/test-predict-parameters.R`
- `tests/testthat/test-plot-parameter-surface.R`
- `man/predict_parameters.Rd`
- `man/plot_parameter_surface.Rd`
- `vignettes/model-workflow.Rmd`
- `vignettes/model-map.Rmd`
- `docs/design/39-visualization-grammar.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/recovery-checkpoints/2026-05-17-053925-codex-checkpoint.md`

## Checks Run

- `air format` on changed R, test, roadmap, NEWS, design, and vignette files:
  passed.
- `Rscript -e 'devtools::document()'`: passed; regenerated
  `man/predict_parameters.Rd` and `man/plot_parameter_surface.Rd`.
- `Rscript -e 'devtools::test(filter = "predict-parameters|plot-parameter-surface", reporter = "summary")'`:
  passed with all focused checks.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `git diff --check`: passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-map.Rmd", output_dir = tempfile("model-map-render-"), quiet = FALSE)'`:
  passed.
- `Rscript -e 'pkgdown::build_site(preview = FALSE)'`: passed and rendered
  `ROADMAP.html`, `reference/predict_parameters.html`,
  `reference/plot_parameter_surface.html`, `articles/model-workflow.html`,
  `articles/model-map.html`, and `news/index.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- Rendered-site scans found the new `predict_parameters(conf.int = TRUE)`,
  `conf.level`, confidence-band, and revised Phase 17 runway wording.
- Stale-wording scans for obsolete interval-ribbon wording found only historical
  check-log and after-task notes from earlier slices.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-05-17-053925-codex-checkpoint.md`.

## Tests Of The Tests

The prediction-table tests compare Wald intervals against a direct manual
calculation from `drm_fixed_effect_basis(..., covariance = TRUE)`.

The plot tests include both a hand-built interval table and a real
`predict_parameters(conf.int = TRUE)` table, so the band layer is tested through
the same public table path readers will use. Negative checks confirm
`not_available` rows remain interval-free and random-effect SD prediction rows
report unavailable Wald intervals.

The newdata collision test confirms user-supplied columns named like interval
columns are preserved as `newdata_*` columns rather than overwriting the
prediction-table contract.

## Consistency Audit

The source and rendered docs now agree that prediction-surface bands are
table-first: the table computes Wald fixed-effect intervals for supported
newdata rows, and the plotting helper only consumes explicit finite interval
columns. Historical notes that said `plot_parameter_surface()` did not draw
intervals remain in older after-task/check-log entries and were not edited.

The roadmap now records the corrected runway: Slices 159-202 are a
stabilization bridge before returning to Phase 17, not a direct jump into Phase
18 comprehensive simulation.

## What Did Not Go Smoothly

Two test expectations initially failed only because manually computed expected
vectors retained names while table columns did not. The expectations now compare
unnamed numeric values.

The first roadmap update incorrectly said to return to Phase 18 at Slice 203.
The user corrected this; the roadmap now says to return to Phase 17 after Slice
202 and defer Phase 18 until the resumed Phase 17 closure gate.

The random-slope status also needed sharper wording. The package can fit
multiple independent ordinary Gaussian `mu` slope terms and one correlated
intercept-plus-one-slope block, but it does not yet fit a full
`(1 + x1 + x2 + ... | id)` unstructured covariance block. Ordinary grouped
`mu` should have arbitrary numeric multi-slope covariance with constant
correlations, limited by diagnostics and computation rather than by the formula
grammar. The wider next boundary is a one-slope baseline for each supported
random-effect layer, with constant slope-related correlations during that first
expansion. That cap does not apply to the separate intercept-level
`corpair()` regression lane. Spatial has one coordinate `mu` slope, and
phylogenetic slopes remain planned.

## Team Learning

Ada kept the slice narrow: a plotting helper should not become an interval
engine. Fisher separated cheap fixed-effect Wald bands from direct profile and
future bootstrap intervals. Pat and Darwin pushed the model-workflow example to
show the figure path a reader will actually use. Grace required the rendered
pkgdown check because two articles and two reference pages changed. Rose flagged
the roadmap drift and the need for explicit "why unavailable" statuses before
comprehensive simulation.

## Known Limitations

This slice does not add profile-likelihood or bootstrap intervals to
`predict_parameters()`. It does not add intervals for direct random-effect SD
surfaces, conditional random-effect modes, derived variance ratios, q4 derived
correlations, covariance products, marginal means, contrasts, or slopes.

Wald prediction intervals are asymptotic fixed-effect intervals, not prediction
intervals for future observations and not full uncertainty intervals for
variance components or correlations.

## Next Actions

1. Finish confidence-band examples and boundary docs for Slice 159-163.
2. Revisit Phase 6/13 interval readiness, including profile-target inventory,
   derived interval statuses, and parametric-bootstrap design.
3. Revisit Gaussian double-hierarchical random-slope limits before claiming
   full double-hierarchical support, including the gap between current
   one-slope blocks and arbitrary ordinary grouped location random-slope syntax
   such as `(1 + x1 + x2 + ... | id)`. Keep slope-related correlations
   constant during the first expansion while leaving intercept-level
   `corpair()` regressions on their own design track.
4. Revisit non-Gaussian location-scale-shape and family gaps before returning
   to the remaining Phase 17 visualization, marginal-effect, contrast, slope,
   and reader-facing inference work after Slice 202. At least one phylogenetic
   `mu` slope is an explicit planning target, not an implemented feature.
