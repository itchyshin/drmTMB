# After Task: First-Wave Report Non-Strict Render

## Goal

Make Phase 18 first-wave status and summary reports render missing-artifact
diagnostics by default, while keeping strict missing-artifact failures
available for explicit manual validation gates.

## Implemented

- Changed `require_complete` to `FALSE` in
  `inst/sim/reports/phase18-first-wave-status-report.Rmd`.
- Changed `require_complete` to `FALSE` in
  `inst/sim/reports/phase18-first-wave-summary-report.Rmd`.
- Changed `phase18_render_first_wave_summary_report()` to default
  `require_complete = FALSE`.
- Added tests that render synthetic missing-artifact status and summary reports
  in non-strict mode.
- Kept tests that strict mode still fails fast with
  `require_complete = TRUE`.

## Mathematical Contract

No model, likelihood, simulation result, artifact schema, or operating
characteristic changed. This is a reporting-mode default: missing artifacts
remain visible in status tables, but report rendering does not stop unless a
caller opts into strict validation.

## Files Changed

- `inst/sim/reports/phase18-first-wave-status-report.Rmd`
- `inst/sim/reports/phase18-first-wave-summary-report.Rmd`
- `inst/sim/run/sim_render_first_wave_summary_report.R`
- `tests/testthat/test-phase18-first-wave-status-report.R`
- `tests/testthat/test-phase18-first-wave-summary-report.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-first-wave-report-nonstrict-render.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The new tests use synthetic CSVs with `n_missing = 1`: non-strict rendering must
produce HTML that includes the missing surface, while strict rendering must
still error with the missing-artifact message.

## Consistency Audit

The default behavior now matches the Phase 18 reporting boundary: report pages
are diagnostic views, not formal completeness gates. Formal dispatch or audit
scripts can still pass `require_complete = TRUE`.

## GitHub Issue Maintenance

This slice updates the PR closeout trail after the commit is pushed because it
addresses a CI/check portability risk observed in earlier run logs.

## What Did Not Go Smoothly

The original CI log looked like a failed report, but the strict failure was
also part of an intentional test path. The safer fix was not to remove strict
mode, but to make non-strict rendering the default for report pages.

## Team Learning

Report templates that are included in package checks should default to
diagnostic rendering. Strict artifact completeness belongs in explicit manual
validation gates where a failure is the intended outcome.

## Known Limitations

Strict-mode tests still print the normal R Markdown setup-abort message while
confirming the error path. That is acceptable because default report rendering
no longer uses the strict path.

## Next Actions

Watch the next CI run to confirm the report-render path stays nonfatal on all
platforms.
