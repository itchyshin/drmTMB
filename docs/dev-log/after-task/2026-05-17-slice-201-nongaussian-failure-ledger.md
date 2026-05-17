# Slice 201 Non-Gaussian Failure Ledger

## Goal

Record the non-Gaussian failure modes that must shape Phase 18 before broad
simulation claims are made. This is a design and validation slice, not a new
likelihood or formula-grammar slice.

## What Changed

- Added a Slice 201 failure-ledger section to
  `docs/design/34-validation-debt-register.md`.
- Named the fitted state, main failure modes, and Phase 18 decision for
  ordinary Poisson `mu` random effects, NB2-style count random effects,
  non-Gaussian `sigma`, shape/skewness, zero/hurdle/one inflation, ordinal
  mixed models, structured non-Gaussian dependence, cross-parameter covariance,
  intervals, and runtime.
- Kept the immediate Phase 18 non-Gaussian entry narrow: ordinary
  non-zero-inflated Poisson `mu` random intercepts and independent numeric
  slopes can enter the first operating-characteristics grid, while other
  non-Gaussian random-effect surfaces remain excluded until their own
  implementation and recovery evidence exists.
- Updated NEWS, ROADMAP, and the check log.

## Role Notes

- Ada kept Slice 201 as a gatekeeping ledger rather than an implementation
  detour.
- Fisher separated simulation-measurable failures from features that should be
  excluded because no fitted likelihood exists yet.
- Curie shaped the Phase 18 metrics: convergence, Hessian status, boundary
  warnings, profile success, bias, RMSE, interval coverage, and elapsed time.
- Pat checked that a reader can tell which models are safe to try now.
- Boole kept unsupported syntax out of the fitted grammar.
- Grace required pkgdown and stale-wording checks because this design doc feeds
  public roadmap claims.
- Rose checked that the ledger does not silently promote NB2, non-Gaussian
  scale, shape, inflation, ordinal, structured, or cross-parameter covariance
  random effects into fitted support.

## Remaining Boundary

The failure ledger does not implement any new model. It records what Phase 18
should measure for fitted surfaces and what it should exclude until separate
implementation, diagnostics, interval, and recovery evidence exists.
