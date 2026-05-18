# Slice 230 Wald Interval Table

## Goal

Add the first generic interval-table producer for Phase 18 summaries that
already contain estimates and standard errors.

## What Changed

- Added `phase18_add_wald_intervals()` to `inst/sim/R/sim_uncertainty.R`.
- The helper adds normal Wald endpoints and records `conf.level`,
  `interval_method`, `interval_scale`, `interval_status`, and
  `interval_message`.
- Updated the synthetic interval smoke helper to reuse the shared lower/upper
  column-name validation.
- Added tests for successful Wald endpoints, failed rows with missing standard
  errors, coverage-table compatibility, and validation of confidence levels.

## Checks

- `air format inst/sim/R/sim_uncertainty.R inst/sim/run/sim_interval_coverage_smoke.R tests/testthat/test-phase18-sim-uncertainty.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md docs/design/43-phase-18-interval-producer-contract.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-230-wald-interval-table.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-uncertainty|phase18-interval-coverage-smoke', reporter = 'summary')"`
- `git diff --check`

## Limitations

The helper does not extract standard errors from fitted drmTMB objects. It only
standardizes interval-table metadata once a surface-specific producer has
created `estimate` and `std.error` columns.

## Standing Roles

Fisher shaped the status and coverage-denominator behavior. Noether kept the
reported interval scale explicit. Curie covered valid and failed interval rows.
Pat kept missing intervals readable through messages. Ada kept this generic so
surface-specific standard-error extraction can be added separately.
