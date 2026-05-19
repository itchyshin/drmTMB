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

Slice 292 starts the comprehensive design as a blueprint, not as a full grid.
The scenario map in `docs/design/41-phase-18-simulation-programme.md` decides
which continuous, proportion, count, ordinal, meta-analysis, bivariate,
random-slope, shape, phylogenetic, spatial, `animal()`, and `relmat()` lanes
are admitted, opt-in, design-only, or failure-ledger only before new DGP files
are added here.

Current pilot files:

- `dgp/sim_dgp_gaussian_ls.R` generates Gaussian location-scale data with
  `mu ~ x` and `sigma ~ z`.
- `dgp/sim_dgp_gaussian_mu_random_slope.R` generates Gaussian `mu` data with
  one q=3 grouped random-slope block, `(1 + x1 + x2 | id)`.
- `dgp/sim_dgp_gaussian_sigma_random_slope.R` generates Gaussian
  residual-scale data with one independent `log(sigma)` random slope,
  `(0 + w | id)`.
- `dgp/sim_dgp_spatial_mu_slope.R` generates Gaussian spatial `mu` data with
  independent coordinate-spatial intercept and slope fields,
  `spatial(1 + x | site, coords = coords)`.
- `dgp/sim_dgp_poisson_mu_random_effect.R` generates non-zero-inflated Poisson
  count data with ordinary log-mean random intercepts and independent numeric
  slopes, `(1 | id) + (0 + x | id)`, and its condition helper can cross
  group count, observations per group, fixed effects, and true random-effect
  SDs.
- `dgp/sim_dgp_nbinom2_mu_random_effect.R` generates non-zero-inflated NB2
  count data with ordinary log-mean random intercepts and independent numeric
  slopes, `(1 | id) + (0 + x | id)`, plus fixed-effect overdispersion
  `sigma ~ z`; its condition helper can also cross true overdispersion
  settings.
- `dgp/sim_dgp_meta_v.R` generates Gaussian meta-analysis data with vector or
  dense known sampling covariance via `meta_V(V = V)`.
- `fit/sim_summarise_gaussian_ls.R` converts one fitted pilot model into a
  parameter-level truth/estimate/standard-error/error table.
- `fit/sim_summarise_meta_v.R` does the same for the `meta_V(V = V)` pilot,
  including standard errors for estimated `mu` coefficients and fitted
  residual `sigma`.
- `fit/sim_summarise_gaussian_mu_random_slope.R` summarises fixed `mu`
  coefficients, public residual `sigma`, q=3 random-slope SDs, and q=3
  derived random-effect correlations for the ordinary Gaussian `mu`
  random-slope pilot.
- `fit/sim_summarise_gaussian_sigma_random_slope.R` summarises fixed `mu` and
  fixed `sigma` coefficients plus the direct residual-scale random-slope SD on
  the modelled `log(sigma)` scale.
- `fit/sim_summarise_spatial_mu_slope.R` summarises fixed `mu` coefficients,
  public residual `sigma`, and the two direct coordinate-spatial `mu` SDs for
  the intercept and slope fields.
- `fit/sim_summarise_poisson_mu_random_effect.R` summarises fixed Poisson
  `mu` coefficients and direct ordinary log-mean random-effect SDs.
- `fit/sim_summarise_nbinom2_mu_random_effect.R` summarises fixed NB2 `mu`
  and `sigma` coefficients plus direct ordinary log-mean random-effect SDs.
- `R/sim_runner.R` runs one cell replicate, captures warnings/errors, can save
  or resume an RDS result, can reload saved result directories, and can reduce
  result lists to compact manifests or warning/error ledgers.
- `R/sim_aggregate.R` reduces parameter-level replicate summaries to grouped
  bias, RMSE, convergence, Hessian, warning, and elapsed-time summaries.
- `R/sim_uncertainty.R` adds Monte Carlo uncertainty and explicit
  interval-coverage summaries, plus generic Wald interval-table helpers for
  summaries that already contain estimates and standard errors, including a
  Fisher-z back-transformed path for correlation summaries.
- `R/sim_plot_data.R` prepares plot-ready data tables for Phase 18 outputs,
  starting with paired Poisson/NB2 `mu` random-effect pilot summaries.
- `R/sim_gallery.R` writes plot-ready count-pilot CSV inputs and renders the
  first Florence-facing count-pilot gallery artifact from a pilot object.
- `run/sim_run_gaussian_ls_smoke.R` wires the Gaussian location-scale DGP,
  `drmTMB()` fit, summariser, registry, and replicate runner into one
  end-to-end smoke surface.
- `run/sim_run_gaussian_mu_random_slope_smoke.R` does the same for the ordinary
  Gaussian `mu` q=3 random-slope surface.
- `run/sim_run_gaussian_sigma_random_slope_smoke.R` does the same for the
  Gaussian `sigma` independent one-slope surface.
- `run/sim_run_spatial_mu_slope_smoke.R` does the same for the coordinate
  spatial Gaussian `mu` one-slope surface.
- `run/sim_run_poisson_mu_random_effect_smoke.R` does the same for the
  non-zero-inflated Poisson `mu` random-effect surface.
- `run/sim_run_nbinom2_mu_random_effect_smoke.R` does the same for the
  non-zero-inflated NB2 `mu` random-effect surface.
- `run/sim_run_meta_v_smoke.R` does the same for vector and dense
  `meta_V(V = V)` smoke cells.
- `run/sim_summary_gaussian_ls_smoke.R` runs a tiny Gaussian location-scale
  summary smoke grid and returns grouped bias, RMSE, MCSE, manifest,
  warning/error ledger, formula-coefficient Wald interval, and Wald coverage
  outputs.
- `run/sim_summary_gaussian_mu_random_slope_smoke.R` runs a tiny ordinary
  Gaussian `mu` q=3 random-slope summary smoke grid and returns grouped bias,
  RMSE, MCSE, manifest, and warning/error ledger outputs.
- `run/sim_summary_gaussian_sigma_random_slope_smoke.R` runs a tiny Gaussian
  `sigma` independent one-slope summary smoke grid and returns grouped bias,
  RMSE, MCSE, manifest, and warning/error ledger outputs.
- `run/sim_summary_spatial_mu_slope_smoke.R` runs a tiny coordinate spatial
  Gaussian `mu` one-slope summary smoke grid and returns grouped bias, RMSE,
  MCSE, manifest, and warning/error ledger outputs.
- `run/sim_summary_poisson_mu_random_effect_smoke.R` runs a tiny
  non-zero-inflated Poisson `mu` random-effect summary smoke grid and returns
  grouped bias, RMSE, MCSE, manifest, and warning/error ledger outputs.
- `run/sim_summary_nbinom2_mu_random_effect_smoke.R` runs a tiny
  non-zero-inflated NB2 `mu` random-effect summary smoke grid and returns
  grouped bias, RMSE, MCSE, manifest, warning/error ledger, formula-coefficient
  Wald interval, Wald coverage, direct random-effect SD profile interval, and
  profile coverage outputs.
- `run/sim_summary_count_mu_random_effect_pilot.R` runs the first paired
  Poisson/NB2 `mu` random-effect pilot, returning combined aggregate, manifest,
  failure-ledger, Wald interval, Wald coverage, profile interval, and profile
  coverage tables for count-family comparisons.
- `run/sim_render_count_mu_gallery_smoke.R` runs a tiny paired count pilot and
  renders the Florence-facing count-pilot gallery into a local output folder.
- `run/sim_summary_meta_v_smoke.R` does the same for vector and dense
  `meta_V(V = V)` smoke cells, including Wald interval and coverage outputs for
  estimated targets.
- `run/sim_interval_coverage_smoke.R` adds synthetic interval columns to
  parameter summaries so coverage-table plumbing can be tested before real
  interval methods are attached.
- `reports/phase18-smoke-report-template.Rmd` is the first reader-facing report
  template for smoke aggregate, manifest, and warning/error ledger outputs.
- `reports/phase18-count-mu-gallery.Rmd` is the first Florence-facing figure
  gallery template for paired Poisson/NB2 `mu` random-effect pilot outputs.
