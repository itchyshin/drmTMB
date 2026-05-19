# After Task: Slice 263 correlation-layer figures

## Task

Improve the public figure gallery so correlation displays separate residual,
ordinary group-level, phylogenetic, spatial, animal, and `relmat()` layers
without implying that planned layers already have fitted `corpairs()` rows.

## What Changed

- Replaced the single compact correlation display with a faceted
  `plot_corpairs()` display for implemented estimate rows.
- Kept residual `rho12`, ordinary group-level intercept-slope correlation, and
  phylogenetic location-location correlation in separate facets.
- Added a support-boundary strip that marks spatial, animal, and `relmat()`
  correlation-pair layers as planned boundaries rather than fitted estimates.
- Added prose that distinguishes within-observation coscale, latent group
  covariance, structured species-level covariance, and future structured
  layers.
- Updated the roadmap, visualization grammar design note, and NEWS entry for
  Slice 263.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/after-task/2026-05-18-slice-263-correlation-layer-figures.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-180253-codex-checkpoint.md`
- `vignettes/figure-gallery.Rmd`

## Checks

- `air format vignettes/figure-gallery.Rmd NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/dev-log/after-task/2026-05-18-slice-263-correlation-layer-figures.md docs/dev-log/recovery-checkpoints/2026-05-18-180253-codex-checkpoint.md`
- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-figure-gallery-s263', quiet = FALSE)"`
- Extracted embedded PNGs from `/tmp/drmtmb-figure-gallery-s263/figure-gallery.html` and visually checked the faceted correlation-layer plot plus the support-boundary strip.
- `Rscript -e "devtools::test(filter = 'plot-corpairs', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice as a gallery and documentation update, following the
  Slice 263 roadmap row.
- Pat checked that an applied reader can tell which biological question each
  correlation layer answers.
- Fisher kept planned spatial, animal, and `relmat()` layers out of the
  estimate plot so the figure does not imply unsupported fitted correlations.
- Grace checked the rendered gallery, focused helper tests, pkgdown, and diff
  hygiene before treating the slice as closed.
- Rose checked that the prose keeps `rho12`, `corpairs()`, `spatial()`,
  `animal()`, and `relmat()` statuses consistent with the roadmap.
- Florence reviewed the display split: estimate-bearing rows use
  `plot_corpairs()`, while planned layers use a separate status strip.

## Known Limits

- This slice does not add new `corpairs()` support for spatial, animal, or
  `relmat()` models.
- The gallery uses a compact `corpairs()`-compatible table for speed; fitted
  biological workflows remain in the model-specific tutorials.
- Planned layers should move into the estimate plot only after fitted rows,
  interval status, recovery tests, and reader-facing examples exist.
