# After Task: NB2 Mean-Dispersion Family

## Goal

Add the first overdispersed count family while keeping the distributional
parameter contract explicit and consistent with `drmTMB` scale naming.

## Implemented

- Added exported `nbinom2()` family constructor.
- Added `drm_build_nbinom2_spec()` for one-response, fixed-effect NB2 models
  with `mu` and `sigma` formulas.
- Added `model_type = 7` in the TMB template.
- Added NB2 support to `predict()`, `fitted()`, `simulate()`, `residuals()`,
  `sigma()`, `coef()`, `logLik()`, and family-link helpers.
- Added tests for recovery, independent likelihood calculation, method
  behavior, default `sigma`, complete-case filtering, Poisson-limit behavior,
  and malformed inputs.
- Updated README, NEWS, ROADMAP, DESCRIPTION, pkgdown navigation, formula
  grammar docs, family registry, likelihood docs, testing strategy,
  distribution roadmap, family-link contract, known limitations, source map,
  distribution-family vignette, formula-grammar vignette, generated Rd files,
  and the check log.

## Mathematical Contract

The implemented model is:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment),
  family = nbinom2(),
  data = dat
)
```

Here `sigma` is an overdispersion scale, not a residual standard deviation and
not the native NB size or precision parameter. Larger `sigma` means greater
extra-Poisson variation.

## Files Changed

- `DESCRIPTION`
- `NAMESPACE`
- `_pkgdown.yml`
- `R/drmTMB.R`
- `R/family.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-nbinom2-location-scale.R`
- `tests/testthat/test-family-link-contract.R`
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
- `docs/dev-log/after-task/2026-05-09-nbinom2-mean-dispersion-family.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `man/drmTMB.Rd`
- `man/fitted.drmTMB.Rd`
- `man/nbinom2.Rd`
- `man/residuals.drmTMB.Rd`
- `man/sigma.drmTMB.Rd`
- `man/simulate.drmTMB.Rd`

## Checks Run

- `R -q -e 'devtools::test(filter = "nbinom2|family-link-contract")'`: 76
  passed after hardening one smoke example and adding direct Poisson-limit
  objective checks.
- `R -q -e 'devtools::test(filter = "nbinom2|poisson|family-link-contract")'`:
  115 passed.
- `R -q -e 'devtools::document()'`: completed cleanly on the second pass and
  exported `nbinom2()`.
- `R -q -e 'devtools::test()'`: 860 passed.
- `R -q -e 'pkgdown::check_pkgdown()'`: no problems found.
- `R -q -e 'pkgdown::build_site()'`: completed successfully.
- `R -q -e 'devtools::check()'`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

## Tests Of The Tests

- The independent likelihood test checks `logLik(fit)` against
  `sum(dnbinom(y, mu = mu, size = 1 / sigma^2, log = TRUE))`.
- The simulation and recovery tests use `stats::rnbinom()` with the same
  `size = 1 / sigma^2` mapping.
- The Poisson-limit test checks that the NB2 likelihood approaches `dpois()` as
  `sigma` approaches zero and directly evaluates the TMB objective at very
  small `sigma` values.
- Malformed-input tests cover unsupported parameters, missing responses,
  duplicated `sigma`, negative and non-integer counts, random effects,
  `meta_known_V()`, `sd(id)`, and `mvbind()`.

## Consistency Audit

- Equations and R syntax now agree in the README, likelihood design,
  family-link contract, and distribution-family vignette.
- The formula grammar design doc and formula-grammar vignette list NB2 as
  implemented.
- The source map includes `drm_build_nbinom2_spec()` and `model_type = 7`.
- The pkgdown reference index includes `nbinom2()`, and the generated site has
  `reference/nbinom2.html`.
- NEWS, ROADMAP, and known limitations all describe the same narrow scope.

The exact stale-wording scans were:

```sh
rg -n 'nbinom2.*planned|negative binomial.*planned|planned negative binomial|Candidate negative binomial|before implementing.*nbinom2|Use this contract before implementing `gamma\(\)`|model_type = 7|dnbinom|drm_build_nbinom2_spec' README.md ROADMAP.md NEWS.md DESCRIPTION _pkgdown.yml R src tests docs vignettes man pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'sigma.*overdispersion|size = 1 / sigma\^2|Var\(y\) = mu \+ sigma\^2|negative-binomial 2|Negative-binomial 2|nbinom2\(\)' README.md ROADMAP.md NEWS.md docs vignettes R tests man pkgdown-site --glob '!pkgdown-site/search.json'
rg -n 'Poisson mean, and negative-binomial|Poisson paths|Poisson and negative-binomial|count-response families|COM-Poisson' README.md ROADMAP.md NEWS.md DESCRIPTION docs vignettes pkgdown-site --glob '!pkgdown-site/search.json'
```

Historical after-task notes still contain statements that NB2 was future work;
those were true at the time and are superseded by this report.

## What Did Not Go Smoothly

The first link-contract smoke test used six toy observations and produced a
`sdreport()` warning. That made the test more fragile than useful, so it was
replaced with a modest simulated NB2 data set. The warning disappeared while
the test still exercises the fitted-response helper.

The other risk was terminology. NB2 is often parameterized with a size or
precision parameter where larger values mean less overdispersion. `drmTMB`
uses `sigma`, where larger values mean more overdispersion, so the mapping
`size = 1 / sigma^2` is documented in the family help, likelihood design, and
distribution-family vignette.

Darwin's review caught that the first C++ form of the NB2 likelihood was
algebraically correct but fragile when `sigma` approached zero. The template now
uses an equivalent log-likelihood written in terms of `alpha = sigma^2`, which
avoids direct computation of very large `size = 1 / sigma^2`.

## Team Learning

- Euclid's landscape pass was worth doing before coding; it clarified the
  glmmTMB/GAMLSS/base-R parameter-direction trap.
- Count-family tests need both recovery and direct density checks.
- Small examples are not automatically safer for numerical tests; moderate
  simulated examples can give stabler Hessians.
- Future count families should start with a one-line variance rule and a
  direct map to base-R density parameters.

## Known Limitations

- NB2 is fixed-effect and univariate only.
- No random effects, zero inflation, hurdle component, known sampling
  covariance, phylogenetic/spatial terms, bivariate count model, or mixed
  composed response model is implemented yet.
- No external glmmTMB or GAMLSS comparator is included in the CRAN-safe test
  path yet.

## Next Actions

- Add zero-inflated or hurdle count models only after writing the `zi`/`hu`
  parameter contract.
- Consider an optional non-CRAN comparator script against glmmTMB's NB2 using
  the translation `phi = 1 / sigma^2`.
- Continue using direct density checks for every new count-family likelihood.
