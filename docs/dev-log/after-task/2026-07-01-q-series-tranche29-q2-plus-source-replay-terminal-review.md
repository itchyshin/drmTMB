# After Task: Q-Series Tranche 29 q2-plus Source Replay Terminal Review

## 1. Goal

Review the terminal Rorqual state of job 15027970 and bank the failed-before-R
evidence without importing it as a denominator, coverage result, or q2-plus
status promotion.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche29-source-replay-terminal-review.tsv`,
an eight-row terminal-review ledger. It records `sacct` state `FAILED`, exit
`1:0`, elapsed `00:01:37`, node `rc32610`, metadata-only artifacts, full
sha256 manifest failure at `./tools/run-structured-re-q2-intercept-smoke.R`,
and `r_runner_not_started`.

Mission Control build `r223` loads and renders the sidecar. The validator and
focused conversion-contract test check the terminal state, manifest failure
file, absence of R-runner output, no-new-compute/no-coverage/no-promotion
decisions, unchanged q2-plus support-cell status, and
Fisher/Rose/Noether/Gauss/Grace discussion rows.

## 3a. Decisions and Rejected Alternatives

Chose a terminal-failure review rather than a retry. The job failed before R
because the full source manifest had one checksum mismatch in the q2 intercept
smoke runner. The critical q2-plus entries were recorded, but the q2-plus runner
did not start and no smoke result TSVs were created.

Rejected treating this as a failed denominator replicate. There is no pdHess,
Wald, profile, optimizer, likelihood, or coverage evidence from Tranche 29.
The next gate is a checkpointed Tranche 30 choice: either bank a narrower
critical-manifest replay contract or park q2-plus.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche29-source-replay-terminal-review.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche29-q2-plus-source-replay-terminal-review.md`
- `docs/dev-log/recovery-checkpoints/2026-07-01-qseries-tranche29-codex-checkpoint.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Rorqual poll: `squeue` no longer had job 15027970; `sacct` reported
  `FAILED|1:0|00:01:37|rc32610`.
- Rorqual artifact inspection found only metadata files:
  `source-manifest-check.txt`, `critical-manifest-entries.txt`, and
  `run-log.txt`.
- Manifest tail/grep showed `sha256sum: WARNING: 1 computed checksum did NOT
  match` and `./tools/run-structured-re-q2-intercept-smoke.R: FAILED`.
- Tranche 29 TSV shape check: 9 lines including header, 34 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r223.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 8 Tranche 28 source-replay submission rows,
  8 Tranche 29 source-replay terminal-review rows, and 145
  member-discussion rows.
- Focused `devtools::test(filter = "structured-re-conversion-contracts")`:
  passed with 13,158 expectations, 0 failures, 0 warnings, and 0 skips.
- Support-cell invariant scan: 104 support cells, 8 interval
  `inference_ready`, 8 coverage `inference_ready`, 0 structured
  `authority_status = supported`, and 0 q4 coverage-authorized rows.
- Tranche 29 positive scan: all 8 rows are `FAILED`,
  `full_manifest_failed`, `r_runner_not_started`,
  `terminal_failure_review_no_new_compute`, `coverage_not_authorized`, and
  `do_not_promote`.
- GitHub issue search for `q2-plus source replay submission` returned no
  matching open issue; #687 remains a DDF route parking issue only.
- Served dashboard probe on `http://127.0.0.1:8766`: `version.txt` returned
  `r223`, Tranche 29 sidecar served with 9 lines, `index.html` contained the
  Tranche 29 render label, and the completion map mentioned the Tranche 29
  sidecar.

## 6. Tests of the Tests

The focused R test reads the Tranche 29 sidecar, checks its 34-column schema,
all eight row IDs, exact `sacct` failure details, Rorqual `/project` evidence
paths, manifest failure file, `r_runner_not_started`, no-new-compute/no-coverage
/no-promotion decisions, unchanged support-cell status, and accepted blocking
reviewer rows.

The Python validator independently checks the same terminal-review contract and
would fail if the row claimed a denominator, model-failure taxonomy, coverage
authorization, support-cell promotion, or resubmission authority.

## 7a. Issue Ledger

No Tranche 29-specific GitHub issue was found. Issue #687 was inspected and
remains a separate DDF repair-sidecar parking issue; it does not authorize a
retry, coverage, q2-plus promotion, q4/q8 inheritance, REML, AI-REML, bridge,
or public support.

## 8. Consistency Audit

The q2-plus support cell remains `point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`. Mission Control
still reports 104 Q-Series cells, 8 interval-ready rows, 8 coverage-ready rows,
0 structured `supported` rows, and 0 q4 coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The Tranche 27 job was stricter than the immediate q2-plus question: it checked
the full preserved source manifest, so one drifted q2 intercept runner stopped
the q2-plus replay before R. That is reproducibly conservative, but it means the
next step needs an explicit Tranche 30 decision rather than an automatic retry.

## 10. Known Residuals

Q2-plus remains blocked. Tranche 29 creates no denominator, no pdHess/profile
classification, no coverage evidence, and no status movement.

The next tranche must choose between a narrower critical-manifest replay
contract and parking q2-plus. No new `sbatch` should run until that choice is
banked and reviewed.

## 11. Team Learning

Fisher keeps failed-before-R jobs out of denominators. Rose keeps terminal
failure rows from becoming status. Noether separates the q2 intercept manifest
drift from the five q2-plus target identities. Gauss blocks Hessian taxonomy
without R-runner artifacts. Grace keeps full-manifest drift visible and prevents
an unreviewed resubmission.
