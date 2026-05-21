# After Task: Phylogenetic Models Article Split

## Goal

Add a focused phylogenetic route page for users whose first structural-dependence
question is about tree-based species covariance.

## Implemented

`vignettes/phylogenetic-models.Rmd` now explains when to use `phylo()`, which
Gaussian slices are fitted, how to read q=2 and q=4 phylogenetic correlation
rows, and which outputs to inspect before interpreting the phylogenetic layer.
The structural-dependence overview and pkgdown navigation now link to the new
page.

## Mathematical Contract

No model code, likelihood, parser, extractor, or interval logic changed. The
article summarizes existing fitted support: univariate Gaussian `phylo()` `mu`,
matching bivariate q=2 `mu1`/`mu2`, constant q=4 location-scale phylogenetic
blocks, direct `sd_phylo*()` surfaces, and q=2 predictor-dependent phylogenetic
`corpair()` regression. It keeps residual `rho12` separate from latent
`corpairs()` rows.

## Files Changed

- `vignettes/phylogenetic-models.Rmd`
- `vignettes/structural-dependence.Rmd`
- `_pkgdown.yml`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`

## Checks Run

```sh
air format vignettes/phylogenetic-models.Rmd vignettes/structural-dependence.Rmd NEWS.md _pkgdown.yml docs/design/53-structural-dependence-article-split.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-phylogenetic-models-article-split.md
Rscript -e "devtools::load_all('.', quiet = TRUE); pkgdown::build_article('phylogenetic-models', new_process = FALSE, quiet = TRUE); pkgdown::build_article('structural-dependence', new_process = FALSE, quiet = TRUE)"
rg -n 'phylogenetic-models|Phylogenetic structured effects|phylo\\(1 \\| species|ranef\\(fit, \"phylo_mu\"\\)|sd_phylo|level = \"phylogenetic\"|phylogenetic slopes|matrix inputs|q=4 phylogenetic `corpair`' vignettes/phylogenetic-models.Rmd vignettes/structural-dependence.Rmd _pkgdown.yml NEWS.md docs/design/53-structural-dependence-article-split.md
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- The new `phylogenetic-models` article and the edited
  `structural-dependence` overview rebuilt.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

No tests changed. This was a documentation-routing slice, so the relevant
verification was article rendering, pkgdown navigation checking, and source
scans for fitted and planned phylogenetic wording.

## Consistency Audit

The article uses the supported `ranef(fit, "phylo_mu")` spelling and names the
fitted phylogenetic surfaces without implying support for phylogenetic slopes,
matrix-input phylogeny, simultaneous phylo-plus-spatial layers, q=4
predictor-dependent `corpair()` regressions, structured `rho12`, or
non-Gaussian phylogenetic effects.

## GitHub Issue Maintenance

Issue #31 remains the tutorial-path ledger for this slice. This task did not
change fitted phylogenetic code.

## What Did Not Go Smoothly

The first source check for phylogenetic test filenames used an unmatched shell
glob. The article text was still checked against the existing vignette, README,
and methods source before closing.

## Team Learning

For route pages, extractor spelling should be verified from source before it
lands in prose. This caught the correct `phylo_mu` level name before the page
was committed.

## Known Limitations

This page is a focused article split, not a new fitted capability. It does not
add phylogenetic slopes, public `phylo(A/Ainv = ...)` matrix inputs, simultaneous
phylo-plus-spatial layers, q=4 predictor-dependent phylogenetic `corpair()`
regressions, structured `rho12`, or non-Gaussian phylogenetic effects.

## Next Actions

Create the spatial focused route page only if it can keep coordinate-spatial
fitted support separate from mesh/SPDE, multiple slopes, `sigma`, q=4, direct-SD,
and spatial `corpair()` planned routes.
