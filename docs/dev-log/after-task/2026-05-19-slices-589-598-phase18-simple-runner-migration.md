# Slices 589-598: Phase 18 Simple Runner Migration

## Purpose

Ada migrated the remaining simple Phase 18 smoke runners to the bounded
replicate helper. This covers Gaussian random-slope and coordinate-spatial smoke
surfaces while deliberately leaving closure-heavy Student-t and bivariate
`rho12` runners unchanged.

## Team Notes

- Ada migrated only runners with constant DGP, fit, and summarise functions.
- Fisher and Curie checked the focused test set and small multicore smokes.
- Grace kept all validation smokes at two workers, well below the 10-core cap.
- Rose kept Student-t and bivariate `rho12` out of this slice because they
  construct per-replicate profile or bootstrap closures.

## Files Changed

- `inst/sim/run/sim_run_gaussian_mu_random_slope_smoke.R`
- `inst/sim/run/sim_run_gaussian_sigma_random_slope_smoke.R`
- `inst/sim/run/sim_run_spatial_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_gaussian_mu_random_slope_smoke.R`
- `inst/sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R`
- `inst/sim/run/sim_summary_spatial_mu_slope_smoke.R`
- `tests/testthat/test-phase18-gaussian-mu-random-slope.R`
- `tests/testthat/test-phase18-gaussian-sigma-random-slope.R`
- `tests/testthat/test-phase18-spatial-mu-slope.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`

## What Changed

The Gaussian `mu` random-slope, Gaussian `sigma` random-slope, and coordinate
spatial `mu` slope runners now accept `cores` and `backend`, call
`phase18_run_replicates()`, and return `parallel` metadata. Their summary
wrappers pass those controls through.

## Validation

Checks run:

```sh
air format inst/sim/run/sim_run_gaussian_mu_random_slope_smoke.R inst/sim/run/sim_run_gaussian_sigma_random_slope_smoke.R inst/sim/run/sim_run_spatial_mu_slope_smoke.R inst/sim/run/sim_summary_gaussian_mu_random_slope_smoke.R inst/sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R inst/sim/run/sim_summary_spatial_mu_slope_smoke.R tests/testthat/test-phase18-gaussian-mu-random-slope.R tests/testthat/test-phase18-gaussian-sigma-random-slope.R tests/testthat/test-phase18-spatial-mu-slope.R
Rscript -e "invisible(parse(file = 'inst/sim/run/sim_run_gaussian_mu_random_slope_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_run_gaussian_sigma_random_slope_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_run_spatial_mu_slope_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_gaussian_mu_random_slope_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_spatial_mu_slope_smoke.R')); cat('simple runner parse ok\n')"
Rscript -e "devtools::test(filter = '^phase18-gaussian-mu-random-slope$|^phase18-gaussian-sigma-random-slope$|^phase18-spatial-mu-slope$|^phase18-sim-runner$')"
```

Additional two-core smoke checks ran for:

- `phase18_run_gaussian_mu_rs_smoke()`;
- `phase18_run_gaussian_sigma_rs_smoke()`;
- `phase18_run_spatial_mu_slope_smoke()`.

Results:

- Focused simple-runner tests passed 138 expectations.
- All three `backend = "multicore"` smokes completed with `cores = 2`.

## Known Limitations

- Student-t and bivariate `rho12` runners still need a closure-aware migration
  because they build per-replicate profile or bootstrap summary functions.
- This slice did not rerun the full Phase 18 suite after migration; that should
  be the next validation step.
