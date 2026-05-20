# Slices 959-968: Phase 18 Interval-Heavy Summary Runner

## Goal

Ada staged Student-t shape and bivariate residual `rho12` in a separate
interval-heavy summary runner.

## Implemented

`inst/sim/run/sim_run_interval_heavy_summary_smoke.R` adds
`phase18_run_interval_heavy_summary_smoke()`. The runner executes:

- Student-t fixed-effect shape `nu`;
- bivariate Gaussian residual `rho12`.

It stages the same summary-report machinery used by the first-wave baseline
runner, but keeps these surfaces separate because they carry Wald, profile, and
bootstrap interval artifacts.

## Validation

Focused tests:

```sh
air format inst/sim/run/sim_run_interval_heavy_summary_smoke.R tests/testthat/test-phase18-interval-heavy-summary-smoke-runner.R
Rscript -e "devtools::test(filter = '^phase18-interval-heavy-summary-smoke-runner$')"
Rscript -e "devtools::test(filter = '^phase18-(first-wave|interval-heavy)')"
```

Result:

- 15 expectations passed, 0 failures, 0 warnings, 0 skips.
- The integrated first-wave plus interval-heavy staging bundle then passed 130
  expectations, 0 failures, 0 warnings, 0 skips.

Rendered smoke:

- Output root:
  `inst/sim/results/slice-959-interval-heavy-runner-smoke/`
- Rendered report:
  `inst/sim/results/slice-959-interval-heavy-runner-smoke/interval-heavy-summary/report/phase18-first-wave-summary.html`
- Surfaces: `biv_rho12_grid`, `student_shape_grid`
- Aggregate rows: 16.
- Manifest rows: 2.
- Failure rows: 0.
- Wald coverage rows: 16.
- Parallel-summary rows: 2.
- Actual worker counts: `1`, `1`.

The rendered report includes both interval-heavy surfaces plus
`Run Manifest Summary`, `Interval Coverage Summary`, `Aggregate Bias Overview`,
and `Warning And Error Summary`.

## Mathematical Contract

No likelihood, estimand, interval method, or report schema changed. This runner
orchestrates existing Student-t shape and bivariate `rho12` grid writers.

## Team Learning

- Ada: interval-heavy surfaces should have their own runner rather than being
  hidden in the baseline first-wave bundle.
- Curie: the same report staging works for these surfaces without schema
  changes.
- Fisher: default evidence is Wald-only; profile and bootstrap stay explicit
  opt-in runner arguments.
- Grace: the runner records requested and actual worker counts.
- Pat: the report makes the two interval-heavy surfaces visible without mixing
  them with the baseline six-surface smoke.
- Rose: this keeps earlier promises about Student-t shape and `rho12`
  simulation coverage alive without overclaiming final intervals.

## Known Limitations

- Profile and bootstrap intervals were not run in this default smoke.
- This is private `inst/sim/` infrastructure, not a public API.

## Next Actions

1. Run a tiny profile-enabled interval-heavy smoke when time allows.
2. Keep bootstrap smoke small and multicore-capped because it rebuilds many
   simulated fits.
