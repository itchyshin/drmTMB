# Phase 6c Random-Slope Simulation Plan

This note closes the #446 planning gate. It tells the next Phase 18 worker
which random-slope grids to run first, what each grid may prove, which
artifacts it must save, and which claims remain candidate-only until formal
recovery or coverage evidence exists. It follows the ADEMP structure of
Morris, White, and Crowther (2019) and the transparent-reporting checklist of
Williams et al. (2024).

## Gate Decision

Phase 6c is ready for staged random-slope simulation pilots, not for one large
power run. The next work should start with focused diagnostic pilots that use
the already fitted surfaces and stop before broad claims when convergence,
boundary, interval, or artifact checks fail.

| Surface | Current status | First simulation status | Allowed claim after the first pilot | Held from |
| --- | --- | --- | --- | --- |
| Ordinary Gaussian `mu` q > 2 grouped slopes | Fitted with q=3 recovery, q=4 output-contract, extractor, `corpairs()`, `summary()`, and `profile_targets()` evidence | Formal pilot design | Bias/RMSE, convergence, boundary, and direct-SD profile readiness for named q=3/q=4 cells | Broad arbitrary q, q > 2 direct correlation intervals, and p6/p8 endpoint claims |
| Independent Gaussian `sigma` slopes | Fitted on log-`sigma` with direct `log_sd_sigma` targets | Formal pilot design | Recovery and diagnostics for independent residual-scale slope SDs | Correlated or labelled residual-scale slope covariance |
| Bivariate Gaussian slope-only `mu1`/`mu2` | Artifact-ready through `biv_gaussian_mu_slope`; #440 holds it from recovery, coverage, and power | Formal pilot after the existing smoke artifact | Slope-SD and slope-slope group-correlation recovery for matching `(0 + x | p | id)` only | Intercept-plus-slope q4, random `rho12`, and p8/q8 |
| Bivariate Gaussian q4 location `mu1`/`mu2` | Artifact-wired for matching `(1 + x | p | id)` through `biv_gaussian_q4_location` | Smoke artifact lane before any recovery or coverage pilot | Extractor, direct-SD profile-target, diagnostic, simulation, and derived-correlation status for the q4 location block only | q6 recovery, random `rho12`, q8 coverage/power, and broader p8/q8 endpoint variants |
| Bivariate Gaussian q6 location `mu1`/`mu2` | Artifact-wired for matching `(1 + x + z | p | id)` through `biv_gaussian_q6_location` | Smoke artifact lane before any recovery or coverage pilot | Extractor, direct-SD profile-target, diagnostic, simulation, and derived-correlation status for the q6 location block only | Recovery, coverage, power, random `rho12`, q8 coverage/power, and broader p8/q8 endpoint variants |
| Ordinary Poisson/NB2 independent `mu` slopes | `ready_grid` in the registry with focused tests and first-wave task routing | Formal pilot design | Count-link fixed-effect and slope-SD recovery for non-zero-inflated ordinary count models | Zero-inflated or hurdle random effects, correlated count slopes, labelled covariance, and structured count slopes |
| Student-t, lognormal, Gamma, beta, beta-binomial, zero-truncated NB2 independent `mu` slopes | `ready_source_test` by #441 | Smoke artifact design first, then formal pilot only after smoke audit | Source-tested route becomes artifact-backed if all smoke manifests and diagnostics pass | Coverage, power, correlated slopes, `sigma` or shape random effects, structured effects, and mixed-response models |
| Gaussian `phylo()`, `spatial()`, `animal()`, and `relmat()` one-slope `mu` | Fitted for one numeric univariate Gaussian `mu` slope; #442 records q2/q4 boundaries | Structured one-slope wrapper design | Structured intercept/slope SD recovery for one marker family at a time | Multiple structured slopes, structured slope correlations, residual-scale structured slopes, structured `rho12`, and non-Gaussian structured slopes |
| Coscale and `corpairs()` boundary | #443 separates residual `rho12` from latent group/structured correlations | Reporting and stale-claim gate, not a DGP | Tables distinguish residual `rho12`, group-level correlations, and structured correlations | Random effects in `rho12` and treating `rho12` as a latent covariance layer |

## Run Order

1. **Registry preflight.** Print the `workflow_lane == "random_slopes"` rows
   from `inst/sim/registry/phase18_structured_workflow_registry.csv`, and fail
   closed if any row lacks an `admission_status`, `existing_actions_task`, or
   `supervision_boundary`. This dry run is available through
   `phase18_random_slope_registry_preflight()` and
   `phase18_print_random_slope_registry_preflight()`.
2. **Bivariate slope-only pilot.** Reuse the existing `biv_gaussian_mu_slope`
   task because it already writes aggregate, replicate, manifest, and
   failure-ledger artifacts. Increase only from smoke to diagnostic pilot
   scale. Do not request profile intervals in the first larger run.
3. **Bivariate q=4 location preflight.** Use the separate artifact lane for
   matching `(1 + x | p | id)` in `mu1` and `mu2` before any recovery or
   coverage pilot. Keep derived q=4 correlations as point/status rows until a
   nonlinear interval method exists.
4. **Bivariate q=6 location preflight.** Use the separate artifact lane for
   matching `(1 + x + z | p | id)` in `mu1` and `mu2` before any recovery or
   coverage pilot. Keep derived q=6 correlations as point/status rows until a
   nonlinear interval method exists.
5. **Ordinary Gaussian slope pilots.** Run Gaussian `mu` q=3/q=4 and
   independent `sigma` slope pilots as separate condition sets so location and
   residual-scale failure rates are not averaged together.
6. **Count `mu` slope pilot.** Run ordinary Poisson and NB2 independent slopes
   together only when the report keeps family-specific rows. Keep
   zero-inflated, hurdle, and labelled covariance requests out.
7. **Source-tested non-Gaussian smoke artifacts.** Give Student-t, lognormal,
   Gamma, beta, beta-binomial, and zero-truncated NB2 independent `mu` slopes
   a small artifact writer before any formal coverage or power grid.
8. **Structured Gaussian one-slope wrapper.** Run `phylo()`, `spatial()`,
   `animal()`, and `relmat()` as separate marker families with the same table
   schema. Do not combine their results into one "structured slope" rate until
   each marker has passed its own diagnostics.

## Surface ADEMP Sheets

Each admitted surface gets a compact design sheet before code is written. These
sheets set the first grid that a future runner may implement; later tasks may
split a row into a longer one-page design when the pilot conditions become
final.

| Surface | Aim | Data-generating mechanism | Estimands | Methods | Performance measures |
| --- | --- | --- | --- | --- | --- |
| Ordinary Gaussian `mu` q > 2 grouped slopes | Test whether fitted q=3 and q=4 ordinary location-slope blocks recover fixed slopes, direct SDs, and diagnostics before larger q claims. | Gaussian response with centered numeric predictors, grouped intercept and slope vector, varied group count, repeats, slope SD, and correlation. | Link-scale fixed `mu` slopes, direct random-slope SDs, fitted correlations as point summaries, convergence, `pdHess`, boundary, and elapsed time. | `drmTMB` Gaussian grouped model only; optional `lme4` comparison can be recorded but does not replace drmTMB evidence. | Bias, RMSE, convergence, Hessian, boundary, warning, runtime, and direct-SD interval coverage only when profile rows are requested. |
| Independent Gaussian `sigma` slopes | Test whether independent residual-scale slope SDs recover on log-`sigma` without averaging failures with location slopes. | Gaussian location-scale response with one grouped independent scale slope on `eta_sigma`, varied group count, repeats, and scale-slope SD. | Fixed `sigma` coefficients, direct `log_sd_sigma` slope SDs, convergence, `pdHess`, boundary, warning, and runtime. | `drmTMB` Gaussian `sigma` random-slope model; no correlated or labelled residual-scale covariance comparator. | Bias, RMSE, convergence, Hessian, boundary, warning, runtime, and direct-SD interval coverage when available. |
| Bivariate Gaussian slope-only `mu1`/`mu2` | Test whether the matching slope-only `mu1`/`mu2` lane recovers slope SDs and the direct slope-slope correlation. | Two Gaussian responses with matched `(0 + x | p | id)` slope fields, residual `rho12` fixed separately, varied group count, repeats, slope correlation, and residual `rho12`. | Fixed `mu1`/`mu2` slopes, slope SDs, slope-slope latent correlation, residual `rho12`, diagnostics, and runtime in separate rows. | `drmTMB` bivariate Gaussian slope-only model through the existing artifact route. | Bias, RMSE, convergence, Hessian, boundary, warning, runtime, and direct correlation or SD interval coverage only after a diagnostic pilot passes. |
| Bivariate Gaussian q4 location `mu1`/`mu2` | Test whether the matching q4 location block is artifact-ready before recovery or coverage claims. | Two Gaussian responses with matched `(1 + x | p | id)` location blocks, residual `rho12` fixed separately, varied group count, repeats, intercept/slope SDs, q4 latent correlation pattern, and residual `rho12`. | Fixed `mu1`/`mu2` coefficients, four direct location SDs, six derived q4 location correlations, residual `rho12`, diagnostics, and runtime in separate rows. | `drmTMB` bivariate Gaussian q4 location model through the q4 artifact route; no q6, residual-scale, same-response location-scale, or all-four endpoint comparator. | Smoke-manifest completion, finite estimates, convergence, Hessian, boundary, warning, runtime, and direct-SD interval readiness in the q4 smoke lane. |
| Bivariate Gaussian q6 location `mu1`/`mu2` | Test whether the matching q6 location block is artifact-ready before recovery or coverage claims. | Two Gaussian responses with matched `(1 + x + z | p | id)` location blocks, residual `rho12` fixed separately, varied group count, repeats, intercept/two-slope SDs, q6 latent correlation pattern, and residual `rho12`. | Fixed `mu1`/`mu2` coefficients, six direct location SDs, 15 derived q6 location correlations, residual `rho12`, diagnostics, and runtime in separate rows. | `drmTMB` bivariate Gaussian q6 location model through the q6 artifact route; no residual-scale, same-response location-scale, all-four endpoint, or q8 comparator. | Smoke-manifest completion, finite estimates, convergence, Hessian, boundary, warning, runtime, and direct-SD interval readiness in the q6 smoke lane. |
| Ordinary Poisson/NB2 independent `mu` slopes | Test ordinary count-link slope recovery before opening count covariance, zero-inflation, hurdle, or structured count requests. | Poisson or NB2 response with `eta_mu = X beta + b_id x`, varied family, group count, repeats, mean count, slope SD, and NB2 `sigma`. | Fixed count-link coefficients, independent slope SDs, NB2 scale where fitted, diagnostics, warning classes, and runtime. | `drmTMB` Poisson/NB2 grouped slope models; `lme4` can inform ordinary count means where targets match. | Bias, RMSE, convergence, Hessian, boundary, warning, runtime, and family-specific failure-ledger rates. |
| Source-tested non-Gaussian independent `mu` slopes | Turn source-tested selected families into artifact-backed candidates before any coverage or power claim. | Independent `mu` slope DGP for one family at a time: Student-t, lognormal, Gamma, beta, beta-binomial, or zero-truncated NB2. | Link-scale fixed coefficients, slope SDs, family scale/precision where fitted, diagnostics, warning classes, and runtime. | `drmTMB` family-specific grouped slope route; no correlated, labelled, structured, shape, or mixed-response comparator. | Smoke-manifest completion, finite estimates, convergence, Hessian, boundary, warning, runtime, then bias/RMSE only after smoke artifacts pass. |
| Structured Gaussian one-slope `mu` | Test one marker family at a time before combining structured slope claims. | Gaussian response with structured intercept and one numeric slope field using `phylo()`, `spatial()`, `animal()`, or `relmat()` precision/covariance input. | Fixed `mu` slopes, structured intercept SD, structured slope SD, marker-specific diagnostics, direct profile-target status, and runtime. | `drmTMB` marker-specific Gaussian one-slope model; no cross-marker pooled success rate. | Bias, RMSE, convergence, Hessian, boundary, warning, runtime, direct-SD interval readiness, and matrix/coordinate-condition failure rates. |
| Coscale and `corpairs()` reporting boundary | Prevent residual `rho12` evidence from being mixed with latent group or structured correlation evidence. | No DGP of its own; every runner must tag residual-coscale and latent-correlation rows separately. | Residual `rho12`, group-level correlations, structured correlations, interval status, and unsupported-request flags. | Reporting/stale-claim audit attached to each relevant pilot. | Stale-claim scan, table-grain audit, and explicit unsupported-neighbour count; no recovery or power metric. |

## A - Aims

Primary aim: estimate when each admitted Phase 6c random-slope surface recovers
fixed effects, random-slope SDs, and fitted correlations well enough to support
public tutorials and later power calculations.

Secondary aims:

- measure convergence, Hessian, boundary, warning, and failure-ledger rates
  before any formal power grid is dispatched;
- compare interval routes only where the target is direct and available in
  `profile_targets()`;
- keep residual `rho12`, ordinary group-level covariance, and structured
  covariance in separate reporting rows;
- identify sample-size and signal-strength cells that should stay diagnostic
  rather than graduate to recovery or coverage claims.

## D - Data-Generating Mechanisms

Every DGP uses one centered numeric predictor and one grouping or structured
factor unless the surface-specific formula requires a paired response. Condition
tables must state group count, observations per group, predictor spread,
random-slope SD, fixed-slope size, family-specific scale or dispersion, seed,
and replicate count.

| Surface | DGP sketch | First varied factors |
| --- | --- | --- |
| Gaussian `mu` q > 2 | `eta_mu = X beta + b0_id + b1_id x1 + b2_id x2`; `b_id` multivariate normal | groups `{30, 80}`, repeats `{6, 12}`, slope SD `{0.15, 0.45}`, correlation `{0, 0.4}` |
| Gaussian `sigma` independent slope | `eta_sigma = X gamma + a_id w`; `a_id ~ Normal(0, sd_sigma_slope^2)` | groups `{40, 100}`, repeats `{6, 12}`, scale-slope SD `{0.10, 0.35}` |
| Bivariate slope-only | `eta_mu1 = X1 beta1 + b1_id x`; `eta_mu2 = X2 beta2 + b2_id x`; `(b1_id, b2_id)` bivariate normal; residual `rho12` fixed separately | groups `{40, 100}`, repeats `{6, 12}`, slope correlation `{0, 0.5}`, residual `rho12` `{0, 0.4}` |
| Bivariate q=4 location | `eta_mu1 = X1 beta1 + b01_id + b11_id x`; `eta_mu2 = X2 beta2 + b02_id + b12_id x`; four location effects are multivariate normal; residual `rho12` fixed separately | groups `{40, 100}`, repeats `{6, 12}`, intercept SD, slope SD, latent-correlation pattern, residual `rho12` `{0, 0.4}` |
| Poisson/NB2 `mu` slopes | `eta_mu = X beta + b_id x`; response generated from Poisson or NB2 with fixed overdispersion for NB2 | groups `{40, 100}`, repeats `{6, 12}`, mean count `{1.5, 8}`, slope SD `{0.15, 0.45}`, NB2 `sigma` `{0.3, 0.8}` |
| Source-tested non-Gaussian `mu` slopes | Same independent-slope linear predictor; response family is Student-t, lognormal, Gamma, beta, beta-binomial, or zero-truncated NB2 | family, groups `{40, 100}`, repeats `{6, 12}`, slope SD `{0.15, 0.45}`, family-specific scale/precision |
| Structured Gaussian one-slope | `eta_mu = X beta + z0_level + z1_level x`; structured intercept and slope fields share the marker precision but have independent SDs | marker family, levels `{40, 120}`, repeats `{4, 10}`, slope-field SD `{0.10, 0.35}`, matrix conditioning or coordinate spread |

Diagnostic pilots should use `n_reps = 100` or `200` per cell. Formal coverage
pilots should use at least `n_reps = 500`, giving approximate Monte Carlo
standard error below 1 percentage point for 95% coverage. Final power or
coverage claims should use `n_reps = 1000` when runtime and diagnostics permit,
giving approximate 95% coverage MCSE below 0.7 percentage points.

## E - Estimands

Each replicate must store the true value and fitted estimate for:

- fixed `mu` coefficients on the link scale;
- fixed `sigma`, family-specific scale, or dispersion coefficients when fitted;
- random-slope SDs as direct `sd:<dpar>:<term>` targets;
- fitted group-level slope correlations only when the model estimates a direct
  correlation parameter;
- residual `rho12` only in residual-coscale rows;
- convergence code, `pdHess`, warning count, elapsed time, boundary status,
  and `check_drm()` status rows.

Derived q4 correlations, q > 2 ordinary correlations, and nonlinear
response-scale summaries may be reported as derived point summaries, but they
do not become interval targets in this plan.

## M - Methods

The first method is always the implemented `drmTMB` route named by the fitted
surface. Comparator fits are optional and must be justified by a matched target:
`lme4` can compare ordinary Poisson/NB2-style grouped count mean structures
where scales match, but fixed-effect-only comparators do not validate
random-slope recovery. `glmmTMB`, `brms`, or direct TMB prototypes may inform
later issue #60 comparator work; they do not count as drmTMB evidence until the
same target is reproduced with drmTMB fits and recorded artifacts.

## P - Performance Measures

Every aggregate table must include the metric and its Monte Carlo standard
error where the metric is an average or proportion.

| Measure | Formula or rule | Required grain |
| --- | --- | --- |
| Bias | `mean(estimate - truth)` | aggregate plus replicate rows |
| RMSE | `sqrt(mean((estimate - truth)^2))` | aggregate plus replicate rows |
| Coverage | `mean(ci_low <= truth & truth <= ci_high)` | interval replicate rows; only for direct interval targets |
| Power or false-positive rate | `mean(p_value < alpha)` or equivalent profile/bootstrap decision rule, pre-declared per target | formal power grids only |
| Convergence rate | `mean(convergence == 0)` | fit-level replicate rows |
| Hessian pass rate | `mean(pdHess == TRUE)` | fit-level replicate rows |
| Boundary rate | `mean(boundary_status != "ok")` | fit-level replicate rows and failure ledger |
| Warning/error rate | counts and proportions by condition and warning class | failure ledger plus aggregate rows |
| Runtime | elapsed seconds per fit and per cell | manifest and aggregate rows |

## Required Artifacts

Each pilot or formal grid must write these tables with stable prefixes:

- `*-manifest.csv`: one row per replicate or condition artifact with seed,
  platform, package SHA, R version, task, condition id, status, and paths;
- `*-replicates.csv`: one row per fitted replicate and estimand, including
  truth, estimate, error, convergence, Hessian, boundary, warning, and elapsed
  fields;
- `*-aggregate.csv`: one row per condition, family, dpar, and estimand with
  bias, RMSE, MCSEs, convergence, Hessian, warning, and boundary summaries;
- `*-intervals.csv`: only for requested direct interval targets, with method,
  level, endpoint status, and interval failure reason;
- `*-coverage.csv`: only when interval rows are requested and the replicate
  count meets the MCSE target;
- `*-failures.csv`: one row per failed fit, profile, bootstrap, parsing, or
  artifact-write event.

Reports should include sections for surface status, condition table, fitted
estimands, operating characteristics, diagnostics, failure ledger, runtime, and
claim boundary. Figure code must choose geometry from artifact grain:
replicate-level rows may show error distributions; aggregate-only rows should
show points, intervals, and MCSE bars.

## Execution Guidance

Use local runs for smoke checks and for a single condition from each new table.
Use manual GitHub Actions dispatch for bounded public artifacts with
matrix-sharded jobs, `fail-fast: false`, explicit timeouts, artifact upload,
and a final aggregation step. Use Totoro only for formal or final grids after
local and Actions pilots pass; record SSH assumptions, worker count, package
SHA, and output paths. Do not dispatch a large power grid until the diagnostic
pilot has no unexplained optimizer failures and condition-level stop rules pass.

Default worker limits:

- local laptop smoke: one to four workers;
- GitHub Actions selected job: at most two workers unless a prior task-specific
  audit shows more is stable;
- Totoro formal grid: target 50 to 100 cores, never all available cores, and
  shard by condition before parallelizing within condition.

## Stop Rules

A condition remains diagnostic-only when any of these triggers fire:

- optimizer failures or non-finite estimates exceed 2% of fits;
- `pdHess = FALSE` exceeds 5% of fits;
- boundary warnings exceed 15% of fits or cluster in one condition;
- profile interval failure exceeds 10% for a direct interval target;
- warning-ledger messages are unexplained or platform-specific;
- runtime exceeds the selected job budget before all artifacts are written;
- a stale-claim scan finds recovery, coverage, or power wording for a surface
  whose replicate count or interval evidence does not support it.

Passing a diagnostic pilot permits a formal-pilot design. It does not by itself
permit public recovery, coverage, or power claims.

## Williams 11-Item Self-Audit

| Item | Covered here? | Evidence |
| --- | --- | --- |
| 1. Aims | Yes | `A - Aims` states primary and secondary aims. |
| 2. Data-generating mechanisms | Yes | `D - Data-Generating Mechanisms` names hierarchy, random effects, conditions, and replicate tiers. |
| 3. Estimands | Yes | `E - Estimands` defines truths and fitted quantities. |
| 4. Methods | Yes | `M - Methods` states `drmTMB` and comparator boundaries. |
| 5. Performance measures | Yes | `P - Performance Measures` defines bias, RMSE, coverage, power, convergence, Hessian, boundary, warning, and runtime measures. |
| 6. Software and platform | Planned artifact | The manifest must store package SHA, R version, platform, task, and condition id. |
| 7. Code availability | Planned artifact | Runners and reports must live under `inst/sim/` and `docs/design/`. |
| 8. Data availability | Planned artifact | Simulated replicate and aggregate CSVs must be uploaded as artifacts or stored in documented local paths. |
| 9. Case-study context | Deferred to #444 | Tutorials and release-ledger prose should decide which surfaces get reader-facing examples. |
| 10. Results reporting | Yes | Required reports include operating characteristics, diagnostics, failure ledger, runtime, and claim boundary. |
| 11. Monte Carlo uncertainty | Yes | Replicate tiers and MCSE requirements are specified for diagnostic, formal, and final grids. |

## Issue Routing

#446 is closed by this plan once the check-log and after-task report record
validation. #59 remains open for the broader Phase 18 programme. #444 owns the
reader-facing tutorial and release-ledger path after the simulation status is
stable. The first #437 scout protocol is recorded in
`docs/dev-log/twin-sister-exchange.md`; it should not be used as evidence that
another package's speed, convergence, or coverage transfers to `drmTMB`.
