# After Task: Fixed And Random Effect Extractors

## Goal

Add familiar mixed-model extractor names for fixed-effect and conditional
random-effect quantities without changing likelihoods or formula grammar.

## Implemented

Added exported `fixef()` and `ranef()` generics with `drmTMB` methods.

`fixef(fit)` returns the full distributional fixed-effect coefficient list, and
`fixef(fit, dpar = "mu")` returns one fixed-effect coefficient vector. It is a
thin alias for the existing `coef()` behaviour.

`ranef(fit)` returns the fitted conditional random-effect blocks stored in a
`drmTMB` fit. `ranef(fit, dpar = "mu")`, `ranef(fit, dpar = "sigma")`, and
`ranef(fit, dpar = "phylo_mu")` select individual blocks when present.

## Mathematical Contract

No likelihood or symbolic model equation changed.

For a fitted model with linear predictor

```text
eta_d = X_d beta_d + Z_d b_d
```

`fixef(fit, dpar = d)` returns `beta_d`. `ranef(fit, dpar = d)` returns the
conditional random-effect block used for `b_d`, with model-scale values,
standard-normal latent values, and term-level splits.

## Files Changed

- `R/methods.R`
- `NAMESPACE`
- `man/fixef.Rd`
- `man/ranef.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/_snaps/gaussian-random-intercepts.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-effect-extractors.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'phylo-gaussian')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

The tests compare `fixef()` directly to `coef()`, check that fixed-effect-only
models return an empty `ranef()` list, check ordinary `mu` random effects,
residual-scale `sigma` random effects, and `phylo_mu` effects, and snapshot the
error for an unknown random-effect block.

## Consistency Audit

- Roxygen regenerated the namespace and manual pages.
- `_pkgdown.yml` now includes `fixef()` and `ranef()` in the model fitting
  reference section.
- `pkgdown::check_pkgdown()` found no missing reference topics.
- `pkgdown::build_site()` produced the `fixef()` and `ranef()` reference pages.
- NEWS records both user-facing extractor additions.
- No formula grammar or likelihood design documents required changes.

## What Did Not Go Smoothly

The first `expect_snapshot()` run recorded a new snapshot and emitted the
expected one-time warning. Rerunning the targeted random-intercept tests passed
without warnings.

`air format .` could not run because the `air` executable is not installed.

## Team Learning

Extractor names can follow user muscle memory from mixed-model packages, but
the object shape must be named honestly. For now, `ranef()` exposes the current
`drmTMB` block structure rather than promising an `lme4`-style table.

## Known Limitations

- `ranef()` does not yet reshape random effects into data frames.
- `phylo_mu` is exposed as the current exact block name; a future alias policy
  for structured effects should be designed before adding more structured
  random-effect families.

## Next Actions

1. Commit and push this extractor slice.
2. Watch the GitHub Actions `R-CMD-check` and `pkgdown` workflows.
3. Continue with the next small extractor or tutorial-consistency slice.
