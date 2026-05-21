# After Task: relmat Known-Matrix Article Split

## Goal

Add a focused `relmat()` route page for users with a latent known covariance or
precision matrix that does not belong naturally to `animal()`, `phylo()`, or
`spatial()`.

## Implemented

`vignettes/relmat-known-matrices.Rmd` now explains when to use `relmat()`, which
Gaussian `mu` slices are fitted, how to ask for the first matching bivariate q=2
location covariance, and which outputs to inspect before interpreting the
known-matrix layer. The structural-dependence overview and pkgdown navigation
now link to the new page.

## Mathematical Contract

No model code, likelihood, parser, extractor, or interval logic changed. The
article summarizes existing fitted support: univariate Gaussian location
`relmat()` intercepts and matching bivariate q=2 location-location `relmat()`
covariance. It keeps residual `rho12` separate from latent `corpairs()` rows and
keeps known sampling covariance in the meta-analysis route.

## Files Changed

- `vignettes/relmat-known-matrices.Rmd`
- `vignettes/structural-dependence.Rmd`
- `_pkgdown.yml`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`

## Checks Run

```sh
air format vignettes/relmat-known-matrices.Rmd vignettes/structural-dependence.Rmd NEWS.md _pkgdown.yml docs/design/53-structural-dependence-article-split.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-relmat-known-matrix-article-split.md
Rscript -e "devtools::load_all('.', quiet = TRUE); pkgdown::build_article('relmat-known-matrices', new_process = FALSE, quiet = TRUE); pkgdown::build_article('structural-dependence', new_process = FALSE, quiet = TRUE)"
rg -n 'relmat-known-matrices|Known-matrix relatedness with relmat|relmat\\(1 \\| id|relmat\\(1 \\| p \\| id|ranef\\(fit, \"relmat_mu\"\\)|meta_V\\(V = V\\)|meta_known_V\\(V = V\\)|relatedness `sigma`|relmat.*corpair' vignettes/relmat-known-matrices.Rmd vignettes/structural-dependence.Rmd _pkgdown.yml NEWS.md docs/design/53-structural-dependence-article-split.md
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- The new `relmat-known-matrices` article and the edited
  `structural-dependence` overview rebuilt.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

No tests changed. This was a documentation-routing slice, so the relevant
verification was article rendering, pkgdown navigation checking, and source
scans for the fitted and planned `relmat()` wording.

## Consistency Audit

The article uses the supported `ranef(fit, "relmat_mu")` spelling and names the
fitted `relmat()` surfaces without implying support for slopes, `sigma`, q=4,
predictor-dependent `corpair()` regression, direct-SD grammar, or non-Gaussian
known-matrix effects.

## GitHub Issue Maintenance

Issue #31 remains the tutorial-path ledger for this slice. Issue #147 remains
the animal/`relmat()` implementation ledger; this task did not change fitted
`relmat()` code.

## What Did Not Go Smoothly

The main risk was conceptual, not technical: `relmat()` can look like a generic
answer to every known matrix. The page now explicitly routes known sampling
covariance to preferred `meta_V(V = V)`, notes `meta_known_V(V = V)` only as a
compatibility alias, and reserves `relmat()` for latent random-effect
relatedness.

## Team Learning

For lower-level escape-hatch syntax, Darwin and Rose should both check that the
page says when not to use it. A route page is useful only if it prevents the
wrong route as well as naming the right one.

## Known Limitations

This page is a focused article split, not a new fitted capability. It does not
add structured slopes, relatedness `sigma`, q=4 location-scale blocks,
predictor-dependent `relmat()` `corpair()` regression, direct-SD grammar, or
non-Gaussian known-matrix effects.

## Next Actions

Create the next focused structural-dependence route page only after deciding
whether phylogenetic or spatial material now causes more reader confusion.
