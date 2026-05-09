# After Task: Student-t Scale Terminology

## Goal

Clarify that `sigma` is the package's general residual scale parameter, not
always the residual standard deviation.

## Implemented

- Updated the README definition of `sigma` so Gaussian residual SD is presented
  as a special case.
- Updated `sigma.drmTMB()` documentation to distinguish Student-t scale from
  Student-t residual standard deviation.
- Rebuilt roxygen documentation and the pkgdown site so the rendered home page
  and reference page carry the same wording.

## Mathematical Contract

For Gaussian models,

```text
y_i ~ Normal(mu_i, sigma_i^2)
```

so `sigma_i` is the residual standard deviation.

For Student-t models,

```text
y_i ~ Student-t(mu_i, sigma_i, nu_i)
```

where `sigma_i` is the Student-t scale parameter. When `nu_i > 2`, the
residual standard deviation is

```text
sigma_i * sqrt(nu_i / (nu_i - 2)).
```

## Files Changed

- `README.md`
- `R/methods.R`
- `man/sigma.drmTMB.Rd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-student-t-scale-terminology.md`

Generated and verified locally:

- `pkgdown-site/index.html`
- `pkgdown-site/reference/sigma.drmTMB.html`

## Checks Run

- `Rscript -e "devtools::document()"`
- `Rscript -e "devtools::test(filter = 'student-location-scale')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`
- `rg` scans for Student-t scale and residual-standard-deviation wording in
  source docs and generated pkgdown pages.

## Tests Of The Tests

No new unit tests were added because this was a terminology and documentation
task. The existing Student-t tests were rerun to ensure that the documentation
edit did not accompany a behaviour change, and full package tests were run to
catch accidental inconsistencies.

## Consistency Audit

- The README, extractor documentation, and robust Student-t tutorial now agree
  that Student-t `sigma` is a scale parameter.
- Gaussian tutorials still use residual standard deviation language, which is
  mathematically correct for `Normal(mu_i, sigma_i^2)`.
- Generated pkgdown pages were rebuilt and scanned for the revised wording.
- The check log now records the terminology decision and the validation steps.

## What Did Not Go Smoothly

The earlier package-level README sentence was too Gaussian-specific after the
Student-t family landed. The fix was small, but it exposed a useful habit for
future families: every new family should trigger a pass over extractor wording,
not only the new vignette.

## Team Learning

Rose's after-task audit should explicitly ask whether an existing extractor
name has different mathematical meaning under a newly added family. This is
especially important for shape families where scale, variance, and residual SD
are not interchangeable.

## Known Limitations

`drmTMB` does not yet provide a helper for Student-t residual standard
deviation. Users can compute it from `sigma(fit)` and
`predict(fit, dpar = "nu")` when `nu > 2`.

## Next Actions

- Consider adding a small helper or documentation section for derived quantities
  such as Student-t residual SD.
- Apply the same extractor-wording audit when skewness, kurtosis, beta, or count
  families are added.
