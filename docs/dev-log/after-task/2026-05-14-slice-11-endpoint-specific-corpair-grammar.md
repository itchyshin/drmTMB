# After Task: Slice 11 Endpoint-Specific corpair Grammar

## Goal

Reserve the ordinary predictor-dependent latent-correlation grammar without
claiming a fitted likelihood.

## Implemented

Slice 11 chooses endpoint-specific `corpair()` syntax as the first ordinary
predictor-dependent route:

```r
corpair(id, block = "p", from = "mu1", to = "sigma2") ~ w
```

The parser now stores `from` and `to` endpoints in `drm_formula()` entries and
continues to reject all `corpair()` formulas at fitting time. It also rejects
half-specified endpoints, `class` mixed with endpoint-specific syntax, residual
`rho12` as a latent endpoint, and self-correlations such as
`from = "mu1", to = "mu1"`.

## Mathematical Contract

This slice is grammar only. The fitted model remains unchanged:

- `rho12 = ~ w` is residual within-observation correlation regression;
- `corpairs()` extracts fitted constant latent random-effect correlations;
- endpoint-specific `corpair()` is reserved for future latent random-effect
  correlation regression.

The first fitted ordinary route should be q=2, where one selected latent pair
can use a Fisher-z regression while preserving positive definiteness. q=4
correlation regression remains later because six independent pairwise
`tanh()` regressions do not guarantee a positive-definite correlation matrix.

## Files Changed

- `R/parse-formula.R`
- `R/formula-markers.R`
- `tests/testthat/test-package-skeleton.R`
- `man/corpair.Rd`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/formula-grammar.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format R/parse-formula.R R/formula-markers.R tests/testthat/test-package-skeleton.R docs/design/01-formula-grammar.md docs/design/20-coscale-correlation-pairs.md docs/dev-log/known-limitations.md vignettes/phylogenetic-spatial.Rmd vignettes/formula-grammar.Rmd vignettes/model-map.Rmd NEWS.md`
- `git diff --check`
- `Rscript -e 'devtools::test(filter = "package-skeleton", reporter = "summary")'`
- `Rscript -e 'devtools::document()'`
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE); pkgdown::build_article("formula-grammar", new_process = FALSE, quiet = TRUE)'`
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("model-map", new_process = FALSE, quiet = TRUE)'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n 'corpair\([^\n]*class = "location-(location|scale|scale-scale)"|cor12\(|corpairs\([^\n]*~|corpairs\(\.\.\.\) ~ w|species_residual|fit_biv_phylo_species' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site/articles`

All checks passed. The stale-wording scan returned only intentional `cor12()`
rejection wording and one design note explaining why class-wide
`location-scale` modelling is deferred.

## Tests Of The Tests

The parser tests cover successful endpoint-specific capture and malformed
inputs: non-string options, unsupported classes, missing paired endpoints,
mixed `class` plus `from` / `to`, residual `rho12` as a latent endpoint,
self-correlation endpoints, named `corpair()` formulas, and fitting-time
rejection.

## Consistency Audit

The formula grammar, correlation-pair design note, known limitations, NEWS,
roxygen reference page, formula-grammar article, model-map article, and
phylogenetic-spatial article now use endpoint-specific syntax as the planned
route. The model-map and phylogenetic-spatial articles no longer present the
ordinary-plus-phylogenetic same-species comparison as an introductory example.

## What Did Not Go Smoothly

The first article wording compressed the four location-scale pairs and missed
the cross-trait `mu1`-`sigma2` and `mu2`-`sigma1` rows. Pat and Rose should
flag any future q=4 prose that says "location-scale" without listing whether
same-trait and cross-trait rows are both included.

## Team Learning

- Ada: keep each slice small and stop after the grammar contract rather than
  slipping into likelihood work.
- Boole: endpoint-specific syntax is clearer than class-wide q=4 syntax for the
  first fitted `corpair()` route.
- Gauss: q=4 correlation regression needs a positive-definite parameterization;
  six independent pairwise regressions are not acceptable.
- Noether: every q=4 explanation must enumerate all six rows when the pair
  meanings matter.
- Fisher: q=2 is the correct first fitted correlation-regression target because
  inference and identifiability are easier to audit.
- Pat: cross-trait mean-scale rows need explicit biological interpretation
  warnings.
- Grace: keep GitHub Actions green between small commits; the previous pushed
  commit passed macOS, Ubuntu, and Windows before this slice was pushed.
- Rose: stale tutorial examples can survive in sibling articles; scan generated
  pkgdown pages as well as source Rmd files.

## Known Limitations

This slice does not fit predictor-dependent latent random-effect correlations.
It reserves and validates the endpoint-specific grammar only.

## Next Actions

Slice 12 should implement the first ordinary q=2 predictor-dependent
`corpair()` likelihood only if the q=2 target can be matched unambiguously to a
single fitted latent covariance block. q=4 predictor-dependent correlations
should stay deferred until a positive-definite q=4 correlation-regression
parameterization is designed and tested.
