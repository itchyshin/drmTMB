# After Task: Poisson Mean Family

## Goal

Add the first count-response path without overextending the package: a
fixed-effect univariate Poisson model with a log-linked `mu` formula.

## Implemented

- Added `family = poisson(link = "log")` routing in `drmTMB()`.
- Added `drm_build_poisson_spec()` for one-response, fixed-effect, `mu`-only
  Poisson models.
- Added `model_type = 6` in the TMB template with a `dpois()` likelihood.
- Added Poisson support to `predict()`, `fitted()`, `simulate()`,
  `residuals()`, `sigma()`, `coef()`, `logLik()`, and family-link helpers.
- Added tests for parameter recovery, independent likelihood calculation,
  base-GLM comparison, methods, complete-case filtering, and malformed inputs.
- Updated README, NEWS, ROADMAP, formula grammar docs, family registry,
  likelihood docs, testing strategy, distribution roadmap, family-link
  contract, known limitations, source map, distribution-family vignette,
  formula-grammar vignette, and generated Rd files.

## Mathematical Contract

The implemented model is:

```text
y_i | mu_i ~ Poisson(mu_i)
eta_mu_i = X_mu[i, ] beta_mu
mu_i = exp(eta_mu_i)
E[y_i] = Var[y_i] = mu_i
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat),
  family = poisson(link = "log"),
  data = dat
)
```

This path has no fitted `sigma` distributional parameter. `sigma(fit)` returns
a fixed unit dispersion vector for base-R method compatibility only; it is not
a modelled residual scale.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-poisson-mean.R`
- `tests/testthat/test-family-link-contract.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-gaussian-random-effect-scale.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-poisson-mean-family.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `man/drmTMB.Rd`
- `man/fitted.drmTMB.Rd`
- `man/residuals.drmTMB.Rd`
- `man/sigma.drmTMB.Rd`
- `man/simulate.drmTMB.Rd`

## Checks Run

- `R -q -e 'devtools::test(filter = "poisson|family-link-contract")'`: 61
  passed.
- `R -q -e 'devtools::test(filter = "gaussian-location-scale|gaussian-random-effect-scale|poisson-mean|family-link-contract")'`:
  171 passed.
- `R -q -e 'devtools::document()'`: completed and regenerated Rd files.
- `R -q -e 'devtools::test()'`: 806 passed.
- `R -q -e 'pkgdown::check_pkgdown()'`: no problems found.
- `R -q -e 'pkgdown::build_site()'`: completed successfully.
- `R -q -e 'devtools::check()'`: 0 errors, 0 warnings, 0 notes.

## Tests Of The Tests

- The likelihood test compares `logLik(fit)` to an independent
  `sum(dpois(y, lambda = mu, log = TRUE))` calculation.
- The external comparator checks coefficients and log-likelihood against
  `stats::glm(..., family = poisson(link = "log"))` for the overlapping
  fixed-effect mean model.
- The malformed-input tests check non-log links, unsupported `sigma`, missing
  response, non-integer and negative responses, random effects,
  `meta_known_V()`, `sd(id)`, and `mvbind()`.
- The complete-case test checks that rows with invalid counts are acceptable
  only when removed by predictor missingness before the count validation step.

## Consistency Audit

- Equations and syntax now agree in the README, likelihood design, family-link
  contract, and distribution-family vignette.
- Formula status is synchronized in `docs/design/01-formula-grammar.md` and
  `vignettes/formula-grammar.Rmd`.
- The source map includes `drm_build_poisson_spec()` and `model_type = 6`.
- NEWS, ROADMAP, and known limitations all state the same narrow scope.
- Stale-wording scans were run across source docs, tests, man pages, and the
  generated pkgdown site.

The exact stale-wording scans were:

```sh
rg -n 'Poisson.*planned|poisson.*unsupported|supported families|count models would|Candidate Count|before implementing count|first count family should|model_type = 6|dpois|drm_build_poisson_spec' README.md ROADMAP.md NEWS.md docs vignettes tests R src man pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'poisson\(link = "log"\)|Poisson mean|non-negative integer|unit dispersion|fixed unit dispersion|no fitted `sigma`' README.md ROADMAP.md NEWS.md docs vignettes tests R man pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'Student-t, lognormal, and Gamma|first Student-t, lognormal, and Gamma|Gamma paths|count, beta' README.md ROADMAP.md NEWS.md docs vignettes pkgdown-site --glob '!pkgdown-site/search.json'
```

## What Did Not Go Smoothly

Two older tests still expected `poisson()` to be unsupported. Euler caught the
stale expectations before closure, and the tests were updated to check the new
Poisson-specific rejection paths. Roxygen-generated Rd files were also stale
until `devtools::document()` was run.

The other design wrinkle was `sigma(fit)`. Returning a fixed unit dispersion
vector is useful for base-R compatibility, but it could be mistaken for a
fitted `sigma` distributional parameter. The docs now state that it is not a
modelled residual scale.

## Team Learning

- Count-family work must begin with the family-link contract because `mu` is
  log-linked, unlike the first Gaussian-like paths.
- External comparators are strongest when the overlap is exact; here Poisson
  agrees with base `glm()` on both coefficients and log-likelihood.
- Rose's audit should include generated pkgdown pages whenever user-facing
  docs change.
- Stale "unsupported family" tests are likely whenever a roadmap item becomes
  implemented; those tests should be searched deliberately.

## Known Limitations

- Poisson is fixed-effect and univariate only.
- Only `mu` is fitted.
- No overdispersion, zero inflation, hurdle component, random effects, known
  sampling covariance, phylogenetic/spatial terms, or bivariate Poisson model
  is implemented.
- Ecological count responses with biological extra-Poisson variation will
  usually need the planned negative binomial or COM-Poisson families.

## Next Actions

- Add `nbinom2()` after writing the precise `sigma` overdispersion contract and
  comparator target.
- Keep the count-family examples ecological, but present the package as
  general-purpose.
- Reuse the same family-link, likelihood, comparator, documentation, and
  after-task checklist for the next response family.
