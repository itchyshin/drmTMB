# After Task: Ordinary Correlated Gaussian Mu Random-Effect Blocks

Date: 2026-05-07

## Goal

Implement ordinary correlated random intercept-slope blocks in the univariate
Gaussian location formula, without confusing group-level correlations with
residual bivariate `rho12`.

## Implemented

- `bf(y ~ x + (1 + x | id), sigma ~ z)` now fits a correlated random
  intercept and numeric random slope in Gaussian `mu`.
- `(x | id)` is accepted as ordinary mixed-model shorthand for `(1 + x | id)`.
- `(1 | id) + (0 + x | id)` remains the independent intercept-plus-slope form.
- Group-level correlations are exposed as `corpars$mu`.
- Labelled blocks such as `(1 + x | p | id)` remain reserved for a later
  cross-formula or cross-parameter covariance phase.
- The GitHub README page now points to `man/figures/drmTMB-logo.png` so the
  repo-facing hex logo can refresh separately from older cached image paths.

## Mathematical Contract

For one correlated block:

```text
y_ij | mu_ij, sigma_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

[b_0j, b_1j]' ~ MVN(0, Sigma_id)
Sigma_id =
  [sd0^2,          rho_re sd0 sd1;
   rho_re sd0 sd1, sd1^2]

u_j ~ Normal([0, 0]', I)
b_0j = sd0 * u_0j
b_1j = sd1 * (rho_re u_0j + sqrt(1 - rho_re^2) u_1j)
rho_re = 0.999999 * tanh(eta_cor)
```

`rho_re` is a group-level random-effect correlation. Residual response-response
correlation remains `rho12`.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-comparators.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `README.md`
- `NEWS.md`
- `_pkgdown.yml`
- `man/drmTMB.Rd`
- `man/figures/drmTMB-logo.png`
- `man/figures/drmTMB-logo.svg`
- `docs/design/01-formula-grammar.md`
- `docs/design/03-likelihoods.md`
- `docs/design/04-random-effects.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `ROADMAP.md`
- `vignettes/drmTMB.Rmd`
- `vignettes/location-scale.Rmd`

## Checks Run

```text
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"
Rscript -e "devtools::test(filter = 'comparators')"
Rscript -e "devtools::test()"
Rscript -e "pkgdown::check_pkgdown()"
Rscript -e "pkgdown::build_site()"
local browser preview at http://127.0.0.1:4187/index.html
Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"
```

Results:

- targeted random-effect tests: 93 passed, 0 failed;
- targeted comparator tests: 20 passed, 0 failed;
- full `devtools::test()`: 246 passed, 0 failed;
- `pkgdown::check_pkgdown()`: no problems found;
- `pkgdown::build_site()`: completed successfully;
- local browser preview showed the updated pkgdown home page wording and hex
  logo;
- `devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))`: 0
  errors, 0 warnings, 0 notes.

## Tests Of The Tests

The independent random-slope `lme4` comparator failed during the first
implementation attempt because independent slope design values were accidentally
treated as intercept values in the new coefficient-block layout. That caught a
real regression. After fixing the design-value assignment, both independent and
correlated `lme4` comparator tests passed.

The new correlated-block tests cover positive, near-zero, negative, high
positive/negative, weak-slope-SD, factor-fixed-effect, missingness, and
malformed-syntax cases.

## Consistency Audit

- Symbolic equations, TMB parameterization, R formula grammar, README, vignettes,
  NEWS, roadmap, known limitations, and generated Rd now describe `(1 + x |
  id)` as implemented for univariate Gaussian `mu`.
- Group-level correlations are named `corpars$mu`; residual bivariate
  correlation remains `rho12`.
- Labelled blocks remain future-facing and are still rejected.
- The repo README uses the new repo-facing logo filename.

## What Did Not Go Smoothly

- The first implementation relaxed the parser and changed the random-effect
  layout, but initially missed the independent-slope design-value case. The
  comparator test caught this before the feature was treated as done.
- The local browser refused direct `file://` preview, so the built pkgdown site
  was checked through a local HTTP server instead.
- The GitHub repo page and pkgdown page use different rendering paths, so the
  README/logo update had to be checked separately from the pkgdown site.

## Team Learning

- Fisher's comparator tier is essential for mixed-model semantics.
- Rose's after-task audit should explicitly check README and repository-facing
  images, not only pkgdown.
- Ada should keep implementation ownership local when R parser, TMB, extractors,
  and tests all move together; parallel agents are best used for bounded
  read-only review around that work.

## Known Limitations

- Only ordinary unlabelled `q = 2` Gaussian `mu` blocks are implemented.
- Factor or multi-column random slopes are not implemented.
- Larger `q > 2` correlated blocks are not implemented.
- Labelled covariance blocks such as `(1 + x | p | id)` are not implemented.
- Random effects in `sigma`, random-effect scale models, bivariate group-level
  covariance blocks, phylogenetic/spatial random slopes, and non-Gaussian
  random-effect blocks remain planned.

## Next Actions

- Decide whether the next mixed-model step should be labelled covariance blocks
  or random effects in the scale model.
- Add extraction helpers for `corpars` if users need a formal accessor rather
  than reading the fit slot.
- Add optional larger simulation scripts for weak-identification and boundary
  behavior outside CRAN-safe tests.
