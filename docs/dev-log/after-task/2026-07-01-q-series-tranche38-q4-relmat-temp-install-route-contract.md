# After Task: Q-Series Tranche 38 q4 relmat Temp-Install Route Contract

## 1. Goal

Turn the Tranche 37 Totoro load blocker into a reviewed no-compute route
contract: the wrapper can now forward the existing q4 runner's
`--attempt-temp-install` path, but no q4 relmat retry, denominator, coverage
result, or status movement is created by this tranche.

## 2. Implemented

Updated `tools/run-q4-location-relmat-pregrid-totoro.sh` so it accepts
`--attempt-temp-install` and the environment alternative
`DRMTMB_Q4LOC_ATTEMPT_TEMP_INSTALL=true`. When either route is used, the wrapper
adds `--attempt-temp-install` to the forwarded
`tools/run-structured-re-q4-location-coverage-grid.R` command.

Added
`docs/dev-log/dashboard/structured-re-q4-location-tranche38-relmat-temp-install-route-contract.tsv`
as a three-row Mission Control sidecar. The rows cover the relmat shard-13
target, provider summary, and tranche summary, all linked back to Tranche 37.

Mission Control build `r232` now loads and renders the sidecar. The validator,
focused conversion-contract test, dashboard README, completion map, member
discussion board, check log, and this report now enforce the same boundary.

## 3a. Decisions and Rejected Alternatives

The accepted decision is `route_contract_only_no_compute`. Tranche 38 proves
only that the wrapper can expose and forward the temp-install route while still
failing closed without `DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace`.

Rejected treating the new flag as a successful load, fitted replicate, retained
denominator, coverage result, admission, or support-cell status change. Rejected
running shard 13 immediately. Rejected running shards 14-16 or DRAC from this
contract. The old Tranche 35-36 helper hash is superseded for future execution
planning because the wrapper changed.

## 4. Files Touched

- `tools/run-q4-location-relmat-pregrid-totoro.sh`
- `docs/dev-log/dashboard/structured-re-q4-location-tranche38-relmat-temp-install-route-contract.tsv`
- `docs/dev-log/dashboard/member-discussions.tsv`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-07-01-q-series-tranche38-q4-relmat-temp-install-route-contract.md`
- `/Users/z3437171/shinichi-brain/memory/AGENT_LOG.md`

## 5. Checks Run

- `bash -n tools/run-q4-location-relmat-pregrid-totoro.sh`: passed.
- Tranche 38 TSV shape check: 4 lines including header, 26 columns, no
  bad-width rows.
- CLI dry-run:
  `DRMTMB_REPO=/Users/z3437171/Dropbox/Github\ Local/drmTMB
  DRMTMB_Q4LOC_RUN_ROOT=/tmp/drmtmb-q4-t38-dry-run
  DRMTMB_SOURCE_SHA=local-t38 DRMTMB_SOURCE_DIRTY=dirty bash
  tools/run-q4-location-relmat-pregrid-totoro.sh --dry-run --shards=13
  --attempt-temp-install`: passed and printed the forwarded runner flag.
- Environment dry-run:
  `DRMTMB_Q4LOC_ATTEMPT_TEMP_INSTALL=true ... bash
  tools/run-q4-location-relmat-pregrid-totoro.sh --dry-run --shards=13`:
  passed and printed the forwarded runner flag.
- Fail-closed execute check:
  `... bash tools/run-q4-location-relmat-pregrid-totoro.sh --execute
  --shards=13 --attempt-temp-install`: returned exit status 2 before fitting.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R'));
  invisible(parse('tools/run-structured-re-q4-location-coverage-grid.R'))"`:
  passed.
- `PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile
  tools/validate-mission-control.py`: passed.
- Dashboard JS extraction plus
  `node --check /tmp/drmtmb-mission-control-index-r232.js`: passed.
- `PYTHONDONTWRITEBYTECODE=1 R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`,
  including 104 Q-Series support cells, 3 Tranche 38 route rows, and 180
  member-discussion rows.
- Focused `devtools::test(filter = "structured-re-conversion-contracts",
  reporter = "summary")`: passed with `DONE`.
- After-task checker:
  `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R');
  main_check_after_task('docs/dev-log/after-task/2026-07-01-q-series-tranche38-q4-relmat-temp-install-route-contract.md')"`:
  passed with `after-task structure check passed`.
- Invariant scan: 104 support cells, 8 interval `inference_ready` rows, 8
  coverage `inference_ready` rows, 0 structured-provider rows with any
  `supported` status, 0 q4 coverage-authorized rows, and all 3 Tranche 38 rows
  set to `route_contract_only_no_compute`, `coverage_not_authorized`, and
  `do_not_promote`.
- Served dashboard probe on `http://127.0.0.1:8766`: `version.txt` returned
  `r232`, the Tranche 38 sidecar served with 4 lines and 26 columns, and
  `index.html` contained the Tranche 38 summary label, render label, and sidecar
  load.
- `git diff --check`: passed.
- Recovery checkpoint:
  `docs/dev-log/recovery-checkpoints/2026-07-01-192158-codex-checkpoint.md`.

## 6. Tests of the Tests

The focused R test reads the Tranche 38 sidecar directly, checks all no-compute,
no-coverage, and no-promotion values, confirms the sidecar links to Tranche 37,
reads the wrapper text, runs a dry-run that must visibly forward
`--attempt-temp-install`, and checks that execute without the approval token
still fails closed with exit status 2.

The Python validator independently checks the sidecar schema, row count,
source links, claim-boundary phrases, next-gate phrases, wrapper text, Mission
Control load/render wiring, unchanged q4 relmat support-cell status, and SC382
Rose/Fisher/Grace member-board rows.

## 7a. Issue Ledger

No GitHub issue was opened or updated. This tranche changes internal execution
plumbing and Mission Control evidence only. It does not change public APIs,
formula grammar, package behavior, user-facing support status, or release text.

## 8. Consistency Audit

The q4 relmat support cell remains `fit_status = point_fit`,
`interval_status = diagnostic_only`, `coverage_status = planned`,
`denominator_policy = fixture_not_coverage`, and no q4 coverage is authorized.

Mission Control still reports 104 Q-Series support cells, 8 interval
`inference_ready` rows, 8 coverage `inference_ready` rows, 0 structured-provider
rows with any `supported` status, and 0 q4 coverage-authorized rows.

Public APIs, formula grammar, `R/`, `src/`, pkgdown, README, NEWS, and
support-cell statuses were not changed by Tranche 38.

## 9. What Did Not Go Smoothly

The first focused-test implementation read the wrapper path relative to
`tests/testthat`, which failed under `devtools::test()`. I changed the test to
derive the package root and then run the shell command from that root.

The first shell-call harness used `system2()` and failed inside testthat even
though the command worked outside the test. I replaced it with `system(...,
intern = TRUE)` plus `2>&1`, which captures both dry-run output and fail-closed
status portably.

## 10. Known Residuals

No retry has run. The next tranche must stage a fresh Totoro source snapshot
that contains wrapper hash
`9133474766f6968f4344871e48c8b8a92cfdedc2bfff15e94a6fcc4b3afa9b8c`, record
source and host provenance, dry-run shard 13 with `--attempt-temp-install`,
write a checkpoint, and obtain Rose/Fisher/Grace approval before any execution.

The full Q-Series completion campaign remains active.

## 11. Team Learning

Grace kept the route repair tied to explicit source and host provenance. Fisher
kept wrapper plumbing from becoming denominator evidence. Rose caught the stale
helper-hash risk created by changing the wrapper.
