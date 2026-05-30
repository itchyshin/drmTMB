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
- `docs/design/58-phase-18-animal-relmat-q4-ademp.md` is the focused addendum
  for the constant all-four animal/`relmat()` q=4 location-scale smoke lane
  and its derived-correlation interval boundary.
- `docs/design/56-phase-18-spatial-q2-ademp.md` is the one-page ADEMP sheet for
  the constant coordinate-spatial q=2 bivariate location-covariance lane.
- `docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md` is the
  one-page ADEMP sheet for the ordinary NB2 log-`sigma` random-intercept smoke
  lane.
- `docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md` is the one-page ADEMP
  sheet for the overdispersion-aware NB2 phylogenetic q=1 `mu` formal-admission
  lane.
- `docs/design/75-phase-18-nbinom2-phylo-q1-formal-audit.md` records the local
  NB2 q1 all-cell formal sentinel, representative 5-replicate audit, and
  `hold_smoke_only` promotion decision before the 500-replicate gate.
- `docs/design/76-phase-18-nbinom2-phylo-q1-sharded-formal-grid.md` records
  the cancelled single-job formal dispatch, runtime estimate, and shard
  contract for the 500-replicate NB2 q1 formal grid.
- `docs/design/79-supported-nongaussian-evidence-goal.md` records the
  supported non-Gaussian evidence closeout goal, separating fixed-effect family
  evidence, count mixed-model first slices, q=1 phylogenetic formal gates, and
  blocked neighbouring routes.
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
  records the breadth-first Phase 18 order across counts, proportions,
  positive-continuous responses, ordinal responses, and shape families.
- `docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md`
  records the DGP, smoke, grid, first-wave, and Actions artifact lane for
  fixed-effect `beta()` and `beta_binomial()` models.
- `docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md`
  records the same artifact path for fixed-effect `lognormal()` and
  `Gamma(link = "log")` models.
- `docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md`
  records the same artifact path for fixed-effect `cumulative_logit()` models.
- `docs/design/115-phase-18-zero-one-beta-fixed-effect-artifacts-slices-1339-1348.md`
  records the same artifact path for fixed-effect `zero_one_beta()` models.
- `docs/design/117-phase-18-bounded-response-mu-random-intercept-artifacts-slices-1359-1368.md`
  records the artifact path for ordinary `mu` random intercepts in `beta()`
  and `beta_binomial()` models.
- `docs/design/118-phase-18-positive-continuous-mu-random-intercept-artifacts-slices-1369-1378.md`
  records the artifact path for ordinary `mu` random intercepts in
  `lognormal()` and `Gamma(link = "log")` models.
- `docs/design/119-phase-18-student-mu-random-intercept-artifacts-slices-1379-1388.md`
  records the artifact path for ordinary `mu` random intercepts in
  `student()` models with fixed-effect `sigma` and `nu` formulas.
- `docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md`
  records the opt-in artifact path for ordinary Poisson/NB2 q=1
  `spatial()`, `animal()`, and `relmat()` `mu` intercepts, including the
  pre-grid boundary gate that must be checked before larger pilots become
  recovery or coverage evidence.
- `docs/design/135-phase-18-count-structured-q1-next-pilot-slices-1743-1750.md`
  specifies the next 24-cell x 10-replicate diagnostic pilot for that count
  structured q=1 lane, including dispatch inputs, runtime boundaries,
  no-profile interval policy, helper audit, and reporting requirements.
- `docs/design/136-phase-18-count-structured-q1-pilot-audit-slices-1751-1752.md`
  audits that pilot and records the boundary-gate decision
  `hold_diagnostic`, driven by SD-boundary warnings rather than by a Hessian
  rate or unexplained warning-ledger failure.
- `docs/design/137-phase-18-count-structured-q1-followup-condition-sets-slices-1753-1760.md`
  splits the same 24 cells into executable `stable`, `stable_watch`, and
  `boundary_stress` condition sets for the next diagnostic dispatch.
- `docs/design/138-phase-18-count-structured-q1-stable-diagnostic-audit-slices-1761-1762.md`
  audits the first `condition_set = "stable"` Actions run and records the
  `propose_next_pilot` decision for a separate stable formal-pilot design.
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
- `dgp/sim_dgp_biv_gaussian_mu_slope.R` generates bivariate Gaussian
  `mu1`/`mu2` data with matching ordinary slope-only random-effect blocks,
  `(0 + x | p | id)`, and residual `rho12` kept as a separate layer.
- `dgp/sim_dgp_poisson_mu_random_effect.R` generates non-zero-inflated Poisson
  count data with ordinary log-mean random intercepts and independent numeric
  slopes, `(1 | id) + (0 + x | id)`, and its condition helper can cross
  group count, observations per group, fixed effects, and true random-effect
  SDs.
- `dgp/sim_dgp_poisson_phylo_q1.R` generates non-zero-inflated Poisson count
  data with one q=1 phylogenetic log-mean intercept,
  `phylo(1 | species, tree = tree)`, and its condition helper can cross
  species count, observations per species, true phylogenetic SD, mean count,
  slope, and tree shape.
- `dgp/sim_dgp_nbinom2_mu_random_effect.R` generates non-zero-inflated NB2
  count data with ordinary log-mean random intercepts and independent numeric
  slopes, `(1 | id) + (0 + x | id)`, plus fixed-effect overdispersion
  `sigma ~ z`; its condition helper can also cross true overdispersion
  settings.
- `dgp/sim_dgp_nbinom2_sigma_random_effect.R` generates non-zero-inflated NB2
  count data with fixed-effect log-mean `mu` and an ordinary grouped
  log-`sigma` random intercept, `sigma ~ z + (1 | id)`. Its condition helper
  crosses group count, repeats, mean count, baseline overdispersion, and the
  true grouped overdispersion SD.
- `dgp/sim_dgp_nbinom2_phylo_q1.R` generates non-zero-inflated NB2 count data
  with one q=1 phylogenetic log-mean intercept,
  `phylo(1 | species, tree = tree)`, fixed-effect log-`sigma`
  overdispersion, and tree-shape conditions for the formal-admission lane.
- `dgp/sim_dgp_count_structured_q1.R` generates non-zero-inflated Poisson and
  NB2 count data with one q=1 coordinate-spatial, animal-model, or `relmat()`
  log-mean intercept and fixed-effect NB2 log-`sigma` when needed.
- `dgp/sim_dgp_truncated_nbinom2_mu_random_intercept.R` generates positive
  zero-truncated NB2 count data with one ordinary grouped `mu` random
  intercept, `mu ~ x + (1 | id)`, and fixed-effect `sigma ~ z`.
- `dgp/sim_dgp_proportion_fixed_effect.R` generates strict continuous
  `beta()` proportions and denominator-aware `beta_binomial()` successes with
  fixed-effect `mu ~ x` and `sigma ~ z`.
- `dgp/sim_dgp_bounded_response_mu_random_intercept.R` generates strict
  continuous `beta()` proportions and denominator-aware `beta_binomial()`
  successes with one ordinary grouped `mu` random intercept,
  `mu ~ x + (1 | id)`, and fixed-effect `sigma ~ z`.
- `dgp/sim_dgp_positive_continuous_fixed_effect.R` generates positive
  `lognormal()` and `Gamma(link = "log")` responses with fixed-effect `mu ~ x`
  and `sigma ~ z`.
- `dgp/sim_dgp_tweedie_fixed_effect.R` generates non-negative
  semicontinuous `tweedie()` responses with fixed-effect `mu ~ x`,
  `sigma ~ z`, intercept-only `nu ~ 1`, and low- or high-zero regimes.
- `dgp/sim_dgp_positive_continuous_mu_random_intercept.R` generates positive
  `lognormal()` and `Gamma(link = "log")` responses with one ordinary grouped
  `mu` random intercept, `mu ~ x + (1 | id)`, and fixed-effect `sigma ~ z`.
- `dgp/sim_dgp_student_mu_random_intercept.R` generates Student-t responses
  with one ordinary grouped `mu` random intercept, `mu ~ x + (1 | id)`,
  fixed-effect `sigma ~ z`, and fixed-effect `nu ~ 1` using
  `nu = 2 + exp(eta_nu)`.
- `dgp/sim_dgp_ordinal_fixed_effect.R` generates ordered-category
  `cumulative_logit()` responses with latent `mu ~ x`, ordered cutpoints, and
  no free location intercept.
- `dgp/sim_dgp_zero_one_beta_fixed_effect.R` generates continuous
  proportions on `[0, 1]` with fixed-effect interior `mu ~ x`,
  interior `sigma ~ z`, exact-boundary probability `zoi ~ w`, and
  conditional-one probability `coi ~ v`.
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
- `dgp/sim_dgp_animal_relmat_q4.R` generates bivariate Gaussian data with a
  known animal or lower-level relatedness matrix, matching q=4 `mu1`/`mu2`/
  `sigma1`/`sigma2` structured effects, and residual `rho12` kept separate
  from the six latent endpoint correlations.
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
- `fit/sim_summarise_truncated_nbinom2_mu_random_intercept.R` summarises fixed
  zero-truncated NB2 `mu` and `sigma` coefficients plus the direct ordinary
  positive-count `mu` random-intercept SD on the public SD scale.
- `fit/sim_summarise_proportion_fixed_effect.R` summarises fixed `beta()` and
  `beta_binomial()` `mu` and `sigma` coefficients on their link scales.
- `fit/sim_summarise_bounded_response_mu_random_intercept.R` summarises
  fixed `beta()` and `beta_binomial()` `mu` and `sigma` coefficients plus the
  direct ordinary logit-mean random-intercept SD on the public SD scale.
- `fit/sim_summarise_positive_continuous_fixed_effect.R` summarises fixed
  `lognormal()` and `Gamma(link = "log")` `mu` and `sigma` coefficients on
  their documented link scales.
- `fit/sim_summarise_tweedie_fixed_effect.R` summarises fixed `tweedie()`
  `mu`, public-`sigma`, and intercept-only `nu` coefficients on their formula
  scales while carrying response-scale power and observed-zero diagnostics.
- `fit/sim_summarise_positive_continuous_mu_random_intercept.R` summarises
  fixed `lognormal()` and `Gamma(link = "log")` `mu` and `sigma` coefficients
  plus the direct ordinary positive-continuous `mu` random-intercept SD on the
  public SD scale.
- `fit/sim_summarise_student_mu_random_intercept.R` summarises fixed
  Student-t `mu`, `sigma`, and `nu` coefficients plus the direct ordinary
  Student-t `mu` random-intercept SD on the public SD scale.
- `fit/sim_summarise_ordinal_fixed_effect.R` summarises the identifiable
  cumulative-logit `mu` slope and ordered cutpoints.
- `fit/sim_summarise_zero_one_beta_fixed_effect.R` summarises fixed
  `zero_one_beta()` `mu`, `sigma`, `zoi`, and `coi` coefficients on their
  documented link scales.
- `fit/sim_summarise_spatial_mu_slope.R` summarises fixed `mu` coefficients,
  public residual `sigma`, and the two direct coordinate-spatial `mu` SDs for
  the intercept and slope fields.
- `fit/sim_summarise_spatial_q2.R` summarises fixed `mu1`/`mu2` coefficients,
  public residual scales, coordinate-spatial SDs, the spatial q=2 correlation,
  and residual `rho12` for bivariate spatial smoke fits.
- `fit/sim_summarise_poisson_mu_random_effect.R` summarises fixed Poisson
  `mu` coefficients and direct ordinary log-mean random-effect SDs.
- `fit/sim_summarise_poisson_phylo_q1.R` summarises fixed Poisson `mu`
  coefficients, the direct phylogenetic `mu` SD, profile-target status, and
  phylogenetic diagnostic status for the q=1 route.
- `fit/sim_summarise_nbinom2_mu_random_effect.R` summarises fixed NB2 `mu`
  and `sigma` coefficients plus direct ordinary log-mean random-effect SDs.
- `fit/sim_summarise_nbinom2_sigma_random_effect.R` summarises fixed NB2
  `mu`, fixed NB2 `sigma`, the direct ordinary log-`sigma` random-intercept
  SD, direct `log_sd_sigma` profile-target status, and `check_drm()`
  replication status.
- `fit/sim_summarise_count_structured_q1.R` summarises fixed Poisson/NB2 `mu`
  coefficients, fixed NB2 `sigma` coefficients when present, direct
  structured `mu` SDs, direct `log_sd_phylo` profile-target status, and
  marker-specific diagnostic status for q=1 `spatial()`, `animal()`, and
  `relmat()` count routes. It also carries fit-level Hessian and
  random-effect-SD boundary status so boundary-sensitive smoke replicates are
  visible in the replicate table.
- `fit/sim_summarise_biv_rho12.R` summarises bivariate Gaussian fixed
  `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` coefficients on their fitted
  formula scales, adds optional profile and parametric-bootstrap interval
  columns, and includes a helper for named response-scale truth grids.
- `fit/sim_summarise_biv_gaussian_mu_slope.R` summarises bivariate Gaussian
  fixed `mu1`/`mu2` coefficients, public residual scales, residual `rho12`,
  ordinary slope-only SDs, and the slope-slope `corpairs()` correlation.
- `fit/sim_summarise_student_shape.R` summarises fixed Student-t `mu`,
  `sigma`, and `nu` coefficients on their fitted formula scales, adds optional
  profile and parametric-bootstrap interval columns, and includes a helper for
  named response-scale truth grids.
- `fit/sim_summarise_animal_relmat_q2.R` summarises fixed `mu1`/`mu2`
  coefficients, public residual scales, structured SDs, structured
  correlations, and residual `rho12` for known-matrix animal/`relmat()` q=2
  smoke fits.
- `fit/sim_summarise_animal_relmat_q4.R` summarises fixed `mu1`, `mu2`,
  `sigma1`, and `sigma2` coefficients, the four endpoint structured SDs, the
  six q=4 structured correlations, and residual `rho12`; requested q=4
  correlation intervals are marked as derived-unavailable rather than
  profile-ready.
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
- `run/sim_run_poisson_phylo_q1_smoke.R` does the same for the
  non-zero-inflated Poisson phylogenetic q=1 `mu` surface.
- `run/sim_run_nbinom2_mu_random_effect_smoke.R` does the same for the
  non-zero-inflated NB2 `mu` random-effect surface.
- `run/sim_run_count_structured_q1_smoke.R` does the same for the ordinary
  non-zero-inflated Poisson/NB2 q=1 `spatial()`, `animal()`, and `relmat()`
  `mu` intercept surface.
- `run/sim_run_nbinom2_sigma_random_effect_smoke.R` does the same for the
  non-zero-inflated NB2 log-`sigma` random-intercept surface.
- `run/sim_run_truncated_nbinom2_mu_random_intercept_smoke.R` does the same
  for the zero-truncated NB2 ordinary `mu` random-intercept surface.
- `run/sim_run_proportion_fixed_effect_smoke.R` does the same for the
  fixed-effect `beta()` and `beta_binomial()` proportion surface.
- `run/sim_run_bounded_response_mu_random_intercept_smoke.R` does the same for
  the ordinary bounded-response `mu` random-intercept surface for `beta()` and
  `beta_binomial()`.
- `run/sim_run_positive_continuous_fixed_effect_smoke.R` does the same for the
  fixed-effect `lognormal()` and `Gamma(link = "log")` positive-continuous
  surface.
- `run/sim_run_tweedie_fixed_effect_smoke.R` does the same for the
  fixed-effect `tweedie()` semicontinuous surface with intercept-only `nu`.
- `run/sim_run_positive_continuous_mu_random_intercept_smoke.R` does the same
  for the ordinary positive-continuous `mu` random-intercept surface for
  `lognormal()` and `Gamma(link = "log")`.
- `run/sim_run_student_mu_random_intercept_smoke.R` does the same for the
  ordinary Student-t `mu` random-intercept surface.
- `run/sim_run_ordinal_fixed_effect_smoke.R` does the same for the fixed-effect
  `cumulative_logit()` ordinal surface.
- `run/sim_run_zero_one_beta_fixed_effect_smoke.R` does the same for the
  fixed-effect `zero_one_beta()` exact-boundary bounded-response surface.
- `run/sim_run_meta_v_smoke.R` does the same for vector and dense
  `meta_V(V = V)` smoke cells.
- `run/sim_run_biv_rho12_smoke.R` does the same for the bivariate Gaussian
  residual-correlation surface.
- `run/sim_run_biv_gaussian_mu_slope_smoke.R` does the same for the matching
  bivariate Gaussian `mu1`/`mu2` slope-only surface.
- `run/sim_run_student_shape_smoke.R` does the same for the Student-t
  fixed-effect shape `nu` surface.
- `run/sim_run_animal_relmat_q2_smoke.R` does the same for the known-matrix
  animal/`relmat()` q=2 bivariate location-covariance surface.
- `run/sim_run_animal_relmat_q4_smoke.R` does the same for the constant
  all-four known-matrix animal/`relmat()` q=4 location-scale surface, using
  point-estimate smoke fits by default.
- `run/sim_summary_spatial_q2_smoke.R` reduces the coordinate-spatial q=2
  smoke run into aggregate, replicate, manifest, failure-ledger, fixed-effect
  Wald interval, profile-status, interval-evidence, interval-diagnostics, and
  interval-failure tables.
- `run/sim_summary_animal_relmat_q2_smoke.R` reduces the animal/`relmat()`
  q=2 smoke run into aggregate, replicate, manifest, failure-ledger,
  fixed-effect Wald interval, profile-status, interval-evidence,
  interval-diagnostics, and interval-failure tables.
- `run/sim_summary_animal_relmat_q4_smoke.R` reduces the animal/`relmat()`
  q=4 smoke run into aggregate, replicate, manifest, failure-ledger,
  profile-status, interval-evidence, interval-diagnostics, and
  interval-failure tables. The default smoke writes no Wald rows because the
  q=4 fits use `se = FALSE`.
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
- `run/sim_write_animal_relmat_q4_grid.R` writes the q=4 smoke tables as
  repeatable CSV artifacts. If a q=4 structured-correlation row is requested
  as a profile parameter, the artifact records
  `derived_interval_unavailable` instead of treating the derived correlation
  as a direct profile target.
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
- `run/sim_write_truncated_nbinom2_mu_random_intercept_grid.R` writes the
  zero-truncated NB2 `mu` random-intercept artifact set with aggregate,
  replicate-level, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct-SD profile interval, and profile coverage CSVs.
- `run/sim_write_proportion_fixed_effect_grid.R` writes the fixed-effect
  `beta()` and `beta_binomial()` artifact set with aggregate, replicate-level,
  manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage CSVs.
- `run/sim_write_bounded_response_mu_random_intercept_grid.R` writes the
  bounded-response `mu` random-intercept artifact set with aggregate,
  replicate-level, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct-SD profile interval, and profile coverage CSVs.
- `run/sim_write_positive_continuous_fixed_effect_grid.R` writes the
  fixed-effect `lognormal()` and `Gamma(link = "log")` artifact set with
  aggregate, replicate-level, manifest, failure-ledger, fixed-effect Wald
  interval, and Wald coverage CSVs.
- `run/sim_write_tweedie_fixed_effect_grid.R` writes the fixed-effect
  `tweedie()` semicontinuous artifact set with aggregate, replicate-level,
  manifest, failure-ledger, fixed-effect Wald interval, and Wald coverage
  CSVs.
- `run/sim_write_positive_continuous_mu_random_intercept_grid.R` writes the
  positive-continuous `mu` random-intercept artifact set with aggregate,
  replicate-level, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct-SD profile interval, and profile coverage CSVs.
- `run/sim_write_student_mu_random_intercept_grid.R` writes the Student-t
  `mu` random-intercept artifact set with aggregate, replicate-level,
  manifest, failure-ledger, fixed-effect Wald interval, Wald coverage,
  direct-SD profile interval, and profile coverage CSVs.
- `run/sim_write_ordinal_fixed_effect_grid.R` writes the fixed-effect
  `cumulative_logit()` ordinal artifact set with aggregate, replicate-level,
  manifest, failure-ledger, fixed-effect Wald interval, Wald coverage,
  cutpoint, and cutpoint-ordering CSVs.
- `run/sim_write_zero_one_beta_fixed_effect_grid.R` writes the fixed-effect
  `zero_one_beta()` artifact set with aggregate, replicate-level, manifest,
  failure-ledger, fixed-effect Wald interval, and Wald coverage CSVs.
- `run/sim_write_poisson_phylo_q1_grid.R` writes the ordinary Poisson
  phylogenetic q=1 `mu` smoke artifact set with aggregate, replicate-level,
  manifest, failure-ledger, fixed-effect Wald interval, Wald coverage, and
  direct `log_sd_phylo` profile-target CSVs beside per-replicate RDS results.
  Optional profile requests add profile-interval, profile-coverage,
  interval-evidence, interval-diagnostics, and interval-failure CSVs. The same
  file also provides the formal-grid wrapper, read-back QA, and promotion
  decision helpers; formal recovery or coverage claims still require the
  500-replicate gate and artifact review.
- `run/sim_write_nbinom2_phylo_q1_grid.R` writes the ordinary NB2 phylogenetic
  q=1 `mu` smoke artifact set with fixed-effect `sigma`, aggregate,
  replicate-level, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct `log_sd_phylo` profile-target, optional profile-interval,
  interval-evidence, interval-diagnostics, and interval-failure CSVs. Each
  replicate also records an ordinary grouped NB2 species-intercept comparator
  row, so overdispersion and unstructured species heterogeneity stay visible
  before formal recovery claims. Slices 541-555 wrote ignored local artifacts
  for a 288-cell one-replicate sentinel and a 24-cell x 5-replicate audit; both
  passed artifact QA but kept the promotion state at `hold_smoke_only` because
  the 500-replicate formal gate remains unmet. Slices 561-575 add condition
  sharding for the formal task; shard artifacts cannot allow coverage claims
  by themselves.
- `run/sim_write_count_structured_q1_grid.R` writes the ordinary Poisson/NB2
  q=1 `spatial()`, `animal()`, and `relmat()` count `mu` smoke artifact set
  with aggregate, replicate-level, manifest, failure-ledger, fixed-effect Wald
  interval, Wald coverage, direct `log_sd_phylo` profile-target, optional
  profile-interval, interval-evidence, interval-diagnostics, and
  interval-failure CSVs. It also reads artifacts back through
  `phase18_audit_count_structured_q1_boundary_gate()`, which applies the
  fitted-replicate boundary rule before a larger pilot is proposed. The
  10-replicate diagnostic pilot from Actions run `26631771105` returned
  `hold_diagnostic`, so `phase18_count_structured_q1_followup_conditions()`
  now separates `stable`, `stable_watch`, and `boundary_stress` cells before
  another diagnostic dispatch. The stable-set run `26638116979` passed the
  boundary gate with decision `propose_next_pilot`, which permits a separate
  formal-pilot design note but not a recovery or coverage claim.
- `run/sim_write_nbinom2_sigma_random_effect_grid.R` writes the ordinary NB2
  log-`sigma` random-intercept smoke artifact set with aggregate,
  replicate-level, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct `log_sd_sigma` profile-target, optional profile-interval,
  interval-evidence, interval-diagnostics, and interval-failure CSVs beside
  resumable per-replicate RDS files.
- `run/sim_write_gaussian_mu_random_slope_grid.R`,
  `run/sim_write_gaussian_sigma_random_slope_grid.R`, and
  `run/sim_write_spatial_mu_slope_grid.R` write simple aggregate,
  replicate-level, manifest, and failure-ledger artifact sets for the ordinary
  Gaussian `mu` random-slope, independent Gaussian `sigma` random-slope, and
  coordinate-spatial Gaussian `mu` slope lanes.
- `run/sim_write_biv_gaussian_mu_slope_grid.R` writes the same simple artifact
  set for the matching bivariate Gaussian `mu1`/`mu2` slope-only lane. The
  manual `biv_gaussian_mu_slope` Actions task can run it. Manual run
  `26689587073` audited a one-replicate, two-cell artifact with clean manifest,
  convergence, `pdHess`, and failure-ledger results, but the lane remains
  opt-in and excluded from `task = "all"` until a deliberately sized recovery
  or coverage grid is designed.
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
  location-scale, `meta_V(V = V)`, paired Poisson/NB2 `mu` random-effect,
  zero-truncated NB2 `mu` random-intercept, fixed-effect proportion,
  bounded-response `mu` random-intercept, fixed-effect positive-continuous,
  fixed-effect Tweedie, positive-continuous `mu` random-intercept, Student-t
  `mu` random-intercept, fixed-effect ordinal, fixed-effect zero-one beta,
  ordinary Gaussian `mu` and `sigma` random-slope, and coordinate-spatial
  Gaussian `mu` slope first-wave smoke surfaces, stages the combined
  first-wave summary report, and records requested versus actual worker
  counts.
- `run/sim_run_interval_heavy_summary_smoke.R` executes the Student-t shape and
  bivariate residual `rho12` smoke surfaces as a separate interval-heavy report
  lane, keeping their Wald/profile/bootstrap artifacts out of the baseline
  first-wave runner.
- `run/sim_run_actions_cell.R` is the GitHub Actions entrypoint for manual
  long-run Phase 18 dispatch. It can run the first-wave summary task, the
  interval-heavy task, standalone zero-truncated NB2 `mu` random-intercept,
  fixed-effect proportion, bounded-response `mu` random-intercept,
  positive-continuous fixed-effect, fixed-effect Tweedie, count structured
  q=1, positive-continuous `mu` random-intercept, Student-t `mu`
  random-intercept, ordinal, zero-one beta, and bivariate Gaussian `mu1`/`mu2`
  slope-only tasks, or the opt-in Poisson and NB2 phylogenetic q=1 formal-grid
  tasks. It writes an RDS result beside the task artifact tables and caps
  requested replicate or bootstrap workers at 10 before dispatch. The workflow
  never uses both replicate-layer multicore and bootstrap-layer multicore at
  the same time. The phylogenetic formal tasks, random-slope tasks, and
  standalone family tasks are manual-only and are excluded from `task = "all"`
  by the workflow matrix. Formal tasks also accept one-based `condition_shard`
  and `condition_shards` inputs so the 288-cell formal tables can be split
  across multiple Actions runs.
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
- `run/sim_summary_poisson_phylo_q1_smoke.R` runs a tiny non-zero-inflated
  Poisson phylogenetic q=1 `mu` summary smoke grid and returns aggregate,
  replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct profile-target status, optional direct profile interval,
  interval-evidence, interval-diagnostics, and interval-failure outputs.
- `run/sim_summary_nbinom2_phylo_q1_smoke.R` runs a tiny non-zero-inflated NB2
  phylogenetic q=1 `mu` summary smoke grid with fixed-effect `sigma` and an
  ordinary grouped species-intercept comparator. It returns aggregate,
  replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, direct profile-target status, optional direct profile interval,
  interval-evidence, interval-diagnostics, and interval-failure outputs.
- `run/sim_summary_count_structured_q1_smoke.R` runs a tiny ordinary
  Poisson/NB2 q=1 `spatial()`, `animal()`, and `relmat()` count `mu` summary
  smoke grid. It returns aggregate, replicate, manifest, failure-ledger,
  fixed-effect Wald interval, Wald coverage, direct profile-target status,
  optional direct profile interval, interval-evidence, interval-diagnostics,
  and interval-failure outputs. Replicate rows carry `sd_structured` plus
  fit-level Hessian and SD-boundary diagnostics so the boundary-gate audit can
  collapse them to fitted-replicate units.
- `run/sim_summary_nbinom2_mu_random_effect_smoke.R` runs a tiny
  non-zero-inflated NB2 `mu` random-effect summary smoke grid and returns
  grouped bias, RMSE, MCSE, manifest, warning/error ledger, formula-coefficient
  Wald interval, Wald coverage, direct random-effect SD profile interval, and
  profile coverage outputs.
- `run/sim_summary_nbinom2_sigma_random_effect_smoke.R` runs a tiny
  non-zero-inflated NB2 log-`sigma` random-intercept summary smoke grid and
  returns grouped bias, RMSE, MCSE, manifest, failure-ledger,
  formula-coefficient Wald interval, Wald coverage, direct `log_sd_sigma`
  profile-target rows, optional profile interval rows, interval diagnostics,
  and interval-failure outputs.
- `run/sim_summary_truncated_nbinom2_mu_random_intercept_smoke.R` runs a tiny
  zero-truncated NB2 ordinary `mu` random-intercept summary smoke grid and
  returns aggregate, replicate, manifest, failure-ledger, fixed-effect Wald
  interval, Wald coverage, direct-SD profile interval, and profile coverage
  outputs.
- `run/sim_summary_proportion_fixed_effect_smoke.R` runs a tiny fixed-effect
  `beta()` and `beta_binomial()` summary smoke grid and returns aggregate,
  replicate, manifest, failure-ledger, fixed-effect Wald interval, and Wald
  coverage outputs.
- `run/sim_summary_bounded_response_mu_random_intercept_smoke.R` runs a tiny
  `beta()` and `beta_binomial()` ordinary `mu` random-intercept summary smoke
  grid and returns aggregate, replicate, manifest, failure-ledger,
  fixed-effect Wald interval, Wald coverage, direct-SD profile interval, and
  profile coverage outputs.
- `run/sim_summary_positive_continuous_fixed_effect_smoke.R` runs a tiny
  fixed-effect `lognormal()` and `Gamma(link = "log")` summary smoke grid and
  returns aggregate, replicate, manifest, failure-ledger, fixed-effect Wald
  interval, and Wald coverage outputs.
- `run/sim_summary_tweedie_fixed_effect_smoke.R` runs a tiny fixed-effect
  `tweedie()` summary smoke grid and returns aggregate, replicate, manifest,
  failure-ledger, formula-coefficient Wald interval, and Wald coverage outputs.
- `run/sim_summary_positive_continuous_mu_random_intercept_smoke.R` runs a
  tiny `lognormal()` and `Gamma(link = "log")` ordinary `mu`
  random-intercept summary smoke grid and returns aggregate, replicate,
  manifest, failure-ledger, fixed-effect Wald interval, Wald coverage,
  direct-SD profile interval, and profile coverage outputs.
- `run/sim_summary_ordinal_fixed_effect_smoke.R` runs a tiny fixed-effect
  `cumulative_logit()` ordinal summary smoke grid and returns aggregate,
  replicate, manifest, failure-ledger, fixed-effect Wald interval, Wald
  coverage, cutpoint, and cutpoint-ordering outputs.
- `run/sim_summary_zero_one_beta_fixed_effect_smoke.R` runs a tiny
  fixed-effect `zero_one_beta()` summary smoke grid and returns aggregate,
  replicate, manifest, failure-ledger, fixed-effect Wald interval, and Wald
  coverage outputs.
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
- `run/sim_summary_biv_gaussian_mu_slope_smoke.R` reduces the matching
  bivariate Gaussian `mu1`/`mu2` slope-only smoke run into aggregate,
  replicate, manifest, and failure-ledger tables.
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
