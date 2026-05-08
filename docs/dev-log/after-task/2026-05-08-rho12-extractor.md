# After Task: rho12 Residual Correlation Extractor

## Goal

Make the fitted bivariate residual correlation easier to extract and teach by
adding a dedicated `rho12()` helper.

## Implemented

Added exported `rho12()` and `rho12.drmTMB()`.

`rho12(fit)` returns response-scale residual correlations for bivariate
Gaussian location-coscale fits. `rho12(fit, type = "link")` returns the
atanh-scale linear predictor. `rho12(fit, newdata = dat)` uses the existing
prediction machinery for new data.

The README, getting-started article, bivariate-coscale article, which-scale
tutorial, NEWS, roxygen documentation, and pkgdown reference navigation now use
or advertise `rho12()`.

## Mathematical Contract

No likelihood changed. The extractor maps directly onto the existing
bivariate Gaussian coscale equations:

```text
atanh(rho12_i) = X_rho12[i, ] beta_rho12
rho12_i = tanh(X_rho12[i, ] beta_rho12)
Omega_i[1, 2] = rho12_i sigma1_i sigma2_i
```

`rho12(fit, type = "link")` returns `X_rho12 beta_rho12`.
`rho12(fit)` returns the bounded response-scale correlation used in
`Omega_i`.

## Files Changed

- `R/methods.R`
- `NAMESPACE`
- `man/rho12.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `README.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/which-scale.Rmd`
- `tests/testthat/test-biv-gaussian.R`
- `tests/testthat/test-gaussian-location-scale.R`
- `tests/testthat/_snaps/gaussian-location-scale.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-rho12-extractor.md`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale')"`
- `air format .`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

## Tests Of The Tests

The bivariate tests compare `rho12()` to `predict(fit, dpar = "rho12")` on the
response scale, compare `rho12(type = "link")` to the atanh-scale predictor,
and check `newdata`. A Gaussian fixed-effect-only model snapshots the error
when `rho12()` is used on a fit without residual correlation.

## Consistency Audit

- Roxygen regenerated `NAMESPACE` and `man/rho12.Rd`.
- `_pkgdown.yml` includes `rho12()` in the model fitting reference section.
- `pkgdown::check_pkgdown()` found no missing topics.
- `pkgdown::build_site()` produced `reference/rho12.html` and rebuilt the
  touched tutorials.
- A stale teaching search found no remaining active tutorial or README examples
  using `predict(fit, dpar = "rho12")` as the main extraction path.

## What Did Not Go Smoothly

The first non-bivariate error snapshot produced the expected one-time snapshot
warning. Rerunning the targeted Gaussian location-scale tests passed without
warnings.

`air format .` could not run because `air` is not installed.

## Team Learning

When a helper represents a flagship concept, update the teaching surface at the
same time. Otherwise users learn the lower-level API and the package identity
gets blurrier.

## Known Limitations

- `rho12()` currently covers only bivariate Gaussian residual correlation.
- Phylogenetic, species, site, spatial, and other group-level correlation
  summaries should remain separate from residual `rho12`.

## Next Actions

1. Commit and push this extractor slice.
2. Watch GitHub Actions.
3. Continue with another small user-facing consistency or extractor task.
