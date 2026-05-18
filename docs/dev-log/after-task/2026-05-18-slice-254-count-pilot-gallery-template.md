# Slice 254 Count Pilot Gallery Template

## Goal

Give Florence the first report template for a Phase 18 figure gallery, starting
with paired Poisson/NB2 `mu` random-effect pilots.

## Implemented

- Added `inst/sim/reports/phase18-count-mu-gallery.Rmd`.
- The template reads plot-ready aggregate, coverage, manifest, and failure CSVs.
- When `ggplot2` is available, it draws bias, RMSE, and interval-coverage
  panels with family colours and parameter/interval distinctions.
- When `ggplot2` is unavailable, it falls back to printed tables.
- Added tests for installed reader-facing text and skip-aware rendering with
  tiny CSV inputs.
- Updated the Phase 18 README, visualization grammar, simulation blueprint,
  roadmap, NEWS, and check log.

## Files Changed

- `inst/sim/reports/phase18-count-mu-gallery.Rmd`
- `tests/testthat/test-phase18-count-gallery-template.R`
- `inst/sim/README.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format tests/testthat/test-phase18-count-gallery-template.R inst/sim/README.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-254-count-pilot-gallery-template.md`
- `Rscript -e "devtools::test(filter = 'phase18-count-gallery-template|phase18-report-template|phase18-sim-plot-data', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-count-gallery-template|plot-parameter-surface|plot-corpairs', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The render test supplies tiny aggregate, coverage, manifest, and empty failure
CSV fixtures and checks that the rendered HTML contains the user notes and
Florence checks. It skips cleanly when `rmarkdown` or Pandoc is unavailable.

## Consistency Audit

The gallery template is explicitly labelled as a pilot gallery, not a final
simulation report. It keeps the warning/error ledger adjacent to figures so
readers see failed or warning-bearing runs before interpreting bias or coverage.

## Team Learning

Florence now has a real gallery shell. Pat can read the report without knowing
the internals. Fisher keeps bias, RMSE, and coverage separate. Grace gets a
skip-aware render test. Rose kept the text from over-claiming final power or
coverage.

## Known Limitations

This slice does not generate a full pilot result, save figure files, or add a
pkgdown gallery article. It provides the report template that later slices can
feed with real pilot outputs.

## Next Actions

Run a tiny saved pilot, write the plot-ready CSVs, and render the gallery as a
checked local artifact before considering a pkgdown article.
