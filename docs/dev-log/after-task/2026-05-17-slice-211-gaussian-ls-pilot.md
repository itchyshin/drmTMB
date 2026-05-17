# Slice 211 Gaussian Location-Scale Pilot

## Goal

Add the first Phase 18 data-generating mechanism and pilot summary table for
Gaussian location-scale models.

## What Changed

- Added `inst/sim/dgp/sim_dgp_gaussian_ls.R` with pilot-cell conditions and a
  seeded Gaussian `mu ~ x`, `sigma ~ z` DGP.
- Added `inst/sim/fit/sim_summarise_gaussian_ls.R` to convert one fitted model
  into a parameter-level truth, estimate, error, convergence, and Hessian table.
- Added a CRAN-safe smoke test for DGP reproducibility, truth metadata,
  malformed inputs, and one small fitted pilot.
- Updated the Phase 18 blueprint, simulation README, ROADMAP, NEWS, and check
  log.

## Role Notes

- Curie kept the first fitted simulation check small and deterministic.
- Fisher required the summary output to report truth, estimate, and error on the
  modelled link scales.
- Noether checked that `sigma` truth is stored as log-scale coefficients and
  response-scale row values.
- Grace kept the pilot under optional `inst/sim/` files rather than package
  exports.
- Rose checked that this still makes no comprehensive coverage or power claim.

## Remaining Boundary

This slice adds one fitted pilot, not a grid runner. Slice 212 should add the
Gaussian meta-analysis `meta_V(V = V)` DGP with vector and dense matrix `V`.
