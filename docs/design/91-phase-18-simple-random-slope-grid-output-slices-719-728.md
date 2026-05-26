# Phase 18 Simple Random-Slope Grid Output Slices 719-728

Reader: `drmTMB` contributors checking that the first simple random-slope
surfaces have repeatable Phase 18 grid artifacts before larger simulation
reports consume them.

Slices 719-728 validate simple grid-output writers for ordinary Gaussian `mu`
random slopes, independent Gaussian `sigma` random slopes, and coordinate-
spatial Gaussian `mu` slopes. The implementation is already present in the
current dirty tree: each writer saves aggregate, replicate, manifest, and
failure-ledger CSV artifacts beside resumable per-replicate RDS files.

## Source Evidence

- `phase18_write_gaussian_mu_rs_grid_outputs()` writes the ordinary Gaussian
  location random-slope surface.
- `phase18_write_gaussian_sigma_rs_grid_outputs()` writes the independent
  Gaussian scale random-slope surface.
- `phase18_write_spatial_mu_slope_grid_outputs()` writes the coordinate-spatial
  Gaussian location one-slope surface.
- All three writers use the shared simple-grid helpers for output-directory
  validation, `results`/`tables` directory setup, aggregate/replicate/manifest/
  failure path construction, overwrite protection, CSV writing, and artifact-
  manifest creation.
- The random-slope grid-writer tests cover the three surfaces, table existence,
  artifact-manifest existence, replicate row counts, serial fallback metadata,
  overwrite rejection, and malformed writer inputs.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 719-721 | Validate ordinary Gaussian `mu` random-slope grid output | `phase18-gaussian-mu-random-slope` and grid-writer tests passed |
| 722-724 | Validate independent Gaussian `sigma` random-slope grid output | `phase18-gaussian-sigma-random-slope` and grid-writer tests passed |
| 725-727 | Validate coordinate-spatial Gaussian `mu` slope grid output | `phase18-spatial-mu-slope` and grid-writer tests passed |
| 728 | Validate shared simple-grid helper contract | `phase18-sim-runner`, `phase18-sim-aggregate`, and grid-writer tests passed |

## Commands

```sh
nl -ba inst/sim/run/sim_write_gaussian_mu_random_slope_grid.R | sed -n '1,75p'
nl -ba inst/sim/run/sim_write_gaussian_sigma_random_slope_grid.R | sed -n '1,75p'
nl -ba inst/sim/run/sim_write_spatial_mu_slope_grid.R | sed -n '1,75p'
nl -ba inst/sim/R/sim_runner.R | sed -n '479,545p'
nl -ba tests/testthat/test-phase18-random-slope-grid-writers.R | sed -n '1,135p'
Rscript -e "devtools::test(filter = 'phase18-(random-slope-grid-writers|gaussian-mu-random-slope|gaussian-sigma-random-slope|spatial-mu-slope|sim-runner|sim-aggregate)', reporter = 'summary')"
```

## Result

The focused simple random-slope grid-output bundle completed with exit code 0.
The passing files were:

- `phase18-gaussian-mu-random-slope`
- `phase18-gaussian-sigma-random-slope`
- `phase18-random-slope-grid-writers`
- `phase18-sim-aggregate`
- `phase18-sim-runner`
- `phase18-spatial-mu-slope`

This closes Slices 719-728 as grid-output validation for already-supported
ordinary Gaussian `mu`, independent Gaussian `sigma`, and coordinate-spatial
Gaussian `mu` one-slope smoke surfaces. It does not add bivariate slopes,
correlated non-Gaussian slopes, multiple structured slopes, structured slope
correlations, residual-scale correlated slopes, mesh/SPDE spatial effects,
spatial direct-SD syntax, spatial `corpair()`, formula grammar, likelihood
code, roxygen topics, or new user-facing API.
