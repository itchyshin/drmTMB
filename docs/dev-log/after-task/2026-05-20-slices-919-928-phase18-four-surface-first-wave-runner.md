# Slices 919-928: Phase 18 Four-Surface First-Wave Runner

## Goal

Ada added ordinary Gaussian `mu` random slopes to the reusable first-wave
summary runner.

## Implemented

`phase18_run_first_wave_summary_smoke()` now includes
`phase18_write_gaussian_mu_rs_grid_outputs()` beside the Gaussian
location-scale, `meta_V(V = V)`, and paired Poisson/NB2 `mu` random-effect
surfaces.

The runner return object now includes `gaussian_mu_random_slope`, and the
parallel summary includes a `gaussian_mu_random_slope_grid` row.

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
  `inst/sim/results/slice-919-first-wave-runner-four-surface-smoke/`
- Rendered report:
  `inst/sim/results/slice-919-first-wave-runner-four-surface-smoke/first-wave-summary/report/phase18-first-wave-summary.html`
- Surfaces:
  `count_mu_random_effect_grid`, `gaussian_ls_grid`,
  `gaussian_mu_random_slope_grid`, `meta_v_grid`
- Aggregate rows: 33.
- Manifest rows: 7.
- Failure rows: 0.
- Parallel-summary rows: 5.
- Actual worker counts: `1`, `3`, `1`, `1`, `1`.

The rendered report includes the new Gaussian `mu` random-slope surface plus
`Run Manifest Summary`, `Interval Coverage Summary`, `Aggregate Bias Overview`,
and `Warning And Error Summary`.

## Mathematical Contract

No new likelihood or estimand was added. This integrates an already implemented
Gaussian `mu` random-slope grid writer into the first-wave report runner.

## Team Learning

- Ada: the first-wave runner can grow one admitted surface at a time.
- Curie: adding a surface should update both the runner and its row-count tests.
- Fisher: random-slope rows are operating-characteristic rows, not interval
  evidence unless the surface supplies interval artifacts.
- Grace: the multicore cap still applies through the shared runner.
- Pat: the report shows the added surface in the same table and summary
  structure as the earlier surfaces.
- Rose: this is the right scale of expansion before broad replicate increases.

## Known Limitations

- Gaussian `sigma` random slopes, coordinate spatial `mu` slopes, Student-t
  shape, and bivariate residual `rho12` are still outside this first-wave
  runner.
- The rendered smoke is one replicate per cell.

## Next Actions

1. Decide whether the next admitted surface should be Gaussian `sigma` random
   slopes or coordinate spatial `mu` slopes.
2. Keep Student-t shape and bivariate `rho12` separate until their interval
   evidence is intentionally staged.
