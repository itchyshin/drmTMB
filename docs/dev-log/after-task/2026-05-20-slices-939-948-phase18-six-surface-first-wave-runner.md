# Slices 939-948: Phase 18 Six-Surface First-Wave Runner

## Goal

Ada added coordinate-spatial Gaussian `mu` slopes to the reusable first-wave
summary runner.

## Implemented

`phase18_run_first_wave_summary_smoke()` now includes
`phase18_write_spatial_mu_slope_grid_outputs()` beside the Gaussian
location-scale, `meta_V(V = V)`, paired Poisson/NB2 `mu` random-effect,
ordinary Gaussian `mu` random-slope, and ordinary Gaussian `sigma` random-slope
surfaces.

The runner return object now includes `spatial_mu_slope`, and the parallel
summary includes a `spatial_mu_slope_grid` row.

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
  `inst/sim/results/slice-939-first-wave-runner-six-surface-smoke/`
- Rendered report:
  `inst/sim/results/slice-939-first-wave-runner-six-surface-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Surfaces:
  `count_mu_random_effect_grid`, `gaussian_ls_grid`,
  `gaussian_mu_random_slope_grid`, `gaussian_sigma_random_slope_grid`,
  `meta_v_grid`, `spatial_mu_slope_grid`
- Aggregate rows: 43.
- Manifest rows: 9.
- Failure rows: 0.
- Parallel-summary rows: 7.
- Actual worker counts: `1`, `3`, `1`, `1`, `1`, `1`, `1`.

The rendered report includes the spatial surface plus `Run Manifest Summary`,
`Interval Coverage Summary`, `Aggregate Bias Overview`, and
`Warning And Error Summary`.

## Mathematical Contract

No new likelihood or estimand was added. This integrates an already implemented
coordinate-spatial Gaussian `mu` slope grid writer into the first-wave report
runner.

## Team Learning

- Ada: the baseline first-wave report now includes ordinary, count,
  meta-analysis, and one spatial structured-effect surface.
- Curie: spatial can join the smoke runner without changing report schemas.
- Fisher: spatial rows are operating-characteristic rows here; they do not
  imply bivariate or phylogenetic correlation evidence.
- Grace: bounded worker metadata remains visible after adding a structured
  surface.
- Pat: the rendered report still surfaces the full list of included model
  classes.
- Rose: spatial is now represented, while phylo, animal, Student-t shape, and
  `rho12` remain intentionally separate.

## Known Limitations

- Phylogenetic, animal, Student-t shape, and bivariate residual `rho12` remain
  outside this baseline runner.
- The rendered smoke is one replicate per cell.

## Next Actions

1. Run the six-surface first-wave bundle at `n_rep = 2` if time permits.
2. Stage Student-t shape and bivariate `rho12` separately because they carry
   profile/bootstrap interval complexity.
