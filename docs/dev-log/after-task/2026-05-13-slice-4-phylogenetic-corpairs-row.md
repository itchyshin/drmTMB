# After Task: Slice 4 Phylogenetic `corpairs()` Row

## Goal

Report the already-fitted bivariate phylogenetic `mu1`/`mu2` mean-mean
correlation through `corpairs()` without changing the likelihood.

## Implemented

`corpairs.drmTMB()` now adds a phylogenetic row whenever a bivariate Gaussian
fit contains matching `mu1`/`mu2` `phylo()` terms and `corpars$phylo` is
available. The row uses:

```text
level = "phylogenetic"
group = <phylo grouping variable, usually species>
block = "phylo"
from_dpar = "mu1"
to_dpar = "mu2"
class = "mean-mean"
parameter = "cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)"
```

The estimate and link-scale value are read from the fitted `corpars$phylo`
entry, with the same guarded correlation link used for other fitted
correlations.

## Mathematical Contract

This slice reports the fitted parameter from the previous bivariate
phylogenetic location slice:

```text
rho_phylo = cor(a_mu1, a_mu2)
```

It does not add a new model parameter. It also does not report the planned q=4
phylogenetic scale or mean-scale pairs, because those likelihood components are
not fitted yet.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-corpairs.R`
- `man/corpairs.Rd`
- `NEWS.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/29-mammal-location-coscale-route.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `vignettes/model-map.Rmd`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

- `air format R/methods.R tests/testthat/test-corpairs.R NEWS.md docs/dev-log/known-limitations.md docs/design/20-coscale-correlation-pairs.md docs/design/29-mammal-location-coscale-route.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::test(filter = "corpairs|phylo-gaussian|biv-gaussian")'`:
  passed with 616 expectations.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e 'devtools::test()'`: passed with 2,686 expectations, 0 failures,
  0 warnings, and 0 skips.
- Rendered `vignettes/model-map.Rmd` and
  `vignettes/phylogenetic-spatial.Rmd` to temporary HTML files with
  `rmarkdown::render(...)`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript tools/codex-checkpoint.R --goal "slice 4 phylogenetic corpairs row closeout" --next "review diff, then start slice 5 check_drm diagnostics for fitted bivariate phylogenetic correlations"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md`.
- `git diff --check`: passed.

## Tests Of The Tests

The new `test-corpairs.R` regression fits a small bivariate phylogenetic
Gaussian model, checks that `corpairs()` returns one residual row and one
phylogenetic row, and verifies the row contract: `level`, `group`, `block`,
`from_dpar`, `to_dpar`, response names, class, parameter name, response-scale
estimate, link-scale estimate, and filters for `level`, `group`, `block`, and
`class`.

The test also removes the stored model frame and checks that response names
still come from `model$response_names`, preserving the large-data storage
contract.

## Consistency Audit

NEWS, known limitations, the correlation-pair design note, the mammal route,
the model-map article, and the phylogenetic-spatial article now say that the
first fitted bivariate phylogenetic mean-mean correlation is visible through
`corpairs(fit, level = "phylogenetic")`. They still keep residual `rho12`
separate and leave phylogenetic scale, mean-scale, full q=4, and spatial
correlations planned.

## What Did Not Go Smoothly

The first targeted test run failed only because the expected one-row data frame
kept the original row name after subsetting. The implementation was already
returning the right row; the test now normalizes the expected row name before
comparing filtered results.

## Team Learning

Ada kept this as a reporting slice instead of reopening TMB code. Boole and Pat
kept the public row names readable. Rose kept the q=4 and spatial claims out of
the fitted-status wording. The user also explicitly asked us to remember that
spatial should be developed as the sibling lane to this phylogenetic path.

## Known Limitations

`corpairs()` now reports only the fitted bivariate phylogenetic mean-mean
correlation. It does not yet report phylogenetic `sigma1`/`sigma2` scale-scale
correlation, mean-scale correlations, non-phylogenetic species covariance, or
spatial covariance.

## Next Actions

1. Add `check_drm()` diagnostics for near-boundary `corpars$phylo` and weak
   bivariate phylogenetic SDs.
2. Plan the spatial sibling lane using the same fitted-versus-planned contract:
   start with an intercept-only spatial location effect, then report structured
   spatial correlations only when code, tests, examples, and `corpairs()` rows
   exist.
