# Slice 202 Pre-Simulation Decision Gate

## Goal

Decide what can honestly move toward Phase 18 after the non-Gaussian gate and
what should return to Phase 17 hardening first.

## Decision

Do not start broad comprehensive Phase 18 yet. The package has enough evidence
for a narrow ordinary Poisson `mu` random-effect pilot simulation, but not for a
full simulation grid covering all non-Gaussian, structured-dependence,
location-scale-shape, inflation, hurdle, ordinal, and interval surfaces.

After Slice 202, return to Phase 17. The first return block should focus on
meta-analysis hardening: preferred `meta_V(V = V)` spelling, vector and matrix
`V`, proportional `meta_V(w = w, scale = "proportional")` boundaries,
profile/summary safety, and reader-facing examples.

## What Changed

- Updated the roadmap preview boundary so Phase 18 remains a comprehensive
  simulation layer, but broad Phase 18 is not opened yet.
- Marked Slice 202 as locally done in the non-Gaussian gate table.
- Added a Slice 202 decision table separating broad Phase 18, narrow Poisson
  pilot simulation, post-202 Phase 17 return work, and the full Phase 18 entry
  rule.
- Updated NEWS and the check log.

## Role Notes

- Ada made the gate operational: narrow pilot allowed, broad Phase 18 delayed.
- Fisher required surface-by-surface simulation eligibility rather than a
  blanket "ready for simulation" claim.
- Curie identified the first pilot grid as ordinary non-zero-inflated Poisson
  `mu` random intercepts and independent numeric slopes.
- Pat and Darwin pushed the post-202 return toward reader-facing
  meta-analysis examples rather than abstract infrastructure.
- Boole kept the future `meta_V()` spelling distinct from the current
  implemented `meta_known_V(V = V)` marker.
- Grace kept this as roadmap/design work with pkgdown validation, not a code
  change.
- Rose checked that blocked non-Gaussian and structured surfaces do not slip
  into the Phase 18 entry claim.

## Remaining Boundary

This slice does not implement simulation helpers, `meta_V()`, proportional
sampling-variance models, bootstrap intervals, or any new non-Gaussian random
effect. It records the decision that those surfaces need hardening before broad
Phase 18 simulation claims.
