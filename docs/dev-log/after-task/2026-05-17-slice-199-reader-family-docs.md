# Slice 199 Reader-Facing Family Docs

## Goal

Make the public docs easier to read before the comprehensive simulation phase:
users should see which non-Gaussian and structural-dependence surfaces are
fitted, which are documented planned markers, and which remain unsupported.

## What Changed

- Updated the model map so structural dependence is introduced in biological
  order: `animal()`, `phylo()`, `spatial()`, combined phylogenetic-plus-spatial
  models, then lower-level `relmat()` known-dependence matrices.
- Added an animal-model planned example to the structural-dependence section of
  the model map, while stating that `animal()` and `relmat()` are not fitted
  paths yet.
- Reworked the structural-dependence article opening and reader route around a
  five-step ladder: animal, phylogeny, spatial, phylogeny plus spatial, and
  other known dependence.
- Added animal and `relmat()` rows to the structural-dependence implementation
  status table.
- Added a compact non-Gaussian random-effect boundary paragraph to the family
  chooser, separating the fitted Poisson `mu` random-effect path from planned
  NB2, non-Gaussian scale, shape, inflation, hurdle, ordinal, and structured
  random-effect paths.
- Updated NEWS and ROADMAP for the reader-facing docs change.

## Role Notes

- Ada kept the slice documentation-only after Slice 198 changed code.
- Pat centred the applied reader's first question: "Can I fit this today?"
- Darwin pushed the order toward biological examples rather than implementation
  history.
- Boole kept public syntax names stable: `animal()`, `phylo()`, `spatial()`,
  and `relmat()`.
- Fisher kept interval and recovery claims tied to existing evidence.
- Grace required pkgdown checks because this slice changes vignettes and the
  public model map.
- Rose checked that the docs do not imply fitted animal, `relmat()`, combined
  phylogenetic-spatial, or broad non-Gaussian random-effect support.

## Remaining Boundary

This slice does not implement new likelihoods. Fitted structural-dependence
paths remain the existing phylogenetic and coordinate-spatial Gaussian slices;
`animal()` and `relmat()` are documented planned markers only.
