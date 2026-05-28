# Phase 18 Simulation Programme

Phase 18 is the evidence layer for `drmTMB`: simulation, power, accuracy,
coverage, runtime, and failure-mode reporting. It should follow the ADEMP
structure of Morris, White, and Crowther (2019) and the transparent-reporting
items of Williams et al. (2024), but it should stay practical for ecology,
evolution, and meta-analysis readers.

The first rule is scope. A surface enters the comprehensive simulation only
after it has a fitted likelihood, parser validation, extractors, diagnostics,
interval status, and focused recovery tests. Surfaces that are still only
planned belong in the failure ledger, not in a broad simulation table.
Before adding a DGP row, check the Slice 291 evidence-ledger gate in
`docs/design/46-pre-simulation-readiness-matrix.md`; the row should name the
public surface, the validation-debt register evidence, and whether the surface
is admitted, opt-in only, or failure-ledger only.

## Slice 292 Comprehensive Design Map

Comprehensive simulation means every advertised scenario lane is assigned a
role before grids run. It does not mean every planned model is fitted. A lane
can enter as an admitted grid, a fixed-effect design target that still needs a
DGP file, an opt-in stress cell, or a failure-ledger row.

| Scenario lane | Phase 18 role after Slice 291 gate | First design action | Failure-ledger boundary |
| --- | --- | --- | --- |
| Continuous location-scale | Admitted for Gaussian location-scale first; fixed-effect lognormal, Gamma, Tweedie, and Student-t have family-specific estimands and artifact lanes; lognormal, Gamma, and Student-t ordinary `mu` random intercepts have separate artifact lanes | `docs/design/47-phase-18-gaussian-location-scale-ademp.md` is the first ADEMP sheet; `docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md` records the fixed-effect lognormal/Gamma artifact lane; `docs/design/118-phase-18-positive-continuous-mu-random-intercept-artifacts-slices-1369-1378.md` records the lognormal/Gamma ordinary `mu` random-intercept lane; `docs/design/119-phase-18-student-mu-random-intercept-artifacts-slices-1379-1388.md` records the Student-t ordinary `mu` random-intercept lane; `tests/testthat/test-tweedie-location-scale.R` records the first focused Tweedie fixed-effect recovery checks | Do not claim positive-continuous or Student-t random slopes, `sigma` random effects beyond fitted Gaussian/NB2 gates, shape/skewness random effects, phylogenetic shape, generalized Gamma, Tweedie extensions beyond fixed-effect intercept-only power, or latent ID-level skewness |
| Proportion and bounded responses | Admitted for fixed-effect beta, beta-binomial, and zero-one beta artifact lanes; beta and beta-binomial ordinary `mu` random intercepts have an artifact lane | `docs/design/50-phase-18-proportion-fixed-effect-ademp.md` records the fixed-effect beta/beta-binomial ADEMP sheet; `docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md` records the beta/beta-binomial DGP/smoke/grid artifact lane; `docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md` records the fixed-effect zero-one beta design gate; `docs/design/115-phase-18-zero-one-beta-fixed-effect-artifacts-slices-1339-1348.md` records the zero-one beta DGP/smoke/grid artifact lane; `docs/design/117-phase-18-bounded-response-mu-random-intercept-artifacts-slices-1359-1368.md` records the beta/beta-binomial ordinary `mu` random-intercept lane | Keep zero-one beta random effects, one-inflation random effects, bounded-response random slopes, bounded-response `sigma` random effects, and bounded-response `meta_V(V = V)` in the failure ledger |
| Counts | Admitted for fixed-effect count families, ordinary non-zero-inflated Poisson/NB2 `mu` random effects, ordinary zero-truncated NB2 `mu` random intercepts, and the first ordinary NB2 log-`sigma` random intercept; ordinary Poisson/NB2 q=1 phylogenetic `mu` routes are fitted but still smoke/formal-admission lanes | `docs/design/49-phase-18-count-mu-random-effect-ademp.md` records the paired Poisson/NB2 `mu` random-effect ADEMP sheet; `docs/design/120-phase-18-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md` records the zero-truncated NB2 ordinary `mu` random-intercept artifact lane; `docs/design/73-phase-18-nbinom2-sigma-random-intercept-ademp.md`, `phase18_run_nbinom2_sigma_re_smoke()`, and `phase18_write_nbinom2_sigma_re_grid_outputs()` exercise the NB2 log-`sigma` random-intercept grid; `phase18_run_poisson_phylo_q1_smoke()`, `phase18_write_poisson_phylo_q1_grid_outputs()`, optional direct `log_sd_phylo` profile artifacts, formal-grid QA helpers, and the manual `poisson_phylo_q1_formal` Actions task exercise the Poisson phylogenetic q1 gate; `docs/design/74-phase-18-nbinom2-phylo-q1-ademp.md`, `phase18_run_nbinom2_phylo_q1_smoke()`, `phase18_write_nbinom2_phylo_q1_grid_outputs()`, the grouped-comparator row, formal-grid QA helpers, and the manual `nbinom2_phylo_q1_formal` Actions task exercise the overdispersion-aware NB2 q1 gate; `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md` closes Slice C as a count inventory and validation lane | Keep zero-inflated/hurdle random effects, zero-truncated NB2 random slopes, correlated count slopes, NB2 `sigma` slopes, NB2 `sigma` phylogeny, spatial/animal/`relmat()` count effects, count-side structured slopes, COM-Poisson, and generalized Poisson out until a separate Slice D decision opens them |
| Ordinal | Admitted only for fixed-effect `cumulative_logit()` location models | `docs/design/51-phase-18-ordinal-fixed-effect-ademp.md` records the fixed-effect ordinal ADEMP sheet; `docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md` records the DGP/smoke/grid artifact lane | Keep ordinal random effects, scale/discrimination formulas, bivariate ordinal, and mixed-response ordinal models out |
| Meta-analysis with known `V` | Admitted for Gaussian `meta_V(V = V)` vector and dense known sampling covariance | `docs/design/48-phase-18-meta-v-ademp.md` records the vector/dense known-`V` ADEMP sheet before larger grids | Keep proportional sampling variance, non-Gaussian known covariance, and phylogenetic-plus-study extensions out |
| Bivariate Gaussian | Admitted for residual `rho12`, selected intercept covariance blocks, and the matching slope-only `mu1`/`mu2` block | `docs/design/52-phase-18-bivariate-rho12-ademp.md` records the residual-correlation ADEMP sheet; group-level `corpairs()` and slope-only covariance need separate sheets | Keep mixed-response families, random effects in `rho12`, broader bivariate random slopes, and broad q=4/q=8 slope covariance out |
| Random slopes | Admitted for ordinary Gaussian `mu` q > 2, independent Gaussian `sigma` one-slope terms, ordinary Poisson/NB2 `mu` independent slopes, and coordinate-spatial, phylogenetic, animal-model, and `relmat()` Gaussian `mu` one-slope paths | Give each admitted slope class its own condition table for group count, repeats, slope SD, and covariate spread | Keep bivariate, correlated non-Gaussian, multiple structured, structured slope-correlation, and residual-scale correlated slopes out |
| Shape and skewness | Admitted for fixed-effect Student-t `nu` smoke, artifact-path, Wald interval, profile-smoke, and bootstrap-smoke evidence; skew-normal and skew-t remain design-only future targets | Extend the fixed-effect Student-t `nu` lane from smoke evidence to formal coverage grids after the interval evidence schema is stable | Keep `nu` random effects, future `tau` random effects, skewness random effects, and latent `skew(id) ~ ...` out |
| Phylogenetic structured effects | Admitted for fitted Gaussian `mu` and `sigma` intercepts, matching univariate `mu`/`sigma` correlation, one numeric `mu` slope, direct-SD, selected bivariate covariance subsets, and ordinary Poisson/NB2 q=1 phylogenetic `mu` first slices | Write small tree-size and phylogenetic-signal condition tables for the fitted Gaussian intercept/direct-SD/one-slope surfaces; keep the Poisson and NB2 q=1 lanes separate until their formal artifacts are run and audited beyond the current smoke/formal-admission evidence | Keep multiple phylogenetic slopes, residual-scale structured slopes, Poisson/NB2 phylogenetic slopes, zero-inflated phylogenetic effects, NB2 `sigma` phylogeny, direct-SD formulas combined with structured `sigma`, structured `rho12`, and predictor-dependent q=4 correlations out |
| Coordinate spatial structured effects | Admitted for univariate Gaussian `mu` and `sigma` intercepts, matching univariate `mu`/`sigma` correlation, one numeric coordinate-spatial `mu` slope, the constant bivariate spatial `mu1`/`mu2` q=2 location covariance, and the constant q=4 location-scale covariance as a first slice | Extend the existing spatial one-slope and q=2 smoke design with site count, observations per site, field SD, covariate-spread, and q=4 endpoint conditions; `docs/design/56-phase-18-spatial-q2-ademp.md` records the q=2 spatial design sheet, while `phase18_run_spatial_q2_smoke()` and `phase18_write_spatial_q2_grid_outputs()` supply the seeded smoke runner, repeatable CSV artifacts, fixed-effect Wald tables, and profile-status ledgers before broad paired-response reports | Keep mesh/SPDE, multiple slopes, residual-scale structured slopes, slope correlations, spatial direct-SD, spatial `corpair()`, and non-Gaussian spatial effects out |
| `animal()` models | Admitted for the small dense-pedigree and known-matrix Gaussian `mu` and `sigma` intercept paths, one-slope `mu` paths, matching bivariate `mu1`/`mu2` q=2 location covariance design lanes, and the first constant all-four q=4 location-scale smoke lane; the q=2 lane now has a first DGP, summariser, smoke runner, CSV grid writer, fixed-effect Wald artifacts, opt-in profile-status artifacts, and an animal-only pedigree smoke cell; the q=4 lane now has a DGP, summariser, smoke runner, CSV grid writer, and derived-correlation interval-status artifacts | `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md` records the intercept and q=2 condition tables before broad grids; `docs/design/55-phase-18-animal-relmat-q2-interval-status.md` defines which q=2 rows receive Wald intervals, profile intervals, or `not_requested` status; `docs/design/58-phase-18-animal-relmat-q4-ademp.md` records the q=4 addendum and derived-unavailable correlation policy | Sparse large-pedigree construction, multiple structured slopes, slope correlations, predictor-dependent `corpair()` regressions, and direct-SD grammar remain failure-ledger rows |
| `relmat()` models | Admitted for the known-matrix Gaussian `mu` and `sigma` intercept paths, one-slope `mu` paths, matching bivariate `mu1`/`mu2` q=2 location covariance design lanes, and the first constant all-four q=4 location-scale smoke lane; the q=2 lane now has a first DGP, summariser, smoke runner, CSV grid writer, fixed-effect Wald artifacts, and opt-in profile-status artifacts; the q=4 lane now has a DGP, summariser, smoke runner, CSV grid writer, and derived-correlation interval-status artifacts | `docs/design/54-phase-18-animal-relmat-known-matrix-ademp.md` records the intercept and q=2 condition tables before broad grids; `docs/design/55-phase-18-animal-relmat-q2-interval-status.md` defines which q=2 rows receive Wald intervals, profile intervals, or `not_requested` status; `docs/design/58-phase-18-animal-relmat-q4-ademp.md` records the q=4 addendum and derived-unavailable correlation policy | Multiple structured slopes, slope correlations, predictor-dependent `corpair()` regressions, and direct-SD grammar remain failure-ledger rows |

Every admitted lane needs a one-page ADEMP sheet before new code: aim,
hierarchy, true parameter values, varied conditions, estimands, fitted methods,
performance measures, replicate count, MCSE target, and failure-ledger row.
The first implementation wave should reuse existing smoke infrastructure before
adding new result schemas.

Slices 591-650 add the supported non-Gaussian evidence closeout in
`docs/design/79-supported-nongaussian-evidence-goal.md`. That goal audits the
current fixed-effect family suite and first count mixed-model lanes; it does
not open the failure-ledger rows for mixed-response families, non-Gaussian
scale or shape random effects, inflation/hurdle random effects, or broad
structured non-Gaussian dependence.

## A - Aims

Primary aim: quantify when fitted `drmTMB` surfaces recover scientifically
interpretable distributional parameters with acceptable bias, coverage, and
diagnostic behaviour.

Secondary aims:

- estimate power for effects on `sigma`, `rho12`, random-effect SDs,
  structured-effect SDs, and direct-SD models under realistic eco-evo sample
  sizes;
- compare narrow `drmTMB` surfaces with standard practice where a comparator is
  defensible, such as Gaussian meta-analysis with known `V`;
- record failure rates, boundary hits, non-positive-definite Hessians, and
  unsupported surfaces instead of silently dropping hard cases.

## D - Data-Generating Mechanisms

Each DGP should be a small named surface, not a giant all-features grid. The
minimum first wave is:

| Surface | Current gate | DGP sketch | Vary first |
| --- | --- | --- | --- |
| Gaussian location-scale | Fitted | `y_i ~ Normal(mu_i, sigma_i^2)` with `mu ~ x` and `log(sigma) ~ z` | `n`, sigma slope, collinearity |
| Gaussian ordinary random effects | Fitted | `y_ij = mu_ij + u_j + e_ij`, optional slopes | groups, observations per group, SD size |
| Gaussian ordinary q=3 random slopes | Fitted but advanced | `mu_ij = X beta + b_0j + x1 b_1j + x2 b_2j` with `(1 + x1 + x2 | id)` | groups, observations per group, slope SD, correlation |
| Gaussian residual-scale random slopes | Fitted independent slope | `log(sigma_ij) = X beta + w_ij a_j` with `(0 + w | id)` | groups, observations per group, scale-slope SD |
| Gaussian location-scale covariance | Fitted | matched `mu`/`sigma` random intercept blocks | group count, correlation, SD ratio |
| Bivariate Gaussian coscale | Fitted | two responses with `sigma1`, `sigma2`, and `rho12` | residual correlation, missing rows excluded |
| Phylogenetic and spatial Gaussian | Fitted subsets | known relatedness or coordinate covariance plus Gaussian residuals | number of taxa/sites, signal size |
| Coordinate spatial q=2 Gaussian | Fitted for matching bivariate location covariance | coordinate covariance plus Gaussian residuals, with residual `rho12` separated from spatial correlation | sites, repeats, geometry stress, spatial SD, spatial correlation |
| Animal/relmat Gaussian relatedness | Fitted for intercept and matching q=2 location covariance | known relatedness matrix or dense animal pedigree plus Gaussian residuals, with residual `rho12` separated from structured correlation | groups, repeats, matrix conditioning, structured SD, structured correlation |
| Structured one-slope parity | Spatial, phylo, animal, and `relmat()` fitted for univariate Gaussian `mu` one-slope paths | independent structured intercept and slope fields | sites or groups, slope-field SD, covariate spread, matrix conditioning |
| Coordinate spatial one-slope smoke | Fitted smoke surface | `eta_mu = X beta + z0_site + x z1_site` with two independent coordinate-spatial fields | sites, observations per site, intercept-field SD, slope-field SD |
| Gaussian meta-analysis | Fitted | `y ~ MVN(mu, V + Omega_estimated)` with vector or matrix `V` | effect sizes, dense `V`, heterogeneity |
| Proportion fixed effects | Fitted for beta and beta-binomial | `logit(mu_i) = beta0 + beta1 x_i`, `log(sigma_i) = gamma0 + gamma1 z_i`; beta-binomial draws successes from a beta-mixed binomial with known trials | sample size, trial count, mean contrast, precision, predictor correlation |
| Beta ordinary `mu` random intercepts | Source-tested first slice | `logit(mu_ij) = beta0 + beta1 x_ij + b_j`, `b_j ~ Normal(0, sd_mu^2)`, with fixed-effect `log(sigma_i)` and strict `(0, 1)` responses | groups, observations per group, `sd_mu`, mean contrast, precision, strict-boundary stress |
| Positive-continuous fixed effects | Fitted for lognormal and Gamma | lognormal uses `mu` as log-response location; Gamma uses `mu` as response mean, with `sigma` as coefficient of variation | sample size, mean contrast, scale contrast, predictor correlation |
| Ordinal fixed effects | Fitted for cumulative logit | `Pr(y_i <= k) = logit^{-1}(theta_k - beta1 x_i)` with ordered cutpoints and no free location intercept | sample size, number of categories, cutpoint pattern, location contrast |
| Poisson `mu` random effects | Fitted smoke surface | log-mean count model with ordinary random intercepts and independent numeric slopes | groups, observations per group, mean count, SD size |
| NB2 `mu` random effects | Fitted smoke surface | log-mean overdispersed count model with ordinary random intercepts and independent numeric slopes; `sigma` remains fixed-effect overdispersion | groups, observations per group, mean count, overdispersion, SD size |
| NB2 `sigma` random intercepts | Fitted smoke surface | log-overdispersion count model with ordinary grouped random intercepts and fixed-effect `mu` | groups, observations per group, mean count, overdispersion, true `sigma` SD |
| NB2 phylogenetic q=1 `mu` | Fitted smoke/formal-admission surface with completed audit hold | log-mean overdispersed count model with `phylo(1 | species, tree = tree)` in `mu`; `sigma` remains fixed-effect overdispersion; ordinary grouped species-intercept comparator recorded beside target rows; local Slices 541-555 artifacts pass QA, Slices 561-575 add sharded formal dispatch after the singleton Actions shape proved too large, and Slice D1 keeps the route at `hold_smoke_only` after the merged 500-replicate shard audit | species, observations per species, mean count, overdispersion, phylogenetic SD, tree shape |

Later waves can add zero-inflation or hurdle random effects, ordinal mixed
models, shape/skew extensions, and non-Gaussian scale/random-effect surfaces
only after their focused gates are closed. The NB2 `mu`, NB2 `sigma`, and beta
ordinary `mu` random-effect rows are admitted as focused first slices; larger
grids still need a separate runtime and artifact-review decision before they
are treated as routine evidence. The failure ledger in
`docs/design/34-validation-debt-register.md` names the remaining blocked
surfaces.

The cross-distributional-parameter correlation gate in
`docs/design/45-cross-dpar-correlation-gate.md` is part of the same admission
rule. Residual `rho12`, group-level random-effect correlations, structured
random-effect correlations, and known sampling covariance `V` are different
layers. Phase 18 Wave A should not simulate random effects in `rho12`,
non-Gaussian covariance among `mu`, `sigma`, `zi`, `hu`, `zoi`, `coi`, or
`nu`, or slope-level cross-parameter covariance until the focused likelihood,
extractor, interval, diagnostic, and recovery gates exist.

Every DGP file should state the hierarchy, true fixed effects, random-effect
distributions, covariance labels, sampling covariance `V` when present,
interval target truths, varied conditions, and number of replicates per cell.

## E - Estimands

Store both the true value and the estimator output for each estimand:

| Class | Truth | Estimator output |
| --- | --- | --- |
| Fixed effects | DGP coefficient on the link scale | `coef(fit, dpar)` |
| Residual scale | response-scale `sigma` or sigma ratio | `sigma(fit)` or documented transform of `coef(fit, "sigma")` |
| Residual correlation | true `rho12` or mean true `rho12_i` | `rho12(fit)` and `profile_targets()` rows |
| Random-effect SD | true group-level SD | `sdpars` and direct profile target |
| Random-effect correlation | true block correlation | `corpars`, `corpairs()`, and profile target when direct |
| Known sampling covariance | supplied `V` | no estimator; it is input data and must not become an interval target |
| Derived quantities | repeatability, variance share, total observation variance | explicit formula from fitted components |

Replicate-specific truths should be saved when they depend on realised sample
sizes, realised `V`, or a generated covariance matrix.

## M - Methods

The first implementation should fit the intended `drmTMB` model, a simpler
nested `drmTMB` model when the question is power or false-positive rate, and at
most one external comparator per surface where the parameterization and
likelihood are close enough to be honest.

Do not create a comparator zoo. If `glmmTMB`, `brms`, `metafor`, ASReml, or
MCMCglmm cannot fit the same parameter target, the report should say that
directly rather than forcing an unfair comparison.

## P - Performance Measures

Each report should include the metric and its Monte Carlo standard error:

| Measure | Formula | Report with |
| --- | --- | --- |
| Bias | `mean(theta_hat - theta_true)` | MCSE of the mean |
| Relative bias | `mean((theta_hat - theta_true) / theta_true)` when denominator is stable | MCSE of the mean |
| RMSE | `sqrt(mean((theta_hat - theta_true)^2))` | bootstrap or delta MCSE |
| Coverage | `mean(lo <= theta_true & theta_true <= hi)` | `sqrt(p * (1 - p) / n_sim)` |
| Power | `mean(ci_excludes_null)` or test rejection | binomial MCSE |
| Convergence | `mean(converged & pdHess)` | binomial MCSE |
| Boundary rate | `mean(check_drm_boundary_flag)` | binomial MCSE |
| Runtime | median and high quantiles | MCSE or bootstrap interval |

Coverage MCSE should be planned before running large grids. Coverage near 0.95
has MCSE about 1.0 percentage point with 500 replicates and about 0.7
percentage points with 1000 replicates. A pilot grid can use fewer replicates
if it is labelled as a pilot and does not make final coverage claims.

## Implementation Layout

Use a resumable layout:

```text
inst/sim/
  dgp/
    sim_dgp_gaussian_ls.R
    sim_dgp_meta_v.R
  fit/
    sim_fit_drmtmb.R
    sim_fit_comparators.R
  run/
    0_prepare_cells.R
    1_run_cells.R
    2_summarise_cells.R
  reports/
    phase18-gaussian-ls.qmd
    phase18-meta-analysis.qmd
```

Per-cell results should be saved as RDS files with replicate seeds, fit status,
warnings, elapsed time, `check_drm()` rows, interval status, and session info.
CRAN tests should only run smoke checks for seed stability and output shape.

Slice 549 adds `phase18_run_replicates()` as the first bounded parallel
execution helper for replicate grids. The default remains serial
`backend = "none"`, while Unix `backend = "multicore"` can fork independent
replicate tasks with actual workers capped at 10 and at the number of
replicates. The Gaussian location-scale, `meta_V(V = V)`, Poisson `mu`
random-effect, NB2 `mu` random-effect, Gaussian `mu` random-slope, Gaussian
`sigma` random-slope, coordinate spatial `mu` slope, Student-t shape, and
bivariate residual `rho12` smoke runners are wired through this helper.
Student-t shape and bivariate `rho12` use the helper's closure-aware
`summarise_fun_factory` path so each replicate can keep its own profile or
bootstrap seed without reverting to a local loop.

Slices 679-688 make the higher-level wrappers respect the same execution
contract. Gaussian location-scale, Student-t shape, and bivariate residual
`rho12` grid writers forward replicate-runner `cores` and `backend`; the paired
count pilot and count-gallery smoke wrapper do the same. Student-t shape and
bivariate residual `rho12` keep separate `bootstrap_cores` and
`bootstrap_backend` arguments for the inner private parametric-bootstrap layer,
and bootstrap interval rows carry `bootstrap.backend`,
`bootstrap.requested_cores`, and `bootstrap.cores` for artifact audits. The
recommended heavier-use pattern is to parallelize either the replicate layer or
the bootstrap layer, not both at once. Slices 689-698 turn that recommendation
into a guard for Student-t shape and bivariate residual `rho12` bootstrap
smokes: if the replicate layer and bootstrap layer would both use more than one
worker, the runner errors before fitting.

Simulation artifacts have two explicit grains. Replicate-level summaries carry
`artifact_grain = "replicate"` and one row per fitted simulation replicate,
parameter, and cell. They are the only valid input for replicate-error clouds,
empirical quantiles, per-cell failure-pattern displays, and future bootstrap or
profile-draw comparisons. Aggregate summaries carry
`artifact_grain = "aggregate"` and one row per grouped estimand, with
`n_replicate`, bias, RMSE, MCSE, convergence, Hessian, warning, and runtime
columns. Aggregate-only reports must use points, bars, and MCSE or interval
ranges; they must not draw distributional clouds from rows that have already
been reduced.

Grid-output writers also return artifact manifests with one row per CSV
artifact, file-existence status, and CSV row counts. First-wave report staging
binds those manifests across surfaces and writes both the bound manifest and a
surface-status table before a report tries to read the individual aggregate,
replicate, interval, or failure-ledger files. The first status report template
uses those tables as a preflight gate and can stop immediately when required
artifacts are missing. A separate first-wave table-bundle writer can then bind
selected CSV artifacts across surfaces, preserving source-surface and
source-artifact columns first while filling missing table columns with `NA`. The
first summary-report skeleton is table-first: it reads artifact status,
aggregate operating-characteristic rows, interval diagnostics, interval
failures, manifests, and warning/error ledgers before figure design begins. A
render helper now ties those staging pieces together by writing status outputs,
writing bundled tables, and optionally rendering the HTML summary report from
the staged CSVs. The summary report displays priority columns first and caps
large tables, while leaving the full CSVs intact for downstream figures. It
also adds a compact warning/error summary above the raw ledger so recurring
surface-level diagnostics are visible before a reader scans every event row. A
first compact aggregate-bias overview gives reviewers a quick visual screen of
largest finite signed-bias rows, with the report caption explicitly reserving
replicate-level clouds for later Florence-reviewed simulation figures. The
summary report also reads Wald, profile, and bootstrap coverage artifacts when
present and summarises interval methods by surface before the raw diagnostic
tables. A run-manifest summary groups run status, skipped rows, warnings,
errors, and elapsed time by surface before the raw manifest.

## Williams-Style Self-Audit

| Item | Covered by this blueprint |
| --- | --- |
| 1. Aims | Named in the A section. |
| 2. Data-generating mechanisms | Named by surface with required DGP fields. |
| 3. Estimands | Truth and estimator output table. |
| 4. Methods | `drmTMB`, nested models, and limited comparators. |
| 5. Performance measures | Bias, RMSE, coverage, power, convergence, boundary, runtime. |
| 6. Software and settings | Required session info and seeds in per-cell output. |
| 7. Code availability | Planned under `inst/sim/` and rendered reports. |
| 8. Replicability | Per-cell RDS output and replicate-level seeds. |
| 9. Real-data motivation | Reports should pair each simulation wave with the relevant tutorial/example. |
| 10. Complete results | Failed fits, boundary hits, and diagnostics are reported, not dropped. |
| 11. Monte Carlo uncertainty | Every aggregate metric carries an MCSE or bootstrap uncertainty estimate. |

## First Three Slices

1. Slice 210 adds the `inst/sim/` skeleton, seed helper, cell registry, and
   one tiny CRAN-safe smoke test.
2. Slice 211 adds the Gaussian location-scale DGP and a pilot summariser that
   records truth, estimate, error, convergence, and Hessian status.
3. Slice 212 adds the Gaussian meta-analysis `meta_V(V = V)` DGP with vector
   `V`, dense matrix `V`, pilot summaries, and interval-target checks.
4. Slice 213 adds a resumable replicate runner with warning/error capture and
   optional per-replicate RDS output.
5. Slice 214 adds the first end-to-end Gaussian location-scale smoke surface,
   wiring registry, DGP, fit, summariser, saved output, and combined parameter
   table without yet making coverage or power claims.
6. Slice 215 adds the matching `meta_V(V = V)` smoke surface for vector and
   dense known sampling covariance cells, again stopping at per-parameter
   summaries rather than aggregate operating-characteristic claims.
7. Slice 216 adds the first parameter-level aggregation helper for bias, RMSE,
   empirical standard error, convergence, Hessian, warning, and elapsed-time
   summaries. Monte Carlo uncertainty and interval coverage remain separate
   follow-up slices.
8. Slice 217 adds Monte Carlo uncertainty helpers for mean error, RMSE, and
   proportions, plus an explicit interval-coverage summary that only runs when
   lower and upper interval columns are present.
9. Slice 218 wires the Gaussian location-scale smoke runner to the aggregation
   and MCSE helpers, giving the first tiny end-to-end bias/RMSE summary surface.
10. Slice 219 does the same for vector and dense `meta_V(V = V)` smoke cells,
    preserving the separation between known sampling covariance and fitted
    residual heterogeneity `sigma`.
11. Slice 220 adds a reader-facing smoke report template so aggregate outputs
    have a stable place for purpose, methods, reader checks, and interpretation
    boundaries before full evidence reports are claimed.
12. Slice 222 adds compact result manifests so saved or resumed runs can be
    audited without opening every per-replicate summary.
13. Slice 223 adds a warning/error ledger for replicate results so failed fits
    remain visible beside aggregate summaries.
14. Slice 224 adds result-directory loading so manifests and warning/error
    ledgers can be rebuilt from saved RDS output after a resumable run.
15. Slice 225 attaches manifests and warning/error ledgers to Gaussian
    location-scale and `meta_V(V = V)` summary-smoke outputs.
16. Slice 226 adds synthetic interval-coverage smoke plumbing. This validates
    the coverage summary path before real Wald, profile, or bootstrap interval
    producers are attached surface by surface.
17. Slice 227 updates the smoke report template so aggregate, manifest, and
    warning/error ledger CSVs have explicit reader-facing sections.
18. Slice 228 adds a skip-aware render test for the smoke report template using
    tiny aggregate, manifest, and warning/error ledger CSV fixtures.
19. Slice 229 records the interval-producer contract for Wald, profile, and
    bootstrap endpoints, including reported scale, method, failure status, and
    correlation-scale rules.
20. Slice 230 adds a generic Wald interval-table helper for summaries that
    already carry estimates and standard errors.
21. Slice 231 adds Fisher-z back-transformed Wald intervals for correlation
    summaries, complementing raw-rho Wald intervals from the generic helper.
22. Slice 232 adds fixed-effect standard errors to Gaussian location-scale pilot
    summaries when fitted models expose them.
23. Slice 233 attaches formula-coefficient Wald interval rows and coverage
    summaries to the Gaussian location-scale summary-smoke output.
24. Slice 234 adds standard errors to `meta_V(V = V)` pilot summaries for
    estimated `mu` coefficients and fitted residual `sigma`, while leaving
    known sampling covariance `V` out of interval targets.
25. Slice 235 attaches Wald interval rows and coverage summaries to the
    `meta_V(V = V)` summary-smoke output.
26. Slice 236 reconciles the random-slope pre-simulation promise: ordinary
    Gaussian `mu` q > 2 is fitted but advanced; Gaussian `sigma` is independent
    slopes only; coordinate spatial has one fitted `mu` slope. Slice 83 later
    opens the matching slope-only bivariate `mu1`/`mu2` route, while broader
    bivariate slope, slope-level location-scale covariance, and non-Gaussian
    scale/shape random-effect slopes remain outside Phase 18 Wave A until
    their recovery gates close.
27. Slice 237 adds a CRAN-safe smoke surface for ordinary Gaussian `mu` q=3
    random slopes, including a seeded DGP, replicate runner, summary table,
    aggregate output, manifest, failure ledger, and tests.
28. Slice 238 adds a CRAN-safe smoke surface for Gaussian `sigma` independent
    one-slope random effects on `log(sigma)`, keeping correlated scale-slope
    covariance and labelled scale-slope blocks outside Wave A.
29. Slice 239 records the structured-slope parity gate: coordinate spatial had
    the first fitted Gaussian `mu` slope, and Slice 39 of the post-0.1.3 parity
    lane later fits the phylogenetic, animal, and `relmat()` sibling one-slope
    paths with diagnostics, profile targets, recovery tests, and biological
    examples still needed before broad grids.
30. Slice 240 records the cross-distributional-parameter correlation gate:
    residual `rho12`, constant fitted random-effect block correlations,
    predictor-dependent q=2 `corpair()` routes, and known sampling covariance
    `V` stay separate; non-Gaussian, slope-level, shape, inflation, hurdle,
    one-inflation, and `rho12` random-effect covariance surfaces remain outside
    Wave A until focused gates close.
31. Slice 241 adds a CRAN-safe smoke surface for the fitted coordinate spatial
    Gaussian `mu` one-slope path, including a seeded DGP, live `drmTMB()` fit,
    parameter summaries, aggregate output, manifest, failure ledger, and tests.
32. Slice 242 adds a CRAN-safe smoke surface for fitted ordinary
    non-zero-inflated Poisson `mu` random effects, covering random intercepts
    plus independent numeric slopes on the log-mean predictor.
33. Slice 243 attaches Wald interval rows and coverage summaries to the
    Poisson `mu` random-effect smoke output for fixed log-mean coefficients,
    while leaving random-effect SD rows visible as profile-needed interval
    failures until direct SD profile producers are attached.
34. Slice 244 attaches direct profile-likelihood interval rows and coverage
    summaries for the Poisson `mu` random-effect SD targets in the smoke output.
35. Slice 245 fits ordinary non-zero-inflated NB2 `mu` random intercepts and
    independent numeric slopes, exposes their SDs and direct profile targets,
    and keeps zero-inflated NB2, correlated/labelled NB2 slope blocks, joint
    `mu`/`sigma` random effects, and NB2 `sigma` slopes outside Wave A.
36. Slice 246 adds a CRAN-safe smoke surface for fitted ordinary
    non-zero-inflated NB2 `mu` random effects, covering random intercepts plus
    independent numeric slopes on the log-mean predictor, while leaving Wald
    and profile interval coverage for follow-up slices.
37. Slice 247 attaches Wald interval rows and coverage summaries to the NB2
    `mu` random-effect smoke output for fixed log-mean and log-overdispersion
    coefficients, while leaving random-effect SD rows visible as profile-needed
    interval failures until direct SD profile producers are attached.
38. Slice 248 attaches direct profile-likelihood interval rows and coverage
    summaries for the NB2 `mu` random-effect SD targets in the smoke output.
39. Slice 249 adds a focused weak-SD boundary diagnostic for fitted NB2 `mu`
    random intercepts, exercising `check_drm()` lower-boundary reporting before
    larger NB2 grids vary the true random-effect SD.
40. Slice 250 records the pre-simulation readiness matrix in
    `docs/design/46-pre-simulation-readiness-matrix.md`, separating fitted,
    smoke-tested, interval-ready, weak-boundary-tested, planned, and blocked
    surfaces before broad simulation reports are written.
41. Slice 251 starts the first paired count pilot by combining the ready Poisson
    and NB2 `mu` random-effect smoke surfaces into one optional pilot output
    with aggregate, manifest, failure-ledger, Wald-coverage, and profile-
    coverage tables.
42. Slice 252 turns the Poisson and NB2 `mu` random-effect condition helpers
    into true grid builders, so optional pilots can cross group count, repeats,
    true random-effect SDs, fixed mean effects, and NB2 overdispersion settings.
43. Slice 253 adds the first Phase 18 plot-data helper, converting the paired
    count pilot into aggregate, coverage, manifest, and failure tables ready for
    Florence's later figure gallery.
44. Slice 254 adds the first count-pilot figure-gallery report template,
    rendering bias, RMSE, coverage, manifest, and warning/error sections from
    the plot-ready tables.
45. Slice 255 adds count-pilot gallery helpers that write the plot-ready CSV
    inputs and render a checked local HTML gallery artifact from a paired count
    pilot object.
46. Slice 256 adds the end-to-end count-gallery smoke runner that runs a tiny
    paired count pilot, writes gallery inputs, renders the HTML gallery, and
    returns the pilot and artifact paths together.
47. Slice 257 applies the first Florence visual polish to the count-pilot
    gallery, including horizontal estimand labels, shared palette/theme
    helpers, captions, and MCSE-aware coverage ranges when available.
48. Slice 258 built the first pkgdown-facing count simulation diagnostics draft,
    but the public page is removed for now because it was narrower than the
    intended figure gallery. Count diagnostics should return later as part of a
    broader set of simulation result articles covering power, bias, coverage,
    runtime, convergence, and failures across continuous, proportion, count,
    and other data types.
49. Slice 265 adds `vignettes/simulation-plot-grammar.Rmd` as the first
    Simulation & Comparison article for operating-characteristic displays. The
    article uses illustrative fixtures across continuous, proportion, count,
    and meta-analysis examples to show bias, RMSE, coverage, power,
    convergence, runtime, and warning/error ledger plots. It is a display
    contract for later simulation reports, not final Phase 18 evidence.
50. Slice 268 adds a capability audit to the pre-simulation readiness matrix.
    It records implemented, tested, planned, and unsupported status for
    Gaussian, non-Gaussian, shape, inflation, bivariate, random-slope,
    meta-analysis, phylogenetic, spatial, animal, and `relmat()` model
    classes, so Phase 18 reports can admit only the fitted and tested subsets.
51. Slices 300 and 301 tighten the accuracy-display contract before broad
    result reports. Bias may show replicate-level error clouds only when
    replicate rows are available; aggregate-only count-pilot reports instead
    show fixed family facets with bias and RMSE points plus MCSE bars. RMSE
    remains a root mean-square aggregate, not the center of an absolute-error
    cloud.
52. Slice 303 merges the figure-visual-audit PR and verifies that the
    post-merge R-CMD-check on `main` passes before the next simulation branch
    begins.
53. Slice 304 records the artifact-grain contract in code and design prose:
    replicate rows and aggregate rows are separate, named outputs, and plots
    choose geometry from that grain.
54. Slice 305 routes all current Phase 18 smoke runners through a shared
    replicate-summary binder so run summaries keep `artifact_grain =
    "replicate"` and summary-smoke objects expose a top-level `replicates`
    table beside aggregate, manifest, and failure outputs.
55. Slice 306 extends the count-pilot gallery inputs with an optional
    replicate-level CSV. When it is present, the bias display overlays faint
    replicate-error points with mean-bias MCSE bars; when it is absent, the
    gallery stays aggregate-only.
56. Slice 307 adds a repeatable Gaussian location-scale grid writer and runs
    the first small grid: 8 cells, 5 replicates per cell, 160 replicate-level
    parameter rows, 32 aggregate rows, and no warning/error ledger rows.
57. Slice 308 adds a simulation-only correlation target inventory. It reads
    fitted `corpairs()` rows, matches direct profile targets where available,
    and keeps residual `rho12`, ordinary group-level, and phylogenetic
    correlation routes separate before coverage claims are made.
58. Slice 309 adds the bivariate Gaussian residual `rho12` DGP, live
    `drmTMB()` smoke runner, fixed-effect summariser, and formula-coefficient
    Wald coverage tables.
59. Slice 310 adds a repeatable bivariate `rho12` grid writer with aggregate,
    replicate, manifest, failure, Wald-interval, and Wald-coverage CSVs beside
    per-replicate RDS results.
60. Slice 311 adds an interval-failure ledger helper so failed, missing,
    derived-unavailable, or `newdata_required` interval rows stay visible
    beside coverage summaries.
61. Slice 312 adds a private Phase 18 parametric-bootstrap refit harness for
    simulation studies. This does not implement public
    `confint(method = "bootstrap")`; it supplies controlled simulation
    artifacts for later bootstrap coverage work.
62. Slice 313 adds percentile bootstrap interval summarisation for bootstrap
    draws produced by the private harness, including interval status and
    failure messages when too few finite refits succeed.
63. Slice 314 runs the first small bivariate `rho12` grid under
    `inst/sim/results/slice-314-biv-rho12-small-grid/`: 4 cells, 3 replicates
    per cell, 12 successful replicate results, 120 replicate-level parameter
    rows, 40 aggregate rows, and no warning/error ledger rows.
64. Slice 315 records the shape-model admission gate: fitted fixed-effect
    Student-t `nu` is admitted first, while skew-normal, skew-t, second-shape
    `tau`, shape random effects, and latent-effect skewness stay planned or
    failure-ledger only.
65. Slice 316 adds the Student-t shape ADEMP sheet, keeping the DGP, estimands,
    fitted model, performance measures, MCSE target, and unsupported skew lanes
    explicit before broad shape grids are claimed.
66. Slice 317 adds the Student-t shape condition helper and DGP with `mu ~ x`,
    `sigma ~ z`, `nu ~ w`, optional mean-shape predictor correlation, and
    link-scale truth storage.
67. Slice 318 records the fitted shape transform `nu = 2 + exp(eta_nu)` in the
    DGP and row-level truth helper so response-scale `nu` summaries can be
    added later only on named grids.
68. Slice 319 adds a live `student()` fit wrapper for the admitted fixed-effect
    shape model `bf(y ~ x, sigma ~ z, nu ~ w)`.
69. Slice 320 adds a Student-t fit summariser for fitted `mu`, `sigma`, and
    `nu` formula coefficients, including standard errors when `summary()`
    exposes them.
70. Slice 321 adds the resumable Student-t shape smoke runner with
    replicate-level result summaries, per-replicate RDS paths, and skip-aware
    reload behavior.
71. Slice 322 adds the Student-t shape summary smoke output with aggregate,
    MCSE, manifest, warning/error ledger, Wald interval, Wald coverage, and
    interval-failure tables.
72. Slice 323 attaches formula-coefficient Wald intervals to fixed `mu`,
    `sigma`, and `nu` rows while keeping response-scale `nu` profile or
    bootstrap coverage outside this smoke lane.
73. Slice 324 keeps invalid or missing Student-t Wald interval rows visible in
    the interval-failure ledger rather than silently dropping them from
    coverage evidence.
74. Slice 325 hardens the shared interval-coverage summariser so groups with
    zero or one finite interval width return `NA` interval-width MCSE instead
    of failing.
75. Slice 326 adds the repeatable Student-t shape grid writer with aggregate,
    replicate, manifest, failure, Wald-interval, Wald-coverage, and interval-
    failure CSVs beside per-replicate RDS results.
76. Slice 327 adds overwrite and artifact-existence tests for the Student-t
    shape grid writer.
77. Slice 328 adds DGP, truth-transform, runner, resume, and cell-validation
    tests for the Student-t shape surface.
78. Slice 329 adds summary-smoke tests for Student-t aggregate rows, replicate
    rows, Wald interval rows, coverage rows, and interval-failure ledgers.
79. Slice 330 updates the simulation README so the Student-t shape design
    sheet, DGP, summariser, runner, summary output, and grid writer are
    discoverable.
80. Slice 332 runs the first small Student-t shape grid under
    `inst/sim/results/slice-332-student-shape-small-grid/`: 4 cells, 3
    replicates per cell, 12 successful replicate results, 72 replicate-level
    parameter rows, 24 aggregate rows, and no warning/error or interval-failure
    rows.
81. Slice 332 records the Student-t shape after-task evidence and keeps the
    claim boundary explicit: this is smoke and artifact-path evidence, not yet
    formal Student-t shape coverage evidence.
82. Slice 333 re-audits the interval target contract so failed, planned, and
    unavailable interval rows remain visible instead of being counted as finite
    coverage evidence.
83. Slice 334 moves profile-interval columns into shared Phase 18 helpers, with
    explicit status and message columns that can be joined into interval
    evidence ledgers.
84. Slice 335 adds optional Student-t `nu` profile interval smoke evidence while
    keeping the fitted target on the formula-coefficient scale.
85. Slice 336 adds optional Student-t parametric-bootstrap interval smoke
    evidence for fixed `mu`, `sigma`, and `nu` coefficients.
86. Slice 337 combines Wald, profile, and bootstrap rows into one
    interval-evidence table and matching failure ledger.
87. Slice 338 applies the same optional profile and parametric-bootstrap
    interval path to bivariate Gaussian residual-correlation `rho12` smoke
    runs.
88. Slice 339 extends the Student-t and `rho12` grid writers so interval
    evidence, profile, bootstrap, and interval-failure CSVs sit beside the
    existing aggregate, replicate, manifest, and Wald coverage artifacts.
89. Slice 340 runs a tiny Student-t interval comparison grid to check artifact
    paths and interval status handling, not to claim formal coverage.
90. Slice 341 adds reader-facing animal-model, Student-t, and skew-normal
    examples. The animal-model page now has a fitted known-matrix intercept
    example; one numeric animal-model slope was added later in the post-0.1.3
    parity lane, while skew-normal likelihoods remain planned-only.
91. Slice 342 records the after-task evidence and closes the gate from smoke
    interval infrastructure to the next formal simulation slices.
92. Slice 343 adds interval diagnostics that keep method status, usable
    interval coverage, usable interval misses, and unusable interval rows
    separate.
93. Slice 344 returns interval diagnostics from the Student-t shape and
    bivariate residual `rho12` summary surfaces.
94. Slice 345 extends the Student-t shape and bivariate residual `rho12` grid
    writers with interval-diagnostics CSV artifacts.
95. Slice 346 tests that failed or not-requested intervals are status
    evidence, while finite intervals that miss truth are coverage evidence.
96. Slice 347 runs the next Student-t shape interval pilot with profile and
    private parametric-bootstrap rows for `nu` coefficients.
97. Slice 348 runs the matching bivariate residual `rho12` interval pilot with
    profile and private parametric-bootstrap rows.
98. Slice 349 compares method status and coverage diagnostics across Wald,
    profile, and private parametric-bootstrap rows without treating the pilot
    as final coverage evidence.
99. Slice 350 updates the simulation README and interval-producer contract so
    readers know where to find diagnostics, evidence, and failure ledgers.
100. Slice 351 runs the focused Phase 18 interval tests and package-site
     checks.
101. Slice 352 records the after-task evidence and leaves the next audit and
     convergence-stress-test jobs queued explicitly.
102. Slice 353 locates the local Ayumi test folder and confirms the relevant
     lightness data live in `data_raw/data_6196spp.csv`, not the smaller
     `dat_500spp.csv` table.
103. Slice 354 adds `tools/ayumi-convergence-stress.R`, a reproducible local
     stress script that writes summary CSVs but keeps raw data outside the
     package.
104. Slice 355 records the tree-preflight result: the pruned raw 10,597-tip
     tree is not ultrametric, so phylogenetic fits fail before optimization
     unless a stress-test-only forced-ultrametric tree is supplied.
105. Slice 356 runs aggregate 80-species non-phylogenetic bivariate Gaussian
     checks; residual `rho12` and predictor-dependent residual `rho12` converge
     cleanly with positive-definite Hessians.
106. Slice 357 runs the forced-tree aggregate phylogenetic mean-correlation
     check; it fits, but `check_drm()` flags a boundary phylogenetic
     mean-mean correlation and weak species replication.
107. Slice 358 runs forced-tree aggregate q4 phylogenetic location-scale
     variants; they run but show false convergence, non-positive-definite
     Hessians, large gradients, and near-boundary latent correlations.
108. Slice 359 verifies that residual `rho12` remains profile-ready on the
     stable aggregate fit and that `corpairs(conf.int = TRUE)` returns a
     profile interval.
109. Slice 360 runs row-level replicated variants and records why they are not
     a rescue for these data: species-level responses repeated over rows push
     residual `rho12` to the boundary and retain Hessian/gradient warnings.
110. Slice 361 records the warm-start boundary: optimizer presets are not a
     real starting-value contract, and robust budgets did not rescue the q4
     phylogenetic location-scale fits.
111. Slice 362 writes the convergence report, check-log entry, after-task note,
     and validation evidence before returning to the Phase 18 simulation wave.
112. Slices 539-548 add bounded private parametric-bootstrap execution for
     Phase 18 interval evidence, with serial and Unix `multicore` backends,
     actual-worker caps of 10 and `nsim`, and recorded requested versus actual
     core counts.
113. Slices 549-578 add and migrate the shared bounded replicate runner for
     Gaussian location-scale, `meta_V(V = V)`, Poisson `mu`, and NB2 `mu`
     smoke surfaces.
114. Slices 579-628 validate the migrated Phase 18 runners, then run the full
     package test suite, pkgdown checks, and package checks.
115. Slices 629-638 add the closure-aware summary-factory path so Student-t
     shape and bivariate residual `rho12` runners can keep profile or
     bootstrap seeds per replicate while still using the shared runner.
116. Slices 639-668 rerun focused Phase 18 tests, full package tests, pkgdown,
     and package checks after the closure-aware migration.
117. Slices 669-678 synchronize the roadmap and simulation programme text with
     the implemented bounded-runner status, while keeping public bootstrap
     intervals and PSOCK support out of the implemented surface.
118. Slices 679-688 forward bounded runner settings through the first grid and
     count-gallery wrappers, add separate bootstrap backend settings for
     Student-t shape and bivariate residual `rho12`, and record bootstrap
     backend/core metadata in interval artifacts.
119. Slices 689-698 add a nested-parallel guard so Student-t shape and
     bivariate residual `rho12` bootstrap smokes cannot run multicore
     replicate and multicore bootstrap layers at the same time.
120. Slices 699-708 add the repeatable `meta_V(V = V)` grid-output writer,
     saving aggregate, replicate, manifest, failure-ledger, Wald interval, and
     Wald coverage CSV artifacts beside resumable per-replicate RDS files.
121. Slices 709-718 add the repeatable paired Poisson/NB2 `mu` random-effect
     grid-output writer, including aggregate, replicate, manifest,
     failure-ledger, Wald interval, Wald coverage, direct-SD profile interval,
     and profile coverage CSV artifacts.
122. Slices 719-728 add repeatable simple grid-output writers for ordinary
     Gaussian `mu` random slopes, independent Gaussian `sigma` random slopes,
     and coordinate-spatial Gaussian `mu` slopes.
123. Slices 729-738 add grid-artifact manifests to the first-wave writers so
     report staging can audit file existence and CSV row counts, including
     zero-row optional interval artifacts.
124. Slices 739-748 add manifest binding and surface-level artifact status
     summaries for first-wave report staging.
125. Slices 749-758 add a first-wave artifact-status writer that saves bound
     artifact-manifest and surface-status CSVs from multiple grid-writer
     outputs before a report consumes the simulation tables.
126. Slices 759-768 add a first-wave artifact-status report template that
     renders the preflight status page for complete outputs and fails clearly
     when required artifacts are missing.
127. The post-`0.1.3` animal/`relmat()` q=2 interval-artifact slice adds
     fixed-effect Wald interval and coverage CSVs plus profile interval,
     profile coverage, interval-evidence, interval-diagnostics, and
     interval-failure CSVs. The next animal-only pedigree smoke-artifact
     slice adds `matrix_argument = "pedigree"` for the public
     `animal(1 | p | id, pedigree = pedigree)` spelling while keeping
     `relmat()` matrix-only. Profile parameters remain empty by default, and
     opt-in profile evidence keeps structured SDs, structured correlations,
     and residual `rho12` separate from public residual `sigma1`/`sigma2`.
127. Slices 769-778 add a first-wave table-bundle writer that combines selected
     CSV artifacts across grid-writer outputs while retaining source-surface
     and source-artifact columns.
128. Slices 779-788 add a first-wave summary-report skeleton over artifact
     status, aggregate operating-characteristic rows, interval diagnostics,
     interval failures, manifests, and warning/error ledgers.
129. Slices 789-798 add a first-wave summary-report render helper that writes
     artifact status, table-bundle outputs, and optional HTML from grid-writer
     outputs in one orchestration step.
130. Slices 809-818 run a tiny real first-wave summary smoke under
     `inst/sim/results/slice-809-first-wave-summary-smoke/`, combining actual
     Gaussian location-scale and `meta_V(V = V)` grid-writer outputs into a
     rendered summary HTML.
131. Slices 819-828 make the first-wave table-bundle provenance columns lead
     the combined tables, then rerun the tiny Gaussian plus `meta_V(V = V)`
     summary smoke under
     `inst/sim/results/slice-819-first-wave-summary-polished-smoke/`.
132. Slices 829-838 add the paired Poisson/NB2 `mu` random-effect grid writer
     to the tiny first-wave rendered summary smoke under
     `inst/sim/results/slice-829-first-wave-summary-count-smoke/`, giving the
     report a continuous, meta-analysis, and count mixed-model surface mix.
133. Slices 839-848 add priority-column and row-cap display polish to the
     first-wave summary report, then rerun the three-surface smoke under
     `inst/sim/results/slice-839-first-wave-summary-table-polish-smoke/`.
134. Slices 849-858 add a compact warning/error summary to the first-wave
     summary report, then rerun the three-surface smoke under
     `inst/sim/results/slice-849-first-wave-summary-warning-smoke/`.
135. Slices 859-868 add the first compact aggregate-bias overview to the
     first-wave summary report, then rerun the three-surface smoke under
     `inst/sim/results/slice-859-first-wave-summary-bias-overview-smoke/`.
136. Slices 869-878 add a compact interval-coverage summary to the first-wave
     summary report, then rerun the three-surface smoke under
     `inst/sim/results/slice-869-first-wave-summary-interval-coverage-smoke/`.
137. Slices 879-888 add a compact run-manifest summary to the first-wave
     summary report, then rerun the three-surface smoke under
     `inst/sim/results/slice-879-first-wave-summary-manifest-smoke/`.
138. Slices 889-898 run a slightly larger three-surface first-wave staging
     smoke with `n_rep = 2` and a small `multicore` backend under
     `inst/sim/results/slice-889-first-wave-summary-nrep2-smoke/`, keeping
     actual worker counts below the 10-core cap.
139. Slices 899-908 add a reusable private first-wave summary smoke runner for
     the Gaussian location-scale, `meta_V(V = V)`, and paired Poisson/NB2 `mu`
     random-effect grid writers, including a requested-versus-actual worker
     summary CSV.
140. Slices 909-918 validate that reusable runner with a rendered `n_rep = 2`
     multicore smoke under
     `inst/sim/results/slice-909-first-wave-runner-nrep2-smoke/`.
141. Slices 919-928 add ordinary Gaussian `mu` random slopes to the reusable
     first-wave summary runner and validate the rendered four-surface smoke
     under
     `inst/sim/results/slice-919-first-wave-runner-four-surface-smoke/`.
142. Slices 929-938 add ordinary Gaussian `sigma` random slopes to the reusable
     first-wave summary runner and validate the rendered five-surface smoke
     under
     `inst/sim/results/slice-929-first-wave-runner-five-surface-smoke/`.
143. Slices 939-948 add coordinate-spatial Gaussian `mu` slopes to the reusable
     first-wave summary runner and validate the rendered six-surface smoke
     under
     `inst/sim/results/slice-939-first-wave-runner-six-surface-smoke/`.
144. Slices 949-958 run the six-surface first-wave runner at `n_rep = 2` with
     a small `multicore` backend under
     `inst/sim/results/slice-949-first-wave-runner-six-surface-nrep2-smoke/`.
145. Slices 959-968 add a separate interval-heavy summary runner for
     Student-t shape and bivariate residual `rho12`, then validate the rendered
     two-surface report under
     `inst/sim/results/slice-959-interval-heavy-runner-smoke/`.
146. Slices 969-978 run a tiny profile-enabled interval-heavy smoke for
     `nu:w` and `rho12:w` under
     `inst/sim/results/slice-969-interval-heavy-profile-smoke/`.
147. Slices 979-988 run a tiny bootstrap-enabled interval-heavy smoke with
     `bootstrap_nsim = 2` and a two-worker `multicore` bootstrap backend under
     `inst/sim/results/slice-979-interval-heavy-bootstrap-smoke/`.
148. Slices 989-998 run focused validation over first-wave staging,
     interval-heavy staging, Student-t shape, and bivariate residual `rho12`
     tests: 260 expectations, 0 failures, 0 warnings, 0 skips.
149. Slices 999-1008 run the broader `^phase18-` focused validation suite:
     1008 expectations, 0 failures, 0 warnings, 0 skips.
150. Slices 1009-1018 run the full package test suite after the first-wave
     and interval-heavy runner additions: 5480 expectations, 0 failures,
     0 warnings, 0 skips.
151. Slices 1019-1028 run `pkgdown::check_pkgdown()` after the report-runner
     documentation updates: no problems found.
152. Slices 1029-1038 normalize active Phase 18 smoke/grid/bootstrap tests to
     request at most 10 cores, then rerun the affected tests: 266
     expectations, 0 failures, 0 warnings, 0 skips.
153. Slices 1039-1048 rerun the full package test suite after the 10-core
     test normalization: 5480 expectations, 0 failures, 0 warnings, 0 skips.
154. Slices 1049-1058 fix two example-style vignette source tangles and rerun
     the light package check: 0 errors, 0 warnings, 1 time-verification NOTE.
155. Slices 1059-1068 run the six-surface first-wave staging grid at
     `n_rep = 3` with a `multicore` backend and a 10-core request cap, then
     audit and fix the rendered aggregate-bias overview so long parameter
     labels no longer clip the plot.
156. Slices 1069-1078 consolidate the merge payload after the first-wave
     staging run: duplicate warning messages are collapsed in the Phase 18
     warning/error ledger, bulky Ayumi CSV/RDS stress outputs and local
     recovery checkpoints stay out of git, and the branch passes focused
     Phase 18 validation, full package tests, pkgdown checks, and package
     checks before staging.
157. Slices 1239-1278 merge PR #263, then add the manual
     `.github/workflows/phase18-simulation-grid.yaml` dispatch workflow and
     `inst/sim/run/sim_run_actions_cell.R` runner. The workflow follows the
     sibling `gllvmTMB` production-grid lesson: manual dispatch, one artifact
     per matrix task, `fail-fast: false`, bounded matrix parallelism, explicit
     artifact retention, and no automatic execution on ordinary pull requests.
     The runner caps requested replicate and bootstrap workers at 10 and
     rejects nested multicore requests, so a bootstrap-heavy interval task
     cannot accidentally use two parallel layers at once.
158. Slices 1279-1288 add the common-family completion map in
     `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`.
     The map keeps counts, proportions, positive-continuous responses,
     ordinal responses, and shape families as separate evidence lanes before
     the team opens more covariance or likelihood surfaces.
159. Slices 1289-1298 add the fixed-effect proportion artifact lane in
     `docs/design/110-phase-18-proportion-fixed-effect-artifacts-slices-1289-1298.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `proportion_fixed_effect` Actions task for
     `beta()` and `beta_binomial()`, while keeping exact 0/1 boundary mass,
     `zoi`/`coi`, bounded-response random effects beyond the beta and
     beta-binomial ordinary `mu` intercept slices, structured bounded
     responses, and mixed-response bounded models outside the fitted claim.
160. Slices 1299-1308 add the fixed-effect positive-continuous artifact lane in
     `docs/design/111-phase-18-positive-continuous-fixed-effect-artifacts-slices-1299-1308.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `positive_continuous_fixed_effect` Actions
     task for `lognormal()` and `Gamma(link = "log")`, while keeping Tweedie,
     generalized Gamma, positive-response random effects beyond the ordinary
     `mu` intercept slice, structured effects, known covariance, and
     mixed-response positive-continuous models outside the fitted claim.
161. Slices 1309-1318 add the fixed-effect ordinal artifact lane in
     `docs/design/112-phase-18-ordinal-fixed-effect-artifacts-slices-1309-1318.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `ordinal_fixed_effect` Actions task for
     `cumulative_logit()`, while keeping ordinal random effects, scale or
     discrimination formulas, bivariate ordinal, known-covariance ordinal, and
     mixed-response ordinal models outside the fitted artifact claim.
162. Slices 1319-1328 close Slice C as the count first-wave review lane in
     `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md`.
     The lane inventories paired Poisson/NB2 `mu` random effects, NB2
     log-`sigma` random intercepts, and Poisson/NB2 q=1 phylogenetic `mu`
     routes; revalidates the focused count and first-wave smoke tests; records
     the later NB2 q1 shard-audit hold decision; and names Slice D choices
     without adding COM-Poisson, Tweedie, zero-one beta, skew-normal, or new
     random-effect syntax.
163. Slice D1 audits the completed 16-shard NB2 q1 formal grid from GitHub
     Actions. The artifacts contain 288 unique formal condition combinations,
     144,000 manifest rows, 500 rows per global shard-cell, and all expected
     CSV artifact families. The result remains `hold_smoke_only` because direct
     `log_sd_phylo` profile intervals are boundary-sensitive and low-count,
     low-overdispersion cells still show fixed-`sigma` recovery problems.
164. Slice D3 records the zero-one bounded-response design gate in
     `docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md`.
     The gate separates strict `beta()` responses, denominator-aware
     `beta_binomial()` responses, and fixed-effect zero-one beta responses with
     exact 0/1 mass. It originally opened no likelihood, formula grammar, TMB
     code, or `zoi`/`coi` random-effect route.
165. The first fixed-effect `zero_one_beta()` source slice adds the univariate
     likelihood, `mu`/`sigma`/`zoi`/`coi` formulas, tests, and documentation for
     structural exact 0/1 mass. It does not add a broad Phase 18 artifact lane
     or random effects in `zoi`, `coi`, `mu`, or `sigma`.
166. Slices 1339-1348 add the fixed-effect zero-one beta artifact lane in
     `docs/design/115-phase-18-zero-one-beta-fixed-effect-artifacts-slices-1339-1348.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `zero_one_beta_fixed_effect` Actions task
     for `zero_one_beta()`, while keeping zero-one random effects, denominator
     syntax, structured bounded responses, known covariance, and bivariate or
     mixed bounded-response models outside the fitted artifact claim.
167. Slices 1359-1368 add the bounded-response ordinary `mu` random-intercept
     artifact lane in
     `docs/design/117-phase-18-bounded-response-mu-random-intercept-artifacts-slices-1359-1368.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `bounded_response_mu_random_intercept`
     Actions task for `beta()` and `beta_binomial()` with ordinary `(1 | id)`
     in `mu`. It records fixed-effect Wald rows plus direct-SD profile rows and
     keeps bounded-response random slopes, labelled covariance, `sigma` random
     effects, exact 0/1 boundary mass, zero-one beta random effects, structured
     bounded responses, known covariance, and mixed-response models outside the
     fitted artifact claim.
168. Slices 1369-1378 add the positive-continuous ordinary `mu`
     random-intercept artifact lane in
     `docs/design/118-phase-18-positive-continuous-mu-random-intercept-artifacts-slices-1369-1378.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `positive_continuous_mu_random_intercept`
     Actions task for `lognormal()` and `Gamma(link = "log")` with ordinary
     `(1 | id)` in `mu`. It records fixed-effect Wald rows plus direct-SD
     profile rows and keeps positive-continuous random slopes, labelled
     covariance, `sigma` random effects, Tweedie, generalized Gamma,
     structured effects, known covariance, and mixed positive-continuous
     models outside the fitted artifact claim.
169. Slices 1379-1388 add the Student-t ordinary `mu` random-intercept
     artifact lane in
     `docs/design/119-phase-18-student-mu-random-intercept-artifacts-slices-1379-1388.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual `student_mu_random_intercept` Actions task
     for `student()` with ordinary `(1 | id)` in `mu`, fixed-effect
     `sigma ~ z`, and fixed-effect `nu ~ 1`. It records fixed-effect Wald
     rows for `mu`, `sigma`, and `nu` plus direct-SD profile rows, while
     keeping Student-t random slopes, labelled covariance, `sigma` random
     effects, `nu` random effects, structured effects, known covariance, and
     bivariate Student-t models outside the fitted artifact claim.
170. Slices 1389-1398 add the zero-truncated NB2 ordinary `mu`
     random-intercept artifact lane in
     `docs/design/120-phase-18-truncated-nbinom2-mu-random-intercept-artifacts-slices-1389-1398.md`.
     The lane adds DGP, summariser, smoke runner, grid writer, first-wave
     runner inclusion, and a manual
     `truncated_nbinom2_mu_random_intercept` Actions task for
     `truncated_nbinom2()` with ordinary `(1 | id)` in `mu` and fixed-effect
     `sigma ~ z`. It records fixed-effect Wald rows plus direct-SD profile
     rows, while keeping zero-truncated NB2 random slopes, labelled
     covariance, `sigma` random effects, hurdle random effects,
     zero-inflated zero-truncated models, structured count effects, and
     bivariate count models outside the fitted artifact claim.
171. Slices 1399-1408 add the parallel Phase 18 lane protocol in
     `docs/design/121-phase-18-parallel-lane-protocol-slices-1399-1408.md`.
     The protocol allows independent distribution lanes to be built on
     separate branches while keeping formula grammar, likelihood changes,
     shared helpers, exported APIs, and global status edits behind a serial
     integration gate. The aim is faster lane construction without weakening
     the fitted-claim, boundary, test, documentation, and CI evidence standard.
172. Slices 1409-1418 run the first two-team pilot under that protocol. Team A
     adds the Tweedie scale-mapping preflight note in
     `docs/design/122-tweedie-scale-preflight.md`, keeping Tweedie
     fixed-effect-only until a family helper, R builder, TMB branch,
     methods, tests, and documentation land together. That first fixed-effect
     lane is now fitted; Team B hardens the
     already-fitted zero-truncated NB2 ordinary `mu` random-intercept lane with
     factor/missing-row and malformed-neighbour tests, without widening the
     fitted count surface.
173. Slices 1419-1518 add the first fitted `tweedie()` route for univariate
     fixed-effect semicontinuous responses with exact zeros. The fitted syntax
     is `bf(y ~ x, sigma ~ z, nu ~ 1)`, with public `sigma = sqrt(phi)` and
     intercept-only `nu`; predictor-dependent power, random effects,
     structured effects, bivariate or mixed-response Tweedie, zero-inflation
     aliases, and hurdle aliases stay outside the fitted claim.
174. Slices 1519-1538 add the skew-normal source map as a design-only gate.
     The note records comparator packages, native-versus-moment
     parameterization choices, local papers, unsupported neighbours, and
     first implementation tests without adding `skew_normal()` or changing
     shared family constructors.
175. Slices 1619-1668 are the next Team A Tweedie evidence-hardening lane in
     `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`. The lane
     should decide the PR boundary, add or design the `glmmTMB::tweedie()`
     comparator contract, compare public `sigma^2` to comparator dispersion
     `phi`, keep `fitted()` as the unconditional mean, and stop before
     predictor-dependent `nu`, random effects, structured effects, bivariate
     Tweedie, zero-inflation aliases, or hurdle aliases.
176. Slices 1669-1718 are the next Team B skew-normal decision gate in
     `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`. The lane
     should choose and document the native-versus-moment parameterization,
     define `fitted()`, `sigma()`, `predict(dpar = "nu")`, normal-limit,
     sign-convention, comparator, simulation, interval-status, and diagnostic
     tests, and stop before adding `skew_normal()` or any C++ likelihood code.
177. Slices 1619-1628 add the first `glmmTMB::tweedie()` comparator contract
     in
     `docs/design/126-phase-18-tweedie-comparator-contract-slices-1619-1628.md`.
     The optional test now covers low-zero and high-zero deterministic cells.
     In both cells it compares `drmTMB` location coefficients to `glmmTMB`
     conditional coefficients, `2 * coef(fit, "sigma")` to log-dispersion
     coefficients, intercept-only `nu` to `glmmTMB` power, and log-likelihoods
     directly on the overlapping fixed-effect model. It keeps Tweedie
     `nu ~ x`, random effects, structured effects, bivariate routes,
     zero-inflation aliases, and hurdle aliases closed.
178. Slices 1669-1672 choose the moment parameterization for the first
     skew-normal lane in
     `docs/design/127-phase-18-skew-normal-parameterization-decision-slices-1669-1672.md`.
     Public `mu` is the response mean, public `sigma` is the response standard
     deviation, and `nu` is the slant/shape parameter. The future likelihood
     may transform to native `xi`, `omega`, and `alpha` internally, but no
     constructor or TMB branch is added in this design-only slice.
179. Slices 1673-1702 add the skew-normal first-test contract in
     `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`.
     The contract names the density-normalization target, Gaussian
     normal-limit test, sign-orientation test, false-positive boundaries, and
     no-C++ admission criteria before any `skew_normal()` constructor, source
     branch, or user-facing example is added.
180. Slices 1629-1630 and 1687-1688 add a narrow semantic-boundary test pass in
     `docs/design/129-phase-18-semantic-boundary-tests-slices-1629-1630-1687-1688.md`.
     The Tweedie comparator now rechecks `fitted()` as unconditional `mu` and
     response-scale `nu` in `(1, 2)` inside both zero-regime cells. The
     skew-normal boundary test now reads the first-test contract while still
     requiring `skew_normal()` to be absent.
181. Slices 1631-1632 and 1685-1686 add comparator and support-boundary
     decisions in
     `docs/design/130-phase-18-comparator-boundary-decisions-slices-1631-1632-1685-1686.md`.
     Tweedie weights remain top-level row log-likelihood multipliers, but a
     weighted external comparator waits for a dedicated weighting-semantics
     check. Tweedie offsets stay outside the first comparator pass because
     offset syntax is currently implemented only for count-family `mu`
     exposure models. The future skew-normal lane should validate finite
     continuous responses after model-frame filtering and should use shared
     fixed-effect rank handling unless density tests expose a family-specific
     issue.
182. Slice 1631 addendum adds an internal Tweedie row-weight invariant in
     `docs/design/131-phase-18-tweedie-weight-invariant-slice-1631-addendum.md`.
     Constant row weights double the log-likelihood without moving `mu`,
     `sigma`, or intercept-only `nu`, and integer row weights match explicit
     row duplication. The weighted external `glmmTMB` comparator remains
     postponed until a dedicated weighting-semantics target is written.
183. Slices 1639, 1641, and 1642 harden the fitted Tweedie simulation test.
     `tests/testthat/test-tweedie-location-scale.R` now checks that
     `simulate()` returns the expected data-frame shape and column names,
     preserves the fitted-row count after ordinary missing-row filtering,
     produces finite non-negative draws with exact zeros, and reproduces
     identical draws for repeated calls with the same seed. This is a
     simulation-method invariant for the fitted fixed-effect lane, not
     evidence for predictor-dependent `nu`, random effects, structured
     effects, bivariate Tweedie, zero-inflation aliases, or hurdle aliases.
184. Slices 1644-1646 add the fixed-effect Tweedie artifact-lane preflight in
     `docs/design/133-phase-18-tweedie-fixed-effect-artifact-preflight-slices-1644-1646.md`.
     The note names the future `tweedie_fixed_effect` DGP, estimands, summary
     columns, manifest, and failure-ledger fields before any runner or grid
     writer is added. It keeps the lane univariate, fixed-effect, unweighted,
     and intercept-only for `nu`, excluding offsets, random effects,
     structured effects, bivariate Tweedie, zero-inflation aliases, and hurdle
     aliases.
185. Slices 1689-1702 add the skew-normal implementation gate in
     `docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md`.
     The gate keeps `skew_normal()` planned, not fitted, while naming the
     required density, normal-limit, sign-orientation, malformed-neighbour,
     method, documentation, provenance, no-fit boundary, recovery,
     false-positive, confounding, interval-status, diagnostic, runtime, DGP,
     and summary checks for the first implementation PR. It does not add a
     constructor, TMB branch, formula-grammar change, or user-facing example.
186. Slice 1703 adds a test-only skew-normal density contract fixture in
     `tests/testthat/helper-skew-normal-density.R` and
     `tests/testthat/test-skew-normal-density-contract.R`. The fixture checks
     the accepted public-moment to native-density transform, integration to
     one, the `nu = 0` Gaussian limit, and the public sign orientation before
     any `skew_normal()` constructor, TMB branch, formula-grammar change, or
     user-facing example exists.
187. Slice 1704 adds a direct Tweedie density fixture in
     `tests/testthat/helper-tweedie-density.R`. The focused
     `test-tweedie-location-scale.R` suite now compares an intercept-only
     fitted `tweedie()` log likelihood with the independent compound
     Poisson-Gamma density, including exact-zero mass and positive-density
     terms. This is likelihood-constant evidence only; it does not add a
     Tweedie DGP, runner, grid writer, coverage table, predictor-dependent
     `nu`, random effects, structured effects, bivariate Tweedie, or
     zero-inflation/hurdle aliases.
188. Slices 1705-1708 add the first `tweedie_fixed_effect` Phase 18 artifact
     implementation. The lane now has a low/high-zero DGP, fit summariser,
     smoke runner, summary reducer, saved-result resume check, and Wald
     artifact smoke test for `bf(y ~ x, sigma ~ z, nu ~ 1)` with public
     `sigma = sqrt(phi)`. This is still a small smoke artifact lane: no grid
     writer, Actions task, predictor-dependent `nu`, random effects,
     structured effects, bivariate Tweedie, offset/exposure route,
     zero-inflation alias, or hurdle alias is added.
