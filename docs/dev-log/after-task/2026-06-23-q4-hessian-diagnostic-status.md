# Q4 Hessian Diagnostic Status

## Goal

Inspect the q4 toy fit that reaches optimizer convergence but still has
`pdHess = false`, so the next interval blocker is localized before more grid
work.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-hessian-diagnostic-status.tsv`.
- The converged 10-tip, `m = 4`, default-optimizer q4 toy fit has a tiny
  maximum fixed-gradient magnitude (`5.422e-07`) but an indefinite covariance
  diagnostic (`min_cov_fixed_eigenvalue = -2.931523e+08`).
- Direct q4 SD estimates are near zero (`3.805145e-07` to `4.109797e-05`).
- Derived q4 correlations are near the boundary (`min_abs = 0.9468140`,
  `max_abs = 0.9984888`).
- Direct-SD Wald intervals remain 0/4 finite even after optimizer convergence.

## Interpretation

The next q4 interval task is not user-facing interval wording. The useful next
work is boundary-separated q4 deterministic fixtures, Hessian diagnostics, and
stronger signal designs that can distinguish numerical failure from genuine
boundary identifiability.

## Boundary

This is Hessian/boundary diagnostic evidence only. It does not promote q4
interval reliability, interval coverage, q4 REML, HSquared AI-REML, broad
bridge support, a public optimizer control, a commit, a PR, or an Ayumi-facing
reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 498 assertions.
- `python3 tools/validate-mission-control.py` passed with 8 q4
  Hessian-diagnostic status rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r35`, `status.json`,
  `sweep.json`, `structured-re-q4-hessian-diagnostic-status.tsv`, and
  `structured-re-q4-convergence-probe.tsv`.

## Next Gate

Build a boundary-separated q4 fixture with direct SDs away from zero and
derived correlations away from +/-1, then rerun the same Hessian and finite
interval diagnostics before any calibrated q4 coverage grid.
