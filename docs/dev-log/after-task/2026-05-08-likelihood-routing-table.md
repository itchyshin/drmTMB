# After Task: Likelihood Routing Table

## Goal

Add a central likelihood-routing table so contributors can see how R family
routes map to TMB `model_type` branches, including the hidden phylogenetic test
branch.

## Implemented

- Added an "Implemented TMB Routing" section to
  `docs/design/03-likelihoods.md`.
- Documented `model_type = 1`, `2`, `3`, and hidden `99`.
- Clarified that bivariate Gaussian is the validated fallthrough in
  `make_tmb_data()` after Gaussian and Student-t labels.
- Added `family = list(gaussian(), gaussian())` to the source-map routing
  overview.
- Corrected `rho12` documentation to match the guarded TMB transform:
  `rho12 = 0.99999999 * tanh(eta_rho12)`.
- Updated `NEWS.md` and `docs/dev-log/check-log.md`.

## Mathematical Contract

The bivariate residual-correlation predictor is

```text
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.99999999 * tanh(eta_rho12_i)
```

and the residual covariance uses

```text
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i
```

The numerical guard keeps the fitted covariance matrix away from exact
singularity for extreme linear predictors.

## Files Changed

- `docs/design/03-likelihoods.md`
- `vignettes/source-map.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-08-likelihood-routing-table.md`

## Checks Run

- `git diff --check`
- `rg -n 'list\\(gaussian\\(\\), gaussian\\(\\)\\)|rho12 = tanh|atanh\\(rho12|0\\.99999999|fallthrough|model_type = 2' docs/design/03-likelihoods.md vignettes/source-map.Rmd R/drmTMB.R src/drmTMB.cpp`
- `Rscript -e "rmarkdown::render('vignettes/source-map.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

Results:

- `git diff --check`: clean.
- Source-map render: passed.
- `pkgdown::check_pkgdown()`: no problems found.
- `devtools::test()`: 646 passed, 0 failed, 0 warnings, 0 skips.
- `pkgdown::build_site()`: completed successfully.
- `devtools::check(...)` with `_R_CHECK_SYSTEM_CLOCK_=FALSE`: 0 errors,
  0 warnings, 0 notes.
- The routing scan shows `list(gaussian(), gaussian())` in R docs, the source
  map, and the likelihood design.
- The routing scan shows the guarded `rho12` transform in the source map, the
  likelihood design, and the TMB template.

## Tests Of The Tests

No model code changed. The audit compared the new docs against:

- `R/drmTMB.R` family routing and `make_tmb_data()`;
- `src/drmTMB.cpp` TMB branch numbers;
- `vignettes/source-map.Rmd` implemented-path table;
- `tests/testthat/test-phylo-utils.R` direct construction of
  `model_type = 99`.

## Consistency Audit

- `model_type = 99` is described as a hidden test helper, not a user-facing
  family.
- Public phylogenetic Gaussian models remain on `model_type = 1`.
- Bivariate Gaussian composed-family spellings now include both `c(...)` and
  `list(...)`.
- The bivariate `rho12` equations and source map now match the C++ guard.

## What Did Not Go Smoothly

Rose found that the first routing-table draft missed `list(gaussian(),
gaussian())`, overstated the explicitness of the bivariate TMB route, and used
ungarded `rho12` prose in two places. Those were fixed before commit.

## Team Learning

Architecture maps must be checked at two levels: the public family-normalizing
router and the lower-level TMB data mapper. They are related, but not the same
contract.

## Known Limitations

The bivariate TMB data route is still a fallthrough after Gaussian and
Student-t handling. This is acceptable while the family router validates model
types before `make_tmb_data()`, but future families may make an explicit guard
clearer.

## Next Actions

- Clean stale location-scale wording around implemented `sd(group) ~ x_group`.
- Continue using the source map as the first stop before touching a likelihood
  branch.
