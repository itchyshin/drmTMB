# After Task: Gaussian Random-Effect Scale MVP

## Goal

Implement the first random-effect scale model:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z, sd(id) ~ w),
  family = gaussian(),
  data = dat
)
```

This model asks whether a group-level predictor changes the standard deviation
of a `mu` random intercept. It is not a residual `sigma` model.

## Implemented

- Added univariate Gaussian support for exactly one `sd(group) ~ x_group`
  formula targeting one unlabelled `mu` random intercept.
- Added group-level model-matrix construction for `sd(group)`, one row per
  retained group level.
- Added within-group constancy validation for `sd(group)` predictors after
  missing-row filtering.
- Added TMB data and parameters: `X_sd_mu`, `has_sd_mu_model`,
  `mu_re_sd_row`, and `beta_sd_mu`.
- Replaced the targeted scalar `log_sd_mu` with `exp(W alpha)` while keeping
  `u_mu ~ Normal(0, 1)` as the Laplace-integrated latent effect.
- Updated extraction and prediction so `coef(fit, "sd(id)")`,
  `predict(fit, dpar = "sd(id)")`, and `sdpars$sd(id)` describe the fitted
  group-level random-intercept SD model.

## Mathematical Contract

For observation `i` in group `g[i]`:

```text
y_i | mu_i, sigma_i, b_g[i] ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + b_g[i]
log(sigma_i) = X_sigma[i, ] beta_sigma

b_g = sd_mu_group,g u_g
u_g ~ Normal(0, 1)
log(sd_mu_group,g) = W_group[g, ] alpha_group
sd_mu_group,g = exp(W_group[g, ] alpha_group)
```

The fitted `sd(id)` formula creates `W_group` and estimates `alpha_group` as
`beta_sd_mu` in TMB.

## Files Changed

- R API and parser: `R/drmTMB.R`, `R/parse-formula.R`, `R/methods.R`, `R/bf.R`.
- TMB likelihood: `src/drmTMB.cpp`.
- Tests: `tests/testthat/helper-gaussian-random-effect-scale.R`,
  `tests/testthat/test-gaussian-random-effect-scale.R`,
  `tests/testthat/test-comparators.R`,
  `tests/testthat/test-gaussian-location-scale.R`.
- Docs and tutorials: `README.md`, `NEWS.md`, `ROADMAP.md`,
  `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
  `docs/design/04-random-effects.md`, `docs/design/05-testing-strategy.md`,
  `docs/design/13-gaussian-location-scale-math.md`,
  `docs/design/18-random-effect-scale-models.md`,
  `docs/dev-log/known-limitations.md`, `vignettes/drmTMB.Rmd`,
  `vignettes/location-scale.Rmd`, `vignettes/which-scale.Rmd`.

## Checks Run

- `gh run list --branch main --limit 6`
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-effect-scale|comparators')"`
- Manual smoke fit for `sd(id) ~ w`.
- Manual mapping smoke fit with a preceding `(1 + x | site)` block.
- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)"`
- Stale-wording scans over live docs, generated Rd, and generated pkgdown.

Targeted tests and full tests passed, and pkgdown checked and built
successfully. The first package check produced one NOTE from an unqualified
`setNames()` call; the code was changed to `stats::setNames()`. The rerun of
`devtools::check(env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'), manual = FALSE)`
finished with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

- Simulation recovery tests check `mu`, `sigma`, and `sd(id)` coefficients.
- A zero-slope test checks reduction toward constant random-intercept scale.
- Factor, missingness, malformed-input, and unsupported-family tests exercise
  user-facing failure paths.
- An `lme4` comparator checks the `sd(id) ~ 1` overlap.
- A regression test checks that `sd(id)` maps to the correct expanded
  coefficient when a preceding correlated random-effect block exists.
- A summary/vcov test checks finite aligned SEs for `sd(id)` coefficients.

## Consistency Audit

- The symbolic equations in the likelihood and Gaussian math notes match the
  implemented TMB parameterization.
- README, NEWS, ROADMAP, design docs, known limitations, and tutorials now
  describe `sd(id) ~ x_group` as implemented for the narrow Gaussian MVP.
- Stale wording that described `sd(id)` as only future work was corrected in
  live vignettes and limitations.
- Historical after-task notes were left untouched when they were true at the
  time; this report supersedes the design-only status.
- The correlation roadmap remains broader than residual `rho12`: phylogenetic,
  non-phylogenetic species, spatial, study/site, and group-level covariance
  correlations remain separate future summaries.

## What Did Not Go Smoothly

- The first implementation mixed original random-effect term indices with
  expanded covariance coefficient indices. Rose caught this before commit. The
  fix carries `target_coef` explicitly and adds a regression test.
- The first `devtools::check()` pass exposed an unqualified `setNames()` NOTE.
  This was changed to `stats::setNames()`.
- A quick test edit briefly introduced a missing closing parenthesis. Targeted
  tests caught it immediately.

## Team Learning

- For all future random-effect extensions, write down both the formula-level
  term index and the expanded coefficient index in the design before coding.
- Add "preceding block" tests whenever a feature targets one random-effect
  component after parser expansion.
- Keep the after-task-audit skill as a required phase gate; it caught a real
  implementation bug, not just wording drift.

## Known Limitations

- Only one `sd(group)` formula is supported.
- The target must be one unlabelled univariate Gaussian `mu` random intercept.
- The right-hand side must be group-level after missing-row filtering.
- Multiple targets, slope-specific targets, labelled targets, bivariate
  targets, phylogenetic/spatial targets, and non-Gaussian random-effect scale
  models remain future work.
- `sdpars$sd(id)` includes the dpar in value names, while
  `predict(fit, dpar = "sd(id)")` uses group-level names only. This should be
  revisited when the extractor API is formalized.

## Next Actions

- Add multiple `sd(group)` target design only after the single-target API has
  been used in examples.
- Start the next phase only after remote CI confirms the implementation commit.
