# After Task: Gaussian Residual-Scale Random Intercepts

Date: 2026-05-07

## Goal

Implement the smallest safe scale-side mixed-model feature: univariate Gaussian
residual-scale random intercepts in `sigma`.

## Implemented

- `bf(y ~ x, sigma ~ z + (1 | id))` now fits independent random intercepts in
  the residual-scale formula.
- The residual-scale random effect enters the model on the log-`sigma` scale.
- `sdpars$sigma` reports the standard deviation of the residual-scale random
  intercepts.
- `random_effects$sigma` stores conditional modes and latent standardized
  effects for the residual-scale random effects.
- Fitted-data `predict(fit, dpar = "sigma")`, `sigma(fit)`, Pearson residuals,
  and simulation now include conditional residual-scale random-effect modes.
- `mu` and `sigma` random intercepts can coexist independently, even on the
  same grouping factor.
- Labelled `sigma` blocks, residual-scale random slopes, bivariate scale random
  effects, and `sd(id) ~ x` remain deliberately unsupported.

## Mathematical Contract

For observation `i` in group `g[i]`:

```text
y_i | mu_i, sigma_i, a_g[i] ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma + a_g[i]
a_g = sd_sigma_group * v_g
v_g ~ Normal(0, 1)
sd_sigma_group = exp(theta_sigma_group)
```

The matching R syntax is:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z + (1 | id)),
  family = gaussian(),
  data = dat
)
```

This is residual-scale heterogeneity: group-to-group variation in the residual
standard deviation. It is not the future double-hierarchical model
`sd(id) ~ x`, which will model the standard deviation of a group-level `mu`
random effect.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `README.md`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/05-testing-strategy.md`
- `docs/design/13-gaussian-location-scale-math.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `man/drmTMB.Rd`
- `vignettes/drmTMB.Rmd`
- `vignettes/formula-grammar.Rmd`
- `vignettes/location-scale.Rmd`

## Checks Run

```text
Rscript -e "devtools::load_all(quiet = FALSE)"
manual smoke fit for bf(y ~ x, sigma ~ z + (1 | id))
manual smoke fit for bf(y ~ x + (1 | id), sigma ~ z + (1 | id))
Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale')"
Rscript -e "devtools::document()"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
git diff --check
```

Results:

- targeted Gaussian random-effect tests: 169 passed, 0 failed;
- targeted Gaussian location-scale tests: 39 passed, 0 failed;
- full `devtools::test()`: 326 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes;
- `git diff --check`: passed.

## Tests Of The Tests

- The moderate simulation checks fixed `mu` coefficients, fixed `sigma`
  coefficients, `sdpars$sigma`, positive fitted residual SDs, and populated
  `random_effects$sigma`.
- Boundary-style tests cover near-zero residual-scale heterogeneity and large
  residual-scale heterogeneity without pretending variance-component recovery is
  exact in small CRAN-safe samples.
- Missingness tests verify that variables used by `sigma` random effects
  participate in the same complete-case filter as `mu` and fixed `sigma`
  predictors.
- Failure tests reject residual-scale random slopes and labelled `sigma` blocks.
- A coexistence test fits independent `mu` and `sigma` random intercepts on the
  same grouping factor and checks that both namespaces are populated.

## Consistency Audit

- The active README, NEWS, roadmap, likelihood notes, formula grammar, random
  effects notes, Gaussian math notes, testing strategy, vignettes, generated Rd,
  and known limitations all describe residual-scale random intercepts as
  implemented.
- The docs repeatedly distinguish residual `sigma` from future random-effect
  scale formulas such as `sd(id) ~ x`.
- The formula grammar still states that cross-formula labelled covariance
  sharing remains future work.
- Stale wording scans found only historical check-log entries that were true
  when written.

## What Did Not Go Smoothly

- The feature was easy to over-describe as "scale random effects"; the final
  wording uses "residual-scale random intercepts" to avoid confusing it with
  `sd(id) ~ x`.
- The implementation needed prediction and method updates as well as TMB
  likelihood changes; otherwise `sigma(fit)` and residuals would have silently
  ignored the fitted scale random effects.

## Team Learning

- Arendt recommended this narrow residual-scale random-intercept slice before
  `sd(id) ~ x` because it extends existing Laplace machinery with less grammar
  risk.
- Bacon separated the test criteria for `sigma ~ (1 | id)` from `sd(id) ~ x`;
  these must remain different in future phases.
- Leibniz highlighted that the teaching spine should be the distinction between
  residual `sigma` and group-level random-effect standard deviations.
- Ada should keep updating equations and examples together before treating a
  likelihood change as complete.

## Known Limitations

- Residual-scale random slopes such as `sigma ~ z + (0 + z | id)` are not
  implemented.
- Labelled `sigma` covariance blocks such as `sigma ~ z + (1 | p | id)` are not
  implemented.
- `sd(id) ~ x` random-effect scale models are not implemented.
- Bivariate `sigma1` and `sigma2` random effects are not implemented.
- Phylogenetic and spatial structured effects in `sigma` remain planned.

## Next Actions

- Decide whether the next modelling phase should be `sd(id) ~ x` for one
  unambiguous random-intercept component, or a design-only pass for that grammar.
