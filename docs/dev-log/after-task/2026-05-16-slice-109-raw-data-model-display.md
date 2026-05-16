# After Task: Slice 109 Raw Data Model Display

## Goal

Turn the Phase 17 visualization landscape into concrete example rules for
reader-facing displays. The target was not a new plotting API; it was a safer
teaching pattern: show the observed response, then show fitted distributional
parameter surfaces from an explicit prediction table.

## Implemented

- Added raw-data-plus-model example rules to
  `docs/design/39-visualization-grammar.md`.
- Updated `vignettes/model-workflow.Rmd` so the plotting section first creates
  `pred_temperature` with `predict_parameters()`.
- Added separate examples for an observed-response scatter plot, a fitted `mu`
  surface, and a fitted `sigma` surface.
- Warned readers not to place raw response points on `sigma`, `sigma^2`,
  `rho12`, random-effect SD, or correlation axes.
- Clarified that future ribbons or shaded regions need a real
  `interval_source`, not `interval_source = "not_available"`.
- Updated NEWS and ROADMAP with the Slice 109 display-rule contract.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-109-raw-data-model-display.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-163605-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd`:
  passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated model-workflow article, ROADMAP, and NEWS.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n "Slice 109|raw-data-plus-model|observed-response scale|Fitted mean growth|Fitted residual SD|interval_source|not place raw response|Raw-Data-Plus-Model" NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages carry the Slice 109 display rules.
- `rg -n "plot_corpairs\\(|plot_diagnostics\\(|plot_simulation_summary\\(|autoplot\\.drmTMB|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|posterior draw|credible interval" NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd DESCRIPTION pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only intended planned-name, design-inspiration, and
  confidence-not-credible-interval guardrails.
- `Rscript tools/codex-checkpoint.R --goal "Slice 109 raw-data-plus-model display rules" --next "stage, commit, push stacked branch after Slice 108 PR #72 is green and merged; then open Slice 109 PR"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-163605-codex-checkpoint.md`.

## What Did Not Change

- No plotting helper was exported.
- No dependency, R API, likelihood, formula grammar, or TMB code changed.
- No interval ribbon, `corpairs()` plot, diagnostics plot, EMM, contrast, slope,
  or simulation plot was added.

## Team Learning

- Ada: this slice belongs between the first plot helper and later visual
  extensions because it tells future helpers what examples must preserve.
- Pat: applied readers need to see the observed response before interpreting a
  smooth fitted surface.
- Jason: the useful landscape lesson is the display grammar, not new package
  dependencies.
- Fisher: ribbons and shaded intervals need a real interval source before they
  appear in examples.
- Grace: rendered article scans are needed because code examples can succeed
  while the reader-facing wording still overclaims.
- Rose: the next slice can now choose whether to improve labels for the current
  plot helper or start a narrow interval-status display, but it should not jump
  to broad `autoplot()` behaviour.

## Known Limitations

- The example still uses separate figures rather than a composed multi-panel
  display helper.
- `plot_parameter_surface()` still plots point estimates only.
- Interval displays, `corpairs()` plots, diagnostics plots, EMMs, contrasts,
  slopes, and simulation plots remain future work.

## Next Actions

1. Consider whether `plot_parameter_surface()` should label y-axes from `dpar`
   when a single parameter is plotted.
2. Add `corpairs()` plotting only after correlation rows have consistent
   interval status.
3. Keep any future raw-data overlay helper separate from `sigma`, `rho12`,
   random-effect SD, and correlation displays.
