# Q-Series low-q smoke ledger sync

## 1. Goal

Synchronize the Gaussian low-q smoke ledgers after Fisher/Rose/Rose review found
two stale status surfaces, without promoting any Q-Series row.

## 2. Implemented

- Changed the four q1 `mu` intercept row-selection rows from
  `local_smoke_completed_review_pending` to
  `totoro_fiia_smoke_operational_hold`.
- Kept those rows at `point_fit/planned/planned`; the new label says the local
  rehearsal passed and the tiny Totoro/FIIA smoke contract is reviewed, but the
  host smoke is still operationally held.
- Updated the four q2 `mu1+mu2` intercept support-cell rows to point at
  `docs/dev-log/dashboard/structured-re-q2-intercept-local-smoke.tsv`.
- Updated the matching four Gaussian low-q status-audit rows so they name the
  local q2 smoke, Fisher/Rose sign-off, Totoro/FIIA host hold,
  endpoint-SD/correlation separation, no status promotion, and the
  Nibi/Rorqual/DRAC denominator block.
- Added validator and focused-test guards so q1 `mu` and q2 intercept ledger
  drift fails instead of passing mission control.
- Bumped the dashboard build from `r144` to `r145`.

## 3a. Decisions and Rejected Alternatives

- Chose a status-language sync instead of an inference promotion. The q1 `mu`
  local smoke and q2 local smoke are fixture evidence, not calibrated coverage.
- Chose `totoro_fiia_smoke_operational_hold` for q1 `mu` intercept rows because
  the remaining blocker is host access/checkout, not Fisher/Rose review of the
  tiny-smoke contract.
- Did not move q1 `sigma`, matched `mu+sigma`, q2 slope spatial/animal, high-q,
  or non-Gaussian rows.
- Did not use Nibi/Rorqual/DRAC as substitutes for the first q1/q2 smoke gate.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/version.txt`
- `docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`
- `tools/summarize-structured-re-gaussian-lowq-row-selection.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-29-q-series-lowq-smoke-ledger-sync.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file tools/summarize-structured-re-gaussian-lowq-row-selection.R --overwrite=true`:
  passed and regenerated 23 Gaussian low-q row-selection rows.
- `cmp -s docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv docs/dev-log/simulation-artifacts/2026-06-29-gaussian-lowq-row-selection-local/structured-re-gaussian-lowq-row-selection.tsv`:
  passed.
- `/opt/homebrew/bin/air format tools/summarize-structured-re-gaussian-lowq-row-selection.R tools/validate-mission-control.py tests/testthat/test-structured-re-conversion-contracts.R`:
  passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-gaussian-lowq-row-selection.R")); invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R")); cat("parse_ok\n")'`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`:
  passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`:
  passed with 8526 PASS / 0 FAIL / 0 WARN / 0 SKIP.

## 6. Tests of the Tests

The focused test now fails if the four q1 `mu` intercept row-selection rows
fall back to the stale `local_smoke_completed_review_pending` state. It also
fails if the four q2 intercept support-cell or low-q audit rows stop pointing
at `structured-re-q2-intercept-local-smoke.tsv`, lose the Fisher/Rose host-hold
language, lose endpoint-SD/correlation separation, or change from
`point_fit/planned/planned`.

The validator repeats those guards in mission control, including support-cell
and low-q audit evidence URLs.

## 7a. Issue Ledger

- Fixed stale q1 `mu` row-selection wording that blurred local rehearsal review
  with the reviewed Totoro/FIIA host-smoke contract.
- Fixed stale q2 intercept evidence URLs and next gates in the support-cell TSV
  and Gaussian low-q status audit.
- Deferred actual Totoro/FIIA execution, Nibi/Rorqual/DRAC denominator work, and
  any interval/coverage promotion.

## 8. Consistency Audit

Checked the q1 `mu` intercept rows across dry-run, smoke-contract,
smoke-results, row-selection, validator, and focused tests. Checked the q2
intercept rows across support cells, low-q status audit, row-selection,
q2 local-smoke sidecar, validator, and focused tests. All linked support-cell
statuses remain `point_fit/planned/planned`.

## 9. What Did Not Go Smoothly

The first validator run failed because the dry-run validator still expected the
old q1 `mu` row-selection status. That was useful: it caught the remaining stale
linkage before the slice was reported as green.

## 10. Known Residuals

- q1 `mu` intercept rows still need the reviewed Totoro/FIIA host smoke before
  any denominator work.
- q2 intercept rows still need the reviewed Totoro/FIIA host smoke before any
  denominator work.
- q1 `sigma`, matched `mu+sigma`, q2 slope spatial/animal, q4/q8, and
  non-Gaussian interval rows remain unfinished separate arcs.
- No row was promoted to `inference_ready` or `supported` in this slice.

## 11. Team Learning

When a row moves from local review to host-smoke authorization, the dashboard
needs a distinct operational-hold state. Otherwise the board looks scientifically
blocked when the real blocker is host access, and stale evidence URLs can hide
behind a green validator.
