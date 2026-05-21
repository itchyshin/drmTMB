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

Phase 18 result artifacts now name their grain. Replicate-level tables use
`artifact_grain = "replicate"` and keep one row per simulation replicate and
parameter. Aggregate tables use `artifact_grain = "aggregate"` and carry
`n_replicate`, bias/RMSE, MCSEs, convergence, Hessian, warning, and elapsed
time summaries. Report templates may draw replicate-error clouds only from
replicate-level tables; aggregate-only inputs get points, bars, and MCSE
ranges. Grid-output writers return an `artifact_manifest` table with one row
per CSV artifact, file existence, and row counts; optional interval artifacts
that are present but empty are counted as zero rows. Manifests from multiple
grid-writer outputs can be bound and summarized by surface before a report
tries to read their tables, and
`run/sim_write_first_wave_artifact_status.R` writes those bound manifest and
status tables as first-wave report-staging artifacts. The matching
`reports/phase18-first-wave-status-report.Rmd` template reads those two files
before any larger simulation report tries to consume surface-specific tables.
`run/sim_write_first_wave_table_bundle.R` then combines selected artifact
tables across grid-writer outputs, adding source surface and artifact columns
as the leading columns so the next report can compare surfaces without
hand-binding CSVs. The
`reports/phase18-first-wave-summary-report.Rmd` skeleton reads those staged
tables into one reader-facing page, putting priority columns first and capping
displayed rows before any publication-style figures are added.
`run/sim_render_first_wave_summary_report.R` orchestrates the status writer,
table-bundle writer, and optional HTML summary render in one call.

Slice 292 starts the comprehensive design as a blueprint, not as a full grid.
The scenario map in `docs/design/41-phase-18-simulation-programme.md` decides
which continuous, proportion, count, ordinal, meta-analysis, bivariate,
random-slope, shape, phylogenetic, spatial, `animal()`, and `relmat()` lanes
are admitted, opt-in, design-only, or failure-ledger only before new DGP files
are added here.

Current pilot files:

- `docs/design/47-phase-18-gaussian-location-scale-ademp.md` is the first
  one-page ADEMP sheet for the admitted Gaussian location-scale lane.
- `docs/design/48-phase-18-meta-v-ademp.md` is the one-page ADEMP sheet for
  the admitted Gaussian `meta_V(V = V)` lane.
- `docs/design/49-phase-18-count-mu-random-effect-ademp.md` is the one-page
  ADEMP sheet for the paired Poisson/NB2 `mu` random-effect lane.
- `docs/design/50-phase-18-proportion-fixed-effect-ademp.md` is the one-page
  ADEMP sheet for the fixed-effect `beta()` and `beta_binomial()` lane.
- `docs/design/51-phase-18-ordinal-fixed-effect-ademp.md` is the one-page
  ADEMP sheet for the fixed-effect `cumulative_logit()` ordinal lane.
- `docs/design/52-phase-18-bivariate-rho12-ademp.md` is the one-page ADEMP
  sheet for the bivariate Gaussian residual `rho12` lane.
- `docs/design/53-phase-18-student-shape-ademp.md` is the one-page ADEMP
  sheet for the fixed-effect Student-t shape `nu` lane.
- `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md` is the
  one-page ADEMP sheet for the known-matrix animal/`relmat()` intercept and
  matching q=2 bivariate location-covariance lanes.
- `docs/design/56-phase-18-spatial-q2-ademp.md` is the one-page ADEMP sheet for
  the constant coordinate-spatial q=2 bivariate location-covariance lane.
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
- `dgp/sim_dgp_spatial_q2.R` generates bivariate Gaussian spatial `mu1`/`mu2`
  data with matching coordinate-spatial q=2 fields and residual `rho12` kept as
  a separate layer.
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
- `dgp/sim_dgp_biv_rho12.R` generates bivariate Gaussian data with
  response-specific `mu`, `sigma`, and residual-correlation `rho12 ~ w`
  predictors.
- `dgp/sim_dgp_student_shape.R` generates Student-t data with `mu ~ x`,
  `sigma ~ z`, and `nu ~ w`, using the fitted `nu = 2 + exp(eta_nu)` shape
  transform and optional mean-shape predictor correlation.
- `dgp/sim_dgp_animal_relmat_q2.R` generates bivariate Gaussian data with a
  known animal or lower-level relatedness matrix, matching q=2 `mu1`/`mu2`
  structured effects, and residual `rho12` kept as a separate layer.
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
- `fit/sim_summarise_spatial_q2.R` summarises fixed `mu1`/`mu2` coefficients,
  public residual scales, coordinate-spatial SDs, the spatial q=2 correlation,
  and residual `rho12` for bivariate spatial smoke fits.
- `fit/sim_summarise_poisson_mu_random_effect.R` summarises fixed Poisson
  `mu` coefficients and direct ordinary log-mean random-effect SDs.
- `fit/sim_summarise_nbinom2_mu_random_effect.R` summarises fixed NB2 `mu`
  and `sigma` coefficients plus direct ordinary log-mean random-effect SDs.
- `fit/sim_summarise_biv_rho12.R` summarises bivariate Gaussian fixed
  `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` coefficients on their fitted
  formula scales, adds optional profile and parametric-bootstrap interval
  columns, and includes a helper for named response-scale truth grids.
- `fit/sim_summarise_student_shape.R` summarises fixed Student-t `mu`,
  `sigma`, and `nu` coefficients on their fitted formula scales, adds optional
  profile and parametric-bootstrap interval columns, and includes a helper for
  named response-scale truth grids.
- `fit/sim_summarise_animal_relmat_q2.R` summarises fixed `mu1`/`mu2`
  coefficients, public residual scales, structured SDs, structured
  correlations, and residual `rho12` for known-matrix animal/`relmat()` q=2
  smoke fits.
- `R/sim_correlation_targets.R` classifies fitted `corpairs()` rows by their
  current profile route, keeping residual `rho12`, ordinary group, and
  phylogenetic correlations separate before simulation coverage is claimed.
- `R/sim_bootstrap.R` provides a private Phase 18 parametric-bootstrap refit
  harness, percentile interval summariser, and summary-column adapter for
  simulation studies; it records requested and actual core counts in draw and
  interval tables, and it does not change public `confint()` bootstrap support.
- `R/sim_runner.R` runs one cell replicate, captures warnings/errors, can save
  or resume an RDS result, can reload saved result directories, can bind
  replicate-level summaries, and can reduce result lists to compact manifests
  or warning/error ledgers. Its private bounded execution contract supports
  serial runs and Unix `multicore`, with actual workers capped at 10 and at the
  number of replicate jobs.
- `R/sim_aggregate.R` reduces parameter-level replicate summaries to grouped
  bias, RMSE, convergence, Hessian, warning, and elapsed-time summaries.
- `R/sim_uncertainty.R` adds Monte Carlo uncertainty and explicit
  interval-coverage summaries, plus generic Wald, profile, and interval-
  evidence table helpers for summaries that already contain estimates and
  standard errors, including a Fisher-z back-transformed path for correlation
  summaries, a failure ledger for interval rows whose status is not usable
  evidence, and interval-diagnostics summaries that separate usable coverage,
  misses, failures, and not-requested rows.
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
- `run/sim_run_spatial_q2_smoke.R` does the same for the coordinate-spatial
  q=2 bivariate location-covariance surface.
- `run/sim_run_poisson_mu_random_effect_smoke.R` does the same for the
  non-zero-inflated Poisson `mu` random-effect surface.
- `run/sim_run_nbinom2_mu_random_effect_smoke.R` does the same for the
  non-zero-inflated NB2 `mu` random-effect surface.
- `run/sim_run_meta_v_smoke.R` does the same for vector and dense
  `meta_V(V = V)` smoke cells.
- `run/sim_run_biv_rho12_smoke.R` does the same for the bivariate Gaussian
  residual-correlation surface.
- `run/sim_run_student_shape_smoke.R` does the same for the Student-t
  fixed-effect shape `nu` surface.
- `run/sim_run_animal_relmat_q2_smoke.R` does the same for the known-matrix
  animal/`relmat()` q=2 bivariate location-covariance surface.
- `run/sim_summary_spatial_q2_smoke.R` reduces the coordinate-spatial q=2
  smoke run into aggregate, replicate, manifest, failure-ledger, fixed-effect
  Wald interval, profile-status, interval-evidence, interval-diagnostics, and
  interval-failure tables.
- `run/sim_summary_animal_relmat_q2_smoke.R` reduces the animal/`relmat()`
  q=2 smoke run into aggregate, replicate, manifest, failure-ledger,
  fixed-effect Wald interval, profile-status, interval-evidence,
  interval-diagnostics, and interval-failure tables.
- `run/sim_write_spatial_q2_grid.R` writes those coordinate-spatial q=2 tables
  as repeatable CSV artifacts beside resumable per-replicate RDS files. Profile
  requests are optional; with `profile_parameters = character()`, spatial SDs,
  the spatial correlation, residual `rho12`, and residual `sigma1`/`sigma2`
  rows stay visible as `not_requested`.
- `run/sim_write_animal_relmat_q2_grid.R` writes those tables as repeatable
  CSV artifacts beside resumable per-replicate RDS files. Profile requests are
  optional; with `profile_parameters = character()`, structured SDs,
  structured correlations, residual `rho12`, and residual `sigma1`/`sigma2`
  rows stay visible as `not_requested`.
- `run/sim_summary_gaussian_ls_smoke.R` runs a tiny Gaussian location-scale
  summary smoke grid and returns grouped bias, RMSE, MCSE, manifest,
  warning/error ledger, formula-coefficient Wald interval, and Wald coverage
  outputs.
- `run/sim_write_gaussian_ls_grid.R` writes a repeatable Gaussian
  location-scale grid output folder with aggregate, replicate-level, manifest,
  failure, Wald-interval, and Wald-coverage CSVs beside the per-replicate RDS
  results, forwarding the private runner `cores` and `backend` settings.
- `run/sim_write_meta_v_grid.R` writes the same repeatable artifact set for
  the Gaussian `meta_V(V = V)` lane with vector and dense known sampling
  covariance cells.
- `run/sim_write_count_mu_random_effect_grid.R` writes the paired Poisson/NB2
  `mu` random-effect artifact set with Wald and direct-SD profile interval
  tables.
- `run/sim_write_gaussian_mu_random_slope_grid.R`,
  `run/sim_write_gaussian_sigma_random_slope_grid.R`, and
  `run/sim_write_spatial_mu_slope_grid.R` write simple aggregate,
  replicate-level, manifest, and failure-ledger artifact sets for the ordinary
  Gaussian `mu` random-slope, independent Gaussian `sigma` random-slope, and
  coordinate-spatial Gaussian `mu` slope lanes.
- `run/sim_write_biv_rho12_grid.R` writes the same artifact set for the
  bivariate Gaussian residual `rho12` grid, with optional profile,
  parametric-bootstrap, combined interval-evidence, interval-diagnostics, and
  interval-failure CSVs. Replicate-runner and bootstrap backends are separate
  so a run can parallelize one layer without nesting parallel work in both;
  the runner errors if both layers would use more than one worker.
- `run/sim_write_student_shape_grid.R` writes the same artifact set for the
  Student-t fixed-effect shape `nu` grid, with optional profile,
  parametric-bootstrap, combined interval-evidence, interval-diagnostics, and
  interval-failure CSVs. Replicate-runner and bootstrap backends are separate
  for the same reason as the bivariate `rho12` grid, with the same nested-
  parallel guard.
- `run/sim_write_first_wave_artifact_status.R` writes bound
  artifact-manifest and surface-status CSVs from multiple grid-writer outputs,
  giving report templates a small preflight table before they read individual
  simulation artifacts.
- `run/sim_write_first_wave_table_bundle.R` writes selected first-wave artifact
  tables combined across grid-writer outputs, preserving source surface and
  artifact names while filling missing columns.
- `run/sim_render_first_wave_summary_report.R` writes first-wave status and
  table-bundle artifacts, then optionally renders the first-wave summary report
  HTML from those staged CSVs.
- `run/sim_run_first_wave_summary_smoke.R` executes the current Gaussian
  location-scale, `meta_V(V = V)`, paired Poisson/NB2 `mu` random-effect, and
  ordinary Gaussian `mu` and `sigma` random-slope, and coordinate-spatial
  Gaussian `mu` slope first-wave smoke surfaces, stages the combined first-wave
  summary report, and records requested versus actual worker counts.
- `run/sim_run_interval_heavy_summary_smoke.R` executes the Student-t shape and
  bivariate residual `rho12` smoke surfaces as a separate interval-heavy report
  lane, keeping their Wald/profile/bootstrap artifacts out of the baseline
  first-wave runner.
- `run/sim_run_actions_cell.R` is the GitHub Actions entrypoint for manual
  long-run Phase 18 dispatch. It can run either the first-wave summary task or
  the interval-heavy task, writes an RDS result beside the task artifact
  tables, and caps requested replicate or bootstrap workers at 10 before
  dispatch. The workflow never uses both replicate-layer multicore and
  bootstrap-layer multicore at the same time.
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
- `run/sim_summary_biv_rho12_smoke.R` does the same for the bivariate
  Gaussian residual `rho12` smoke grid, including formula-coefficient Wald
  intervals, optional profile and parametric-bootstrap interval evidence, and
  coverage outputs.
- `run/sim_summary_student_shape_smoke.R` does the same for the Student-t
  fixed-effect shape `nu` smoke grid, including formula-coefficient Wald
  intervals, optional profile and parametric-bootstrap interval evidence,
  coverage outputs, and interval-failure ledgers.
- `run/sim_interval_coverage_smoke.R` adds synthetic interval columns to
  parameter summaries so coverage-table plumbing can be tested before real
  interval methods are attached.
- `reports/phase18-smoke-report-template.Rmd` is the first reader-facing report
  template for smoke aggregate, manifest, and warning/error ledger outputs.
- `reports/phase18-first-wave-status-report.Rmd` is the first report-staging
  template for checking bound artifact-manifest and surface-status CSVs before
  larger first-wave reports read individual simulation artifacts.
- `reports/phase18-first-wave-summary-report.Rmd` is the first table-first
  summary skeleton for artifact status, aggregate operating-characteristic
  rows, a compact aggregate-bias overview, interval coverage, interval
  diagnostics, interval failures, run-manifest summaries, manifests, compact
  warning/error summaries, and full warning/error ledgers.
- `reports/phase18-count-mu-gallery.Rmd` is the first Florence-facing figure
  gallery template for paired Poisson/NB2 `mu` random-effect pilot outputs.
