# After Task: Q-Series Trillium Run-Root Staging

## Goal

Make the newly available Trillium access visible to the Q-Series widget while
keeping host access separate from row-level evidence.

## Implemented

- Confirmed Trillium BatchMode SSH reaches `tri-login03`.
- Confirmed the project area `/project/def-snakagaw/snakagaw` exists.
- Confirmed R 4.4.0 is available after
  `module load StdEnv/2023 gcc/12.3 r/4.4.0`.
- Created `/project/def-snakagaw/snakagaw/drmtmb-qseries`.
- Updated `structured-re-q-series-host-access-recheck.tsv` so Trillium is
  `reachable_root_staged_source_sync_required`.
- Updated the q2 retained-denominator repair contract and repair-smoke guard so
  Trillium remains blocked until source sync and explicit
  `--allow-trillium=true`.
- Bumped the dashboard build from `r175` to `r176`.

## Claim Boundary

This promotes exactly no Q-Series row. It does not change `fit_status`,
`interval_status`, `coverage_status`, `inference_ready`, `supported`, q2 slope
inheritance, q4/q8, non-Gaussian interval status, REML, AI-REML, bridge
support, or public-support wording.

No Trillium jobs were launched. Trillium is only prepared for future bounded
smoke work after source sync, a row-specific contract, retained artifacts, and
Fisher/Rose/Grace review.

## Mathematical Contract

No estimand, likelihood, interval rule, denominator policy, or support-cell
status changed. This is a compute-routing update only: Trillium reachability
can support future bounded smoke work, but cannot supply interval, coverage,
`inference_ready`, or `supported` evidence without a row-specific contract.

## Files Changed

- `docs/dev-log/dashboard/structured-re-q-series-host-access-recheck.tsv`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-contract.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv`
- `docs/dev-log/dashboard/structured-re-gaussian-lowq-row-selection.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/index.html`
- `docs/dev-log/dashboard/version.txt`
- `tools/summarize-structured-re-q2-retained-denominator-repair-contract.R`
- `tools/run-structured-re-q2-retained-denominator-repair-smoke.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`

## Checks Run

- `ssh -o BatchMode=yes -o ConnectTimeout=8 trillium 'set -e; ...'`: reached
  `tri-login03` and confirmed the project area exists.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 trillium 'module load StdEnv/2023
  gcc/12.3 r/4.4.0 ...'`: passed and exposed Rscript 4.4.0.
- `ssh -o BatchMode=yes -o ConnectTimeout=8 trillium 'mkdir -p
  /project/def-snakagaw/snakagaw/drmtmb-qseries ...'`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file
  tools/summarize-structured-re-q2-retained-denominator-repair-contract.R
  --overwrite=true --sync-dashboard=true`: passed.
- `/opt/homebrew/bin/air format
  tools/summarize-structured-re-q2-retained-denominator-repair-contract.R
  tools/run-structured-re-q2-retained-denominator-repair-smoke.R
  tests/testthat/test-structured-re-conversion-contracts.R`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e
  'invisible(parse("tools/summarize-structured-re-q2-retained-denominator-repair-contract.R"));
  invisible(parse("tools/run-structured-re-q2-retained-denominator-repair-smoke.R"));
  invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`:
  passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3
  tools/validate-mission-control.py`: passed with `mission_control_ok`.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1
  OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript
  --no-init-file -e 'devtools::test(filter =
  "structured-re-conversion-contracts")'`: 10132 PASS / 0 FAIL / 0 WARN /
  0 SKIP.

## Tests Of The Tests

The mission-control validator and focused R test both check the exact Trillium
host row, the q2 repair-contract wording, and the repair-smoke runner guard.
This task did not introduce a new deliberate failing test first because it
updated an existing dashboard contract rather than adding a new executable
model path.

## Consistency Audit

- Searched active dashboard/tool/test surfaces for stale Trillium root wording
  with `rg -n "Trillium.*no qseries root|Trillium.*missing.*qseries|Trillium.*until qseries run root|Trillium only after qseries run|qseries run root and source root" docs/dev-log/dashboard tools tests/testthat/test-structured-re-conversion-contracts.R`.
- Historical check-log entries were left intact because they were true when
  written; this after-task note supersedes them.
- `docs/dev-log/dashboard/README.md`, `version.txt`, and the HTML build
  constant all now describe the current Trillium gate.

## GitHub Issue Maintenance

No issue was opened or closed. This was a host-access and widget-state
correction, not a user-facing feature or scientific status promotion.

## What Did Not Go Smoothly

The first Trillium probe confirmed access but also confirmed that plain
`Rscript` was absent from the login PATH. The documented DRAC module stack
resolved that cleanly.

## Team Learning

Host access should be recorded in the board as a routing gate with source-root
and artifact prerequisites. Connected hosts are useful, but they are not
evidence.

## Known Limitations

The Trillium source root is still not staged, and no Trillium scheduler job has
been exercised for this branch. Trillium remains unavailable for denominator
work until source sync, `--allow-trillium=true`, retained artifacts, and
Fisher/Rose/Grace review are present.

## Next Actions

Before Trillium can run Q-Series work, sync a reviewed source root, record
`git-sha.txt`, `sessionInfo.txt`, `module-list.txt`, exact command lines, seed
manifests, and scheduler logs, then use a row-specific smoke or repair contract
with `--allow-trillium=true`.
