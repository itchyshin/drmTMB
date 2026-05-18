# Slice 216 Simulation Aggregation

## Goal

Add the first reusable aggregation helper for Phase 18 parameter-level
simulation summaries.

## What Changed

- Added `inst/sim/R/sim_aggregate.R`.
- Added `phase18_aggregate_parameters()` for grouped parameter summaries.
- The helper reports replicate counts, mean truth, mean estimate, bias, RMSE,
  mean absolute error, empirical standard error, convergence rate, Hessian
  rate, warning rate, and mean elapsed time.
- Added tests for default grouping, requested pooling across cells, and
  malformed summary schemas.

## Checks

- `air format inst/sim/R/sim_aggregate.R tests/testthat/test-phase18-sim-aggregate.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-216-sim-aggregation.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-aggregate', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

The helper deliberately stops before Monte Carlo standard errors, interval
coverage, power, bootstrap uncertainty, plotting, and rendered reports. Those
need dedicated follow-up slices so each estimand has a named denominator and
uncertainty formula.

## Standing Roles

Ada kept this as a small data-frame helper rather than a report system. Fisher
kept MCSE and coverage out of this slice so their denominators can be explicit.
Curie checked schema validation. Grace kept the helper dependency-free. Pat and
Darwin kept the output column names readable. Rose tracked the boundary between
aggregation metrics and simulation claims.
