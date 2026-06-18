# After Task: Student-t Nu Boundary Diagnostic Pilot

## Goal

Bank a small diagnostic pilot for the Student-t finite-variance boundary in the
numerical-guard sensitivity lane tracked by `drmTMB#59`.

## Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/`.
- Added a reproducible `run-pilot.R` that uses the existing Phase 18 Student-t
  shape grid writer.
- Ran 25 replicates in each of two fixed-effect Student-t shape cells:
  `nu(w = 0) = 2.8` and `nu(w = 0) = 8.0`.
- Committed CSV summaries for conditions, fit-level `student_nu` statuses,
  cell-level diagnostic rates, parameter-level bias/RMSE, the standard Student-t
  shape writer tables, and session info.
- Refreshed mission-control active-work and activity text while keeping the
  broad #59 row active.

## Mathematical Contract

The fitted Student-t route is still `nu = 2 + exp(eta_nu)`. It is a
finite-variance Student-t model and cannot represent true `nu <= 2` tails. This
pilot checks whether fitted artifacts report `check_drm()` boundary warnings,
errors, notes, and ok states; it does not alter the likelihood or fit a
different tail model.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/run-pilot.R`
- `docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/student-nu-boundary-run-summary.csv`
- `docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/session-info.txt`
- `docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/tables/*.csv`
- `docs/dev-log/dashboard/status.json`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-student-nu-boundary-diagnostic-pilot.md`

## Checks Run

- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/run-pilot.R`
- `test ! -d docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/results`
- `Rscript -e "devtools::test(filter = 'phase18-student-shape', reporter = 'summary')"`
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null`
- `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null`
- `python3 tools/validate-mission-control.py`
- `git diff --check`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `sh tools/start-mission-control.sh --background && curl -fsS http://127.0.0.1:8765/status.json | jq '{updated, metrics, active_work: .active_work[0:4], first_activity: .activity[0]}'`
- `rg -n 'release readiness|CRAN readiness|coverage language|coverage claim|promotion language|promote|calibrated interval|true nu <= 2' docs/dev-log/simulation-artifacts/2026-06-17-student-nu-boundary-diagnostic-pilot/README.md docs/dev-log/after-task/2026-06-17-student-nu-boundary-diagnostic-pilot.md`
- `gh issue view 59 --repo itchyshin/drmTMB --json number,title,state,url --jq '{number,title,state,url}'`

## Tests Of The Tests

The artifact exercises the boundary path that #614 made visible in simulation
tables. In 25 low-`nu` replicates, the committed fit-status summary records
5 `student_nu` warnings and 3 `student_nu` errors. In the ordinary-`nu` cell it
records no warnings or errors, but 10 notes where fitted `nu` moved toward a
Gaussian-tail limit.

## Consistency Audit

The artifact follows `docs/design/176-numerical-guard-simulation-audit.md`:
Student-t `nu = 2 + exp(eta_nu)` is a model-defining restriction, and the
correct simulation output is an explicit diagnostic status rather than a claim
that low-tail fits are safe. The README names ADEMP and the Williams et al.
simulation-reporting discipline, records the DGP, estimands, methods,
performance measures, files, and boundaries, and avoids coverage or promotion
language.

## GitHub Issue Maintenance

`drmTMB#59` remains open. This pilot is a small evidence artifact inside the
numerical-guard sensitivity programme; it does not close the comprehensive
simulation framework issue.

The branch is based on post-#614 `main` at `6a536ae2`. Post-merge R-CMD-check
run `27735266431` passed on macOS, Ubuntu, and Windows; pkgdown run
`27736233532` built and deployed.

## What Did Not Go Smoothly

The first disposable prototype summarized parameter rows instead of unique
fit-level rows, which inflated the diagnostic counts. The committed runner now
creates a one-row-per-fit `student-nu-fit-status.csv` table and derives
diagnostic rates from that table.

## Team Learning

For diagnostic pilots, write an explicit fit-level status table before
aggregating parameter-level summaries. Parameter rows are useful for bias/RMSE,
but diagnostic rates should count fitted replicates.

## Known Limitations

This is a 25-replicate-per-cell diagnostic pilot. It is too small for calibrated
coverage, power, release, or CRAN-readiness language. It does not test random
effects, bivariate responses, structured effects, Julia bridge behavior,
profile/bootstrap calibration, stress data generated with true `nu <= 2`, or
external comparators.

## Next Actions

- After #614 and this artifact are merged, run a larger Student-t boundary
  calibration pilot if the team wants coverage or MCSE-backed interval language.
- Add an applied-user note explaining what to try when `check_drm()` reports a
  `student_nu` warning or error.
