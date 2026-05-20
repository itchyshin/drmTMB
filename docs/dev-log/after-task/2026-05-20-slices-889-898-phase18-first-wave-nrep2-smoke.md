# Slices 889-898: Phase 18 First-Wave n_rep = 2 Staging Smoke

## Goal

Ada ran a slightly larger first-wave staging smoke after the report summaries
stabilised.

## Run

The smoke combined three first-wave surfaces:

- Gaussian location-scale;
- Gaussian `meta_V(V = V)`;
- paired Poisson/NB2 `mu` random effects.

Each surface used `n_rep = 2`, `backend = "multicore"`, and `cores = 3`. Actual
worker counts stayed under the requested 10-core cap.

## Validation

Output root:

- `inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/`

Rendered report:

- `inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/first-wave-summary/report/phase18-first-wave-summary.html`

Observed rows:

- Aggregate rows: 23.
- Manifest rows: 12.
- Manifest warning total: 1.
- Failure rows: 1.
- Wald coverage rows: 19.
- Profile coverage rows: 4.
- Actual worker counts by surface path: `2`, `3`, `2`, `2`.

The rendered report includes `Run Manifest Summary`,
`Interval Coverage Summary`, `Aggregate Bias Overview`, and
`Warning And Error Summary`.

## Mathematical Contract

No package code changed in this slice. This is validation evidence for the
first-wave staging report and bounded multicore execution.

## Team Learning

- Ada: the report still works once the smoke has multiple replicates per cell.
- Curie: the first-wave staging path can handle a modest increase in replicate
  count without changing code.
- Fisher: coverage rows remain method-separated at `n_rep = 2`.
- Grace: actual workers stayed below the 10-core limit.
- Pat: the rendered report sections remain visible in the larger smoke.
- Rose: this is still staging evidence and should not be inflated into final
  operating-characteristic claims.

## Known Limitations

- Two replicates per cell are not enough for final bias, RMSE, or coverage
  claims.
- The count warning remains present and visible.
- The generated result artifacts are ignored local outputs.

## Next Actions

1. Consider adding a reusable first-wave smoke runner script so the long manual
   smoke command is not repeated.
2. Then decide whether to expand replicate counts or add more first-wave
   surfaces.
