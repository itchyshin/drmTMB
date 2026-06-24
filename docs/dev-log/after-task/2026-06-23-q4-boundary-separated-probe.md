# Q4 Boundary-Separated Probe

## Goal

Test whether a stronger q4 toy design can move the interval blocker by moving
direct SD truth away from zero and target correlations away from +/-1.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-boundary-separated-probe.tsv`.
- The probe used larger direct SD truth (`0.8`, `0.7`, `0.45`, `0.45`), mild
  target correlations, denser sampling (`m = 6`), 16-tip and 24-tip trees, two
  seeds, and default/careful/robust optimizer presets.
- All 12 rows returned fits, but all 12 had `pdHess = false`.
- Two 24-tip, seed-777 rows reached optimizer convergence under default and
  careful presets, but Hessian reliability still failed.
- Fitted derived correlations stayed near boundary (`max_abs` roughly
  `0.93` to `0.99`), so the stronger toy design did not yet provide finite
  interval evidence.

## Boundary

This is boundary-separated diagnostic evidence only. It does not promote q4
interval reliability, interval coverage, q4 REML, HSquared AI-REML, broad
bridge support, a public optimizer control, a commit, a PR, or an Ayumi-facing
reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 509 assertions.
- `python3 tools/validate-mission-control.py` passed with 12 q4
  boundary-separated probe rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r36`, `status.json`,
  `sweep.json`, `structured-re-q4-boundary-separated-probe.tsv`, and
  `structured-re-q4-hessian-diagnostic-status.tsv` from
  `http://127.0.0.1:8765/`.

## Next Gate

Design an even more controlled q4 fixture that constrains fitted correlations
away from the boundary or decomposes the q4 Hessian into direct-SD and
correlation subproblems before attempting profile/bootstrap intervals.
