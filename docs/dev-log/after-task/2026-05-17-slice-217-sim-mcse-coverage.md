# Slice 217 Simulation MCSE and Coverage Helpers

## Goal

Add the first Monte Carlo uncertainty and explicit interval-coverage helpers
for Phase 18 simulation summaries.

## What Changed

- Added `inst/sim/R/sim_uncertainty.R`.
- Added MCSE helpers for means, proportions, and RMSE through the delta method.
- Added `phase18_aggregate_error_mcse()` for grouped bias and RMSE uncertainty.
- Added `phase18_summarise_interval_coverage()` for summary tables that already
  carry explicit lower and upper interval columns.
- Added tests for error MCSEs, coverage summaries, custom grouping, and
  malformed inputs.

## Checks

- `air format inst/sim/R/sim_uncertainty.R tests/testthat/test-phase18-sim-uncertainty.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-217-sim-mcse-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-uncertainty', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

Coverage is computed only from explicit interval columns. This slice does not
create Wald, profile, bootstrap, or derived-quantity intervals; it only
summarises intervals supplied by later fit/report slices.

## Standing Roles

Fisher set the denominator and MCSE boundary. Noether kept interval columns
explicit rather than inferred. Curie checked malformed-input paths. Grace kept
the helper dependency-free. Pat and Darwin kept the output names readable for
later reports. Rose marked interval construction as still outside this slice.
