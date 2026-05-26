# Phase 18 First-Wave Summary Runner Revalidation Slices 899-908

Reader: `drmTMB` contributors checking that the reusable first-wave summary
smoke runner still records requested and actual worker counts.

This is a current-state revalidation of Slices 899-908. The original May 20
after-task note introduced `phase18_run_first_wave_summary_smoke()` for the
then-current three-surface first-wave bundle. The current source has since
expanded that private runner to include seven surface rows in its parallel
summary: Gaussian location-scale, `meta_V(V = V)`, Poisson `mu` random effects,
NB2 `mu` random effects, Gaussian `mu` random slopes, Gaussian `sigma` random
slopes, and spatial `mu` slopes. The validation claim here is runner plumbing,
not a new admitted-surface or final simulation claim.

## Source Evidence

- `phase18_run_first_wave_summary_smoke()` validates `output_dir`, `n_rep`,
  `master_seed`, and optional `notes`.
- The runner writes the first-wave summary report through
  `phase18_render_first_wave_summary_report()`.
- The runner writes `first-wave-parallel-summary.csv`.
- `phase18_first_wave_parallel_summary()` builds one row per current surface
  entry, and `phase18_parallel_summary_row()` records `backend`,
  `requested_cores`, and actual `cores`.
- The focused test confirms the runner stages outputs, writes the parallel
  summary CSV, returns seven surface rows in the current expanded bundle, clamps
  actual workers to one under `backend = "none"`, writes report status and table
  artifacts, and rejects malformed inputs.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 899-901 | Revalidate private runner entry point and input checks | Source read and tests passed |
| 902-904 | Revalidate requested-versus-actual worker summary | Source read and tests passed |
| 905-906 | Revalidate report artifact staging | Focused tests passed |
| 907-908 | Record current expanded-surface boundary | After-task audit passed |

## Commands

```sh
sed -n '1,130p' docs/dev-log/after-task/2026-05-20-slices-899-908-phase18-first-wave-smoke-runner.md
sed -n '685,698p' docs/design/41-phase-18-simulation-programme.md
nl -ba inst/sim/run/sim_run_first_wave_summary_smoke.R | sed -n '1,220p'
nl -ba inst/sim/run/sim_run_first_wave_summary_smoke.R | sed -n '197,270p'
nl -ba tests/testthat/test-phase18-first-wave-summary-smoke-runner.R | sed -n '55,125p'
Rscript -e "devtools::test(filter = 'phase18-(first-wave-summary-report|first-wave-summary-render-helper|first-wave-summary-smoke-runner)', reporter = 'summary')"
```

## Result

The focused first-wave summary-report, render-helper, and summary-smoke-runner
tests completed with exit code 0. Current source reads show the runner writes a
report, writes `first-wave-parallel-summary.csv`, and records `backend`,
`requested_cores`, and actual `cores`. The current test expects seven surface
rows and actual worker counts of one under `backend = "none"`. This closes the
current-state revalidation only. It does not add likelihoods, formula grammar,
public API, roxygen topics, pkgdown navigation, or formal simulation claims.
