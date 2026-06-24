# After-Task: SR130 q2 Parity Acceptance Blocker

## Goal

Evaluate whether q2 bridge parity can be accepted after SR121-SR129.

## Result

The answer is no. Native q2 point fixtures and row-shaped payload/provenance
contracts now exist, but direct q2 DRM.jl fits and q2-specific R-via-Julia
routes remain unavailable. Without those routes there is no same-target
native/direct/bridge comparison and no tolerance policy to accept.

## Changes

- Added `phase18_structured_re_q2_acceptance_gate()` with one blocked row for
  each q2 structured target: `phylo()`, `spatial()`, `animal()`, and `relmat()`.
- Added `structured-re-q2-acceptance-gate.tsv`.
- Added validator checks that acceptance stays blocked until direct q2 and
  q2-specific bridge routes exist.
- Updated dashboard rendering, dashboard README, fixture tests, and
  dashboard-contract tests.

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 239 assertions, 0 failures, 0 warnings, and 0 skips.
- `python3 tools/validate-mission-control.py` passed with 4 q2 acceptance-gate
  rows.

## Boundary

This is blocker evidence, not support evidence. It does not promote q2
R-via-Julia bridge support, direct q2 fit support, q2 REML, q4 support,
interval coverage, public bridge support, a commit, a PR, or an Ayumi-facing
reply.

## Update 2026-06-23: Phylo Row Covered, Aggregate Gate Still Blocked

The phylo row has moved from fully blocked to covered for one
complete-response exact-Gaussian ML native/direct/bridge fixture. The aggregate
q2 acceptance gate remains blocked because spatial, animal, and relmat q2
direct/bridge same-target routes are still unavailable.

Current row-level interpretation:

- `phylo()`: covered for one q2 ML same-target fixture only.
- `spatial()`, `animal()`, and `relmat()`: still blocked for q2 direct/bridge
  parity.
- Aggregate SR130: still blocked until all required structured types have
  direct and R-via-Julia same-target evidence.

No q2 REML, q4 support, interval coverage, broad public bridge support, commit,
PR, or Ayumi-facing reply is promoted by this update.

## Update 2026-06-23: Direct Non-Phylo Evidence, Aggregate Still Blocked

The direct DRM.jl side now has q2 residual-correlation fixture evidence for
`animal()` and `relmat()` known covariance/precision matrices, plus a
fixed-covariance `spatial()` fixture. The aggregate q2 acceptance gate remains
blocked because `spatial()`, `animal()`, and `relmat()` still lack
R-via-Julia same-target bridge routes and same-target tolerance evidence. The
spatial fixture is not a range-estimating q2 spatial route.

Current row-level interpretation:

- `phylo()`: covered for one q2 ML same-target native/direct/bridge fixture.
- `animal()` and `relmat()`: direct DRM.jl known-covariance evidence banked;
  R-via-Julia bridge parity still blocked.
- `spatial()`: direct DRM.jl fixed-covariance evidence banked; range-estimating
  q2 spatial and R-via-Julia bridge parity still blocked.
- Aggregate SR130: still blocked until all required structured types have
  R-via-Julia same-target evidence and tolerance checks.

No q2 REML, q4 support, interval coverage, broad public bridge support, commit,
PR, or Ayumi-facing reply is promoted by this update.
