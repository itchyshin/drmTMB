# Q-Series q1 sigma SR150 blocker status sync

## 1. Goal

Make the imported animal/relmat q1 `sigma:(Intercept)` SR150 pregrid result a
durable board blocker without changing any Q-Series support-cell status.

## 2. Implemented

- Updated `qseries_animal_q1_sigma_intercept` and
  `qseries_relmat_q1_sigma_intercept` so their support-cell evidence points to
  `structured-re-gaussian-lowq-sigma-intercept-pregrid-results.tsv`.
- Updated their denominator policy to
  `sr150_pregrid_diagnostic_blocked_not_coverage`.
- Synced the same blocker into the low-q audit, next-campaign queue,
  closure-triage ledger, and sweep summary.
- Kept both support cells at `point_fit/planned/planned`.
- Updated mission-control validation and focused conversion-contract tests for
  the SR150 blocker wording.
- Bumped the dashboard widget build to `r171`.

## 3a. Decisions and Rejected Alternatives

Fisher rejected promotion from the finite subset because the SR150 evidence has
only 115/150 usable raw-Wald intervals and 118/150 warning replicates. The
rejected alternative was to treat 113/115 finite-subset coverage as retained
coverage evidence. That would hide interval censoring, so the rows stayed
planned for interval and coverage.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv`
- `docs/dev-log/dashboard/sweep.json`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- Scoped `git diff --check` over the touched dashboard, validator, and focused
  test files: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 9527 PASS / 0 FAIL / 0 WARN /
  0 SKIP.
- Dashboard JavaScript extracted from `docs/dev-log/dashboard/index.html` and
  checked with `node --check`: passed.

## 6. Tests of the Tests

The validator and focused test require both linked support cells to remain
`point_fit/planned/planned`, require the SR150 evidence URL, require the
115/150 and 118/150 blocker text, and reject any `inference_ready` or
`supported` wording for these rows.

## 7a. Issue Ledger

No GitHub issue was updated in this historical blocker-sync slice. The current
follow-up generator sync records the later issue search and supersedes the
row-selection drift found after this note was first written.

## 8. Consistency Audit

The blocker was checked across the support-cell TSV, low-q status audit,
closure triage, queue ledger, sweep summary, mission-control validator, and
focused conversion-contract tests. This note was later repaired to the
11-section protocol after Rose found that its original section headings were
too loose.

## 9. What Did Not Go Smoothly

The support-cell and audit surfaces were updated before the active
row-selection generator was updated. A later Rose audit found that the
row-selection generator could still recreate stale
`sigma_smoke_route_passed_denominator_review_hold` wording for animal/relmat.

## 10. Known Residuals

The SR150 evidence is diagnostic-blocked, not a coverage pass. The sigma
intercept interval route must be hardened or replaced before SR475/SR1000
top-up, DRAC denominator escalation, TSV promotion, `inference_ready`, or
public-support claims.

## 11. Team Learning

When a dashboard row is hand-synced after an imported cluster result, update
the source generator in the same pass or explicitly mark the generated file as
historical. Otherwise a later rerun can silently roll the board backward.
