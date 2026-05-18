# Slice 218 Gaussian Location-Scale Summary Smoke

## Goal

Wire the Gaussian location-scale smoke runner to the Phase 18 aggregation and
MCSE helpers.

## What Changed

- Added `inst/sim/run/sim_summary_gaussian_ls_smoke.R`.
- Added `phase18_summarise_gaussian_ls_smoke()` to run the existing Gaussian
  smoke surface, aggregate parameter summaries, and attach bias/RMSE MCSEs.
- Added tests for a two-replicate end-to-end summary smoke run and the empty
  summary guard.

## Checks

- `air format inst/sim/run/sim_summary_gaussian_ls_smoke.R tests/testthat/test-phase18-gaussian-ls-summary-smoke.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-218-gaussian-ls-summary-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-ls-summary-smoke', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18', reporter = 'summary')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Limitations

This is still a tiny smoke run. It reports bias and RMSE summaries with MCSEs,
but it does not add confidence intervals, interval coverage, power, plots,
parallel execution, or a rendered report.

## Standing Roles

Ada kept this as the first aggregation consumer. Fisher kept it to bias/RMSE
rather than coverage. Curie checked the two-replicate path. Grace kept the
smoke run small enough for routine tests. Pat and Darwin kept the Gaussian
location-scale example aligned with the reader-facing tutorial path. Rose kept
the "summary smoke, not evidence grid" boundary visible.
