# After Task: Animal Models Article Split

## Goal

Add the first focused structural-dependence route page for users who need fitted
animal-model support through `pedigree`, `A`, or `Ainv`.

## Implemented

`vignettes/animal-models.Rmd` now explains when to use `animal()`, which
Gaussian `mu` slices are fitted, how to ask for the first matching bivariate q=2
location covariance, and which outputs to inspect before interpreting the animal
layer. The structural-dependence overview and pkgdown navigation now link to the
new page.

## Mathematical Contract

No model code, likelihood, parser, extractor, or interval logic changed. The
article summarizes existing fitted support: univariate Gaussian location
animal-model intercepts and matching bivariate q=2 location-location animal
covariance. It keeps residual `rho12` separate from latent animal
`corpairs()` rows.

## Files Changed

- `vignettes/animal-models.Rmd`
- `vignettes/structural-dependence.Rmd`
- `_pkgdown.yml`
- `docs/design/53-structural-dependence-article-split.md`
- `docs/dev-log/check-log.md`
- `NEWS.md`

## Checks Run

```sh
air format vignettes/animal-models.Rmd vignettes/structural-dependence.Rmd NEWS.md _pkgdown.yml docs/design/53-structural-dependence-article-split.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-21-animal-models-article-split.md
Rscript -e "devtools::load_all('.', quiet = TRUE); pkgdown::build_article('animal-models', new_process = FALSE, quiet = TRUE); pkgdown::build_article('structural-dependence', new_process = FALSE, quiet = TRUE)"
rg -n 'animal-models|Animal models and additive relatedness|animal\\(1 \\| individual|animal\\(1 \\| p \\| individual|ranef\\(fit, \"animal_mu\"\\)|sparse large-pedigree|animal.*corpair' vignettes/animal-models.Rmd vignettes/structural-dependence.Rmd _pkgdown.yml NEWS.md docs/design/53-structural-dependence-article-split.md
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

- The new `animal-models` article and the edited `structural-dependence`
  overview rebuilt.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

No tests changed. This was a documentation-routing slice, so the relevant
verification was article rendering, pkgdown navigation checking, and source
scans for the fitted and planned animal-model wording.

## Consistency Audit

The article uses the supported `ranef(fit, "animal_mu")` spelling, not a new
argument name. It names the fitted `animal()` surfaces and planned neighbors in
one page so readers do not mistake planned sparse-pedigree, slope, `sigma`, q=4,
or animal `corpair()` routes for implemented support.

## GitHub Issue Maintenance

Issue #31 remains the tutorial-path ledger for this slice. Issue #147 remains
the animal/`relmat()` implementation ledger; this task did not change fitted
animal-model code.

## What Did Not Go Smoothly

The first draft used an unsupported-looking `ranef(fit, level = "animal_mu")`
example. A source scan against existing docs corrected it to
`ranef(fit, "animal_mu")` before the slice closed.

## Team Learning

For focused route pages, Pat's check should include extractor syntax as well as
formula syntax. A page can be right about fitted models and still mislead users
with one wrong post-fit call.

## Known Limitations

This page is a focused article split, not a new fitted capability. It does not
add sparse large-pedigree precision construction, animal-model slopes,
structured `sigma`, q=4 animal blocks, predictor-dependent animal `corpair()`
regression, or non-Gaussian animal effects.

## Next Actions

Create the next focused route page for phylogenetic models or `relmat()` only
after checking which split reduces the most reader confusion.
