# Slice 231 Correlation Fisher-Z Wald Intervals

## Goal

Add a Phase 18 Wald interval helper for correlation summaries that uses
Fisher-z intervals and reports endpoints back on the raw correlation scale.

## What Changed

- Added `phase18_add_correlation_fisher_z_intervals()` to
  `inst/sim/R/sim_uncertainty.R`.
- The helper accepts standard errors supplied on raw correlation scale or on
  Fisher-z scale, records `std.error.scale`, and reports
  `interval_scale = "fisher_z_backtransformed"`.
- Rows with missing standard errors or boundary correlations are marked as
  failed with missing endpoints instead of being silently clipped.
- Added tests for back-transformed endpoints, bounded output, failed boundary
  rows, metadata, and argument validation.

## Checks

- `air format inst/sim/R/sim_uncertainty.R tests/testthat/test-phase18-sim-uncertainty.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md docs/design/43-phase-18-interval-producer-contract.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-17-slice-231-correlation-fisher-z-wald.md`
- `Rscript -e "devtools::test(filter = 'phase18-sim-uncertainty', reporter = 'summary')"`
- `git diff --check`

## Limitations

The helper still expects a summary table with a correlation estimate and
standard error. It does not yet extract correlation estimates or standard
errors from fitted `drmTMB` objects.

## Standing Roles

Fisher prioritized the Fisher-z interval because it respects correlation
boundaries better than raw-rho Wald intervals. Noether kept the reported
endpoint scale explicit. Curie covered valid, near-boundary, and failed rows.
Pat kept the failure message readable. Ada kept this as a generic table helper
before model-specific extraction.
