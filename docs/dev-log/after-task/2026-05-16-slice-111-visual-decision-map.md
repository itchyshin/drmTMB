# After Task: Slice 111 Visualization Decision Map

## Goal

Help readers choose the right current data helper before they choose a plotting
style. The model-map article already told users what can be fitted; this slice
adds a compact Phase 17 table for visualization and post-fit display decisions.

## Implemented

- Added a Phase 17 visualization decision table to `vignettes/model-map.Rmd`.
- Routed observed responses to raw-data displays on the observed-response scale.
- Routed fitted parameter surfaces to `prediction_grid()` plus
  `predict_parameters()`.
- Routed empirical marginal summaries to
  `prediction_grid(..., margin = "empirical")` plus `marginal_parameters()`.
- Routed residual and latent correlation summaries to `rho12()` and
  `corpairs()`.
- Routed interval displays to `confint()` or `summary(conf.int = TRUE)` before
  any future ribbon or shaded-region plot.
- Routed diagnostics to `check_drm()`.
- Updated NEWS and ROADMAP with the Slice 111 decision-map contract.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-111-visual-decision-map.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-164842-codex-checkpoint.md`
- `vignettes/model-map.Rmd`

## Checks Run

- `air format NEWS.md ROADMAP.md vignettes/model-map.Rmd`: passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-map.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated model-map article, ROADMAP, and NEWS.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n "Slice 111|visualization decision|observed responses|fitted parameter surfaces|empirical marginal summaries|diagnostics before interpretation|Current display route|Check before styling" NEWS.md ROADMAP.md vignettes/model-map.Rmd pkgdown-site/articles/model-map.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages carry the decision map.
- `rg -n "plot_corpairs\\(|plot_diagnostics\\(|plot_simulation_summary\\(|autoplot\\.drmTMB|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|posterior draw|credible interval" NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-map.Rmd vignettes/model-workflow.Rmd DESCRIPTION pkgdown-site/articles/model-map.html pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only intended planned-name, design-inspiration, and
  confidence-not-credible-interval guardrails.
- `Rscript tools/codex-checkpoint.R --goal "Slice 111 visualization decision map" --next "stage, commit, push stacked branch, then open or retarget PR after Slice 109 and Slice 110 settle"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-164842-codex-checkpoint.md`.

## What Did Not Change

- No plotting helper was exported.
- No R API, dependency, likelihood, formula grammar, TMB code, or tests changed.
- No interval overlay, diagnostics plot, EMM, contrast, slope, `corpairs()` plot,
  or simulation plot was added.

## Team Learning

- Ada: navigation slices are useful when several small helpers exist and the
  next user question is "which one first?"
- Pat: the decision table belongs before the stable-core matrix because it
  answers a workflow choice rather than an implementation-status question.
- Jason: the visualization landscape should become routing language for users,
  not a dependency list.
- Fisher: interval rows should point to interval tables first; plot styling is
  a later layer.
- Grace: semantic scans should include rendered model-map output whenever the
  article becomes a navigation surface.
- Rose: future slices can now extend the map as new helpers appear without
  rewriting the whole Phase 17 narrative.

## Known Limitations

- This slice is documentation-only.
- It does not add `plot_corpairs()`, diagnostic plots, interval ribbons, EMMs,
  contrasts, slopes, or simulation displays.
- It does not change the Reference index.

## Next Actions

1. Keep the decision table synchronized when new plot helpers are exported.
2. Add `corpairs()` plotting only after correlation rows have consistent
   interval status.
3. Keep the interval-first rule before any future ribbon or shaded-region
   examples.
