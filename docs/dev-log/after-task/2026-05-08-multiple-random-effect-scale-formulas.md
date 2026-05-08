# After Task: Multiple Random-Effect Scale Formulae

## Goal

Extend the Gaussian random-effect scale path from one `sd(group) ~ ...`
formula to multiple distinct unlabelled `mu` random-intercept targets.

## Implemented

- `drmTMB()` now accepts models such as:

```r
drmTMB(
  bf(
    y ~ x + (1 | id) + (1 | site),
    sigma ~ z,
    sd(id) ~ w_id,
    sd(site) ~ w_site
  ),
  family = gaussian(),
  data = dat
)
```

- The R builder stacks per-target `sd()` model matrices into one block-diagonal
  `X_sd_mu` matrix for TMB.
- Coefficients, predictions, `sdpars`, summaries, and `vcov()` split the
  combined TMB parameter vector back into user-facing `sd(id)` and `sd(site)`
  components.
- Duplicate `sd(group)` formulas still fail clearly.

## Mathematical Contract

For two unlabelled Gaussian `mu` random-intercept components:

```text
y_i | mu_i, sigma_i, b_id, b_site ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + b_id[id_i] + b_site[site_i]
log(sigma_i) = X_sigma[i, ] beta_sigma

b_id[j] = sd_mu_id,j u_id,j
b_site[k] = sd_mu_site,k u_site,k
u_id,j, u_site,k ~ Normal(0, 1)

log(sd_mu_id,j) = W_id[j, ] alpha_id
log(sd_mu_site,k) = W_site[k, ] alpha_site
```

This is not residual `sigma`. It models the scale of group-level location
effects.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/helper-gaussian-random-effect-scale.R`
- `tests/testthat/test-gaussian-random-effect-scale.R`
- `tests/testthat/test-package-skeleton.R`
- `README.md`, `NEWS.md`, `ROADMAP.md`
- `vignettes/drmTMB.Rmd`, `vignettes/formula-grammar.Rmd`,
  `vignettes/location-scale.Rmd`, `vignettes/which-scale.Rmd`
- design docs for formula grammar, family registry, likelihoods, random
  effects, testing, distribution roadmap, reference programme, Gaussian math,
  and random-effect scale models
- `docs/design/19-phylogenetic-location-scale-shape.md`
- generated `man/` files from `devtools::document()`

## Checks Run

- `devtools::test(filter = "gaussian-random-effect-scale")`: 60 passed.
- `devtools::test(filter = "package-skeleton")`: 20 passed.
- `devtools::test(filter = "comparators")`: 31 passed.
- `devtools::test()`: 403 passed.
- `devtools::document()`: updated Rd files.
- `pkgdown::check_pkgdown()`: no problems found.
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(error_on = "never")`: 0 errors, 0 warnings, 1 local clock
  note.
- `devtools::check(error_on = "never", env_vars =
  c("_R_CHECK_SYSTEM_CLOCK_" = "FALSE"))`: 0 errors, 0 warnings, 0 notes.
- `git diff --check`: passed.

`air format .` was attempted, but `air` is not installed locally.

## Tests Of The Tests

- The new multi-target recovery test simulates two independent grouped
  random-intercept scale models and checks convergence, Hessian status,
  coefficient recovery, positive predicted SDs, and response-scale correlation
  with the known group-level SDs.
- Existing malformed-input tests were updated so duplicate `sd(id)` formulas
  fail for duplicate targets, while distinct targets are accepted.
- Existing single-target, factor-predictor, missingness, and lme4-overlap tests
  still pass.

## Consistency Audit

- Public docs no longer say that only one `sd(group) ~ ...` target is
  implemented.
- Known limitations now reserve only slope-specific, labelled-block,
  bivariate, phylogenetic, spatial, and non-Gaussian random-effect scale
  targets for later phases.
- The formula grammar, likelihood equations, and R syntax now describe the same
  model.
- Remaining `meta_gaussian()` and `tau ~` matches are intentional guardrails.

## What Did Not Go Smoothly

The single-target assumption appeared in more places than expected: starts,
maps, parameter splitting, `sdpars`, prediction, tests, vignettes, roadmap, and
design docs. The implementation stayed smaller because TMB could keep one
combined `X_sd_mu` path while R handled block construction and splitting.

## Team Learning

- Popper mapped the single-target implementation and identified the
  block-diagonal design matrix as the smallest safe extension.
- Aquinas identified stale user-facing files before they became a new source of
  confusion.
- Feynman connected the change to phylogenetic location-scale models and Box 1:
  `sd(group) ~ ...` is the bridge to random-factor scale equations.
- Confucius clarified that phylogenetic shape/skewness is substantially harder
  than scale and should be staged later with strict simulation evidence.
- Ada should keep using implementation scouts and documentation scouts in
  parallel for formula-grammar changes.

## Known Limitations

- Multiple `sd(group) ~ ...` formulas only target distinct unlabelled
  univariate Gaussian `mu` random intercepts.
- Random-slope SD formulas, labelled-block SD formulas, bivariate SD formulas,
  phylogenetic/spatial structured scale formulas, and non-Gaussian random-effect
  scale formulas remain future work.
- Shape/skewness/kurtosis design is documented, but not implemented.

## Next Actions

1. Add a comparator-style test for two constant random-intercept SDs if an
   appropriate `lme4` overlap is stable enough.
2. Start the sparse precision/A-inverse design spike for phylogenetic
   intercept-only Gaussian `mu`.
3. Keep shape/skewness/kurtosis in the literature/design lane until Student-t,
   skew-normal fixed effects, and Gaussian phylogenetic location-scale are
   stable.
