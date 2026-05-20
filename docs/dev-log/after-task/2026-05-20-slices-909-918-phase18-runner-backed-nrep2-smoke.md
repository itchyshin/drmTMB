# Slices 909-918: Phase 18 Runner-Backed n_rep = 2 Smoke

## Goal

Ada validated the reusable first-wave summary smoke runner on a rendered
`n_rep = 2` multicore smoke.

## Run

The run called `phase18_run_first_wave_summary_smoke()` with:

- `n_rep = 2`;
- `backend = "multicore"`;
- `cores = 3`;
- `render = TRUE`.

## Validation

Output root:

- `inst/sim/results/slice-909-first-wave-runner-nrep2-smoke/`

Rendered report:

- `inst/sim/results/slice-909-first-wave-runner-nrep2-smoke/first-wave-summary/report/phase18-first-wave-summary.html`

Observed rows:

- Aggregate rows: 23.
- Manifest rows: 12.
- Manifest warning total: 2.
- Failure rows: 2.
- Wald coverage rows: 19.
- Profile coverage rows: 3.
- Requested worker counts: `3`, `3`, `3`, `3`.
- Actual worker counts: `2`, `3`, `2`, `2`.

The rendered report includes `Run Manifest Summary`,
`Interval Coverage Summary`, `Aggregate Bias Overview`, and
`Warning And Error Summary`.

## Mathematical Contract

No code changed in this slice. The run validates the reusable runner introduced
in Slices 899-908.

## Team Learning

- Ada: the new runner reproduces the manual staging workflow with less room for
  transcription errors.
- Curie: profile coverage rows remain seed-sensitive at this smoke scale.
- Fisher: Wald and profile evidence stay method-separated in the report.
- Grace: requested and actual worker counts are recorded and stay below the
  10-core limit.
- Pat: the rendered report remains readable with doubled replicate count.
- Rose: the warning count increased from the previous seed, which confirms why
  warning summaries should stay prominent.

## Known Limitations

- This is still smoke-scale evidence, not final Phase 18 simulation output.
- The generated artifacts are ignored local results.

## Next Actions

1. Add one more admitted first-wave surface through a grid writer before
   increasing replicate counts much further.
2. Keep the current three-surface runner stable as the baseline smoke.
