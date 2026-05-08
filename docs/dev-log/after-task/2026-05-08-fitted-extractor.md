# After Task: Fitted Mean Extractor

## Goal

Add a familiar base-R extractor for fitted location values without creating a
second prediction implementation.

## Implemented

Added exported `fitted.drmTMB()`.

For univariate Gaussian fits, `fitted(fit)` returns the fitted `mu` vector. For
bivariate Gaussian fits, it returns a two-column matrix with `mu1` and `mu2`.
The method is deliberately limited to fitted training rows; `predict()` remains
the API for new data and for non-location distributional parameters such as
`sigma`, `sigma1`, `sigma2`, and `rho12`.

The location-scale and bivariate-coscale tutorials now map the symbolic fitted
mean quantities directly to `fitted(fit)`.

## Mathematical Contract

No likelihood changed. The extractor returns the location component already
used by the fitted model.

For univariate Gaussian models:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = eta_mu_i
```

`fitted(fit)[i]` returns `mu_i`.

For bivariate Gaussian models:

```text
[y1_i, y2_i]' | mu1_i, mu2_i, Omega_i
  ~ MVN([mu1_i, mu2_i]', Omega_i)
```

`fitted(fit)[i, "mu1"]` returns `mu1_i`, and
`fitted(fit)[i, "mu2"]` returns `mu2_i`.

For fitted rows in univariate Gaussian mixed models, the existing
`predict(fit, dpar = "mu")` path adds the current conditional `mu`
random-effect contribution. `fitted(fit)` therefore returns conditional fitted
means for those implemented models.

## Files Changed

- `R/methods.R`
- `NAMESPACE`
- `man/fitted.drmTMB.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `vignettes/location-scale.Rmd`
- `vignettes/bivariate-coscale.Rmd`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/test-gaussian-random-intercepts.R`
- `tests/testthat/test-biv-gaussian.R`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-fitted-extractor.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts')"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

The fixed-effect Gaussian test checks that `fitted(fit)` equals
`predict(fit, dpar = "mu")`.

The Gaussian random-intercept test checks that `fitted(fit)` equals the
conditional `mu` prediction, which includes current random-intercept
contributions for fitted rows.

The bivariate Gaussian test checks that `fitted(fit)` has dimensions
`n x 2`, columns `mu1` and `mu2`, and columns equal to
`predict(fit, dpar = "mu1")` and `predict(fit, dpar = "mu2")`.

## Consistency Audit

- Roxygen regenerated `NAMESPACE` and `man/fitted.drmTMB.Rd`.
- `_pkgdown.yml` includes `fitted.drmTMB` in the model fitting reference
  section.
- `pkgdown::check_pkgdown()` found no missing topics.
- `pkgdown::build_site()` produced `reference/fitted.drmTMB.html` and rebuilt
  the touched tutorials.
- A teaching search found `fitted(fit)` in the source vignettes and rebuilt
  pkgdown pages where expected.

## What Did Not Go Smoothly

`air format .` could not run because `air` is not installed on this machine.

## Team Learning

When adding a familiar extractor, the main risk is not numerical correctness
but ambiguity about scale and conditioning. The documentation now says that
`fitted()` returns location values for fitted rows and that `predict()` remains
the general distributional-parameter and `newdata` interface.

## Known Limitations

- `fitted()` currently returns only location values.
- Future composed-response families may need family-specific fitted-value
  shapes beyond the current univariate vector and bivariate two-column matrix.

## Next Actions

1. Commit and push this extractor slice.
2. Watch GitHub Actions.
3. Continue with the next small user-facing consistency task.
