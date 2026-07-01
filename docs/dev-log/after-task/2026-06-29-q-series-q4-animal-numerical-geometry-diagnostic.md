# After Task: Q-Series q4 animal numerical-geometry diagnostic

## 1. Goal

Bank a narrow Gauss-style numerical-geometry diagnostic for the animal q4
all-four one-slope row after the Nibi admission probe showed 2/16 positive
Hessians, without promoting q4 interval reliability, coverage,
`inference_ready`, `supported`, q8, REML, AI-REML, bridge support, or public
support.

## 2. Implemented

This promotes exactly no Q-Series row under the animal q4 all-four
numerical-geometry diagnostic channel, with selected-seed fit/Hessian
denominator accounting, and does not claim q4 interval reliability, q4
coverage, `inference_ready`, `supported`, q8 support, REML, AI-REML, broad
bridge support, derived-correlation intervals, or public support.

Added `tools/run-structured-re-q4-animal-numerical-geometry-diagnostic.R`, a
small internal runner that reuses the q4 all-four stability fixture but writes
its own artifact directory after sourcing the shared helper prefix. The runner
captures fit-level geometry for four selected `more_levels` seeds:
`910101`, `910102`, `910107`, and `910110`. Those seeds compare two
`pdHess = FALSE` admission failures against the two `pdHess = TRUE` admission
smoke successes.

Added two dashboard sidecars:

- `structured-re-q4-animal-numerical-geometry-diagnostic.tsv`: four fit-level
  rows with optimizer selection, selected-attempt objective delta, fixed
  gradient size, `sdreport` covariance eigenvalues, q4 theta magnitude,
  derived-correlation/covariance conditioning, direct-SD boundary counts, and
  diagnostic-only claim boundaries.
- `structured-re-q4-animal-numerical-geometry-attempts.tsv`: seven
  optimizer-attempt rows explaining the default and fallback-BFGS attempts
  behind the four retained fits.

The diagnostic found that the two `pdHess = FALSE` rows have large fixed
gradients, negative `sdr$cov.fixed` eigenvalues, extreme q4 theta values, and
selected fallback-BFGS fits whose objective is worse than the best failed
default attempt. The two `pdHess = TRUE` rows have finite covariance geometry,
but one still selects a worse fallback objective. That keeps the next step in
the numerical geometry lane: parameter-transform or optimizer-start work before
any q4 coverage-grid design.

## 3a. Decisions and Rejected Alternatives

Decision: do not launch q4 coverage arrays on DRAC from this evidence. The
sidecar explains the current animal q4 admission failure more precisely, but it
does not pass the q4 admission gate.

Rejected alternatives:

- Do not treat the two `pdHess = TRUE` selected seeds as a coverage
  denominator.
- Do not treat fallback-BFGS convergence as automatically better when the
  selected objective is worse than the best failed default attempt.
- Do not promote the animal q4 all-four row, q8-shaped rows, derived
  correlations, REML, AI-REML, bridge parity, or public support.
- Do not spend Nibi/Rorqual budget on coverage before the optimizer/Hessian
  geometry has a stable admission story.

## 3b. Mathematical Contract

No likelihood, formula grammar, estimator, or interval implementation changed.
The diagnostic uses the same animal A-matrix q4 all-four one-slope formula
shape as the admission probe:

- `mu1 = y1 ~ x + animal(1 + x | p | id, A = A)`
- `mu2 = y2 ~ x + animal(1 + x | p | id, A = A)`
- `sigma1 = ~ z + animal(1 + x | p | id, A = A)`
- `sigma2 = ~ z + animal(1 + x | p | id, A = A)`
- `rho12 = ~ 1`

The diagnostic target is numerical geometry around the q4 structured random
effect block, not interval calibration. Direct SD estimates, q4 theta
magnitudes, derived q4 correlation/covariance eigenvalues, and
`sdr$cov.fixed` eigenvalues are recorded to guide Gauss/Noether review.

## 4. Files Touched

- `tools/run-structured-re-q4-animal-numerical-geometry-diagnostic.R`
- `docs/dev-log/dashboard/structured-re-q4-animal-numerical-geometry-diagnostic.tsv`
- `docs/dev-log/dashboard/structured-re-q4-animal-numerical-geometry-attempts.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q4-animal-numerical-geometry-local/`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q4-animal-numerical-geometry-diagnostic.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-animal-numerical-geometry-diagnostic.R --overwrite=true --write-dashboard=true`: passed, writing four fit-level rows and seven optimizer-attempt rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/run-structured-re-q4-slope-interval-stability-probe.R`: reran the original q4 stability probe to repair an early path leak from the first draft of the numerical diagnostic runner.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/run-structured-re-q4-animal-numerical-geometry-diagnostic.R")); cat("runner_parse_ok\n")'`: passed.
- `/opt/homebrew/bin/air format tools/run-structured-re-q4-animal-numerical-geometry-diagnostic.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Dashboard JavaScript parse check via `node`: `dashboard_js_ok`.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including four structured RE q4 animal numerical-geometry diagnostic rows and seven optimizer-attempt rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 7051 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q4-animal-numerical-geometry-diagnostic.md')"`: after-task structure check passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`.
- Served dashboard verification: `curl -fsS http://127.0.0.1:8765/version.txt` returned `r109`; `index.html` contained the `q4AnimalNumericalGeometryDiagnostic` markers; `structured-re-q4-animal-numerical-geometry-diagnostic.tsv` served four rows; `structured-re-q4-animal-numerical-geometry-attempts.tsv` served seven rows.

## 6. Tests of the Tests

The first draft of the runner sourced the q4 stability helper prefix after
setting its own output paths, so the helper reset `artifact_dir` and wrote
diagnostic rows through the older q4 slope stability result path. This was
caught by inspecting the sidecar paths before validator wiring. The runner now
restores its own artifact, dashboard, attempt, run-log, session-info, and
git-SHA paths after sourcing the helper prefix. The original q4 stability
runner was rerun after the fix, restoring the expected 128-row source artifact
and 64-row dashboard sidecar.

The mission-control validator and focused R test now require the exact
four-seed diagnostic contrast, the seven optimizer-attempt rows, the
`pdHess = FALSE` versus `pdHess = TRUE` split, selected-objective deltas,
negative covariance-eigenvalue blockers in the failed-Hessian rows, finite
geometry in the pass-smoke rows, and diagnostic-only claim wording.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This was a local
diagnostic/dashboard banking slice inside the Q-Series high-q arc.

## 8. Consistency Audit

The linked Q-Series animal q4 all-four one-slope cell remains
`interval_status = diagnostic_only` and `coverage_status = planned`. The new
diagnostic sidecar itself records `interval_claim_status = diagnostic_only`
and `coverage_status = not_evaluable`. The widget and README keep stability,
optimizer-attempt evidence, inference readiness, interval status, and coverage
status separate.

## 9. What Did Not Go Smoothly

The shared helper prefix reset the new runner's paths on the first draft, so
the first execution briefly wrote through the old q4 slope stability artifact
path. That was repaired before validator/test wiring by rerunning the original
q4 stability probe and then restoring the numerical diagnostic runner's own
paths after sourcing.

## 10. Known Residuals

Animal q4 all-four direct-SD admission remains blocked. The four-seed
diagnostic narrows the suspected failure mode to optimizer/Hessian geometry,
but it does not validate a parameter transform, profile interval channel, or
coverage denominator. Derived q4 correlations, q8 rows, REML, AI-REML, and
bridge parity remain future work.

## 11. Team Learning

When a diagnostic runner sources a fixed-output helper, restore the derived
paths immediately after the source call and inspect the `source_artifact`
column before wiring a dashboard. For DRAC use, keep FIIA/Totoro to smoke work
and reserve Nibi/Rorqual for admission/top-up campaigns after the local
artifact contract is stable.

## 12. Next Actions

- Ask Gauss/Noether to design a parameter-transform or optimizer-start
  experiment for the animal q4 all-four block.
- Keep q4 coverage-grid design paused until the admission denominator has
  stable `pdHess` and finite direct-SD interval rates.
- Ask Fisher/Rose to review any future denominator-policy change before a
  Q-Series status edit.
