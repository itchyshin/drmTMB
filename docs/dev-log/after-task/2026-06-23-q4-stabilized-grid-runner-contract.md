# Q4 Stabilized Grid Runner Contract

## Goal

Add an executable dry-run contract for the future calibrated q4 profile and
coverage grid before any long replicate run is launched.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-grid-runner-contract.tsv`.
- Added dry-run script
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-dry-run.R`.
- Added generated dry-run artifact
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-calibrated-grid-dry-run.tsv`.
- The dry-run contract names the seed start, scale levels, four direct SD
  targets, six derived-correlation targets, denominator fields, warning fields,
  output schema, MCSE fields, and claim boundary.
- The script deliberately accepts only `--n-rep=0` so it cannot accidentally run
  a large grid.

## Boundary

This is a dry-run grid contract only. It does not promote q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap coverage, broad bridge support, a public optimizer control, a
commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 639 assertions.
- `python3 tools/validate-mission-control.py` passed with 8 q4 stabilized
  grid-runner contract rows.
- `Rscript --vanilla docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-dry-run.R --n-rep=0`
  wrote `q4-stabilized-calibrated-grid-dry-run.tsv`.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r45`,
  `structured-re-q4-stabilized-grid-runner-contract.tsv`, and
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-calibrated-grid-dry-run.tsv`
  from `http://127.0.0.1:8765/`.

## Next Gate

Replace the dry-run artifact with calibrated replicate output only after the
denominator, warning, failure, and MCSE fields remain in the output schema.
