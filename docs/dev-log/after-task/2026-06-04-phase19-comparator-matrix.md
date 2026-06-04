# After Task: Phase 19 Comparator Matrix

## Goal

Block 2 of the capability close-out push: advance the non-TMB issues. The most
reliably completable item is the Phase 19 comparator design (#60), which needs
no model fitting from the cloud sandbox.

## Finding

Comparator design existed only piecemeal — a Tweedie comparator contract
(doc 126) and comparator-boundary decisions (doc 130) — with no consolidated
matrix mapping every fitted surface to its comparator package and scale
conversion.

## Implemented

- Added `docs/design/158-phase-19-comparator-matrix.md`: principles (one-off
  shared datasets, convert-before-comparing, no implied one-to-one comparator,
  reproducible timing), a scale-conversion reference table (the public `sigma`
  vs each comparator's dispersion/precision/size/variance, grounded in the
  family registry's internal mappings), the comparator matrix itself (each
  `drmTMB` surface to `glmmTMB`/`brms`/`metafor`/`betareg`/`gamlss`/`ordinal`/
  `MCMCglmm`/`spaMM`/`phylolm` with what cannot be matched), and the Phase 19
  definition of done.
- Pointed the ROADMAP Phase 19 line at the matrix.

## Scope

Design only. No fits were run (the comparator packages are not installable in
the sandbox; the network policy blocks the R repositories). The matrix fixes the
mapping and conversions so the eventual comparator runs are mechanical and
scale-correct. This advances #60 to "design complete; fits pending a machine
with the comparator packages."

## Checks Run

Documentation-only block: no R code, tests, or fitted status changed.
