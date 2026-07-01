# After Task: Q-Series q2 animal correlation miss diagnostic

## 1. Goal

Turn the animal q2 fixed-8 SR150 correlation pregrid undercoverage into a
first-class blocker diagnostic without promoting the linked Q-Series row.

## 2. Implemented

- Added `docs/dev-log/dashboard/structured-re-q2-animal-correlation-miss-diagnostic.tsv`.
- Added `docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-miss-diagnostic-local/animal-cor-miss-rows.tsv`.
- Updated the Q-Series widget to show the diagnostic as a separate blocker
  signal near the top of the 104-row board.
- Updated `structured-re-q2-slope-row-gate-synthesis.tsv` so the animal q2 row
  points at the miss diagnostic and still keeps `planned/planned`.

## 3a. Decisions and Rejected Alternatives

Decision: bank the miss taxonomy as blocker evidence and move the animal q2
next gate to a Fisher/Rose interval-calibration decision.

Rejected alternatives:

- Do not treat 150/150 finite Wald/profile intervals as interval readiness.
- Do not top up before deciding whether the upper-tail miss shape is
  calibration- or interval-channel-specific.
- Do not promote animal q2, spatial q2, sigma, q4/q8, or non-Gaussian rows from
  this artifact.

## 3b. Mathematical Contract

This diagnostic reuses the fixed-8 animal q2 correlation estimand
`mu1:x+mu2:x` with true correlation 0.2. It does not change the likelihood,
parameterization, interval construction, or formula grammar. It classifies each
SR150 replicate by whether the Wald interval or endpoint-profile interval lies
entirely below or above the truth, then retains any interval miss or
boundary/convergence flag in the miss ledger.

## 4. Files Touched

- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-q2-animal-correlation-miss-diagnostic.tsv`
- `docs/dev-log/dashboard/structured-re-q2-animal-correlation-pregrid-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-row-gate-synthesis.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-miss-diagnostic-local/README.md`
- `docs/dev-log/simulation-artifacts/2026-06-29-q2-animal-correlation-miss-diagnostic-local/animal-cor-miss-rows.tsv`
- `docs/dev-log/check-log.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 1 q2 animal correlation miss diagnostic
  row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 6762 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `git diff --check`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q2-animal-correlation-miss-diagnostic.md')"`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`: dashboard already listening at `http://127.0.0.1:8765/`, after a fresh `mission_control_ok`.
- `curl -fsS http://127.0.0.1:8765/version.txt`: `r101`.
- `curl -fsS http://127.0.0.1:8765/structured-re-q2-animal-correlation-miss-diagnostic.tsv`: served the one-row diagnostic sidecar.
- `curl -fsS http://127.0.0.1:8765/index.html | rg 'r101|Animal q2 miss diag|structured-re-q2-animal-correlation-miss-diagnostic|animal miss'`: found all widget markers.

## 6. Tests of the Tests

The focused test checks both the one-row dashboard sidecar and the generated
19-row miss ledger. It asserts the exact shared upper-tail/lower-tail miss
counts, the Wald-only upper miss, and boundary seed 733197, and verifies that
the linked Q-Series row remains `planned/planned`.

## 7a. Issue Ledger

No GitHub issue was opened or closed in this local diagnostic slice. The
artifact is a row-level evidence update inside the existing Q-Series board work.

## 8. Consistency Audit

The widget, validator, R test, check log, dashboard README, and row-gate sidecar
all describe the same boundary: animal q2 is fit-stable enough for diagnostics,
but the SR150 fixed-8 correlation interval evidence is undercovered and
upper-tail imbalanced. No status promotion is made.

## 9. What Did Not Go Smoothly

The first diagnostic extraction counted `n_fit_ok` from a nonexistent `fit_ok`
column. The source replicate TSV uses `attempt_status = fit_ok`, so the sidecar
was corrected to 150 fit-ok replicates before validation.

## 10. Known Residuals

This is SR150 local evidence with MCSE 0.0259 for endpoint-profile coverage. It
is not a top-up, not a support-grade run, not a q4/q8 result, and not a
non-Gaussian result. The next technical question is whether animal q2 needs a
skew-aware correlation interval, another calibration route, or a stop decision.

## 11. Team Learning

Rose's split-state rule paid off here: finite intervals and `pdHess = TRUE` are
not enough for inference readiness. The widget needs separate fit stability,
interval finiteness, coverage, miss shape, and promotion state.

## 12. Next Actions

- Run the validator, focused tests, and dashboard serve check.
- Ask Fisher/Rose whether the miss shape justifies a skew-aware interval or
  animal-specific calibration experiment before any more animal q2 compute.
