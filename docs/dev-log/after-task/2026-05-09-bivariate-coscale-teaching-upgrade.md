# After Task: Bivariate Coscale Tutorial Teaching Upgrade

## Goal

Improve the bivariate location-coscale tutorial so readers can connect the
symbolic `rho12` model to activity, boldness, disturbance, fitted output, and a
response-scale biological interpretation.

## Implemented

- Added activity-boldness equations to `vignettes/bivariate-coscale.Rmd`.
- Clarified that `rho12` is residual correlation, not the raw correlation
  between observed activity and boldness.
- Added an output-reading block after `summary(fit_biv)`.
- Added a response-scale `rho12` curve over a disturbance gradient.
- Added a concise reporting sentence for the fitted residual-coupling result.
- Updated `NEWS.md`.
- Recorded the work in `docs/dev-log/check-log.md`.

## Mathematical Contract

The worked example documents:

```text
[activity_i, boldness_i]' ~ MVN([mu_activity_i, mu_boldness_i]', Omega_i)
mu_activity_i = beta_a0 + beta_a1 food_i + beta_a2 temperature_i
mu_boldness_i = beta_b0 + beta_b1 food_i
log(sigma_activity_i) = gamma_a0 + gamma_a1 food_i + gamma_a2 temperature_i
log(sigma_boldness_i) = gamma_b0 + gamma_b1 food_i
eta_rho12_i = delta_0 + delta_1 disturbance_i
rho12_i = tanh(eta_rho12_i)
```

The matching R syntax is:

```r
drmTMB(
  drm_formula(
    mu1 = activity ~ food + temperature,
    mu2 = boldness ~ food,
    sigma1 = ~ food + temperature,
    sigma2 = ~ food,
    rho12 = ~ disturbance
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

`rho12` is interpreted after modelling `mu1`, `mu2`, `sigma1`, and `sigma2`.
A positive `rho12:disturbance` coefficient means stronger positive residual
activity-boldness coupling at higher disturbance, not a group-level
personality or plasticity correlation.

## Files Changed

- `NEWS.md`
- `vignettes/bivariate-coscale.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-09-bivariate-coscale-teaching-upgrade.md`

## Checks Run

- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/bivariate-coscale.Rmd', output_dir = tempdir(), quiet = TRUE)"`
- `Rscript -e "devtools::test(filter = 'biv-gaussian|corpairs|check-drm')"`
- `git diff --check`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`

The article rendered successfully. Targeted tests passed: 184 passed, 0
failed, 0 warnings, 0 skips. `git diff --check` was clean. Full
`devtools::test()` passed: 1215 passed, 0 failed, 0 warnings, 0 skips.
`pkgdown::build_site()` completed, favicon MIME post-processing completed,
`pkgdown::check_pkgdown()` found no problems, and `devtools::check()` returned
0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The edited tutorial executes the bivariate Gaussian `rho12` likelihood path.
The targeted tests exercise the same model family plus `rho12`, `corpairs()`,
and `check_drm()` behaviour that the tutorial now asks readers to inspect.

## Consistency Audit

The public tutorial keeps `rho12` separate from group-level covariance
correlations. It uses `rho12_i = tanh(eta_rho12_i)` as the teaching equation
and leaves the tiny numerical guard as an implementation note.

## What Did Not Go Smoothly

The page already had a solid example, so the risk was over-editing. The useful
addition was not more syntax, but a small layer that tells readers where to
look in `summary()`, what scale the coefficient lives on, and how to translate
the fitted curve into a biological statement.

## Team Learning

- Ada should add output-reading blocks whenever a tutorial prints `summary()`.
- Noether should keep checking that the tutorial equation and R formula use
  the same variables.
- Darwin and Pat should continue pushing the docs toward biological
  interpretation after every model-output table.

## Known Limitations

- The tutorial uses simulated data.
- The `rho12` curve shows fitted correlations only, without uncertainty.
- Bivariate group-level covariance blocks remain planned.

## Next Actions

1. Add uncertainty summaries once confidence-interval/profile-likelihood
   tooling exists.
2. Source a real behaviour or comparative dataset for a polished teaching
   release.
3. Add a companion double-hierarchical correlation-pair design tutorial after
   the TMB likelihood exists.
