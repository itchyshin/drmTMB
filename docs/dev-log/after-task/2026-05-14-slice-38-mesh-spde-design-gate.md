# After Task: Slice 38 Mesh/SPDE Design Gate

## Goal

Record exactly when `mesh = mesh` becomes legitimate fitted spatial syntax and
what provenance/citation work is required if `drmTMB` builds on existing SPDE
software.

## Implemented

`docs/design/09-phylogenetic-and-spatial-speed.md` now has a
`Mesh/SPDE Implementation Gate` section. It requires a coded mesh object
contract before fitting `spatial(1 | site, mesh = mesh)`. The contract must
specify vertices, triangle topology, projection, precision construction,
coordinate scale, row/site mapping, and the fitted spatial parameters.

The same section records the dependency and citation policy:

- cite Lindgren, Rue, and Lindstrom for the SPDE method;
- cite the `sdmTMB` JSS paper when using it as the ecological TMB-plus-SPDE
  precedent;
- cite `fmesher` if `drmTMB` accepts or builds `fmesher` meshes;
- update `inst/COPYRIGHTS` in the same slice if code or test fixtures are
  copied or closely adapted.

ROADMAP and known limitations now state that the design gate is recorded, but
the coded mesh schema, projection path, recovery tests, and mesh fitting remain
future work.

## Mathematical Contract

The first fitted coordinate path remains:

```text
u_site ~ MVN(0, sd_spatial^2 K_coords)
```

The future mesh/SPDE path should instead represent the spatial field through a
sparse precision and a projection matrix:

```text
u_mesh ~ GMRF(0, Q_spde^{-1})
u_site = A_site_mesh u_mesh
```

This slice records the contract only; it does not add `Q_spde` to TMB.

## Files Changed

- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `ROADMAP.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `PATH=/opt/homebrew/bin:$PATH air format docs/design/09-phylogenetic-and-spatial-speed.md ROADMAP.md docs/dev-log/known-limitations.md`
- `rg -n 'Mesh/SPDE Implementation Gate|coded mesh object schema|fmesher|inst/COPYRIGHTS|not the scalable mesh/SPDE route' docs/design/09-phylogenetic-and-spatial-speed.md ROADMAP.md docs/dev-log/known-limitations.md inst/COPYRIGHTS`

All passed.

## Tests Of The Tests

This slice is design-only. The useful check was the wording scan across design,
roadmap, limitations, and provenance policy, because the main failure mode is
overclaiming mesh support before code exists.

## Consistency Audit

The design docs, roadmap, known limitations, and `inst/COPYRIGHTS` now agree:
the current spatial path is coordinate-based and small-data; mesh/SPDE is the
planned scalable route; citation and provenance are separate obligations.

## What Did Not Go Smoothly

The repo already had a good citation/provenance paragraph, so the main task was
to add an implementation gate without duplicating too much of the article text.

## Team Learning

- Ada: a future feature is easier to govern when the gate names exact required
  artifacts.
- Boole: `coords` and `mesh` are API entry points, not different ecological
  model families.
- Gauss: mesh fitting must enter TMB as a sparse precision/projection path, not
  as a dense coordinate fallback.
- Noether: the spatial object of inference is the field; the mesh is numerical
  support.
- Jason: sister-package sources are a source map, not permission to import a
  high-dimensional GLLVM API.
- Fisher: recovery evidence for one `mu` field comes before scale, bivariate,
  and correlation extensions.
- Pat: user-facing docs should tell ordinary users to start with `coords` and
  reserve `mesh` for expert control.
- Grace: optional dependencies should start as `Suggests` with clear errors
  until the dependency is truly required.
- Rose: provenance and citation are different; both must be checked before a
  spatial implementation is called complete.

## Known Limitations

`spatial(1 | site, mesh = mesh)` is still rejected by the fitter. No SPDE
precision, projection matrix, `fmesher` dependency, or mesh recovery test was
added.

## Next Actions

Run the Phase 5 synthesis pass, rebuild the roadmap/site, and then finish the
Slice 40 release gate.
