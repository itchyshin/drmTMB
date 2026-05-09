# After Task: Gamma Mean-CV Family

## Goal

Add the first fixed-effect Gamma distributional-regression path without
weakening the family grammar or exporting a confusing lowercase `gamma()`
helper.

## Implemented

- `drmTMB()` now routes `family = Gamma(link = "log")` to a fixed-effect
  univariate Gamma mean-CV builder.
- The TMB template has `model_type = 5` for Gamma likelihood evaluation.
- The positive-continuous parameter map now fixes unused `beta_nu` in
  lognormal and Gamma models, so `fit$df` and Hessian diagnostics reflect only
  parameters used by the likelihood.
- `predict()`, `fitted()`, `sigma()`, `simulate()`, and `residuals()` now have
  Gamma-specific response-scale behavior.
- Unsupported neighbouring syntax is rejected before optimization: non-log
  Gamma links, `base::gamma`, non-positive responses, random effects,
  `sd(group)`, `meta_known_V(V = V)`, `mvbind()`, and composed Gamma or mixed
  response families.

## Mathematical Contract

For observation `i`:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i^2 sigma_i^2
```

Matching R syntax:

```r
fit <- drmTMB(
  drm_formula(biomass ~ habitat, sigma ~ treatment),
  family = Gamma(link = "log"),
  data = dat
)
```

`mu` is the response mean. `sigma` is the coefficient of variation, so the
residual standard deviation is `mu * sigma`.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gamma-location-scale.R`
- `tests/testthat/test-family-link-contract.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `man/drmTMB.Rd`
- `man/fitted.drmTMB.Rd`
- `man/residuals.drmTMB.Rd`
- `man/sigma.drmTMB.Rd`
- `man/simulate.drmTMB.Rd`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-family-link-contract.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/adding-families.Rmd`
- `vignettes/distribution-families.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/source-map.Rmd`

## Checks Run

- `Rscript -e "devtools::test(filter = 'gamma-location-scale|family-link-contract')"`:
  55 passed.
- `Rscript -e "devtools::test(filter = 'gamma-location-scale|lognormal-location-scale|family-link-contract')"`:
  114 passed after reviewer-driven map and test hardening.
- `Rscript -e "devtools::document()"`: completed and regenerated Rd files.
- `Rscript -e "devtools::test()"`: 761 passed after reviewer-driven test
  hardening.
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found.
- `Rscript -e "pkgdown::build_site()"`: completed successfully.
- `Rscript -e "devtools::check()"`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: clean.

## Tests Of The Tests

- The likelihood test compares `logLik(fit)` with an independent
  `stats::dgamma()` calculation at the fitted coefficients.
- Prediction tests check `predict(type = "link")`, response-scale
  `predict()`, `newdata` prediction, and `fitted()` for the non-identity `mu`
  link.
- Method tests check `sigma()` as coefficient of variation, Pearson residuals
  as `(y - mu) / (mu * sigma)`, and strictly positive simulations.
- Failure-path tests reject invalid and unsupported syntax before optimization.
- Edge-case tests fit small and large coefficient-of-variation examples.
- Gamma and lognormal tests check that the Hessian is positive definite and
  that the fitted degrees of freedom match the reported fixed-effect
  coefficients, guarding against unused free TMB parameters.
- Gamma tests now also cover default intercept-only `sigma` and complete-case
  filtering before positive-response checks.

## Consistency Audit

- Symbolic equations, R syntax, TMB branch, methods, tests, README, vignettes,
  roadmap, NEWS, source map, known limitations, and generated pkgdown pages now
  describe the same Gamma mean-CV model.
- Formula grammar design docs and the formula grammar vignette now include the
  implemented Gamma route in their current status maps.
- Stale-wording scans found no active "future Gamma" wording outside
  historical check-log entries. Remaining `gamma()` hits explain why no
  lowercase helper is exported.
- Guardrail scans still find `meta_gaussian()` and `tau ~` only where the docs
  explicitly say not to introduce those forms for meta-analysis.

## What Did Not Go Smoothly

The first composed `Gamma/Gamma` rejection test expected the narrower "Only
family" message. The router correctly used the broader mixed-response error,
so the test was revised to check that composed Gamma remains rejected.

The first pass also missed the source map and adding-families vignette. The
after-task stale-wording scan caught those before the slice was closed.

The reviewer pass found a more serious issue: Gamma was reusing the previous
positive-family map and leaving unused `beta_nu` free. That produced false
degrees of freedom and Hessian diagnostics. The map now fixes `beta_nu` for
both Gamma and lognormal models, and tests check that explicitly.

## Team Learning

Jason's landscape review paid off: using `stats::Gamma(link = "log")` respects
R conventions and avoids colliding with `base::gamma()`. Future family work
should start from the same sequence: family-link contract, fitted-response
rule, TMB likelihood, independent density check, then examples.

Rose's audit continues to be useful because family additions touch more than
code. A new likelihood must synchronize the roadmap, source map, known
limitations, method docs, pkgdown, and after-task report.

Galileo and Curie improved the close-out. The most valuable review was not
more prose; it was checking whether unused parameters, `newdata`, missingness,
and malformed inputs had direct tests.

## Known Limitations

- Gamma models are fixed-effect and univariate only.
- Random effects, known sampling covariance, phylogenetic terms, spatial terms,
  bivariate Gamma, and mixed composed families remain future work.
- `sigma` is a coefficient of variation for Gamma fits, so users should not
  read it as a residual standard deviation without multiplying by `mu`.

## Next Actions

- Harden Student-t, lognormal, and Gamma starting values and boundary
  diagnostics together.
- Add optional comparator notes against GAMLSS or base GLM for simple Gamma
  mean-only cases once the parameterization overlap is written down.
- Continue the distribution roadmap with count or beta families only after the
  same family-link and fitted-response tests are in place.
