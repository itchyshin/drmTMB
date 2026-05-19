# After Task: Slice 266 gallery source map and QA

## Task

Add a source-map and QA table to the public figure gallery so each display names
its fitted object or fixture, extractor or plotter, interval source, and support
boundary.

## What Changed

- Added a "Gallery source map" section to `vignettes/figure-gallery.Rmd`.
- Mapped each display to the fitted object or illustrative fixture that drives
  it.
- Recorded each extractor or plotter, including `predict_parameters()`,
  `plot_parameter_surface()`, `emmeans::emmeans()`, `marginal_parameters()`,
  `plot_corpairs()`, status strips, and fixture displays.
- Recorded interval provenance and support boundaries so readers do not treat
  point plots, status strips, or illustrative simulation fixtures as fitted
  interval evidence.
- Updated the roadmap, visualization grammar note, NEWS, check log, and
  recovery checkpoint.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/after-task/2026-05-18-slice-266-gallery-source-map-qa.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-182742-codex-checkpoint.md`
- `vignettes/figure-gallery.Rmd`

## Checks

- `air format vignettes/figure-gallery.Rmd NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md docs/dev-log/recovery-checkpoints/2026-05-18-182742-codex-checkpoint.md`
- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/figure-gallery.Rmd', output_dir = '/tmp/drmtmb-figure-gallery-s266', quiet = FALSE)"`
- Confirmed the rendered HTML contains the "Gallery source map" heading and representative table rows.
- Extracted embedded PNGs from `/tmp/drmtmb-figure-gallery-s266/figure-gallery.html` and spot-checked the post-source-map render output.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice to gallery QA and documentation, with no helper API
  changes.
- Pat checked that the source map tells an applied reader what each plot is and
  is not showing.
- Fisher checked that interval provenance and unsupported boundaries are named
  instead of inferred.
- Grace checked the gallery render, source-map table evidence, pkgdown, and
  diff hygiene before closure.
- Rose checked that the map reduces stale-claim risk across the expanded
  gallery.
- Florence checked that the table supports visual reuse decisions without
  crowding the figure panels themselves.

## Known Limits

- The source map is a documentation table; it does not validate plot output at
  runtime.
- The table should be refreshed when new gallery figures or exported plotting
  helpers are added.
