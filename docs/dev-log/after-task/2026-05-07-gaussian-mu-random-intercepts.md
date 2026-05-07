# After Task: Gaussian mu Random Intercepts

Date: 2026-05-07

## Task

Add the first mixed-model feature to `drmTMB`: univariate Gaussian random
intercepts in the location formula.

Implemented syntax:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z),
  family = gaussian(),
  data = dat
)
```

Also implemented:

```r
drmTMB(
  bf(y ~ x + (1 | site) + (1 | observer), sigma ~ z),
  family = gaussian(),
  data = dat
)
```

## Created Or Changed

- Extended the Gaussian formula builder in `R/drmTMB.R` to split `(1 | group)`
  terms from the fixed-effect `mu` formula.
- Added random-intercept metadata construction after complete-case filtering.
- Extended `TMB::MakeADFun()` calls with `random = "u_mu"` when random
  intercepts exist.
- Extended `src/drmTMB.cpp` with a non-centered random-intercept likelihood:
  `b_group = sd_group * u_group`, `u_group ~ Normal(0, 1)`.
- Added `sdpars` and `random_effects` storage to fitted objects.
- Updated fitted-data prediction and residuals to include conditional random
  intercept modes.
- Added summary/print support for random-effect SDs.
- Added `tests/testthat/test-gaussian-random-intercepts.R`.
- Updated README, NEWS, ROADMAP, likelihood docs, formula grammar docs,
  random-effect docs, known limitations, and vignettes.

## Checks Performed

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'gaussian')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown(); pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never')"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- Stale-text scan for old "fixed effects only" phrasing.

## Outcomes

- Targeted random-intercept tests: 24 passed, 0 failed.
- Full test suite: 139 passed, 0 failed.
- pkgdown check: no problems found.
- pkgdown site: built successfully.
- Standard R CMD check: 0 errors, 0 warnings, 1 environment note about
  verifying the current time.
- R CMD check with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors, 0 warnings,
  0 notes.
- `air format .` was attempted but `air` is not installed locally.

## Consistency Review

- README now shows `bf(y ~ x + (1 | id), sigma ~ z)` as supported.
- ROADMAP Phase 1 and Phase 4 now mark univariate Gaussian `mu` random
  intercepts as implemented.
- `docs/design/03-likelihoods.md` documents the non-centered
  random-intercept likelihood.
- `docs/design/04-random-effects.md` records current support and current
  limits.
- `docs/dev-log/known-limitations.md` no longer says random effects are wholly
  unimplemented.
- Generic unsupported-term errors no longer say "fixed effects only".

## Remaining Limitations

- Random slopes are not implemented.
- Random effects in scale formulae are not implemented.
- Random-effect scale formulae such as `sd(id) ~ x` are not implemented.
- labelled correlated-block syntax such as `(1 | p | id)` is rejected for
  now.
- Bivariate random effects are not implemented.
- `newdata` prediction is fixed-effect-only for random-intercept models.

## Next Best Task

The next coherent modelling task is random slopes in the univariate Gaussian
location formula. After that, we can add `sd(id) ~ predictors` for
double-hierarchical models with a stronger foundation.
