# Pre-Simulation Slice Map

Date: 2026-05-18

## Goal

Record the corrected slice plan before comprehensive Phase 18 simulation, after
the user clarified that a figure gallery should showcase model-interpretation
figures rather than a narrow count-simulation diagnostics report.

## Files Changed

- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-18-pre-simulation-slice-map.md`

## What Changed

- Added a pre-simulation readiness slice map covering Slices 260-292.
- Kept the Florence figure-gallery lane separate from the Simulation &
  Comparison lane.
- Added explicit readiness slices for random slopes, convergence controls,
  warm starts, multi-optimizer fallback, Hessian diagnostics, interval
  hardening, meta-analysis, structural dependence, non-Gaussian families,
  shape models, ordinal models, bivariate mixed-family combinations,
  extractors, documentation boundaries, and the final pre-simulation evidence
  ledger.
- Recorded the process lesson that an internal pilot such as count simulation
  diagnostics must not be promoted as the general figure gallery or as the
  whole comprehensive simulation programme.

## Checks Run

- `air format ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-pre-simulation-slice-map.md`
- `rg -n "Pre-Simulation Readiness Slice Map|Slice 292|count simulation diagnostics|meta_known_V|meta_V\\(V = V\\)|Simulation & Comparison" ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-pre-simulation-slice-map.md`
- `git diff --check`

## Known Limitations

- This slice is roadmap and process work only; it does not implement the
  listed feature hardening.
- Slice order can still change if a failing test, CI issue, or user priority
  makes a specific blocker urgent.

## Standing-Role Summary

- Ada: kept the roadmap split into plotting, hardening, and simulation gates.
- Pat: required reader-facing page and slice names instead of internal phase
  shorthand.
- Fisher: required the simulation gate to cover power, bias, coverage,
  convergence, and interval status across model classes.
- Grace: kept this as a small documentation-only branch after PR #211 merged.
- Rose: identified the count-gallery confusion as scope drift and required a
  durable roadmap correction.
- Florence: kept the figure gallery focused on model interpretation and
  publication-ready visual communication.
