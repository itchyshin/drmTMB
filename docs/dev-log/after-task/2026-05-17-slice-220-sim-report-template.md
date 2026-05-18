# Slice 220 Simulation Report Template

## Goal

Add the first reader-facing Phase 18 smoke report template.

## What Changed

- Added `inst/sim/reports/phase18-smoke-report-template.Rmd`.
- The template names the purpose, surface, aggregate summary placeholder,
  reader checks, and interpretation boundary.
- Added a test confirming the installed template carries the key sections and
  does not present smoke output as comprehensive simulation evidence.

## Checks

- `air format inst/sim/reports/phase18-smoke-report-template.Rmd tests/testthat/test-phase18-report-template.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-220-sim-report-template.md`
- `Rscript -e "devtools::test(filter = 'phase18-report-template', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

The template is not rendered by tests and does not yet read real result files
by default. It is a stable report frame for later slices, not a completed
simulation report.

## Standing Roles

Pat and Darwin shaped the reader-facing questions. Fisher kept the evidence
boundary explicit. Grace kept this as an installed artifact with a small test.
Ada kept it separate from aggregation code. Rose checked that the report does
not overclaim smoke results.
