# Slice 226 Interval Coverage Smoke

## Goal

Test the Phase 18 interval-coverage table path without claiming real
confidence-interval evidence.

## What Changed

- Added `inst/sim/run/sim_interval_coverage_smoke.R`.
- The helper adds deliberately synthetic lower and upper interval columns to a
  parameter summary table, then routes the result through
  `phase18_summarise_interval_coverage()`.
- Added tests for coverage-table output and validation of malformed synthetic
  interval inputs.

## Checks

- `air format inst/sim/run/sim_interval_coverage_smoke.R tests/testthat/test-phase18-interval-coverage-smoke.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-226-interval-coverage-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-interval-coverage-smoke', reporter = 'summary')"`
- `git diff --check`

## Limitations

The intervals are synthetic and must not be interpreted as Wald, profile, or
bootstrap intervals. This slice only validates the coverage-summary plumbing.

## Standing Roles

Fisher insisted on the synthetic label and the no-coverage-claim boundary.
Curie covered the table shape and input validation. Pat and Darwin kept the
purpose reader-facing: the helper explains what can be checked now and what
still needs real interval methods. Grace kept the helper small and optional.
Ada kept it separate from the real interval-producer work.
