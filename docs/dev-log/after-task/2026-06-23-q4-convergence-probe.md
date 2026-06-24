# Q4 Convergence Probe

## Goal

Check whether the q4 interval blocker is only an optimizer-preset problem or
whether the uncertainty surface remains unstable after optimizer convergence.

## Result

- Added `docs/dev-log/dashboard/structured-re-q4-convergence-probe.tsv`.
- Refit the original 10-tip, `m = 2`, q4 pilot shape with default, careful, and
  robust optimizer presets. All three returned fits, but all remained
  nonconverged with `pdHess = false`.
- Probed denser toy variants at 10 and 16 tips with `m = 3` and `m = 4`.
- The useful surprise is the 10-tip, `m = 4` toy fixture: default, careful, and
  robust all reached optimizer convergence, but all still had `pdHess = false`.

## Interpretation

The immediate q4 interval blocker is not only optimizer convergence. Denser
toy data can move the optimizer status, but Hessian/uncertainty reliability
still fails, so finite interval diagnostics and coverage wording remain
blocked.

## Boundary

This is a convergence diagnostic only. It does not promote q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML, broad bridge
support, a public optimizer control, a commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 488 assertions.
- `python3 tools/validate-mission-control.py` passed with 15 q4
  convergence-probe rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r34`, `status.json`,
  `sweep.json`, `structured-re-q4-convergence-probe.tsv`, and
  `structured-re-q4-interval-diagnostic-status.tsv`.

## Next Gate

Use the denser converged-but-`pdHess = false` q4 fixture to isolate Hessian
failure modes before attempting profile/bootstrap interval diagnostics.
