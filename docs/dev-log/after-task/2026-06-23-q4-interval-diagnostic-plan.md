# Q4 Interval Diagnostic Plan

## Goal

Make the q4 interval blocker more observable without promoting interval
reliability. The previous dashboard showed q4 scale-axis failures and the SR150
coverage gate, but it did not expose one row per q4 target saying what evidence
is required before finite-interval or coverage language can move.

## Result

- Added `phase18_structured_re_q4_interval_diagnostic_plan()` to the structured
  RE ADEMP scaffold.
- Extended the scaffold writer so local scaffold artifacts include
  `structured-re-q4-interval-diagnostic-plan.csv`.
- Added the validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-interval-diagnostic-plan.tsv`.
- The sidecar has 10 q4 phylo rows: 4 direct SD targets and 6 derived
  among-axis correlation targets.
- Updated the SR143/SR150 q2 wording so q2 fixture parity is no longer listed
  as a blocker, while finite intervals and calibrated replicates remain
  blocked.

## Boundary

This is a diagnostic plan and denominator contract only. It does not promote q4
interval reliability, interval coverage, q4 REML, HSquared AI-REML, broad
bridge support, a public optimizer control, a commit, a PR, or an Ayumi-facing
reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-ademp-scaffold|structured-re-conversion-contracts')"`
  passed 541 assertions.
- `python3 tools/validate-mission-control.py` passed with 10 q4
  interval-diagnostic plan rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r32`, `status.json`,
  `sweep.json`, `structured-re-q4-interval-diagnostic-plan.tsv`, and
  `structured-re-coverage-acceptance-gate.tsv`.
- Optional in-app browser attachment timed out; this report relies on
  command-line served-copy evidence for the widget refresh.

## Next Gate

Run deterministic q4 interval diagnostics that produce finite interval status
rows for direct SD targets and derived correlation targets, keeping failed fits
and unavailable intervals in the denominator before any calibrated coverage
grid or user-facing wording changes.
