# Slices 979-988: Phase 18 Interval-Heavy Bootstrap Smoke

## Goal

Ada ran a tiny bootstrap-enabled interval-heavy smoke for Student-t shape and
bivariate residual `rho12`.

## Run

The run called `phase18_run_interval_heavy_summary_smoke()` with:

- `bootstrap_nsim = 2`;
- `bootstrap_level = 0.70`;
- `bootstrap_cores = 2`;
- `bootstrap_backend = "multicore"`;
- serial replicate execution;
- no profile.

## Validation

Output root:

- `inst/sim/results/slice-979-interval-heavy-bootstrap-smoke/`

Rendered report:

- `inst/sim/results/slice-979-interval-heavy-bootstrap-smoke/interval-heavy-summary/report/phase18-first-wave-summary.html`

Observed rows:

- Aggregate rows: 16.
- Bootstrap interval rows: 16.
- Bootstrap coverage rows: 16.
- Interval failure rows: 0.
- Failure rows: 0.
- Bootstrap statuses: `ok`.
- Bootstrap method: `parametric_bootstrap`.

The rendered report includes `parametric_bootstrap` evidence and the
interval-coverage summary.

## Mathematical Contract

No code changed in this slice. The run validates the existing parametric
bootstrap path through the interval-heavy summary runner.

## Team Learning

- Ada: the interval-heavy runner can stage bootstrap evidence without joining
  the baseline first-wave bundle.
- Curie: `bootstrap_nsim = 2` is enough to validate table plumbing but not
  enough for inference.
- Fisher: bootstrap rows remain method-labelled and separate from Wald/profile
  evidence.
- Grace: serial replicate execution avoided nested multicore while bootstrap
  used two workers.
- Pat: the report exposes bootstrap evidence in the same interval-coverage
  summary.
- Rose: this satisfies the bootstrap smoke promise without overstating
  uncertainty quality.

## Known Limitations

- `bootstrap_nsim = 2` is plumbing evidence only.
- No final bootstrap uncertainty claim should use this smoke.

## Next Actions

1. Add tested runner-level bootstrap coverage only if the added runtime remains
   acceptable.
2. For real reports, choose a bootstrap replicate count large enough for stable
   interval quantiles.
