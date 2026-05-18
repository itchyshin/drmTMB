# Slice 222 Run Manifest

## Goal

Add a compact manifest helper for Phase 18 replicate-run results.

## What Changed

- Added `phase18_result_manifest()` to `inst/sim/R/sim_runner.R`.
- The manifest records `cell_id`, `replicate`, `seed`, `status`, `skipped`,
  `warning_count`, `error`, and `elapsed`.
- Added tests for successful and failed result rows plus malformed result
  objects.

## Checks

- `air format inst/sim/R/sim_runner.R tests/testthat/test-phase18-sim-runner.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-222-run-manifest.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-runner', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

The manifest records run status but does not aggregate parameter estimates,
compute MCSEs, or inspect saved RDS files from disk. Later scheduled-run
scripts can use it as the run-level audit table.

## Standing Roles

Ada asked for a small audit surface before larger grids. Grace kept it simple
and dependency-free. Curie covered malformed result objects. Fisher kept it
separate from performance metrics. Pat and Rose kept the manifest readable for
handoffs and failure triage.
