# Q4 Interval Diagnostic Status

## Goal

Turn the q4 interval blocker from a summary count into target-level diagnostic
evidence, while keeping SR150 blocked and avoiding any interval-coverage claim.

## Result

- Added `phase18_structured_re_q4_interval_diagnostic_status()` to aggregate q4
  pilot interval rows.
- Generated
  `docs/dev-log/dashboard/structured-re-q4-interval-diagnostic-status.tsv` from
  `docs/dev-log/simulation-artifacts/2026-06-22-structured-coverage-unblock-pilots/tables/structured-coverage-pilot-rows.csv`.
- Direct SD targets (`sd_mu1`, `sd_mu2`, `sd_sigma1`, `sd_sigma2`) each retain
  two attempted q4 pilot rows, two `fit_ok` rows, zero converged rows, zero
  positive-Hessian rows, and zero finite Wald intervals.
- Derived among-axis correlations retain zero interval rows because derived
  correlation interval reconstruction is not available.

## Boundary

This is blocker evidence and denominator accounting only. It does not promote
q4 interval reliability, interval coverage, q4 REML, HSquared AI-REML, broad
bridge support, a public optimizer control, a commit, a PR, or an Ayumi-facing
reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-ademp-scaffold|structured-re-conversion-contracts')"`
  passed 574 assertions.
- `python3 tools/validate-mission-control.py` passed with 10 q4
  interval-diagnostic status rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r33`, `status.json`,
  `sweep.json`, `structured-re-q4-interval-diagnostic-plan.tsv`,
  `structured-re-q4-interval-diagnostic-status.tsv`, and
  `structured-re-coverage-acceptance-gate.tsv`.

## Next Gate

Diagnose q4 convergence and positive-Hessian failure modes before rerunning
finite interval diagnostics. Derived-correlation interval work remains a
separate reconstruction problem after q4 point/corpairs parity.
