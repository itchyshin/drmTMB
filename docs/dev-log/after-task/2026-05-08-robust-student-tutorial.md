# After Task: Robust Student-t Tutorial

## Goal

Create a user-facing tutorial that pairs the Student-t location-scale-shape
equation with matching `drmTMB` syntax, using an ecological example and clear
interpretation of `mu`, `sigma`, and `nu`.

## Implemented

- Added `vignettes/robust-student.Rmd`.
- Added the tutorial to the pkgdown Tutorials menu and article index.
- Linked the tutorial from `vignettes/distribution-families.Rmd`.
- Explained that Student-t `sigma` is a scale parameter; the residual standard
  deviation is `sigma * sqrt(nu / (nu - 2))` when `nu > 2`.
- Added practical interpretation of `check_drm()` `student_nu` notes and
  warnings.

## Mathematical Contract

The tutorial presents:

```text
growth_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
mu_i = beta_0 + beta_1 dry_i
log(sigma_i) = gamma_0 + gamma_1 dry_i
nu_i = 2 + exp(delta_0)
```

and pairs it with:

```r
drmTMB(
  bf(growth ~ drought, sigma ~ drought, nu ~ 1),
  family = student(),
  data = seedlings
)
```

The tutorial defines `dry_i` as the model-matrix indicator corresponding to the
`droughtdry` coefficient.

## Files Changed

- `_pkgdown.yml`
- `vignettes/robust-student.Rmd`
- `vignettes/distribution-families.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

- Rendered the vignette with `devtools::load_all()` and `rmarkdown::render()`.
- `Rscript -e "devtools::test(filter = 'student-location-scale|check-drm')"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- Generated-site scans for the tutorial page, navigation links, Student-t scale
  wording, `dry_i`, and near-boundary `nu` guidance.
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `git diff --check`

All targeted tests, full tests, pkgdown checks, pkgdown build, and package
check passed after the tutorial and navigation updates.

## Tests Of The Tests

The new tutorial is documentation, so the main checks are renderability,
pkgdown navigation, and generated-site searches. Existing Student-t and
`check_drm()` tests were rerun because the tutorial teaches those behaviours.

## Consistency Audit

Volta reviewed as an applied user and caught the most important wording issue:
Student-t `sigma` must be described as scale, not residual standard deviation.
Dewey reviewed repository consistency and caught missing after-task closure,
implemented fixed-effect `nu ~ predictors` underclaiming, and untracked-file
risk. These were fixed before closure.

## What Did Not Go Smoothly

The first direct render failed because `library(drmTMB)` could not load an
uninstalled package. The correct local render path loaded the package with
`devtools::load_all()` before rendering. pkgdown and R CMD check install the
package before vignette rendering, so this does not indicate a vignette error.

## Team Learning

Student-t examples need extra care around scale language. The Gaussian habit of
calling `sigma` residual SD does not transfer exactly when `nu` is small.

## Known Limitations

- The tutorial uses simulated data rather than an online ecological dataset.
- It does not cover Student-t random effects, known sampling covariance,
  phylogenetic terms, spatial terms, or bivariate Student-t models because
  those are later phases.

## Next Actions

- Add a future empirical example once a stable teaching dataset is chosen.
- Consider adding a helper or documentation note for converting Student-t scale
  to residual SD when users need that quantity.
