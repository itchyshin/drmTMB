# After Task: Q-Series Tranche 35 q4 relmat Source-Snapshot Preflight

## 1. Goal

Convert the Tranche 34 q4 relmat source-provenance blocker into a verified
Totoro source snapshot and dry-run preflight, without running a q4 fit,
submitting DRAC work, or creating a denominator.

## 2. Implemented

Staged a new isolated Totoro runtime source snapshot:

`/home/snakagaw/codex/drmTMB-q4loc-tranche35-source-56add7f0-20260702T002713Z`

The snapshot includes package/runtime source plus the q4 runner and helper
scripts. It records `SOURCE-PROVENANCE.tsv` and a 3,057-file
`SOURCE-MANIFEST.sha256`. The snapshot is 174M and records local source SHA
`56add7f0` with `source_dirty = dirty`.

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche35-relmat-source-snapshot-preflight.tsv`
as a six-row Mission Control sidecar. The rows cover the four relmat q4
location direct-SD targets plus provider and tranche summaries.

Mission Control build `r229` now loads and renders the Tranche 35 sidecar. The
validator, focused conversion-contract test, dashboard README, completion map,
check log, member discussion board, and this report now enforce the same
boundary.

## 3a. Decisions and Rejected Alternatives

The accepted decision is
`totoro_snapshot_staged_and_dry_run_verified_but_compute_requires_checkpoint_approval`.
Tranche 35 runs no q4 fit, submits no DRAC job, creates no coverage-evaluable
denominator, and moves no support-cell status.

Rejected treating a dry-run as execution evidence. Rejected treating a dirty
source snapshot as automatically acceptable for a claim-bearing run. The next
gate is a Rose/Fisher/Grace decision on dirty snapshot versus clean committed
source, then a fresh checkpoint before at most shard 13 can run.

## 4. Files Touched

- `docs/dev-log/dashboard/structured-re-q4-location-tranche35-relmat-source-snapshot-preflight.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche35-q4-relmat-source-snapshot-preflight.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- Totoro snapshot stage: copied runtime source to
  `/home/snakagaw/codex/drmTMB-q4loc-tranche35-source-56add7f0-20260702T002713Z`.
- Remote manifest capture with null-delimited paths: passed with 3,057 files
  and snapshot size 174M.
- Remote helper hash check: matched local hashes for
  `tools/run-q4-location-relmat-pregrid-totoro.sh`,
  `tools/run-structured-re-q4-location-coverage-grid.R`, and
  `tools/slurm/q4-location-relmat-pregrid.sbatch`.
- Remote Totoro dry-run:
  `bash tools/run-q4-location-relmat-pregrid-totoro.sh --dry-run --shards=13,14,15,16`:
  printed all four shard commands and ended with dry-run/no-execution wording.
- Remote fail-closed check:
  `bash tools/run-q4-location-relmat-pregrid-totoro.sh --execute --shards=13`
  without `DRMTMB_Q4LOC_EXECUTION_APPROVED`: returned exit status 2 before
  running a shard.
- Tranche 35 TSV shape check: 7 lines including header, 32 columns.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'))"`:
  passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r229.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 6 Tranche 35 source-snapshot rows, and
  171 member-discussion rows.
- Focused `devtools::test(filter = "structured-re-conversion-contracts",
  reporter = "summary")`: passed with `DONE` and exit code 0 after one test
  assertion type correction.
- Invariant scan: 104 support cells, 8 interval `inference_ready`, 8 coverage
  `inference_ready`, 0 structured rows with any `supported` status, 0 q4
  coverage-authorized rows, and all 6 Tranche 35 rows set to
  `no_compute_in_tranche35`, `coverage_not_authorized`, and
  `do_not_promote`.
- Served dashboard probe on `http://127.0.0.1:8766`: `version.txt` returned
  `r229`, the Tranche 35 sidecar served with 7 lines and 32 columns, and
  `index.html` contained the Tranche 35 render label and sidecar load.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche35-q4-relmat-source-snapshot-preflight.md')"`:
  passed with `after-task structure check passed`.
- `git diff --check`: passed.

## 6. Tests of the Tests

The focused R test reads the Tranche 35 sidecar directly and checks schema,
row IDs, scopes, source links back to Tranche 34 rows, snapshot path,
manifest count, helper hashes, dry-run status, fail-closed status,
`no_compute_in_tranche35`, unchanged q4 relmat support-cell status, and the
Rose/Fisher/Grace member-board rows.

The Python validator independently checks the same schema, row count, common
values, claim-boundary phrases, next-gate phrases, source Tranche 34 row links,
unchanged support-cell status, and SC379 member-board entries.

## 7a. Issue Ledger

No new GitHub issue was opened. This is an internal Mission Control provenance
gate for a staged source snapshot, not a user-facing API, formula, package
behavior, or public documentation feature.

## 8. Consistency Audit

The q4 relmat location support cell remains `point_fit/planned/planned`.
Mission Control still reports 104 Q-Series support cells, 8 interval-ready rows,
8 coverage-ready rows, 0 structured rows with any `supported` status, and 0 q4
coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed.

## 9. What Did Not Go Smoothly

The first remote manifest command failed because filenames under
`dis_reg_models/` contain spaces. I reran the manifest capture with
null-delimited paths.

The first focused-test rerun failed because the test expected
`snapshot_file_count` as character, while `read.delim()` read it as integer.
The assertion was corrected and the focused test was rerun to completion.

## 10. Known Residuals

The Totoro snapshot is dirty. Rose/Fisher/Grace still need to decide whether
that exact manifested snapshot is acceptable for a first shard or whether a
clean committed source is required. No q4 relmat execution is authorized by
Tranche 35.

The full Q-Series completion campaign remains active.

## 11. Team Learning

Grace turned a vague source-sync instruction into a manifest and hash check.
Fisher kept dry-run output from becoming denominator evidence. Rose kept a
staged dirty snapshot from becoming a status claim.
