# After Task: Slice 186 Phylogenetic Slope Audit

## Goal

Audit phylogenetic one-slope support and parity gaps against the spatial lane.

## Implemented

The phylogenetic slope rejection now names the current structured-effect
parity gap: coordinate spatial already fits one univariate Gaussian `mu` slope
through `spatial(1 + x | site, coords = coords)`, but
`phylo(1 + x | species, tree = tree)` remains rejected until separate
phylogenetic slope recovery, diagnostics, and profile-target naming exist.

## Mathematical Contract

The fitted coordinate-spatial one-slope path estimates independent intercept
and slope fields:

```text
mu_i = X_i beta + z_0(site_i) + x_i z_1(site_i)
```

The phylogenetic sibling is still planned:

```text
mu_i = X_i beta + a_0(species_i) + x_i a_1(species_i)
```

where the slope vector `a_1` would follow the tree-derived covariance. Slice
186 does not fit that second equation.

## Files Changed

- `R/drmTMB.R`
- `R/formula-markers.R`
- `tests/testthat/test-phylo-gaussian.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-17-slice-186-phylo-slope-audit.md`

## Checks Run

- `air format R/drmTMB.R R/formula-markers.R tests/testthat/test-phylo-gaussian.R NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/design/33-phase-6c-core-random-effects.md`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated `man/phylo.Rd`.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|gaussian-location-scale", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed.
- `git diff --check`: passed.

## Tests Of The Tests

The updated test converts the phylogenetic slope error into an inspected
condition and checks both the intercept-only phylogenetic boundary and the
spatial one-slope sibling message.

## Consistency Audit

The roadmap, formula grammar, structured-effect design notes, and public
marker documentation now all say the same thing: spatial one-slope support is
fitted for univariate Gaussian `mu`; phylogenetic one-slope support is still
planned.

## What Did Not Go Smoothly

The main risk was wording drift. Several documents already mentioned
structured slopes, but not all of them made clear that spatial and phylogeny
are no longer at the same implementation level.

## Team Learning

Ada kept the audit separate from implementation. Noether checked that the
spatial and phylogenetic equations are siblings, not aliases. Fisher and Curie
kept the fitting claim closed until simulation recovery exists for the
phylogenetic slope SD. Pat asked that the error name the supported spatial
sibling so users can understand the asymmetry. Grace required roxygen
regeneration because marker documentation changed. Rose recorded the parity
gap for the pre-simulation gate.

## Known Limitations

This slice does not add phylogenetic slope likelihood code, `sdpars`,
`ranef()`, `profile_targets()`, `check_drm()` diagnostics, or recovery tests
for `phylo(1 + x | species, tree = tree)`.

## Next Actions

Slice 187 should confirm the spatial one-slope path itself: docs, tests,
diagnostics, and the boundary against multiple slopes, mesh slopes, spatial
scale terms, and bivariate spatial covariance.
