# Slice 215 Meta-V Smoke Runner

## Goal

Add the first end-to-end Phase 18 smoke runner for the Gaussian
`meta_V(V = V)` pilot.

## What Changed

- Added `inst/sim/run/sim_run_meta_v_smoke.R`.
- Added a cell-to-DGP adapter for vector and dense known sampling covariance
  registry rows.
- Added a `drmTMB()` fitting wrapper for
  `bf(yi ~ x + meta_V(V = V), sigma ~ 1)`.
- Added `phase18_run_meta_v_smoke()` to build a registry, run seeded
  replicates through the generic runner, save optional RDS results, and return
  one combined parameter summary.
- Added tests for vector and dense cells, completion, saved-output resume
  behaviour, summary shape, missing known `V`, and malformed inputs.

## Checks

- `air format inst/sim/run/sim_run_meta_v_smoke.R tests/testthat/test-phase18-meta-v-runner.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-215-meta-v-runner.md`
- `Rscript -e "devtools::test(filter = 'phase18-meta-v-runner', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

This is still a smoke runner. It does not make dense-`V` scalability claims,
compute MCSE, estimate coverage, run profile intervals, compare with
`metafor`, or render simulation reports.

## Standing Roles

Ada kept the runner stacked after the generic runner and Gaussian smoke
surface. Fisher kept known `V` as input-only evidence rather than an interval
target. Noether kept the fitted `sigma` and known sampling covariance separate.
Grace watched installed-package sourcing. Curie checked vector and dense cells.
Pat and Darwin kept the meta-analysis surface readable for applied users. Rose
kept the limitation language explicit.
