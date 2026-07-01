# Q-Series q1 Mu Smoke Status Sync

## 1. Goal

Sync the Gaussian low-q q1 `mu` intercept support-cell, status-audit, and
row-selection ledgers to the executed local n=5 smoke without promoting any
Q-Series support status.

## 2. Implemented

- Updated the four q1 `mu` intercept support-cell rows to point at
  `structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv` while keeping
  `fit_status=point_fit`, `interval_status=planned`, and
  `coverage_status=planned`.
- Updated the four matching Gaussian low-q status-audit rows so their evidence
  basis names the local n=5 fixture smoke and their next gate is Fisher/Rose
  review before host or denominator escalation.
- Updated `tools/summarize-structured-re-gaussian-lowq-row-selection.R` so the
  four q1 `mu` intercept rows now report
  `local_smoke_completed_review_pending` and
  `fisher_rose_review_before_host_or_denominator_escalation`.
- Regenerated `structured-re-gaussian-lowq-row-selection.tsv` and its artifact
  mirror.
- Updated the q1 `mu` smoke runner filter so reruns can read the completed
  local-smoke row-selection state.
- Updated mission-control validation and the focused conversion-contract tests
  to guard the completed-smoke state.
- Bumped the dashboard build to `r141` and added the q1 `mu` smoke result
  sidecar to the widget note.

## 3a. Decisions and Rejected Alternatives

This promotes exactly no Q-Series row. The evidence is a local n=5 fixture
smoke under `default_confint_wald_direct_sd_mu` with all attempted rows
retained. It is not calibrated interval evidence, not coverage evidence, not
`inference_ready`, not `supported`, not sigma, not q2/q4/q8, not
non-Gaussian, not REML, not AI-REML, not bridge support, and not public support.

I rejected promoting these rows to `inference_ready` because n=5 is a route
smoke, not a calibrated denominator. I also kept the older Totoro/FIIA smoke
contract visible because it explains the provenance of the local smoke, but the
current row-selection state now reflects the imported artifact.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-smoke-status-sync.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/run-structured-re-gaussian-lowq-mu-intercept-dry-run.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells, 35
  Gaussian low-q status-audit rows, 23 Gaussian low-q row-selection rows, 4 q1
  `mu` dry-run rows, 4 q1 `mu` smoke-contract rows, and 4 q1 `mu`
  smoke-result rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8415 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `node -e 'const fs=require("fs"); const html=fs.readFileSync("docs/dev-log/dashboard/index.html","utf8"); const m=html.match(/<script>([\s\S]*)<\/script>/); if(!m) throw new Error("no script"); new Function(m[1]); console.log("dashboard_js_ok");'`:
  passed with `dashboard_js_ok`.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed and confirmed the dashboard was already listening.
- `curl -fsS http://127.0.0.1:8765/version.txt`: returned `r141`.
- `curl -fsS http://127.0.0.1:8765/ | rg -n "r141|Q-Series Support Cells|structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv"`:
  found the widget, build, and sidecar reference.
- `curl -fsS http://127.0.0.1:8765/structured-re-gaussian-lowq-row-selection.tsv | rg -n "qseries_(animal|phylo|relmat|spatial)_q1_mu_intercept"`:
  confirmed the served rows are `local_smoke_completed_review_pending`.
- `rm -rf tools/__pycache__ && find tools -type d -name '__pycache__' -print`:
  returned no paths.

## 6. Tests of the Tests

The focused test now checks the row-selection status, run mode, evidence URL,
and required q1 `mu` smoke phrases. The validator separately checks the same
state and verifies that linked support cells remain `point_fit/planned/planned`.
This guards the intended behaviour: import the local smoke evidence without
turning it into interval or coverage readiness.

## 7a. Issue Ledger

No GitHub issue action was taken. This slice changes internal dashboard/status
evidence pointers and does not change public support claims.

## 8. Consistency Audit

- The support-cell TSV, Gaussian low-q status audit, row-selection TSV, and
  served dashboard all point the four q1 `mu` intercept rows at the local smoke
  result sidecar.
- The dashboard row-selection TSV and artifact mirror are byte-identical after
  regeneration.
- `rg -n "q1 mu.*ready_for_totoro_fiia_smoke|ready_for_totoro_fiia_smoke.*q1 mu|linked row-selection status must be ready_for_totoro_fiia_smoke|structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv; local n=2 q1 mu-intercept dry-run passed" tools tests docs/dev-log/dashboard docs/dev-log/after-task docs/dev-log/check-log.md`
  returned no matches.
- `rg -n "qseries_(phylo|spatial|animal|relmat)_q1_mu_intercept.*(inference_ready|supported)|q1 mu-intercept.*(inference_ready|supported)|local n=5 smoke.*coverage evidence" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`
  returned only explicit non-claim boundary text such as "not
  inference_ready", "not supported", and "not coverage evidence".
- README, ROADMAP, NEWS, and formula grammar docs did not need changes because
  this was an internal evidence-ledger sync, not a user-facing syntax or
  behaviour change.

## 9. What Did Not Go Smoothly

The row-selection generator still had an old q1 `mu` assignment before a later
override. It did not affect the regenerated TSV, but it made stale-wording
searches noisy, so I removed the redundant assignment.

## 10. Known Residuals

The local n=5 smoke is too small for calibrated interval or coverage claims.
Fisher/Rose still need to review the smoke before any host or denominator
escalation. Totoro/FIIA access or checkout remains unresolved from this shell,
and Nibi/Rorqual/DRAC remain blocked before denominator work for these rows.

## 11. Team Learning

When a tiny smoke moves from contract to executed local artifact, update the
support-cell source, status-audit row, generated row-selection sidecar, runner
filter, validator, focused test, widget build, and after-task note in one pass.
Otherwise the board can say both "ready to smoke" and "smoke completed" for the
same row.

## Next Actions

- Continue row-by-row Q-Series closure using the same split between stability,
  local smoke, recovery, interval readiness, and coverage readiness.
- For q1 `mu` intercept rows, the next scientific gate is Fisher/Rose review of
  the local n=5 smoke and a denominator decision before any cluster run or TSV
  promotion.
