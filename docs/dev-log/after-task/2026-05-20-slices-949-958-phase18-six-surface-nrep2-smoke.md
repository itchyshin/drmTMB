# Slices 949-958: Phase 18 Six-Surface n_rep = 2 Smoke

## Goal

Ada ran the six-surface first-wave summary runner at `n_rep = 2` with bounded
multicore execution.

## Run

The run called `phase18_run_first_wave_summary_smoke()` with:

- `n_rep = 2`;
- `backend = "multicore"`;
- `cores = 3`;
- `render = TRUE`.

The included surfaces were Gaussian location-scale, `meta_V(V = V)`, paired
Poisson/NB2 `mu` random effects, ordinary Gaussian `mu` random slopes, ordinary
Gaussian `sigma` random slopes, and coordinate-spatial Gaussian `mu` slopes.

## Validation

Output root:

- `inst/sim/results/slice-949-first-wave-runner-six-surface-nrep2-smoke/`

Rendered report:

- `inst/sim/results/slice-949-first-wave-runner-six-surface-nrep2-smoke/first-wave-summary/report/phase18-first-wave-summary.html`

Observed rows:

- Aggregate rows: 43.
- Manifest rows: 18.
- Manifest warning total: 1.
- Failure rows: 1.
- Wald coverage rows: 19.
- Profile coverage rows: 4.
- Parallel-summary rows: 7.
- Actual worker counts: `2`, `3`, `2`, `2`, `2`, `2`, `2`.

The rendered report includes `Run Manifest Summary`,
`Interval Coverage Summary`, `Aggregate Bias Overview`, and
`Warning And Error Summary`.

Focused first-wave validation:

```sh
Rscript -e "devtools::test(filter = '^phase18-first-wave')"
```

Result:

- 115 expectations passed, 0 failures, 0 warnings, 0 skips.

## Mathematical Contract

No code changed in this slice. This run validates the six-surface first-wave
runner introduced over Slices 899-948.

## Team Learning

- Ada: the six-surface bundle is stable enough for smoke-scale rendered report
  checks.
- Curie: doubling replicates raises manifest rows as expected while preserving
  aggregate row shape.
- Fisher: Wald/profile coverage remains method-separated, and profile rows are
  present in this seed.
- Grace: actual workers stayed below the 10-core cap.
- Pat: all report summaries remain visible with six surfaces.
- Rose: Student-t shape and bivariate `rho12` should remain separate because
  they carry profile/bootstrap-specific complexity.

## Known Limitations

- This is smoke-scale validation, not final simulation evidence.
- Student-t shape and bivariate residual `rho12` remain separate
  interval-heavy lanes.

## Next Actions

1. Run a focused first-wave test bundle after this larger smoke.
2. Stage Student-t shape and bivariate `rho12` separately rather than folding
   them into this baseline runner by default.
