# After Task: Student-t Fixed-Effect Location-Scale-Shape

## Goal

Add the first robust continuous response family after Gaussian: a univariate
Student-t model where users can write formulas for `mu`, `sigma`, and `nu`.

## Implemented

- Added the exported `student()` family constructor.
- Added a Student-t TMB likelihood branch with `model_type = 3`.
- Added `X_nu` and `beta_nu` plumbing through the R model builder and TMB data
  list.
- Added `predict(fit, dpar = "nu")`, `simulate()`, `residuals()`, `sigma()`,
  `summary()`, `vcov()`, and `logLik()` support through the existing methods.
- Added tests for parameter recovery, an independent likelihood comparator,
  simulation/residual methods, and unsupported-term errors.
- Updated public and design documentation.

## Mathematical Contract

For each observation:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
mu_i = X_mu[i, ] beta_mu
sigma_i = exp(X_sigma[i, ] beta_sigma)
nu_i = 2 + exp(X_nu[i, ] beta_nu)
```

The TMB density includes the normalizing constants:

```text
z_i = (y_i - mu_i) / sigma_i
log f(y_i) =
  lgamma((nu_i + 1) / 2) - lgamma(nu_i / 2)
  - 0.5 log(nu_i pi) - log(sigma_i)
  - 0.5 (nu_i + 1) log(1 + z_i^2 / nu_i)
```

The matching first user syntax is:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = student(),
  data = dat
)
```

## Files Changed

- `DESCRIPTION`
- `NEWS.md`
- `NAMESPACE`
- `_pkgdown.yml`
- `R/drmTMB.R`
- `R/family.R`
- `R/methods.R`
- `src/drmTMB.cpp`
- `tests/testthat/test-student-location-scale.R`
- `tests/testthat/test-phylo-utils.R`
- `README.md`
- `vignettes/distribution-families.Rmd`
- `docs/design/02-family-registry.md`
- `docs/design/03-likelihoods.md`
- `docs/design/06-distribution-roadmap.md`
- `docs/design/19-phylogenetic-location-scale-shape.md`
- `man/drmTMB.Rd`
- `man/simulate.drmTMB.Rd`
- `man/student.Rd`

## Checks Run

- `Rscript -e "devtools::load_all()"`
- ad hoc Student-t smoke fit with `student()`, `predict(dpar = "nu")`, and
  `simulate()`
- `Rscript -e "devtools::test(filter = 'student-location-scale')"`:
  21 passed, 0 failed
- `Rscript -e "devtools::test(filter = 'gaussian-location-scale|biv-gaussian|meta-known-v|phylo-gaussian')"`:
  196 passed, 0 failed
- `Rscript -e "devtools::test()"`: 623 passed, 0 failed
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`: no problems found
- `Rscript -e "pkgdown::build_site()"`: completed
- generated-site and stale-wording scans for Student-t claims
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`:
  0 errors, 0 warnings, 0 notes
- `git diff --check`: clean

## Tests Of The Tests

- The likelihood test compares TMB output with an independent R calculation of
  the Student-t negative log likelihood.
- The recovery test uses deterministic Student-t quantiles rather than a fully
  random heavy-tailed sample, keeping the test stable while checking `mu`,
  `sigma`, and `nu`.
- The unsupported-term test confirms that Student-t currently rejects random
  effects, `meta_known_V(V = V)`, and `sd(group)` rather than silently fitting
  unsupported syntax.

## Consistency Audit

- The family registry, likelihood design, distribution roadmap, README,
  NEWS, roxygen page, and distribution-family vignette all describe Student-t
  as fixed-effect univariate only.
- Generated pkgdown pages include `reference/student.html`, list `student()`
  in the reference index, and show the Student-t article text.
- Stale-wording scans did not find active docs claiming Student-t random
  effects, Student-t known covariance, Student-t phylogeny, or implemented
  bivariate Student-t models.

## What Did Not Go Smoothly

- The first full test run failed in a direct TMB phylogenetic-prior helper
  because it manually constructed the TMB data/parameter lists and therefore
  needed dummy `X_nu` and `beta_nu` entries after the template changed.
- A first version of the recovery test used fully random Student-t draws and
  made `nu` recovery too noisy for a routine CRAN-safe test. Deterministic
  Student-t quantiles gave a better test of the intended implementation.
- `air format .` could not run because `air` is not installed.

## Team Learning

- Gauss's likelihood rule matters: include the Student-t normalizing constants
  and compare the objective against independent R code.
- Fisher's warning about shape weak identification showed up immediately:
  `nu` needs tolerant, deterministic tests before it is used as evidence of
  biological tail effects.
- Rose's systems view caught the hidden coupling between the TMB template
  parameter list and direct helper tests.

## Known Limitations

- Student-t models are fixed-effect only in this task.
- `meta_known_V(V = V)`, `phylo()`, `spatial()`, ordinary random effects, and
  random-effect scale formulae are not implemented for Student-t yet.
- `nu` is degrees of freedom/tail weight here. It is not a skewness parameter;
  future skew-normal and skew-t families need separate documentation.

## Next Actions

- Add a short robust-continuous example to a later tutorial using an ecology or
  evolution question with heavy-tailed residuals.
- Consider Student-t known-covariance meta-analysis only after Gaussian
  meta-analysis and fixed-effect Student-t diagnostics are more mature.
- Keep bivariate Student-t as a later design task after bivariate Gaussian
  random effects and structured correlations are clearer.
