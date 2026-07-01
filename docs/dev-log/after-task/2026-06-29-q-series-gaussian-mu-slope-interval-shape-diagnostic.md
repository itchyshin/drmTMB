# After Task: Q-Series Gaussian mu-slope interval-shape diagnostic

## 1. Goal

Make the Gaussian q1 `mu` one-slope SR475 blocker visible at target level in
mission control, before spending DRAC/Totoro time on another denominator
campaign.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian q1 `mu` interval-shape
diagnostic channel, with retained SR475 target-level denominator accounting,
and does not claim `inference_ready`, `supported`, sigma readiness, q2/q4/q8
readiness, non-Gaussian intervals, REML, AI-REML, or public support.

Added `tools/summarize-structured-re-gaussian-mu-slope-interval-shape.R`, which
derives a six-row sidecar from the existing SR475 replicate TSVs plus the
endpoint-profile boundary diagnostic TSVs. The script writes:

- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-shape-local/structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-shape-local/structured-re-gaussian-mu-slope-interval-shape-upper-miss-rows.tsv`

The sidecar splits phylo, relmat, and spatial q1 `mu` one-slope rows into
intercept and slope targets. All six target rows meet MCSE `<= 0.01`, but all
six have more upper misses than lower misses. The combined upper-miss ledger
has 73 retained upper misses.

Mission control now validates this sidecar and fails if the diagnostic drifts
away from the raw artifact, from `planned/planned` linked support-cell status,
or from `do_not_promote`. The dashboard renders a compact "Mu shape targets"
table above the detailed 104-row Q-Series support-cell ledger and links the
three affected support cells to the diagnostic.

## 3a. Decisions and Rejected Alternatives

Decision: keep this as blocker evidence, not a promotion. MCSE passing is not
enough when one-sided misses still show target-level upper-tail pressure.

Decision: do not use Totoro, FIIA, Nibi, Rorqual, or the DRAC machines for this
step. The evidence already says more denominator work should wait until Fisher
and Rose accept a new interval-shape or calibration rule.

Rejected alternatives:

- Do not promote phylo, relmat, or spatial q1 `mu` one-slope rows to
  `inference_ready`.
- Do not infer anything for animal q1 `mu`, sigma, q2, q4/q8, or
  non-Gaussian rows from this sidecar.
- Do not call the SR475 result `supported`.
- Do not hide endpoint-profile failures or boundary rows from the denominator.

## 3b. Mathematical Contract

No likelihood, TMB parameterization, estimator, or interval formula changed.
The script overlays endpoint-profile boundary rows onto the existing retained
Wald denominator and reports the target-level miss shape. The result is a
diagnostic of interval shape, not a new correction rule.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-mu-slope-interval-shape.R`
- `docs/dev-log/dashboard/structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-shape-local/structured-re-gaussian-mu-slope-interval-shape-diagnostic.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-mu-slope-interval-shape-local/structured-re-gaussian-mu-slope-interval-shape-upper-miss-rows.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-interval-shape-diagnostic.md`

## 5. Checks Run

- `/opt/homebrew/bin/air format
  tools/summarize-structured-re-gaussian-mu-slope-interval-shape.R
  tools/validate-mission-control.py
  tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file tools/summarize-structured-re-gaussian-mu-slope-interval-shape.R
  --overwrite=true`: passed; wrote 6 diagnostic rows and 73 upper-miss rows.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `node -e '...'`: passed with `dashboard_js_parse_ok` after extracting the
  dashboard script block from `docs/dev-log/dashboard/index.html`.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`: passed
  with `mission_control_ok`, including 104 Q-Series support cells and 6
  Gaussian mu-slope interval-shape diagnostic rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 7233 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-mu-slope-interval-shape-diagnostic.md')"`:
  passed.
- `git diff --check`: passed.
- `find . -type d -name '__pycache__' -print`: returned no paths after
  removing the `tools/__pycache__` directory created by `py_compile`.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh
  tools/start-mission-control.sh --background`: passed; the dashboard was
  already listening at `http://127.0.0.1:8765/`.
- Served dashboard checks: `curl -fsS http://127.0.0.1:8765/version.txt`
  returned `r113`, the interval-shape TSV served 7 lines including the header,
  and the in-app browser rendered the "Mu shape targets" card plus 6 target
  rows.

## 6. Tests of the Tests

The first mission-control rerun failed because `version.txt` had been bumped to
`r113` while the dashboard `BUILD` constant still said `r112`. The version
guard caught the stale widget build marker before the dashboard was served.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence hygiene inside the active Q-Series board.

## 8. Consistency Audit

The support-cell TSV remains unchanged for the linked q1 `mu` rows: phylo,
relmat, and spatial q1 `mu` one-slope cells stay `fit_status = point_fit`,
`interval_status = planned`, and `coverage_status = planned`. The new sidecar
is shown separately from inference readiness, matching the current board
policy that stability, recovery, interval, and coverage status are separate
signals.

## 9. What Did Not Go Smoothly

The dashboard version sync needed one extra pass. Mission control caught it
cleanly.

## 10. Known Residuals

Gaussian q1 `mu` one-slope remains blocked until a new interval-shape or
calibration rule is specified and reviewed. Animal q1 `mu` remains a separate
hard-negative row. q4/q8 remain diagnostic/planned/stability-blocked, and
non-Gaussian rows remain recovery-only, rejected, or planned.

## 11. Team Learning

For cluster-heavy arcs, an MCSE-qualified denominator is not automatically a
promotion. When the blocker is shape, the next useful step is a target-level
miss ledger and a new interval rule, not simply more replicates.

## 12. Next Actions

Ask Fisher and Rose whether to design a skew-aware or calibration-specific
interval route for Gaussian q1 `mu` one-slope rows. Use Totoro/FIIA only for
smoke and DRAC machines only for the first prespecified replacement-rule
campaign.
