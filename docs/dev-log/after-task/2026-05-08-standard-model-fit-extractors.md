# After Task: Standard Model-Fit Extractors

## Goal

Make `drmTMB` fits behave more like ordinary R model objects for basic model
summary and comparison tasks.

## Implemented

Added S3 methods for:

- `nobs.drmTMB()`
- `df.residual.drmTMB()`
- `deviance.drmTMB()`

The methods are documented together in `model-fit-extractors.Rd` and listed in
the pkgdown model fitting reference section.

## Mathematical Contract

No likelihood changed.

The methods expose quantities already stored by the fitted object:

```text
nobs(fit) = n
df.residual(fit) = n - p
deviance(fit) = -2 logLik(fit)
```

where `n` is the number of fitted rows after complete-case filtering and `p`
is the number of optimized top-level parameters recorded as the `df` attribute
of `logLik(fit)`.

For these likelihood-based distributional models, `deviance()` is an absolute
negative twice log-likelihood value. It is not a saturated-model GLM deviance.

## Files Changed

- `R/methods.R`
- `R/drmTMB-package.R`
- `NAMESPACE`
- `man/model-fit-extractors.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-comparators.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-standard-model-fit-extractors.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'comparators')"`
- `Rscript -e "devtools::load_all(); fit <- drmTMB(bf(y ~ x), data = data.frame(y = rnorm(20), x = rnorm(20)), family = gaussian()); stopifnot(stats::nobs(fit) == 20L, is.numeric(stats::df.residual(fit)), is.numeric(stats::deviance(fit))); cat('namespace smoke ok\\n')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

The Gaussian location-scale tests check:

- `nobs(fit)` equals the simulated row count;
- `nobs(fit)` respects complete-case filtering;
- `df.residual(fit)` equals `fit$nobs - fit$df`;
- `deviance(fit)` equals `-2 * logLik(fit)`;
- `AIC(fit)` equals `deviance(fit) + 2 * fit$df`.

The bivariate Gaussian tests check the same extractor algebra on a two-response
fit. The comparator tests check that `AIC()` and `BIC()` agree with `lme4` on
an overlapping Gaussian random-intercept model.

## Consistency Audit

- Roxygen regenerated `NAMESPACE` and `man/model-fit-extractors.Rd`.
- `_pkgdown.yml` includes `model-fit-extractors`.
- `pkgdown::check_pkgdown()` found no missing reference topics.
- `pkgdown::build_site()` produced `reference/model-fit-extractors.html` and
  redirects for the individual S3 method aliases.
- A stale wording search found the extractor methods only in expected code,
  tests, NEWS, reference documentation, and rebuilt pkgdown pages.

## What Did Not Go Smoothly

The first `devtools::check()` run failed with namespace-load warnings because
the S3 methods were registered before the `stats` generics were imported.
Adding `@importFrom stats nobs df.residual deviance` and regenerating
`NAMESPACE` fixed the issue. The final `devtools::check()` passed with 0
errors, 0 warnings, and 0 notes.

`air format .` could not run because `air` is not installed on this machine.

## Team Learning

`devtools::test()` can miss namespace-registration problems for base-R S3
generics. For user-facing S3 method additions, the package check is not
ceremony; it is the test that catches whether a clean namespace can load.

## Known Limitations

- `df.residual()` currently uses the simple `nobs - df` convention.
- Future penalized or constrained models may need more explicit effective
  degrees-of-freedom documentation.

## Next Actions

1. Commit and push this extractor slice.
2. Watch GitHub Actions.
3. Continue with another small user-facing modelling-software polish task or
   move to the next planned spatial/mesh design note.
