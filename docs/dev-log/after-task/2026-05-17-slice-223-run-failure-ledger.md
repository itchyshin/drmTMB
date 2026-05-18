# Slice 223 Run Failure Ledger

## Goal

Keep Phase 18 warning and error rows visible beside aggregate summaries.

## What Changed

- Added `phase18_result_failures()` to `inst/sim/R/sim_runner.R`.
- The helper extracts one row for each failed replicate and one row for each
  captured warning.
- Added tests for mixed ok/error results and empty failure ledgers.

## Checks

- `air format inst/sim/R/sim_runner.R tests/testthat/test-phase18-sim-runner.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-223-run-failure-ledger.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-runner', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

The ledger records warning and error messages from in-memory result objects. It
does not classify root causes, parse optimizer diagnostics, or scan result
directories from disk.

## Standing Roles

Rose pushed for failures to remain visible. Fisher kept the ledger separate
from denominator-based metrics. Curie covered empty and mixed-result cases.
Pat kept the rows readable for handoff reports. Grace kept it dependency-free.
