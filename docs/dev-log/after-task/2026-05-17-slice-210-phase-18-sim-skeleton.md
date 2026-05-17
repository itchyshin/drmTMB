# Slice 210 Phase 18 Simulation Skeleton

## Goal

Add the first small reusable Phase 18 simulation infrastructure without running
any simulation grid.

## What Changed

- Added `inst/sim/README.md` with the intended optional simulation layout.
- Added `inst/sim/R/sim_registry.R` with `phase18_seed_table()` and
  `phase18_cell_registry()`.
- Added placeholder directories for `dgp/`, `fit/`, `run/`, `reports/`, and
  local results.
- Added CRAN-safe tests for seed reproducibility, registry shape, and malformed
  input.
- Updated the Phase 18 blueprint, ROADMAP, NEWS, and check log.

## Role Notes

- Curie kept the first implementation to seed and cell bookkeeping only.
- Fisher required replicate-level seeds and explicit cell ids before any
  performance claims.
- Grace kept the code optional and CRAN-safe.
- Pat kept the README focused on how a future reader can audit a run.
- Rose checked that this does not claim a simulation grid has been run.

## Remaining Boundary

This slice does not add DGPs, fitters, runners, reports, results, external
comparators, or coverage/power claims.
