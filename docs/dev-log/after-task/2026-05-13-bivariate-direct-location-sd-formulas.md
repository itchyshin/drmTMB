# After Task: Bivariate Direct Location SD Formulas

## Goal

Implement the first Family B bivariate direct-SD slice from the SD/correlation
roadmap: `sd1(group)` and `sd2(group)` should model bivariate location
random-effect SDs without claiming support for scale-random-effect SD
regressions, phylogenetic SD regressions, spatial SD regressions, or full q4
location-scale covariance blocks.

## Implemented

The formula parser now accepts `sd1(group) ~ predictors` and
`sd2(group) ~ predictors` as unnamed random-effect scale formulas.
`sd1(group)` targets the labelled `mu1` location random intercept in a
`biv_gaussian()` model, and `sd2(group)` targets the labelled `mu2` location
random intercept. The bivariate builder routes those targets through the
existing non-centered TMB random-effect scale path: group-level design matrices
enter `X_sd_mu`, coefficients enter `beta_sd_mu`, and targeted latent effects
receive row-specific SDs through `mu_re_sd_row`.

The fitted surface now exposes `sd1()` and `sd2()` through `coef()`,
`predict()`, `summary()`, `vcov()`, and `sdpars`, following the existing
univariate `sd(group)` convention. Predictors are checked to be constant within
the target group after missing-row filtering.

Unsupported names are deliberately bounded. `sd_phylo*()` and `sd_spatial*()`
now error as planned but not implemented. `sd_sigma1()` and `sd_sigma2()` error
as unsupported because they would invite mixing a direct SD model with a scale
formula random effect for the same latent layer.

## Team Roles

Ada kept the slice narrow. Boole checked the parser surface and response-
specific naming. Gauss checked that the TMB parameter path reuses the existing
non-centered SD machinery. Noether checked that the equations, R syntax, and
implementation all say location random-effect SD, not residual scale. Curie
added focused recovery and malformed-input tests. Rose checked the docs for
overclaims about phylogenetic, spatial, q4, and `corpair()` support.

## Scope Boundary

This slice does not implement `sd_phylo()`, `sd_phylo1()`, `sd_phylo2()`,
spatial direct-SD models, full q4 ordinary or phylogenetic location-scale
covariance blocks, or predictor-dependent `corpair()` models. It also does not
let `sd1()` or `sd2()` target random effects inside `sigma1` or `sigma2`
formulas.

## Files Changed

- `R/parse-formula.R`
- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-biv-gaussian.R`
- `NEWS.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md`

## Checks Run

- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|gaussian-random-effect-scale", reporter = "summary")'`:
  passed.
- `air format R/parse-formula.R R/drmTMB.R R/methods.R
  tests/testthat/test-biv-gaussian.R NEWS.md
  docs/design/01-formula-grammar.md docs/design/03-likelihoods.md
  docs/design/18-random-effect-scale-models.md
  docs/dev-log/known-limitations.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian|gaussian-random-effect-scale", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.

## Next Actions

1. Add the next small slice for ordinary q4 Family A covariance blocks, or
   stay in Family B and design `sd_phylo()` carefully against the tree
   covariance.
2. Keep spatial as the sibling lane after ordinary and phylogenetic paths have
   stable code, tests, and examples.
