# Slice 255 Count Gallery Render Helper

## Goal

Close the first Florence bridge from paired count-pilot simulation tables to a
checked local figure-gallery artifact.

## Implemented

- Added `inst/sim/R/sim_gallery.R`.
- Added `phase18_write_count_mu_re_gallery_inputs()` to write stable aggregate,
  coverage, manifest, and failure CSV inputs from a paired count pilot object.
- Added `phase18_render_count_mu_re_gallery()` to render
  `inst/sim/reports/phase18-count-mu-gallery.Rmd` from those CSV inputs.
- Added overwrite checks so local gallery inputs and outputs are not silently
  replaced.
- Added tests for CSV writing, overwrite protection, and skip-aware HTML
  rendering.
- Updated the Phase 18 README, visualization grammar, simulation blueprint,
  roadmap, NEWS, and check log.

## Files Changed

- `inst/sim/R/sim_gallery.R`
- `tests/testthat/test-phase18-count-gallery-render-helper.R`
- `inst/sim/README.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/R/sim_gallery.R tests/testthat/test-phase18-count-gallery-render-helper.R inst/sim/README.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md`
- `Rscript -e "devtools::test(filter = 'phase18-count-gallery-render-helper|phase18-count-gallery-template|phase18-sim-plot-data', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-count-mu-random-effect-pilot|phase18-count-gallery-render-helper', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The render-helper tests use a small pilot-like fixture so the rendering path is
checked without requiring a long simulation grid. A separate focused test run
keeps the live paired count pilot beside the new gallery helper, so the helper
stays aligned with real pilot object structure.

## Consistency Audit

The helper renders an HTML artifact from pilot output, but it still labels that
artifact as pilot evidence. This keeps Florence's figure-gallery path concrete
without promoting one-replicate smoke surfaces into final simulation claims.

## Team Learning

Ada kept the slice scoped to artifact plumbing. Florence now has a reproducible
gallery-render path. Pat gets a concrete HTML report rather than a hidden R
object. Fisher keeps interval coverage separate from bias and RMSE. Grace gets
skip-aware rendering and overwrite checks. Rose verified that the docs do not
claim a publication-ready gallery yet.

## Known Limitations

This slice does not commit rendered HTML output, increase replicate counts, save
standalone image files, or add a pkgdown gallery article. It gives later slices
the helper needed to render those artifacts from real pilot runs.

## Next Actions

Use the helper on a tiny saved count pilot, inspect the rendered gallery
visually, then decide whether the next Florence slice should polish the figure
theme or write the first pkgdown gallery article.
