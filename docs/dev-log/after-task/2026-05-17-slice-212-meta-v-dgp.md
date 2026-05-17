# Slice 212 Meta-V Simulation DGP

## Goal

Add the first Gaussian meta-analysis Phase 18 DGP for the preferred
`meta_V(V = V)` API, including vector and dense known sampling covariance.

## What Changed

- Added `inst/sim/dgp/sim_dgp_meta_v.R` for seeded `meta_V(V = V)` data with
  vector or dense known sampling covariance.
- Added `inst/sim/fit/sim_summarise_meta_v.R` for parameter-level truth,
  estimate, error, convergence, and Hessian summaries.
- Moved shared simulation helper utilities into `inst/sim/R/sim_utils.R`.
- Added smoke tests for DGP shape, covariance positive-definiteness, fitted
  vector and dense pilots, and interval-target exclusion of known `V`.
- Updated the Phase 18 blueprint, simulation README, ROADMAP, NEWS, and check
  log.

## Role Notes

- Fisher kept known sampling covariance out of interval targets and kept
  fitted `sigma` visible as the estimated extra heterogeneity target.
- Noether kept the DGP equation aligned with `y ~ MVN(mu, V + sigma^2 I)`.
- Curie kept vector and dense pilots deterministic and small enough for routine
  smoke testing.
- Pat kept the output table at the parameter level so a reader can audit
  truth, estimate, and error directly.
- Grace kept dense `V` small and labelled it as a pilot, not a scalability
  benchmark.

## Remaining Boundary

This slice does not add grid runners, saved per-cell RDS output, coverage
summaries, power calculations, or external comparators.
