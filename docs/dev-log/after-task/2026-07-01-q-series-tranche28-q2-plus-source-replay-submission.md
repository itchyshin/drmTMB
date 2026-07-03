# After Task: Q-Series Tranche 28 q2-plus Source Replay Submission

## 1. Goal

Record the approved Rorqual submission of the Tranche 27 q2-plus source-matched
replay without importing artifacts, creating a denominator, authorizing
coverage, or moving support-cell status.

## 2. Implemented

Added
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche28-source-replay-submission.tsv`,
an eight-row submission ledger for Rorqual job 15027970, array task 108. The
ledger records the reviewed sbatch staging path, approval token, remote result
root, first scheduler state (`PENDING_PRIORITY`), and first-probe absence of
replay artifacts.

Mission Control build `r222` initially loaded and rendered the Tranche 28
sidecar; build `r223` keeps that sidecar and adds the later Tranche 29 terminal
review. The validator and focused conversion-contract test check Tranche 28's
schema, one submitted task, pending/no-artifact boundary, unchanged q2-plus
support-cell status, and Fisher/Rose/Noether/Gauss/Grace discussion rows.

## 3a. Decisions and Rejected Alternatives

Chose a submission ledger rather than editing the Tranche 27 contract. Tranche
27 was a non-submitted job pack; Tranche 28 records the separate execution
transition.

Rejected treating the submitted job as denominator evidence. At the first probe
the job was pending and no replay artifacts had been imported. Tranche 28
therefore authorizes no top-up, coverage, interval status, coverage status,
`inference_ready`, `supported`, q2-plus promotion, q4/q8, REML, AI-REML,
bridge, or public-support claim.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-tranche28-source-replay-submission.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche28-q2-plus-source-replay-submission.md`

## 5. Checks Run

- Tranche 28 TSV shape check: 9 lines including header, 31 columns on every
  row.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r222.js`: passed.
- `bash -n tools/slurm/q2-plus-rep108-source-replay-rorqual.sbatch`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series cells, 8 Tranche 28 source-replay submission rows,
  and no structured support promotion.
- Focused `devtools::test(filter = "structured-re-conversion-contracts")`:
  passed after the final `r223` wiring with 13,158 passing expectations.
- Support-cell invariant scan: 104 support cells, 8 interval
  `inference_ready`, 8 coverage `inference_ready`, 0 structured
  `authority_status = supported`, and 0 q4 coverage-authorized rows.
- Tranche 28 positive scan: all 8 rows are
  `one_rorqual_task_submitted`, `job_pending_no_artifacts_imported`,
  `one_source_matched_replay_submitted_pending`,
  `coverage_not_authorized`, and `do_not_promote`.
- GitHub issue search for `q2-plus source replay submission` returned no
  matching open issue; #687 remains a DDF route parking issue only.

## 6. Tests of the Tests

The focused R test reads the Tranche 28 sidecar, checks its 31-column schema,
all eight row IDs, the exact job id and array task, Rorqual `/project` paths,
approval token, no-artifact first-probe status, no-coverage/no-promotion
decisions, unchanged q2-plus support-cell status, and the five accepted blocking
reviewer rows.

The Python validator independently checks the same fields and would fail if the
submission were relabeled as a denominator, coverage result, status promotion,
or pooled-host result.

## 7a. Issue Ledger

No Tranche 28-specific GitHub issue was found. Issue #687 was inspected and
remains a separate DDF repair-sidecar parking issue; it does not authorize this
source replay, coverage, q2-plus promotion, q4/q8 inheritance, REML, AI-REML,
bridge, or public support.

## 8. Consistency Audit

The q2-plus support cell `qseries_phylo_q2_plus_q2_intercept` remains
`point_fit/planned/planned` with
`denominator_policy = repair_contract_ready_not_coverage`.

Tranche 28 records only the first submission state. The later Rorqual terminal
failure is recorded separately in Tranche 29 so the submission ledger is not
rewritten into a result.

## 9. What Did Not Go Smoothly

The first served-dashboard probe used port 8765 and hit a dashboard-path 404.
Port 8766 was the server root that cleanly served the dashboard index,
`version.txt`, and Tranche 29 sidecar at the end of the task.

## 10. Known Residuals

Tranche 28 does not explain the replay result. It creates no denominator, no
coverage evidence, and no status movement. Its next gate was terminal-job
review, now banked as Tranche 29.

## 11. Team Learning

Fisher keeps submitted jobs separate from denominators. Rose keeps job IDs from
becoming status claims. Noether keeps task 108 tied to the same five q2-plus
targets. Gauss waits for actual model artifacts before classifying Hessian or
profile behavior. Grace keeps Rorqual provenance and host denominators
separate.
