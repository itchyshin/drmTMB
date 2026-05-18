# Slice 227 Report Ledger Inputs

## Goal

Give Phase 18 smoke reports explicit places for aggregate summaries, run
manifests, and warning/error ledgers.

## What Changed

- Updated `inst/sim/reports/phase18-smoke-report-template.Rmd`.
- Added optional `manifest_csv` and `failures_csv` parameters beside
  `aggregate_csv`.
- The template now renders a message when a CSV is not supplied and displays
  the table when a path is provided.
- Extended the template test to check the new sections and parameters.

## Checks

- `air format inst/sim/reports/phase18-smoke-report-template.Rmd tests/testthat/test-phase18-report-template.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-227-report-ledger-inputs.md`
- `Rscript -e "devtools::test(filter = 'phase18-report-template', reporter = 'summary')"`
- `git diff --check`

## Limitations

The test checks the template source rather than rendering an HTML report. A
later report slice should render a toy report with real CSV fixtures.

## Standing Roles

Pat and Darwin wanted the report to show not only estimates but also run
status. Rose kept warning/error rows visible. Grace kept the template optional
so it renders before all files exist. Fisher kept coverage claims out of this
report-template slice. Ada kept the change limited to report inputs.
