# Slice 233 Gaussian Location-Scale Wald Coverage

## Goal

Attach real Wald interval and coverage outputs to the Gaussian location-scale
summary-smoke surface.

## What Changed

- Updated `phase18_summarise_gaussian_ls_smoke()` to return `wald_intervals`
  and `wald_coverage`.
- The intervals use `phase18_add_wald_intervals()` and are labelled
  `interval_scale = "formula_coefficient"`, because the pilot summary targets
  coefficients such as `mu:x` and `sigma:z`.
- Extended the Gaussian location-scale summary-smoke test to check interval
  status, interval scale, replicate counts, and interval counts.

## Checks

- `air format inst/sim/run/sim_summary_gaussian_ls_smoke.R tests/testthat/test-phase18-gaussian-ls-summary-smoke.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md docs/design/43-phase-18-interval-producer-contract.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-233-gaussian-ls-wald-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-ls-summary-smoke', reporter = 'summary')"`
- `git diff --check`

## Limitations

These are formula-coefficient Wald intervals, not response-scale confidence
bands for predicted `mu` or `sigma`. Confidence bands for figures remain a
separate visualization and prediction slice.

## Standing Roles

Fisher tied the new intervals to explicit coverage rows. Noether insisted on
the `formula_coefficient` scale label. Curie extended the smoke test around
denominators and interval counts. Pat kept the limitation visible for readers.
Ada kept this to the Gaussian location-scale surface before extending to
`meta_V(V = V)`.
