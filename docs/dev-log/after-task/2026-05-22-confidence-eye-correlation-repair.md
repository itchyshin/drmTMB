# After Task: Confidence Eye Correlation Plot Repair

## Purpose

Repair the rejected Confidence Eye figure work by fixing the actual
correlation-row display and the exported `plot_corpairs()` helper. The default
visual grammar is now the one requested: a pale finite confidence region plus a
hollow point estimate. Conventional CI lines remain available, but only as an
optional display variant.

## Team Review

- Ada re-scoped the task after the discussion drifted to a different rendered
  figure and required the target image path, chunk name, and title before
  further edits.
- Boole checked the `ggplot2` layer mapping and helped catch the need for
  explicit ribbon grouping.
- Noether checked the correlation scale: eye shapes are built on a guarded
  Fisher-z/atanh scale and displayed back on the correlation axis.
- Fisher kept interval provenance visible: only finite bounds with supported
  `conf.status` and `interval_source` receive eyes.
- Pat checked that the rendered figures now read without duplicated labels or
  hidden implementation history.
- Florence checked the visual grammar: pale confidence region, hollow estimate
  circle, no default CI bar, no outer eye outline, and no row guide line
  running through the eye.
- Grace rebuilt the reference page, affected articles, full pkgdown site, and
  focused tests.
- Rose recorded the process failure and the new gate: figure QA must name the
  rendered image path, chunk name, and figure title before edits or review.

## Changes

- Changed `plot_corpairs()` so `interval_style = "eye"` is the default, drawing
  Confidence Eye regions for supported finite correlation intervals.
- Added `interval_style = "line"` for conventional CI-line overlays when a
  diagnostic, grayscale, or reader-preference display needs them.
- Updated `plot_corpairs()` tests for the new default and optional line variant.
- Regenerated `man/plot_corpairs.Rd`.
- Repaired the figure-gallery correlation-row display so residual, group,
  phylogenetic, spatial, animal, and `relmat()` rows use pale confidence
  regions plus hollow estimates, with no default CI bars or row guide lines.
- Removed a stale overlay point layer from the bivariate-coscale quick
  `corpairs()` plot and let the helper draw the hollow estimates.
- Updated NEWS, visualization grammar, figure-audit notes, and the team
  improvement log.

## Validation

```sh
air format R/plot-corpairs.R tests/testthat/test-plot-corpairs.R vignettes/figure-gallery.Rmd NEWS.md docs/design/39-visualization-grammar.md docs/dev-log/check-log.md docs/dev-log/team-improvements.md docs/dev-log/after-task/2026-05-22-confidence-eye-correlation-repair.md docs/dev-log/figure-audits/2026-05-22-article-figures/README.md
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'plot-corpairs', reporter = 'summary')"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_reference(topics = 'plot_corpairs', lazy = FALSE, preview = FALSE); pkgdown::build_article('figure-gallery', new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::load_all(quiet = TRUE); pkgdown::build_article('bivariate-coscale', new_process = FALSE, quiet = TRUE); pkgdown::build_article('location-scale', new_process = FALSE, quiet = TRUE)"
Rscript -e "devtools::test(filter = 'plot-corpairs|corpairs|predict-parameters', reporter = 'summary')"
git diff --check
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "devtools::test(reporter = 'summary')"
```

All focused checks passed. The full pkgdown site built successfully,
`pkgdown::check_pkgdown()` reported no problems, and the full
`devtools::test(reporter = "summary")` suite passed.

## Remaining Work

The Confidence Eye display is now implemented for the `plot_corpairs()` helper
and the gallery correlation-row figure. The broader figure audit still needs to
continue page by page: every substantial figure should show estimate plus
uncertainty where available, and point-only displays should be explicitly named
as unavailable-interval diagnostics rather than treated as final inference
figures.
