# Slice 239 Structured Slope Parity Gate

## Goal

Record the structured-effect one-slope boundary before Phase 18 so spatial,
phylogenetic, animal, and `relmat()` models are not treated as equivalent until
the code and validation evidence are actually equivalent.

## Implemented

- Added `docs/design/44-structured-slope-parity-gate.md`.
- Linked the gate from the common phylogenetic/spatial/animal/relmat math note.
- Updated the Phase 18 simulation programme to admit coordinate spatial
  one-slope models to Wave A while keeping phylogenetic, animal, and `relmat()`
  one-slope paths planned.
- Updated the roadmap and NEWS with the same fitted-versus-planned boundary.

## Mathematical Contract

The common one-slope structured-effect model is:

```text
eta_mu,ij = X_ij beta + z0_j + x_ij z1_j
z0 ~ MVN(0, sd0^2 K)
z1 ~ MVN(0, sd1^2 K)
cov(z0, z1) = 0 in the first fitted slope path
```

Only the coordinate spatial version is fitted today. For phylogenetic, animal,
and `relmat()` models, this equation is a design target, not an implemented
claim.

## Files Changed

- `docs/design/44-structured-slope-parity-gate.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format docs/design/44-structured-slope-parity-gate.md docs/design/16-phylo-spatial-common-math.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-239-structured-slope-parity-gate.md`
- `Rscript -e "devtools::test(filter = 'spatial-gaussian|phylo-gaussian|package-skeleton|nongaussian-structured-boundary', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

This is a documentation and status-gate slice. The targeted tests cover the
implemented coordinate-spatial one-slope path, phylogenetic slope rejection,
planned `animal()`/`relmat()` marker parsing, and non-Gaussian structured-effect
boundaries.

## Consistency Audit

The new gate keeps `spatial(1 + x | site, coords = coords)` separate from
planned `phylo(1 + x | species, tree = tree)`,
`animal(1 + x | id, pedigree = ped)`, and
`relmat(1 + x | id, K = K)`. It also keeps known relatedness matrices separate
from known sampling covariance `V` in `meta_V(V = V)`.

## What Did Not Go Smoothly

The main risk was language drift: saying spatial and phylogenetic models share
the same template can sound like they are equally fitted. The slice therefore
uses a status table before examples.

## Team Learning

Ada kept one structured-effect roadmap. Darwin supplied eco-evo animal-model
examples. Fisher kept Phase 18 limited to fitted surfaces. Noether aligned the
equation and syntax. Pat kept planned examples visibly labelled. Rose kept
false parity out of the roadmap.

## Known Limitations

This slice does not implement phylogenetic, animal, or `relmat()` one-slope
models. It does not add a coordinate-spatial simulation runner; it only decides
which structured slope surface is eligible for the next smoke grid.

## Next Actions

Use the next structured-effect slice to add a coordinate-spatial one-slope
smoke surface or, if count-family work takes priority, keep the spatial surface
listed as the only fitted structured-slope Wave A candidate.
