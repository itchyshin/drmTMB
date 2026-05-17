# Slice 213 Simulation Replicate Runner

## Goal

Add the first resumable runner primitive for Phase 18 pilot simulation cells.

## What Changed

- Added `inst/sim/R/sim_runner.R` with `phase18_run_replicate()` and result
  path/validation helpers.
- Captured warnings, errors, elapsed time, session metadata, status, and
  optional RDS output for one cell replicate.
- Added smoke tests for save/resume behaviour, warning and error capture, and
  malformed inputs.
- Updated the simulation README, ROADMAP, NEWS, and check log.

## Role Notes

- Curie kept the runner generic and tested it with tiny fake DGP/fit/summarise
  functions rather than launching a grid.
- Fisher kept one replicate as the atomic audit unit: seed, cell id, summary,
  status, and warnings are stored together.
- Grace kept result files optional and under ignored local output.
- Rose checked that the runner does not imply any Phase 18 performance result
  has been generated.

## Remaining Boundary

This slice adds a runner primitive only. Surface-specific runner scripts,
parallel execution, per-cell aggregation, reports, and comparator fits are still
future slices.
