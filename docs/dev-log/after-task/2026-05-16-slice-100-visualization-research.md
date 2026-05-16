# After Task: Slice 100 Visualization Research

## Goal

Research the `ggplot2`, tidy Bayesian, marginal-effects, EMM, diagnostics, and
publication-figure ecosystem enough to define a Phase 17 visualization contract
for `drmTMB` without prematurely adding a plotting dependency or Bayesian
surface.

## Implemented

- Added `docs/design/39-visualization-grammar.md`.
- Updated `ROADMAP.md` so Phase 17 points to the Slice 100 design note and
  separates predictions, adjusted predictions, estimated marginal means,
  contrasts, slopes, and diagnostics as distinct estimands.
- Updated `vignettes/model-workflow.Rmd` to state that
  `predict_parameters()` and `marginal_parameters()` are current table
  surfaces for future visualization helpers, not current plotters.
- Updated `NEWS.md` with the design-note change.
- Used official package documentation for `ggplot2`, `tidybayes`, `ggdist`,
  `emmeans`, `ggeffects`, `marginaleffects`, `performance`, `DHARMa`,
  `patchwork`, and `viridis`.

## Mathematical Contract

No formula grammar, likelihood, TMB code, extractor, parameter transformation,
or fitted-model behaviour changed. Slice 100 is a design and documentation
slice. It keeps `sigma` as the public scale parameter, `rho12` as the residual
bivariate correlation parameter, and `corpairs()` as the correlation-row route
for residual, group-level, phylogenetic, spatial, and mean-scale correlation
layers.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md`:
  passed.
- `git diff --check`: passed.
- `LC_ALL=C rg -n '[^\x00-\x7F]' NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md`:
  returned no matches.
- `git diff -U0 -- NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  returned no matches in the Slice 100 patch.
- `Rscript -e "devtools::test(filter = 'predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed with 40 expectations across the focused prediction and marginal-table
  helpers.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `ROADMAP.html`, `articles/model-workflow.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `rg -n 'visualization-grammar|tables, not plotting functions|dependency-light|estimated marginal means|EM means|posterior draws|interval_source' NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md pkgdown-site/ROADMAP.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed the source and rendered site carry the intended Slice 100 wording,
  including the EMM terminology guard and interval-source contract.
- `rg -n 'plotting support|autoplot\\.drmTMB\\(\\).*export|tidybayes.*dependency|ggdist.*dependency|ggplot2.*Imports|EM means' NEWS.md ROADMAP.md DESCRIPTION docs/design vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  returned only intended design-boundary and terminology-guard matches, not a
  dependency or implemented-plotting claim.

## Tests Of The Tests

No new testthat tests were added because Slice 100 changes research notes,
roadmap prose, NEWS, and the model-workflow vignette only. The focused
`predict_parameters()` and `marginal_parameters()` tests were rerun because
the design note depends on those helpers as the current data surface.

## Consistency Audit

The design note, roadmap, NEWS, model-workflow source, and rendered pkgdown
pages now tell the same story:

- Phase 17 remains planned.
- `predict_parameters()` and `marginal_parameters()` are tables, not plotting
  helpers.
- Future plots should consume explicit data frames rather than hide grids,
  marginalization, scale choices, or uncertainty provenance.
- `tidybayes` and `ggdist` are inspirations for tidy uncertainty data and
  geoms, not new dependencies or Bayesian claims.
- Estimated marginal means are referred to as EMMs, not "EM means".

## What Did Not Go Smoothly

The first stale-wording scan intentionally matched the phrase "EM means" inside
the new guardrail sentence. I kept the guardrail because it directly records
the terminology correction, and I treated that match as expected evidence
rather than stale wording.

## Team Learning

- Ada: Phase 17 should begin with grid and data contracts before any
  `autoplot()`-style convenience layer.
- Pat: a beginner-friendly visual workflow should show raw data, then fitted
  distributional parameters, then interval status and diagnostics.
- Fisher: every visual interval needs `interval_source` or equivalent
  provenance before it is drawn.
- Rose: design notes should name external packages as lessons without turning
  them into dependencies or implemented claims.

## Known Limitations

- No plotting helper was implemented.
- No `emmeans`, `ggeffects`, or `marginaleffects` method was implemented.
- No uncertainty columns were added to `predict_parameters()` or
  `marginal_parameters()`.
- No ggplot-oriented dependency was added to `DESCRIPTION`.
- The design note does not decide exact exported function names for Phase 17.

## Next Actions

1. Design a `prediction_grid()` or equivalent helper for focal terms,
   conditioning, and marginalization.
2. Extend prediction or marginal tables with interval provenance only after
   the interval source is tested.
3. Add one narrow optional ggplot-oriented helper after the table contract is
   stable.
4. Revisit `emmeans` compatibility after the reference-grid and link-scale
   contract is tested across implemented families.
