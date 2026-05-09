# After Task: Fixed-Effect Beta Mean-Scale Family

## Goal

Implement the strict continuous-proportion `beta()` family without expanding
scope into beta-binomial, zero/one-inflated beta, random effects, or bivariate
mixed responses.

## Implemented

- Added exported `beta()` in `R/family.R`.
- Routed `family = beta()` through `drmTMB()` with
  `drm_build_beta_ls_spec()`.
- Added TMB `model_type = 10` for the beta likelihood.
- Added beta support in `predict()`, `fitted()`, `sigma()`, `simulate()`,
  `residuals()`, `print()`, and the internal link table.
- Added simulation, likelihood, method, complete-case, edge-scale, and
  unsupported-input tests in `tests/testthat/test-beta-location-scale.R`.
- Updated family-link, likelihood, formula-grammar, source-map, roadmap,
  README, NEWS, pkgdown, and testing-guide documentation.

## Mathematical Contract

The implemented model is:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

Matching R syntax:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment),
  family = beta(),
  data = dat
)
```

`sigma` is the public scale parameter. It is not beta precision; precision is
the internal derived quantity `phi = 1 / sigma^2`.

## Files Changed

- `R/family.R`
- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-beta-location-scale.R`
- `tests/testthat/test-family-link-contract.R`
- `DESCRIPTION`, `NAMESPACE`, `NEWS.md`, `README.md`, `_pkgdown.yml`
- `man/beta.Rd`, `man/drmTMB.Rd`, `man/fitted.drmTMB.Rd`,
  `man/sigma.drmTMB.Rd`, `man/simulate.drmTMB.Rd`
- `docs/design/01-formula-grammar.md`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `vignettes/adding-families.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`
- `vignettes/testing-likelihoods.Rmd`

## Checks Run

- `Rscript -e "parse('R/drmTMB.R'); parse('R/methods.R')"`: passed.
- `Rscript -e "devtools::load_all()"`: failed once on C++ `log1p()` for the
  TMB autodiff type, then passed after switching to `log(1 - y)`.
- `Rscript -e "devtools::test(filter = 'beta|family-link-contract')"`:
  103 passed, 0 failed, 0 warnings, 0 skips after test tightening.
- `Rscript -e "devtools::test(filter = 'gamma-location-scale')"`:
  54 passed, 0 failed, 0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: passed and generated `man/beta.Rd`.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `air format .`: failed because `air` is not installed locally.
- `Rscript -e "devtools::test()"`: 1043 passed, 0 failed, 0 warnings,
  0 skips.
- `git diff --check`: clean.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `Rscript -e "devtools::check()"`: 0 errors, 0 warnings, 0 notes.
- After adding the `base::beta()` masking note, `devtools::document()`,
  targeted beta/family-link tests, `pkgdown::check_pkgdown()`,
  `git diff --check`, and `devtools::check()` were rerun successfully.

## Tests Of The Tests

- Independent likelihood test compares fitted `logLik()` to
  `stats::dbeta()` at the fitted coefficients.
- Complete-case test verifies invalid boundary rows are not checked when they
  are dropped by missing predictors first.
- Unsupported-input tests cover boundary responses, unsupported dpars,
  duplicate `sigma`, missing response, random effects, random-effect scale
  syntax, known sampling covariance, `mvbind()`, and denominator syntax.
- The first beta edge test failed before correction because a very diffuse
  deterministic beta quantile produced exact boundary values. The corrected
  edge test stays strict but avoids machine-boundary data.

## Consistency Audit

Stale-wording scans:

```sh
rg -n 'future beta|planned beta|Candidate Beta|beta\(\).*Planned|Next family sequence: `beta\(\)`|before adding beta|not supported fitting paths.*beta|Once implemented.*beta|beta\(\).*roadmap syntax' README.md ROADMAP.md NEWS.md docs vignettes R tests pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'
rg -n 'type="”|drmTMB_v25|trancated|lue distribution|old hex|man/figures/logo.png' README.md docs vignettes pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'
```

Both scans returned no active hits. A positive consistency scan found the beta
contract in the source docs, generated pkgdown articles, `reference/beta.html`,
and generated NEWS page.

The package status now says beta is implemented in `README.md`, `ROADMAP.md`,
`NEWS.md`, formula grammar docs, the family registry, likelihood docs,
family-link contract, response-family vignette, source map, testing guide, and
pkgdown reference index.

## What Did Not Go Smoothly

- The TMB branch initially used `log1p(-y)`, but the local TMB autodiff type
  did not compile that call. The implementation now uses `log(1 - y)`.
- An edge-case test with a highly diffuse beta distribution generated exact
  0/1 values from `qbeta()` at machine precision. The test now checks a large
  but less boundary-dominated scale.
- One stale-wording scan was initially typed with shell backticks around a
  pattern and tried to execute `beta()` in the shell. The rerun used single
  quotes and is the scan recorded above.
- `air` remains unavailable locally, so code formatting could not be run.

## Team Learning

- Curie should keep flagging AD-safe mathematical functions when translating
  densities into TMB.
- Meitner's "tests of the tests" mindset paid off: the independent likelihood
  check and complete-case/boundary check are now part of the family template.
- Rose should keep requiring generated-site scans because pkgdown pages can
  preserve stale status even when source files look aligned.
- Ada should continue implementing one family at a time with small contracts
  rather than mixing beta, beta-binomial, and zero/one-inflation in one phase.

## Known Limitations

- `beta()` currently supports fixed-effect univariate strict proportions only.
- Boundary values 0 and 1 are rejected.
- Denominator syntax such as `cbind(successes, failures)` is reserved for a
  later beta-binomial design decision.
- Random effects, known sampling covariance, phylogenetic/spatial terms,
  bivariate beta, mixed composed beta families, and zero/one-inflated beta are
  not implemented yet.

## Next Actions

1. Implement `truncated_nbinom2()` as the next response family.
2. Keep `hu ~ predictors` as the hurdle-zero formula after the truncated count
   likelihood is tested.
3. Add a user-facing beta example to a future tutorial only after deciding
   whether a small ecology/evolution data example should be simulated or drawn
   from an existing public dataset.
