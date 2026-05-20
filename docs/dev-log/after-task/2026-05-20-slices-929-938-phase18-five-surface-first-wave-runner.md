# Slices 929-938: Phase 18 Five-Surface First-Wave Runner

## Goal

Ada added ordinary Gaussian `sigma` random slopes to the reusable first-wave
summary runner.

## Implemented

`phase18_run_first_wave_summary_smoke()` now includes
`phase18_write_gaussian_sigma_rs_grid_outputs()` beside the Gaussian
location-scale, `meta_V(V = V)`, paired Poisson/NB2 `mu` random-effect, and
ordinary Gaussian `mu` random-slope surfaces.

The runner return object now includes `gaussian_sigma_random_slope`, and the
parallel summary includes a `gaussian_sigma_random_slope_grid` row.

## Validation

Focused tests:

```sh
air format inst/sim/run/sim_run_first_wave_summary_smoke.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-smoke-runner$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner)$')"
```

Result:

- 16 expectations passed, 0 failures, 0 warnings, 0 skips.
- The broader first-wave report/render-helper/smoke-runner bundle then passed
  64 expectations, 0 failures, 0 warnings, 0 skips.

Rendered smoke:

- Output root:
  `inst/sim/results/slice-929-first-wave-runner-five-surface-smoke/`
- Rendered report:
  `inst/sim/results/slice-929-first-wave-runner-five-surface-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Surfaces:
  `count_mu_random_effect_grid`, `gaussian_ls_grid`,
  `gaussian_mu_random_slope_grid`, `gaussian_sigma_random_slope_grid`,
  `meta_v_grid`
- Aggregate rows: 38.
- Manifest rows: 8.
- Failure rows: 0.
- Parallel-summary rows: 6.
- Actual worker counts: `1`, `3`, `1`, `1`, `1`, `1`.

The rendered report includes both Gaussian random-slope surfaces plus
`Run Manifest Summary`, `Interval Coverage Summary`, `Aggregate Bias Overview`,
and `Warning And Error Summary`.

## Mathematical Contract

No new likelihood or estimand was added. This integrates an already implemented
Gaussian `sigma` random-slope grid writer into the first-wave report runner.

## Team Learning

- Ada: the ordinary Gaussian mixed-model portion now covers location and scale
  random slopes in the shared first-wave report.
- Curie: runner row-count tests need to track every admitted surface added to
  the bundle.
- Fisher: the `sigma` random-slope surface contributes operating
  characteristics but no interval-coverage rows yet.
- Grace: bounded worker metadata remains visible after adding the surface.
- Pat: the report still gives one coherent surface list rather than separate
  ad hoc reports.
- Rose: this is a stronger staging baseline before deciding whether spatial
  should join.

## Known Limitations

- Coordinate spatial `mu` slopes, Student-t shape, and bivariate residual
  `rho12` remain outside this first-wave runner.
- The rendered smoke is one replicate per cell.

## Next Actions

1. Add coordinate spatial `mu` slopes next only if we want first-wave structured
   effects in the baseline report.
2. Keep Student-t shape and bivariate `rho12` staged separately because they
   carry more interval-specific complexity.
