# Q-Series q1 Mu+Sigma Smoke Status Sync

## 1. Goal

Sync the Gaussian low-q q1 `mu+sigma` intercept rows to the executed local n=1
target-smoke evidence without promoting any Q-Series support status.

## 2. Implemented

- Updated the four q1 `mu+sigma` intercept support-cell rows so their evidence
  points at `structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv`.
- Kept all four support cells at `fit_status=point_fit`,
  `interval_status=planned`, and `coverage_status=planned`.
- Updated the matching Gaussian low-q status-audit rows to name local n=1
  target-smoke bookkeeping, including the phylo nonusable boundary/correlation
  interval signal.
- Updated `tools/summarize-structured-re-gaussian-lowq-row-selection.R` so the
  four q1 `mu+sigma` intercept rows report
  `local_smoke_completed_review_pending`,
  `fisher_noether_rose_review_before_endpoint_denominator`, and
  `first_smoke_n_rep=1`.
- Regenerated `structured-re-gaussian-lowq-row-selection.tsv` and its artifact
  mirror.
- Updated mission-control validation and the focused conversion-contract test
  to guard the review-pending local-smoke state.
- Bumped the dashboard build to `r142` and added the q1 `mu+sigma` smoke
  sidecar to the widget note.

## 3a. Decisions and Rejected Alternatives

This promotes exactly no Q-Series row. The local n=1 smoke separates direct
`sd_mu`, direct `sd_sigma`, and `mu-sigma` correlation targets. It is not
calibrated interval evidence, not coverage evidence, not `inference_ready`, not
`supported`, not q2 covariance support, not q4/q8, not non-Gaussian, not REML,
not AI-REML, not DRAC evidence, and not public support.

I rejected treating the spatial, animal, and relmat pass rows as a promotion
signal because the smoke has only one replicate per provider and phylo already
retains a nonusable boundary/correlation interval signal. The next legitimate
step is Fisher/Noether/Rose review of target separation and denominator rules.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-smoke-status-sync.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and wrote 23 Gaussian low-q row-selection rows.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 104 Q-Series support cells, 35
  Gaussian low-q status-audit rows, 23 Gaussian low-q row-selection rows, and
  4 Gaussian low-q `mu+sigma` intercept smoke rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8433 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- Dashboard JavaScript parse check from `docs/dev-log/dashboard/index.html`:
  passed with `dashboard_js_ok`.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-q1-mu-sigma-smoke-status-sync.md')"`:
  passed.
- `git diff --check` over the touched files: passed.
- `rm -rf tools/__pycache__ && find tools -type d -name '__pycache__' -print`:
  returned no paths.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background && curl -fsS http://127.0.0.1:8765/version.txt`:
  passed; the served dashboard returned `r142`.
- `curl -fsS http://127.0.0.1:8765/structured-re-gaussian-lowq-row-selection.tsv | python3 -c ...`:
  passed; the served row-selection TSV had 23 rows with 12
  `local_smoke_completed_review_pending`, 6 `hold_until_row_contract`, and 5
  `ready_for_totoro_fiia_smoke`, and all four q1 `mu+sigma` intercept rows
  pointed at `structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv`.

## 6. Tests of the Tests

Mission-control failed before the final wording fix because the low-q
status-audit rows no longer contained the exact protected phrase
`point/fixture evidence only`. I restored that phrase instead of weakening the
validator. The focused test now checks the four q1 `mu+sigma` rows for
review-pending local smoke, n=1, the correct sidecar, target separation, and
explicit blocked host escalation.

## 7a. Issue Ledger

No GitHub issue action was taken. This slice is an internal evidence-ledger
sync. It does not change user-facing syntax, fitting behaviour, interval
defaults, or public support claims.

## 8. Consistency Audit

- The support-cell TSV, Gaussian low-q status audit, generated row-selection
  TSV, and row-selection artifact mirror all point the four q1 `mu+sigma`
  intercept rows at the local-smoke evidence.
- The regenerated row-selection TSV has 23 rows: 12
  `local_smoke_completed_review_pending`, 6 `hold_until_row_contract`, and 5
  `ready_for_totoro_fiia_smoke`.
- The 104 support-cell rows still have only 5 `inference_ready` interval rows
  and 5 `inference_ready` coverage rows.
- The dashboard note now names
  `structured-re-gaussian-lowq-mu-sigma-intercept-local-smoke.tsv` as the q1
  `mu+sigma` target-smoke source.
- Neighbouring q1 `mu`, q1 `sigma`, q2, high-q, and non-Gaussian statuses were
  not promoted in this slice.

## 9. What Did Not Go Smoothly

The first mission-control rerun failed because my revised claim-boundary wording
said "point/fixture and local n=1 target-smoke evidence only" but omitted the
older exact guard phrase "point/fixture evidence only". That was a useful guard:
it forced the new local-smoke wording to remain compatible with the old
overclaim protection.

One served TSV check also failed because I combined a shell pipe and a Python
here-document incorrectly. I reran it with `python3 -c` so the TSV was passed as
stdin to the parser.

## 10. Known Residuals

The q1 `mu+sigma` intercept rows still need Fisher/Noether/Rose review before
Totoro/FIIA smoke or any denominator design. Phylo retains a nonusable
boundary/correlation interval signal. Nibi/Rorqual/DRAC remain blocked before
replicated denominator work. No q1 `mu+sigma` row is interval-ready,
coverage-ready, or supported.

## 11. Team Learning

When a combined endpoint row gains target-smoke evidence, keep the row visible
as attempted but preserve the target split. A local smoke can be useful for the
board without changing `interval_status` or `coverage_status`; the validator
should guard both facts at once.
