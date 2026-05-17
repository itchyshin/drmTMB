# After Task: Slices 160-164 Confidence/Profile Bridge

## Goal

Continue the stabilization bridge through Slice 164: finish the first
confidence-band documentation block and refresh the profile-target inventory
before returning to deeper profile/bootstrap interval work.

## Implemented

Slice 160 adds a real factor-grid confidence-band test. The test fits a small
Gaussian model with a factor predictor, builds `prediction_grid(fit, focal =
"habitat")`, requests `predict_parameters(conf.int = TRUE, conf.level = 0.90)`,
and checks that `plot_parameter_surface(..., x = "habitat", line = FALSE)` uses
an error-bar layer. The model-workflow article now shows the same discrete-x
example.

Slice 161 adds a fitted-row interval-status example. When
`predict_parameters(fit, dpar = "mu", conf.int = TRUE)` is called without
`newdata`, the workflow prints `conf.status = "newdata_required"` and explains
that the next action is to build an explicit prediction row or grid.

Slice 162 adds a non-default confidence-level example and states the display
rule: `conf.level` is the requested level for an interval attempt and must be
read with `conf.status` and `interval_source`.

Slice 163 is the documentation gate for the confidence-band block. Focused
tests, model-workflow rendering, pkgdown build/check, `git diff --check`, stale
wording scans, and rendered-page scans passed.

Slice 164 refreshes the profile-target inventory in
`docs/design/12-profile-likelihood-cis.md`. The new table separates fixed
effects, constant distributional parameters, row-specific `newdata` profiles,
ordinary random-effect SD/correlation targets, modelled `sd(group)` surfaces,
bivariate q2 and q4 covariance rows, phylogenetic/spatial SDs, derived
summaries, and ordinal cutpoint internals.

## Mathematical Contract

No likelihood changed. The confidence-band contract remains:

```text
eta_hat_i = X_i beta_hat
se_eta_i = sqrt(X_i V_beta X_i')
eta_low_i = eta_hat_i - z_(1 - alpha/2) se_eta_i
eta_high_i = eta_hat_i + z_(1 - alpha/2) se_eta_i
```

Continuous x-values draw ribbons and discrete x-values draw interval bars when
the table contains finite supported interval bounds. Rows without a validated
interval source remain line-only or point-only.

The profile-target contract also did not change. A target is profile-ready only
when it maps to a direct current TMB parameter or linear combination and the
fit retained the TMB object. Row-specific scale and residual-correlation
profiles are generated from supplied `newdata`, while derived summaries remain
status-only.

## Files Changed

- `tests/testthat/test-plot-parameter-surface.R`
- `vignettes/model-workflow.Rmd`
- `docs/design/39-visualization-grammar.md`
- `docs/design/12-profile-likelihood-cis.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slices-160-164-confidence-profile-bridge.md`

## Checks Run

- `air format tests/testthat/test-plot-parameter-surface.R vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md docs/design/12-profile-likelihood-cis.md ROADMAP.md`: passed.
- `Rscript -e 'devtools::test(filter = "plot-parameter-surface|profile-targets", reporter = "summary")'`: passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`: passed.
- `Rscript -e 'pkgdown::build_site(preview = FALSE)'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `git diff --check`: passed.
- Stale wording scan returned no matches:
  `rg -n "ribbons remain planned|add interval ribbons later|point-estimate surfaces|does not draw intervals|leaves confidence intervals|conf\\.level.*success flag|newdata_required.*error|profile-target inventory.*planned only" README.md NEWS.md ROADMAP.md docs/design vignettes R man pkgdown-site --glob '!pkgdown-site/search.json' --glob '!docs/dev-log/**'`.
- Rendered-page scan confirmed source and rendered roadmap/article wording:
  `rg -n "Slice 160|Slice 161|Slice 162|Slice 163|Slice 164|newdata_required|conf.level = 0.9|interval bars|Refreshed Target Inventory" ROADMAP.md docs/design/39-visualization-grammar.md docs/design/12-profile-likelihood-cis.md vignettes/model-workflow.Rmd pkgdown-site/ROADMAP.html pkgdown-site/articles/model-workflow.html --glob '!pkgdown-site/search.json'`.

## Tests Of The Tests

The new Slice 160 test uses the public table path rather than a hand-built
plotting table: `prediction_grid()` -> `predict_parameters(conf.int = TRUE)` ->
`plot_parameter_surface()`. It checks the layer class and interval provenance,
so it would catch a regression where factor x-values were treated as ribbons or
where `conf.level` was lost.

The profile-target focused tests were rerun because Slice 164 changed the
target inventory documentation. No profile implementation changed.

## Consistency Audit

The source and rendered model-workflow article now agree on three reader
actions: build explicit grids for intervals, use interval bars for discrete
focal predictors, and treat `conf.level` as a requested level rather than proof
that an interval was computed.

The roadmap now says Slices 160-164 are closed as a confidence/profile bridge
and points next to Slice 165. The profile design note states that q4
correlations, derived summaries, modelled `sd(group)` fitted surfaces, ordinal
transformed summaries, and custom contrasts remain unavailable for direct
profile intervals.

## What Did Not Go Smoothly

Nothing material. The only mild risk was over-teaching confidence bands in the
workflow article; Pat kept the examples short and table-first.

## Team Learning

Ada kept the slices bundled on one stacked branch because they were all
documentation/test stabilization around the same interval surface. Pat checked
the workflow examples, Fisher checked interval interpretation, Grace owned the
docs gate, Rose checked roadmap continuity, Boole watched the API examples,
and Curie required the factor-grid test to use the public prediction-table
path. No spawned subagents were running.

## Known Limitations

No new interval estimator was added. Direct random-effect SD surfaces still do
not receive Wald bands. Derived q4 correlations and variance-ratio summaries
remain point-estimate/status rows only.

Slice 164 is an inventory refresh, not new profile support.

## Next Actions

1. Start Slice 165 by pinning row-specific profile examples for `sigma`,
   `sigma1`, `sigma2`, and `rho12`.
2. Keep profile examples small because profile CIs can be slow.
3. Preserve the same status vocabulary across `summary()`, `confint()`,
   `corpairs()`, and prediction tables.
