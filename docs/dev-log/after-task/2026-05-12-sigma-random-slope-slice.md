# After Task: Independent Sigma Random Slopes

## Goal

Add the next small double-hierarchical Gaussian slice: univariate Gaussian
`sigma` formulas can now include independent numeric residual-scale random
slopes such as `sigma ~ z + (0 + w | id)`.

## Implemented

- `parse_random_sigma_term()` now accepts unlabelled independent sigma slopes
  and reuses the existing independent random-effect design path.
- Correlated residual-scale blocks such as `sigma ~ z + (1 + w | id)` still
  error before TMB assembly.
- Labelled residual-scale slope covariance such as
  `sigma ~ z + (0 + w | p | id)` still errors before covariance matching.
- Tests now cover the fitted sigma slope path and the unsupported syntax
  boundaries.

## Mathematical Contract

For observation `i`, an implemented independent residual-scale slope contributes
on the log residual standard-deviation scale:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + w_i a_id[i]
a_g = sd_sigma_w * v_g
v_g ~ Normal(0, 1)
```

This is residual-scale heterogeneity. It is not `sd(id) ~ ...`, which models
predictors of a location random-effect standard deviation, and it is not
residual bivariate `rho12`.

## Files Changed

- `R/drmTMB.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `man/drmTMB.Rd`
- `NEWS.md`, `README.md`, `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/design/16-phylo-spatial-common-math.md`
- `docs/design/18-random-effect-scale-models.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/location-scale.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/which-scale.Rmd`

## Checks Run

- `air format R/drmTMB.R tests/testthat/test-gaussian-random-intercepts.R NEWS.md README.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/03-likelihoods.md docs/design/04-random-effects.md docs/design/05-testing-strategy.md docs/design/13-gaussian-location-scale-math.md docs/design/16-phylo-spatial-common-math.md docs/design/18-random-effect-scale-models.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/drmTMB.Rmd vignettes/formula-grammar.Rmd vignettes/location-scale.Rmd vignettes/model-map.Rmd vignettes/which-scale.Rmd`
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`:
  passed with 225 expectations.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|check-drm|profile-targets|summary|phylo-utils')"`:
  passed with 640 expectations.
- `Rscript -e "devtools::test()"`: passed with 1918 expectations.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## Tests Of The Tests

The new simulation test checks a live fitted model rather than only parser
state. It verifies convergence, sigma SD naming, random-effect value length,
nontrivial residual-scale contribution variation, link-scale sigma prediction,
and the response-scale `sigma(fit)` transform. The boundary tests now check
that independent sigma slopes fit, while correlated and labelled sigma slope
blocks still fail with explicit planned-phase messages.

## Consistency Audit

Status inventory was updated in `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, and
`vignettes/formula-grammar.Rmd`. `_pkgdown.yml` did not need a navigation
change because this extends existing articles and reference pages.

Exact searches run:

```sh
rg -n "Only random intercepts|only random intercepts|random slopes are planned|Residual-scale random slopes are planned|limited to random intercepts|sigma random effects are limited|residual-scale random effects are limited" README.md ROADMAP.md NEWS.md docs vignettes R tests man
rg -n "residual-scale random intercepts|independent.*random slopes|labelled residual-scale random-slope|correlated residual-scale" README.md ROADMAP.md NEWS.md docs vignettes R tests man
rg -n "sigma ~[^\\n]*(0 \\+|1 \\|)|rho12|sd\\(" README.md ROADMAP.md docs vignettes R tests
```

## What Did Not Go Smoothly

An early broad `air format .` run reformatted unrelated files. Those
formatter-only changes were restored before validation, and the final branch
uses a targeted `air format` command over the intended files only.

## Team Learning

Rose should keep calling out formatter spillover as a branch-hygiene issue.
Gauss and Noether's main boundary for the next slice is covariance: independent
sigma slopes reuse existing diagonal random-effect machinery, but correlated
sigma slope blocks need a separate recovery and covariance-design pass.

## Known Limitations

- Correlated residual-scale intercept-slope blocks in `sigma` remain planned.
- Labelled `mu`/`sigma` slope covariance remains planned.
- Bivariate `sigma1` and `sigma2` random effects remain planned.
- Non-Gaussian residual-scale random effects remain planned.

## Next Actions

The safest next implementation slice is not the full four-effect
double-hierarchical endpoint yet. Add a recovery/comparator lane for correlated
residual-scale sigma intercept-slope blocks, then extend labelled covariance
matching across `mu` and `sigma` slopes once the sigma-side covariance is
stable.
