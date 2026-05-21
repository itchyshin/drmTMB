# After Task: Spatial Models Article Split

## Goal

Add a focused coordinate-spatial route page for users whose first
structural-dependence question is about nearby sites and coordinate-based
spatial fields.

## Implemented

`vignettes/spatial-models.Rmd` now explains when to use `spatial()`, which
Gaussian slices are fitted, how to read q=2 spatial correlation rows, and which
outputs to inspect before interpreting the spatial layer. The
structural-dependence overview and pkgdown navigation now link to the new page.

## Mathematical Contract

No model code, likelihood, parser, extractor, or interval logic changed. The
article summarizes existing fitted support: univariate Gaussian coordinate
`spatial()` `mu` intercepts, one numeric coordinate-spatial `mu` slope, and
matching bivariate q=2 `mu1`/`mu2` coordinate-spatial location covariance. It
keeps residual `rho12` separate from latent `corpairs()` rows.

## Files Changed

- `vignettes/spatial-models.Rmd`
- `vignettes/structural-dependence.Rmd`
- `_pkgdown.yml`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`

## Checks Run

```sh
air format vignettes/spatial-models.Rmd vignettes/structural-dependence.Rmd NEWS.md _pkgdown.yml docs/design/53-structural-dependence-article-split.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-spatial-models-article-split.md
Rscript -e "devtools::load_all('.', quiet = TRUE); pkgdown::build_article('spatial-models', new_process = FALSE, quiet = TRUE); pkgdown::build_article('structural-dependence', new_process = FALSE, quiet = TRUE)"
rg -n 'spatial-models|Coordinate-spatial structured effects|spatial\\(1 \\| site|spatial\\(1 \\+ depth|spatial\\(1 \\| p \\| site|ranef\\(fit, \"spatial_mu\"\\)|level = \"spatial\"|mesh|spatial `corpair`' vignettes/spatial-models.Rmd vignettes/structural-dependence.Rmd _pkgdown.yml NEWS.md docs/design/53-structural-dependence-article-split.md
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

## Tests Of The Tests

No tests changed. This was a documentation-routing slice, so the relevant
verification was article rendering, pkgdown navigation checking, and source
scans for fitted and planned spatial wording.

## Consistency Audit

The article uses the supported `ranef(fit, "spatial_mu")` spelling and names
the fitted coordinate-spatial surfaces without implying support for mesh/SPDE
inputs, multiple spatial slopes, slope correlations, spatial `sigma`, q=4
spatial blocks, direct spatial SD surfaces, predictor-dependent spatial
`corpair()` regressions, simultaneous phylo-plus-spatial layers, or
non-Gaussian spatial effects.

## GitHub Issue Maintenance

Issue #31 remains the tutorial-path ledger for this slice. This task did not
change fitted spatial code.

## What Did Not Go Smoothly

The main risk was overclaiming spatial parity because one univariate slope is
fitted while richer spatial covariance routes are not. The page therefore keeps
the one-slope route narrow and repeats the planned boundaries near the top.

## Team Learning

Spatial route pages need to name the data contract early: site labels live in
the data, while the coordinate table is supplied through `coords = coords`.
That is the simplest way to keep coordinate-spatial support distinct from
future mesh/SPDE support.

## Known Limitations

This page is a focused article split, not a new fitted capability. It does not
add mesh/SPDE inputs, multiple slopes, slope correlations, spatial `sigma`,
spatial q=4 blocks, direct spatial SD surfaces, spatial `corpair()`
regressions, simultaneous phylo-plus-spatial layers, or non-Gaussian spatial
effects.

## Next Actions

Create the planned phylo-plus-spatial route page only after the status table can
make clear that simultaneous structural layers remain a design target rather
than a fitted route.
