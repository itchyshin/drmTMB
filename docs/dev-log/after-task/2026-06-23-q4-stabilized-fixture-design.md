# Q4 Stabilized Fixture Design

## Goal

Turn the q4 interval blocker from a vague `pdHess = false` failure into a
validator-owned fixture design contract with measurable exit gates.

## Result

- Added
  `docs/dev-log/dashboard/structured-re-q4-stabilized-fixture-design.tsv`.
- The sidecar records six required gates for a future q4 fixture: direct SD
  estimates away from zero, interior fitted correlations, positive Hessian
  diagnostics, finite direct-SD interval status, denominator accounting, and
  route-specific parity.
- Each row points back to the q4 interval plan/status, convergence probe,
  boundary-separated probe, Hessian diagnostic, direct DRM.jl export, or q4
  parity sidecar that motivated the gate.
- Updated the mission-control widget so the stabilized fixture design renders
  beside the q4 boundary-separated and Hessian diagnostic tables.
- Added validator and test coverage for the sidecar schema, expected blockers,
  acceptance metrics, owner members, evidence inputs, and claim boundaries.

## Boundary

This is a fixture-design contract only. It does not promote q4 interval
reliability, interval coverage, q4 REML, HSquared AI-REML, broad bridge support,
a public optimizer control, a commit, a PR, or an Ayumi-facing reply.

## Checks

- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed 520 assertions.
- `python3 tools/validate-mission-control.py` passed with 6 q4 stabilized
  fixture-design rows.
- `python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null` and
  `python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null` passed.
- `sh -n tools/start-mission-control.sh` passed.
- `git diff --check` passed in both active worktrees.
- Live dashboard refresh served `version.txt = r37`, `status.json`,
  `sweep.json`, `structured-re-q4-stabilized-fixture-design.tsv`, and
  `structured-re-q4-boundary-separated-probe.tsv` from
  `http://127.0.0.1:8765/`.

## Next Gate

Implement a controlled q4 stabilized-fixture preflight only after the design
rows are visible in mission control and validator-clean.
