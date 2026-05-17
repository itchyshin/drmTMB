# Slice 203 Meta-Analysis Return Map

## Goal

Set the first Phase 17 return block after the pre-simulation gate. The block
focuses on meta-analysis hardening before broad Phase 18 simulation claims.

## What Changed

- Added a post-202 Phase 17 return section to `ROADMAP.md`.
- Set Slice 203 as the local roadmap slice that records the return map.
- Laid out Slices 204-208: `meta_V()` API decision, additive known-`V`
  implementation if approved, proportional sampling-variance boundary,
  interval safety, and reader examples.
- Re-stated that meta-analysis remains Gaussian regression with known sampling
  covariance, not a new `meta_gaussian()` family.
- Re-stated that public fitted extra heterogeneity remains `sigma`; any
  connection to meta-analytic `tau` belongs in prose and reporting tables, not
  a new `tau ~` grammar.
- Updated NEWS and the check log.

## Role Notes

- Ada placed the return block before broad Phase 18 so simulation evidence is
  built on stable reader-facing contracts.
- Boole separated the preferred future `meta_V()` spelling from the current
  implemented `meta_known_V(V = V)` marker.
- Fisher kept interval safety and proportional sampling-variance likelihood
  boundaries explicit.
- Pat and Darwin kept the examples focused on applied meta-analysis questions:
  known sampling variance, heterogeneity, repeated study effects, and
  reader-safe interpretation.
- Grace required pkgdown validation because ROADMAP and NEWS changed.
- Rose checked that the map does not imply `meta_V()` or proportional
  sampling-variance models are implemented yet.

## Remaining Boundary

This slice is roadmap work only. It does not implement `meta_V()`, deprecate
`meta_known_V()`, add proportional sampling-variance likelihoods, or change the
current fitted meta-analysis path.
