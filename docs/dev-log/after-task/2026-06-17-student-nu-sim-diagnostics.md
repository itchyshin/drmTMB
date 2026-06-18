# Student-t Nu Simulation Diagnostics

## Goal

Make the existing Phase 18 Student-t shape simulation summaries report the
`check_drm()` `student_nu` diagnostic row. The next finite-variance-boundary
guard pilot should be able to count warning, error, note, and ok states without
rerunning diagnostics outside the artifact tables.

## Implemented

- Added Student-t shape summary columns:
  `fit_diagnostic_status`, `fit_diagnostic_message`, `student_nu_status`,
  `student_nu_value`, and `student_nu_message`.
- Attached diagnostics after optional profile and bootstrap interval columns,
  so replicate CSVs written by `phase18_write_student_shape_grid_outputs()`
  carry both interval and fit-diagnostic status.
- Added a focused test that fits a small Student-t model, forces the fitted
  `nu` coefficient near the finite-variance boundary at 2, and checks that the
  simulation summary records the expected `student_nu` warning.
- Updated `inst/sim/README.md` to document the new diagnostic columns.
- Refreshed dashboard active-work text so it names `drmTMB#59` as the active
  row without saying the current main branch is still the previous merge.

## Mathematical Contract

The fitted Student-t family still uses `nu = 2 + exp(eta_nu)`, so the model is
a finite-variance Student-t route and cannot represent `nu <= 2` tails. This
slice does not change the likelihood or parameterization; it only preserves the
existing `check_drm()` boundary diagnostic in simulation artifacts.

## Files Changed

- `inst/sim/fit/sim_summarise_student_shape.R`
- `tests/testthat/test-phase18-student-shape-summary-smoke.R`
- `inst/sim/README.md`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-student-nu-sim-diagnostics.md`

## Checks Run

- `Rscript -e "devtools::test(filter = 'phase18-student-shape', reporter = 'summary')"`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `jq -r '.active_work[].text' docs/dev-log/dashboard/status.json docs/dev-log/dashboard/sweep.json | rg -n 'post-#612|current main is post|6386eb8'`
- `sh tools/start-mission-control.sh --background && curl -fsS http://127.0.0.1:8765/status.json | jq '{updated, metrics, active_work}'`

## Tests Of The Tests

The new test checks a boundary path rather than only the ordinary Student-t
smoke grid. It manipulates a fitted object to place `nu` near 2 and verifies
that the simulation summary captures the same finite-variance warning that
`check_drm()` reports to users.

## Consistency Audit

The implementation matches `docs/design/176-numerical-guard-simulation-audit.md`:
Student-t `nu = 2 + exp(eta_nu)` is a model-defining finite-variance
restriction, not a hidden likelihood-altering clamp. The simulation summaries
now expose the warning state needed for a future ADEMP/Williams boundary pilot.

## GitHub Issue Maintenance

`drmTMB#59` remains the active numerical-guard simulation umbrella. This slice
does not close it because no new operating-characteristic artifact was run; it
only makes the Student-t boundary diagnostic auditable in future artifacts.

## What Did Not Go Smoothly

The previous dashboard source used a literal "current main is post-#612" phrase
that became stale as soon as #613 merged. This refresh keeps the active-work
text row-oriented instead of merge-number-oriented.

## Team Learning

For active dashboard text, name the active row and the next evidence need. Put
exact merge evidence in check-log entries and PR comments, where it can remain
historical instead of pretending to be live state.

## Known Limitations

This is diagnostic plumbing only. It does not run the Student-t finite-variance
boundary pilot, add coverage evidence, change profile or bootstrap behavior,
relax Julia gates, add `engine_control`, promote release readiness, or change
the Student-t likelihood.

## Next Actions

- Run a small Student-t finite-variance-boundary diagnostic pilot that compares
  ordinary `nu` and low-`nu` cells and reports `student_nu_status` rates beside
  bias, RMSE, coverage, MCSE, convergence, `pdHess`, warnings, and runtime.
