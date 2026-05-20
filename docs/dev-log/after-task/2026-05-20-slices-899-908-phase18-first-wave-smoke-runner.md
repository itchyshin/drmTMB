# Slices 899-908: Phase 18 First-Wave Summary Smoke Runner

## Goal

Ada replaced the repeated manual first-wave smoke script with a reusable
private runner.

## Implemented

`inst/sim/run/sim_run_first_wave_summary_smoke.R` adds
`phase18_run_first_wave_summary_smoke()`. The runner executes the current
three-surface first-wave smoke bundle:

- Gaussian location-scale;
- Gaussian `meta_V(V = V)`;
- paired Poisson/NB2 `mu` random effects.

It then stages the combined first-wave summary report and writes
`first-wave-parallel-summary.csv` with backend, requested core count, and actual
worker count for each surface path.

## Validation

Focused tests:

```sh
air format inst/sim/run/sim_run_first_wave_summary_smoke.R tests/testthat/test-phase18-first-wave-summary-smoke-runner.R
Rscript -e "devtools::test(filter = '^phase18-first-wave-summary-smoke-runner$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner)$')"
```

Result:

- 15 expectations passed, 0 failures, 0 warnings, 0 skips.
- The broader first-wave report/render-helper/smoke-runner bundle then passed
  63 expectations, 0 failures, 0 warnings, 0 skips.

The test stages outputs with `render = FALSE`, checks the parallel summary CSV,
checks aggregate and interval-coverage artifacts, and validates malformed
inputs.

## Mathematical Contract

No simulation estimand, DGP, likelihood, interval method, or report table
schema changed. This is orchestration infrastructure for already implemented
first-wave writers.

## Team Learning

- Ada: repeated long smoke commands should become private runners before grids
  grow.
- Curie: profile coverage row counts can vary under smoke seeds, so tests now
  require nonzero profile coverage instead of one brittle exact count.
- Fisher: method-specific coverage artifacts remain separate.
- Grace: requested and actual worker counts are recorded in a small CSV.
- Rose: this closes the manual-command repetition risk before larger
  first-wave runs.

## Known Limitations

- This runner covers the current three-surface bundle only.
- It is private `inst/sim/` infrastructure, not a public API.
- It does not yet run Student-t shape, bivariate `rho12`, random-slope, or
  spatial first-wave surfaces.

## Next Actions

1. Use the runner for the next `n_rep = 2` rendered smoke instead of the manual
   script.
2. Decide which additional admitted surface should join the first-wave bundle
   next.
