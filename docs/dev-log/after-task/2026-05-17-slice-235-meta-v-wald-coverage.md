# Slice 235 Meta-V Wald Coverage

## Goal

Attach Wald interval and coverage outputs to the `meta_V(V = V)` summary-smoke
surface.

## What Changed

- Updated `phase18_add_wald_intervals()` so `interval_scale` can be one value
  per row.
- Updated `phase18_summarise_meta_v_smoke()` to return `wald_intervals` and
  `wald_coverage`.
- `mu` coefficients are labelled `formula_coefficient`; fitted residual
  `sigma` is labelled `public`.
- Extended tests for `meta_V(V = V)` summary smoke and row-specific interval
  scales.

## Checks

- `air format inst/sim/R/sim_uncertainty.R inst/sim/run/sim_summary_meta_v_smoke.R tests/testthat/test-phase18-meta-v-summary-smoke.R tests/testthat/test-phase18-sim-uncertainty.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md docs/design/43-phase-18-interval-producer-contract.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-235-meta-v-wald-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-meta-v-summary-smoke|phase18-sim-uncertainty', reporter = 'summary')"`
- `git diff --check`

## Limitations

These are Wald intervals from fitted standard errors. Profile and bootstrap
intervals remain later interval-producer work.

## Standing Roles

Fisher kept estimated targets separate from known `V`. Noether set
row-specific interval scales so `mu` coefficients and public `sigma` do not get
mixed. Curie extended the smoke tests. Pat kept the known-covariance boundary
readable. Ada kept this as the `meta_V` sibling to Slice 233.
