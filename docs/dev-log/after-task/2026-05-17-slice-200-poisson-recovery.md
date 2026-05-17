# Slice 200 Poisson Recovery Tests

## Goal

Add focused recovery evidence for the fitted non-Gaussian random-effect path
before the Phase 18 simulation gate. The slice stays on ordinary
non-zero-inflated Poisson `mu` random effects and does not add new model
surfaces.

## What Changed

- Added a factor-predictor Poisson random-intercept simulation where habitat
  levels affect the log mean and the group-level intercept SD is recovered from
  the fitted `sdpars$mu` path.
- Added a weak-SD Poisson random-intercept simulation with a small true group
  SD. The test checks convergence, finite positive fitted SDs, stable fixed
  effects, and the `check_drm(sd_boundary = 0.20)` lower-boundary warning.
- Parameterized the existing Poisson random-intercept simulator with `sd_id`
  so ordinary and weak-SD cases share the same deterministic data-generating
  contract.
- Updated NEWS, ROADMAP, and the check log for the non-Gaussian gate evidence.

## Role Notes

- Ada kept Slice 200 inside the existing fitted Poisson `mu` surface.
- Curie focused the tests on deterministic, CRAN-safe recovery cases rather
  than a broad simulation grid.
- Fisher treated the weak-SD case as a diagnostic-stability test, not a precise
  tiny-variance recovery claim.
- Boole kept the grammar unchanged: `(1 | id)` remains the fitted random
  intercept, and correlated or labelled Poisson blocks remain planned.
- Grace required targeted test and pkgdown validation because NEWS and ROADMAP
  changed.
- Rose checked that the slice does not imply NB2, zero-inflated, scale, shape,
  ordinal, animal, phylogenetic, or spatial non-Gaussian random effects now fit.

## Remaining Boundary

This slice does not implement any new likelihood path. The fitted non-Gaussian
random-effect support remains ordinary non-zero-inflated Poisson `mu` random
intercepts and independent numeric random slopes.
