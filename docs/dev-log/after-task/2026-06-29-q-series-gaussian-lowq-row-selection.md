# After Task: Q-Series Gaussian low-q row selection

## 1. Goal

Turn the broad Gaussian low-q point/fixture queue into an exact row-selection
and host-gate contract before using Totoro, FIIA, Nibi, Rorqual, or DRAC.

## 2. Implemented

This promotes exactly no Q-Series row under the Gaussian low-q row-selection
channel, with generated dashboard/artifact TSV evidence only, and does not
claim `interval_status`, `coverage_status`, `inference_ready`, `supported`,
sigma readiness, q2/q4/q8 readiness, non-Gaussian interval readiness, REML,
AI-REML, bridge support, or public support.

Added `tools/summarize-structured-re-gaussian-lowq-row-selection.R`. The
script joins `structured-re-q-series-support-cells.tsv` to
`structured-re-gaussian-lowq-status-audit.tsv`, keeps the 27 structured
Gaussian low-q gate-required rows, excludes the four q1 `mu` one-slope rows
already blocked by interval-shape evidence, and writes a 23-row host-gate
contract:

- 4 first smoke candidates: q1 `mu` intercept rows for phylo, spatial, animal,
  and relmat;
- 4 scale-side holds: q1 `sigma` intercept rows;
- 8 matched endpoint holds: q1 `mu+sigma` intercept and one-slope rows;
- 5 q2 intercept holds;
- 2 special target holds: `phylo_interaction()` and direct-SD univariate rows.

The script writes:

- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`

Mission control now validates the row-selection sidecar, and the widget renders
a "Low-q row select" card/table at build `r117`.

## 3a. Decisions and Rejected Alternatives

Decision: allow only the four q1 `mu` intercept rows to advance to a local
dry-run, then a tiny Totoro/FIIA smoke if Fisher/Rose accept the row contract.
Nibi/Rorqual/DRAC remain blocked until local and Totoro/FIIA evidence passes.

Decision: keep q1 `mu` one-slope rows out of this sidecar. They already have
negative interval-shape and split-calibration evidence and should not be
rescued by a broad low-q row-selection table.

Rejected alternatives:

- Do not include sigma rows in the first smoke tranche; they need a scale-side
  interval route.
- Do not bundle matched `mu+sigma` rows with q1 `mu` intercept rows.
- Do not let q2 intercept rows inherit q1 evidence.
- Do not run DRAC denominator work from this contract.

## 4. Files Touched

- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-row-selection.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed; wrote 23 Gaussian low-q row-selection rows.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`, including 23 Gaussian low-q row-selection
  rows.
- Dashboard JavaScript parse check: passed with `dashboard_js_parse_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  7392 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-29-q-series-gaussian-lowq-row-selection.md')"`:
  passed.
- `git diff --check`: passed.
- `DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background`:
  passed; the dashboard was already listening at `http://127.0.0.1:8765/`.
- Served dashboard checks at `http://127.0.0.1:8765/`: `version.txt`
  returned `r117`, the row-selection TSV served 24 lines including the header,
  `/` contained `Low-q row select`, `/` contained the row-selection TSV fetch
  path, and the TSV contained `first_smoke_candidate_location_intercept` plus
  `Nibi/Rorqual/DRAC before local dry-run`.

## 6. Tests of the Tests

The new focused test requires 23 generated rows, exact row-selection class
counts, exactly four q1 `mu` intercept smoke candidates, exclusion of the four
q1 `mu` one-slope blockers, matching support-cell statuses, and byte-for-field
agreement between the dashboard TSV and the artifact mirror.

Mission control also checks class counts, exact smoke-candidate cell IDs, host
gates, linked support-cell statuses, local evidence links, and non-claim
wording.

## 7a. Issue Ledger

No GitHub issue was opened, closed, or commented on. This is local
mission-control evidence hygiene inside the active Q-Series board.

## 8. Consistency Audit

Checked the support-cell TSV, Gaussian low-q audit TSV, campaign queue, q1
`mu` blocker sidecars, dashboard renderer, dashboard README, validator, and
focused tests.

The board remains 104 rows with exactly five interval-and-coverage
`inference_ready` rows and no structured `supported` row. The row-selection
contract does not change support-cell status and does not authorize DRAC.

## 9. What Did Not Go Smoothly

No compute was run because the point of this slice is to prevent premature
compute. The useful output is an exact host gate, not a fitted-model result.

## 10. Known Residuals

The four q1 `mu` intercept rows still need a local dry-run, Totoro/FIIA smoke,
and Fisher/Rose review before any denominator campaign. Sigma, matched
`mu+sigma`, q2 intercept, direct-SD, `phylo_interaction()`, q4/q8, and
non-Gaussian interval rows remain separate unfinished arcs.

## 11. Team Learning

A row-selection table is useful when many rows share a broad "point/fixture
evidence" status. It stops the team from spending DRAC time on rows that still
need target contracts, while preserving a small path for the rows that are
actually ready to smoke.
