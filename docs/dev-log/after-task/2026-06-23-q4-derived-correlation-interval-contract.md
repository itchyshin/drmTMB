# Q4 Derived-Correlation Interval Contract

## Goal

Convert the r46 q4 smoke result's derived-correlation interval gap into an
explicit reconstruction contract before any larger calibrated grid is run.

## Result

- Added validator-owned dashboard sidecar
  `docs/dev-log/dashboard/structured-re-q4-derived-correlation-interval-contract.tsv`.
- The sidecar records all six q4 derived-correlation targets:
  `cor_mu1_mu2`, `cor_mu1_sigma1`, `cor_mu1_sigma2`,
  `cor_mu2_sigma1`, `cor_mu2_sigma2`, and `cor_sigma1_sigma2`.
- Each row links the `corpairs` point target and the r46 smoke artifact
  `q4-stabilized-calibrated-grid-smoke-results.tsv`.
- Each row keeps `current_interval_status = not_available` and requires a
  planned delta/profile reconstruction route plus bootstrap accounting before
  intervals can be interpreted.
- The contract requires `Sigma_a`, target identity, fit status, `pdHess`,
  warning context, failure reason, denominator policy, `coverage_mcse`, and
  `failure_rate_mcse` fields before any calibrated interval wording.

## Boundary

This is a q4 derived-correlation interval contract only. It does not promote q4
interval reliability, interval coverage, q4 REML, HSquared AI-REML,
profile/bootstrap coverage, broad bridge support, a public optimizer control, a
commit, a PR, or an Ayumi-facing reply.

## Next Gate

Implement and validate a reconstruction path for derived q4 correlations. The
first executable path should still be diagnostic: it must retain unavailable
rows, warnings, failed fits, and MCSE fields before any coverage wording.
