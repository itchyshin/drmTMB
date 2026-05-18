# Slice 253 Count Pilot Plot Data

## Goal

Prepare Florence's figure-gallery input layer for the paired Poisson/NB2 `mu`
random-effect pilot without yet adding rendered plots.

## Implemented

- Added `phase18_count_mu_re_plot_data()` under `inst/sim/R/sim_plot_data.R`.
- The helper converts paired count pilot output into inspectable aggregate,
  coverage, manifest, and failure tables.
- Aggregate rows gain plot-facing `family`, `parameter_class`, `dpar`, `term`,
  and `abs_bias` columns.
- Coverage rows gain `family`, `parameter_class`, `dpar`, `term`, and
  `interval_method` columns.
- Added focused tests using synthetic pilot output.
- Updated the Phase 18 README, visualization grammar, simulation blueprint,
  roadmap, NEWS, and check log.

## Files Changed

- `inst/sim/R/sim_plot_data.R`
- `tests/testthat/test-phase18-sim-plot-data.R`
- `inst/sim/README.md`
- `docs/design/39-visualization-grammar.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/R/sim_plot_data.R tests/testthat/test-phase18-sim-plot-data.R inst/sim/README.md docs/design/39-visualization-grammar.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-253-count-pilot-plot-data.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-plot-data|phase18-count-mu-random-effect-pilot', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-sim-plot-data|plot-parameter-surface|plot-corpairs', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The tests use a small synthetic paired count pilot object to verify family
labels, fixed-effect versus random-SD classification, distributional-parameter
labels, term extraction, absolute bias, and interval-method provenance.

## Consistency Audit

This follows the visualization grammar: table first, figure second. No `ggplot2`
dependency or exported plotting API is added in this slice.

## Team Learning

Florence gets a stable figure input table before the gallery is drawn. Pat can
inspect the data before a figure appears. Fisher keeps coverage method
provenance visible. Rose keeps this labelled as a data contract, not a finished
gallery.

## Known Limitations

This slice does not create `ggplot2` figures, a gallery article, or report
rendering.

## Next Actions

Use this helper in the figure-gallery slice to draw bias/RMSE, coverage, and
failure-status panels for ready Phase 18 count pilot surfaces.
