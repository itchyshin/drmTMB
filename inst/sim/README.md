# Phase 18 Simulation Skeleton

This folder holds optional simulation infrastructure for Phase 18. It is not a
package dependency and it is not run as part of ordinary examples.

The layout follows the Phase 18 blueprint in
`docs/design/41-phase-18-simulation-programme.md`:

- `R/` contains small reusable helpers that CRAN-safe tests can source.
- `dgp/` will contain data-generating mechanisms.
- `fit/` will contain model-fitting wrappers.
- `run/` will contain resumable cell runners.
- `reports/` will contain rendered simulation reports.
- `results/` is reserved for ignored local or scheduled-run output.

Every simulation cell should have a stable cell id, explicit conditions,
replicate-level seeds, fit diagnostics, interval status, and enough metadata to
resume or audit a partial run.

Current pilot files:

- `dgp/sim_dgp_gaussian_ls.R` generates Gaussian location-scale data with
  `mu ~ x` and `sigma ~ z`.
- `dgp/sim_dgp_meta_v.R` generates Gaussian meta-analysis data with vector or
  dense known sampling covariance via `meta_V(V = V)`.
- `fit/sim_summarise_gaussian_ls.R` converts one fitted pilot model into a
  parameter-level truth/estimate/error table.
- `fit/sim_summarise_meta_v.R` does the same for the `meta_V(V = V)` pilot.
- `R/sim_runner.R` runs one cell replicate, captures warnings/errors, can save
  or resume an RDS result, can reload saved result directories, and can reduce
  result lists to compact manifests or warning/error ledgers.
- `R/sim_aggregate.R` reduces parameter-level replicate summaries to grouped
  bias, RMSE, convergence, Hessian, warning, and elapsed-time summaries.
- `R/sim_uncertainty.R` adds Monte Carlo uncertainty and explicit
  interval-coverage summaries, plus generic Wald interval-table helpers for
  summaries that already contain estimates and standard errors.
- `run/sim_run_gaussian_ls_smoke.R` wires the Gaussian location-scale DGP,
  `drmTMB()` fit, summariser, registry, and replicate runner into one
  end-to-end smoke surface.
- `run/sim_run_meta_v_smoke.R` does the same for vector and dense
  `meta_V(V = V)` smoke cells.
- `run/sim_summary_gaussian_ls_smoke.R` runs a tiny Gaussian location-scale
  summary smoke grid and returns grouped bias, RMSE, MCSE, manifest, and
  warning/error ledger outputs.
- `run/sim_summary_meta_v_smoke.R` does the same for vector and dense
  `meta_V(V = V)` smoke cells.
- `run/sim_interval_coverage_smoke.R` adds synthetic interval columns to
  parameter summaries so coverage-table plumbing can be tested before real
  interval methods are attached.
- `reports/phase18-smoke-report-template.Rmd` is the first reader-facing report
  template for smoke aggregate, manifest, and warning/error ledger outputs.
