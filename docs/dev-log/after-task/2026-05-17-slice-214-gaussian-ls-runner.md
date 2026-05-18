# Slice 214 Gaussian Location-Scale Smoke Runner

## Goal

Add the first end-to-end Phase 18 surface runner for the Gaussian
location-scale pilot.

## What Changed

- Added `inst/sim/run/sim_run_gaussian_ls_smoke.R`.
- Added a cell-to-DGP adapter for Gaussian location-scale registry rows.
- Added a small `drmTMB()` fitting wrapper for `bf(y ~ x, sigma ~ z)`.
- Added `phase18_run_gaussian_ls_smoke()` to build a registry, run each seeded
  replicate through the generic runner, save optional RDS results, and return a
  combined parameter summary.
- Added tests for completion, saved-output resume behaviour, summary shape, and
  malformed runner inputs.

## Checks

- `air format inst/sim/run/sim_run_gaussian_ls_smoke.R tests/testthat/test-phase18-gaussian-ls-runner.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-214-gaussian-ls-runner.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-ls-runner', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

This is a CRAN-safe smoke runner, not a comprehensive grid. It does not add
parallel execution, MCSE calculations, coverage summaries, power curves,
external comparators, or rendered reports.

## Standing Roles

Ada kept the slice small and stacked behind the generic runner. Curie checked
that the smoke surface exercises the full Phase 18 path. Fisher kept it framed
as a pilot runner rather than coverage evidence. Grace kept the tests
installed-package safe. Pat and Darwin kept the target surface close to the
reader-facing Gaussian location-scale story. Rose noted that claims should stay
at "runs end-to-end" until aggregation and coverage slices exist.
