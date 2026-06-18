# After Task: Student-t Diagnostic Guidance

## Goal

Help applied users carry the Student-t `student_nu` diagnostic into model
interpretation after the simulation summaries started recording that row.

## Implemented

- Updated the robust Student-t vignette so the diagnostic example stores
  `check_drm(fit_student)`, prints the full table, and extracts the
  `student_nu` status, value, and message.
- Added guidance to keep `student_nu` status beside AIC, coefficient, and
  simulation-summary tables.
- Refreshed mission-control activity text without changing dashboard metrics.

## Mathematical Contract

The Student-t model remains

\[
\nu_i = 2 + \exp(\eta_{\nu i}).
\]

This keeps fitted values in the finite-variance region. The vignette now
explains how to report the diagnostic status around that boundary, but it does
not change the likelihood, link, optimizer, or diagnostic threshold.

## Files Changed

- `vignettes/robust-student.Rmd`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-student-nu-diagnostic-guidance.md`

## Checks Run

- `Rscript -e "devtools::load_all('.', quiet = TRUE); rmarkdown::render('vignettes/robust-student.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `sh tools/start-mission-control.sh --background`
- `curl -fsS http://127.0.0.1:8765/status.json | jq '{updated, metrics, active_work: .active_work[0:4], first_activity: .activity[0]}'`
- `rg -n "release readiness|CRAN readiness|coverage claim|promotion language|promote|calibrated interval|engine_control|REML|AI-REML" vignettes/robust-student.Rmd docs/dev-log/after-task/2026-06-17-student-nu-diagnostic-guidance.md docs/dev-log/check-log.md docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json`

## Tests Of The Tests

This is a documentation-only slice. The rendered vignette exercises the edited
chunk by fitting the Student-t example, running `check_drm()`, and extracting
the `student_nu` row. The diagnostic behavior itself is already covered by
`test-check-drm.R` and the Phase 18 Student-t shape summary smoke tests.

## Consistency Audit

The prose follows the Student-t diagnostic implementation in `R/check.R`:
`student_nu` is `ok` when fitted `nu` values are finite and above 2, warns near
the finite-variance boundary, and notes very large `nu` values that are close
to the Gaussian tail limit. The vignette keeps the current fixed-effect
Student-t boundary and does not promote random effects, bivariate responses,
structured effects, coverage, release readiness, or CRAN readiness.

The mission-control validator reported
`mission_control_ok: 25/68 banked_or_verified, 1 active, 17 matrix rows, 11 finish rows, 15 Julia gate rows, 9 Julia capability rows`.
`pkgdown::check_pkgdown()` found no problems. The served dashboard reported the
new `2026-06-17 23:06 MDT` status with unchanged metrics and the Student-t
diagnostic guidance as the first activity row.

## GitHub Issue Maintenance

`drmTMB#59` remains open. This follow-up supports the numerical-guard
sensitivity lane by making the diagnostic row easier for users to retain beside
their model-comparison evidence; it does not close the comprehensive simulation
framework issue.

## What Did Not Go Smoothly

The first instinct was to add this to the model-selection article, but the
robust Student-t vignette is the better reader path because it already defines
`nu`, the finite-variance boundary, and the Gaussian-tail interpretation.

## Team Learning

When a simulation artifact starts carrying a new diagnostic column, add a small
user-facing example that shows how to carry the same diagnostic through an
ordinary analysis table.

## Known Limitations

This slice does not add new simulation evidence or interval calibration. It
does not change `check_drm()` thresholds or add recovery advice for every
possible warning source.

## Next Actions

- If the larger Student-t boundary study grows beyond this diagnostic pilot,
  add a report table that joins AIC, coefficient estimates, `student_nu`
  status, convergence, and `pdHess` status in one displayed artifact.
