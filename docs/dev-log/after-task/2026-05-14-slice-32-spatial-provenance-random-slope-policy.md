# After Task: Slice 32 Spatial Provenance And Random-Slope Policy

## Goal

Close the design gap before fitted spatial work by recording how `coords`,
`mesh`, spatial citations, code provenance, multiple random factors, and future
structured slopes should be handled.

## Implemented

- Updated `ROADMAP.md` to keep the spatial lane live and explicit: `coords` is
  the friendly public input, `mesh` is optional expert control, and the scalable
  SPDE/GMRF path uses a mesh-like scaffold internally.
- Updated `docs/design/09-phylogenetic-and-spatial-speed.md`,
  `docs/design/16-phylo-spatial-common-math.md`, and
  `docs/design/01-formula-grammar.md` to distinguish coordinates, meshes, dense
  coordinate covariance comparators, and scalable sparse-precision spatial
  models.
- Updated `vignettes/phylogenetic-spatial.Rmd` and
  `vignettes/formula-grammar.Rmd` so the pkgdown reader sees the same message.
- Updated `inst/COPYRIGHTS` to say spatial citations and code provenance have
  different jobs: citations acknowledge methods/software; `COPYRIGHTS` records
  copied or closely adapted code.
- Updated `docs/dev-log/known-limitations.md` to record the slope policy:
  one structured `mu` slope first, at most two structured `mu` slopes as an
  advanced path, multiple random factors as separate additive blocks, and no
  near-term intercept-slope `corpair()` rows.

## Mathematical Contract

`coords` names observed or site coordinates. A `mesh` is not a sampling level or
biological predictor; it is numerical support for approximating a continuous
spatial field with a sparse SPDE/GMRF precision. A dense covariance built
directly from pairwise distances could be useful as a small-data comparator, but
it is not the scalable default route.

For future structured slopes, the first contract is independent structured `mu`
slope fields. Intercept-slope and slope-slope covariance should not appear in
the first slope implementation. The biologically interesting later exception is
a bivariate slope1-slope2 correlation for the same covariate across responses,
matching a plasticity-syndrome question; that needs coefficient-aware
`corpair()` syntax and recovery tests before it is claimed.

## Files Changed

- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/09-phylogenetic-and-spatial-speed.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/dev-log/known-limitations.md`
- `inst/COPYRIGHTS`
- `vignettes/formula-grammar.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `/opt/homebrew/bin/air format ROADMAP.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd inst/COPYRIGHTS`
- `/Library/Frameworks/R.framework/Resources/bin/Rscript -e 'devtools::test(filter = "package-skeleton", reporter = "summary")'`
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::build_site()'`
- `PATH=/opt/homebrew/bin:$PATH /Library/Frameworks/R.framework/Resources/bin/Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'friendly public input|friendly data-level input|scalable SPDE|dense coordinate|mesh is not|required by the scalable|expert-control|expert route|mesh-like' ROADMAP.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd`
- `rg -n 'slope1-slope2|plasticity-syndrome|intercept-slope|two structured .*mu.* slopes|Multiple random factors|Spatial Citation|sdmTMB|fmesher|Lindgren' ROADMAP.md docs/design/01-formula-grammar.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/16-phylo-spatial-common-math.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/phylogenetic-spatial.Rmd inst/COPYRIGHTS`
- `git diff --check`

All passed.

## Tests Of The Tests

This was a documentation and design-policy slice. The test evidence is that the
status inventory searches found the intended concepts across roadmap, grammar,
design docs, known limitations, tutorials, and generated pkgdown pages, and
`pkgdown::build_site()` rendered the touched articles without errors.

## Consistency Audit

The fitted/planned boundary stayed intact: no spatial likelihood, mesh helper,
structured slope, or slope `corpair()` support was claimed as implemented. The
docs now say that the current spatial lane is planned, that the scalable route
uses SPDE/GMRF mesh machinery, and that direct coordinate covariance is only a
possible comparator.

## What Did Not Go Smoothly

The first roadmap text mentioned `mesh` but did not answer the user's practical
question: whether a mesh is required and how it differs from coordinates. Pat
caught that missing reader explanation, and the text now makes the distinction
direct.

## Team Learning

- Ada should treat the roadmap as live and patch it when user questions reveal
  missing design decisions.
- Boole should keep public syntax readable: `coords` for ordinary users,
  `mesh` for expert control.
- Gauss should remember that mesh is a numerical device for sparse precision,
  not a data level.
- Noether should keep the spatial contract aligned across equations, syntax,
  and TMB data expectations.
- Darwin should keep slope1-slope2 correlations visible as the biologically
  interesting plasticity-syndrome future target.
- Fisher should require simulation and identifiability evidence before
  structured slopes or slope correlations are advertised.
- Pat should keep asking whether the user can see why a computational object is
  needed.
- Grace should keep pkgdown rebuilds attached to roadmap and tutorial changes.
- Rose should watch for roadmap drift when the implementation plan changes
  faster than the public docs.

## Known Limitations

- Spatial random effects, mesh building, structured slopes, and slope
  `corpair()` targets are still planned.
- Formal bibliography entries are still not part of the pkgdown site; this
  slice uses prose citations, DOI text, and links.

## Next Actions

Move from policy into the spatial implementation lane: decide the first
intercept-only spatial contract, then add the smallest fitted Gaussian `mu`
spatial path with comparator or simulation evidence.
