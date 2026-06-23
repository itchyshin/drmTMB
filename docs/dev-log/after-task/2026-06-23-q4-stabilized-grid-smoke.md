# Q4 Stabilized Grid Smoke

## Goal

Add an executable one-replicate smoke path for the future calibrated q4
profile/coverage grid, while keeping the result explicitly below any interval
reliability or coverage claim.

## Result

- Added
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/run-calibrated-grid-smoke.R`.
- The smoke runner permits only `--n-rep=1` and defaults to the known stabilized
  q4 Gaussian phylo seed `202606902` at scale `0.50`.
- The runner wrote
  `docs/dev-log/simulation-artifacts/2026-06-23-q4-stabilized-preflight/q4-stabilized-calibrated-grid-smoke-results.tsv`.
- The generated artifact has ten target-level rows: four finite direct-SD Wald
  rows and six derived-correlation rows whose intervals remain explicitly not
  reconstructed.
- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-stabilized-grid-smoke-status.tsv`.
- Updated the mission-control widget to render the smoke sidecar as build
  `r46`.

## Boundary

This is q4 calibrated-grid plumbing evidence only. It does not promote q4
interval reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap coverage, broad bridge support, a public optimizer control, a
commit, a PR, or an Ayumi-facing reply.

## Next Gate

Run a predeclared calibrated q4 grid only after the denominator, warning,
derived-correlation interval, and MCSE policies are frozen. The grid must keep
failed fits, `pdHess = false` rows, warning rows, unavailable intervals, and
MCSE fields in the denominator before any coverage wording is considered.
