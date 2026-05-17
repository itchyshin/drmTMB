# Slice 209 Phase 18 Simulation Blueprint

## Goal

Open Phase 18 deliberately by writing the simulation-programme blueprint before
adding simulation code or broad grids.

## What Changed

- Added `docs/design/41-phase-18-simulation-programme.md`.
- Framed Phase 18 with ADEMP aims, data-generating mechanisms, estimands,
  methods, and performance measures.
- Listed first-wave eligible surfaces and kept planned non-Gaussian, shape,
  ordinal, inflation, and structured non-Gaussian surfaces out of the broad
  grid until their gates close.
- Required MCSE or bootstrap uncertainty for every aggregate simulation metric.
- Proposed the first three implementation slices: `inst/sim/` skeleton,
  Gaussian location-scale pilot, and Gaussian meta-analysis `meta_V(V = V)`
  DGP.

## Role Notes

- Ada opened the phase as a blueprint, not as a premature broad simulation run.
- Curie set the first implementation order around small reusable helpers and
  CRAN-safe smoke tests.
- Fisher required estimand, interval, convergence, boundary, and MCSE reporting.
- Darwin kept the first-wave surfaces tied to ecology/evolution and
  meta-analysis questions.
- Pat required each simulation report to have a reader interpretation, not only
  tables.
- Grace kept broad grids out of CRAN tests and required resumable optional
  outputs.
- Rose checked that blocked surfaces remain in the failure ledger rather than
  being quietly simulated.

## Remaining Boundary

This slice does not add simulation code, run simulation grids, choose external
comparators, or make coverage/power claims.
