# drmTMB Roadmap

`drmTMB` is a focused R package for fast univariate and bivariate
distributional regression models using TMB.

## Version 0.1.1 Preview Release

- Current preview version: `0.1.1`.
- Meaning of `0.1.1`: a patch preview that includes the first large-data
  storage controls and corrected installation guidance. It is not the final
  double-hierarchical individual-difference endpoint.
- Release boundary: Phase 9 is closed at the implemented ordinal and
  denominator-aware MVPs. The first Phase 11 bivariate `mu1`/`mu2`
  random-intercept covariance slice is now implemented. Phase 18 records the
  visualization and marginal-effects layer that should make fitted location,
  scale, coscale, random-effect SD, and latent correlation results easier to
  inspect across model families. Richer bivariate random slopes,
  residual-scale covariance, structured covariance, and the full
  double-hierarchical endpoint remain roadmap work for later releases.
- Completed before bumping the version:
  - `devtools::check()` passes with 0 errors, 0 warnings, and 0 notes;
  - `devtools::test()` and `pkgdown::check_pkgdown()` pass;
  - pkgdown deploys with the short landing page and current family reference
    pages;
  - implemented families have simulation, independent-likelihood, or
    comparator coverage plus malformed-input tests;
  - `docs/dev-log/known-limitations.md`, `NEWS.md`, `README.md`, and the
    roadmap agree about what is implemented versus planned;
  - paper examples for individual-difference location-scale models are
    presented as a replication roadmap unless the matching drmTMB model class
    is actually implemented and tested.

## Phase 0: Project Infrastructure

- R package scaffold with `DESCRIPTION`, `R/`, `src/`, `tests/`, and
  vignettes.
- Design documents for formula grammar, families, likelihoods, random effects,
  testing, distribution priorities, and the reference/paper programme.
- Codex-native project instructions, agents, and skills.
- Continuous integration for R CMD check.

## Phase 1: Gaussian Location-Scale MVP

- Status: initial MVP implemented.
- `bf()` and `drmTMB()` support Gaussian location-scale models with fixed
  effects, `mu` random intercepts, simple numeric `mu` random slopes, and
  residual-scale random intercepts plus independent random slopes in `sigma`.
- Supported syntax:
  `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x2 + (1 | id) + (0 + w | id))`.
- Keep parser support for `sd(group) ~`, `meta_known_V(V = V)`, `phylo()`,
  and `spatial()` terms from the start.
- Prediction for `mu` and `sigma` is implemented.
- Simulation and parameter-recovery tests are implemented for the first
  Gaussian case.

## Phase 2: Meta-Analytic Gaussian Regression

- Status: diagonal and dense full known sampling covariance implemented.
- Treat meta-analysis as `family = gaussian()` plus `meta_known_V(V = V)`.
- Support known sampling covariance through vectors, columns, diagonal matrices,
  dense block-diagonal matrices, or dense full matrices.
- The implemented known-covariance Gaussian path is now tested with ordinary
  `mu` random intercepts and random-effect scale formulae such as
  `sd(id) ~ x_group` using independent dense marginal-likelihood comparators.
- Add sparse known covariance after dense covariance tests pass.
- Use `sigma ~ x1` for heterogeneous heterogeneity, even when papers
  describe the same unknown SD as `tau`.
- Tests based on fixed known sampling variance and known extra heterogeneity
  are implemented.

## Phase 2b: Likelihood Weights

- Status: implemented for ordinary row likelihood weights.
- A top-level `weights =` argument to `drmTMB()` now supplies ordinary
  likelihood weights, matching the broad convention in mixed-model packages.
- Keep likelihood weights separate from `meta_known_V(V = V)`: weights multiply
  observation log-likelihood contributions, whereas `meta_known_V()` supplies
  known sampling covariance.
- Implemented design rule: univariate models use one non-negative finite
  weight per observation; bivariate models use one weight per complete response
  pair.
- Do not add response-specific bivariate weights until the likelihood and
  interpretation are documented.
- Full dense `meta_known_V(V = V)` covariance paths reject non-unit
  `weights =` until a joint-block weighting design is documented.

## Phase 3: Bivariate Gaussian Coscale

- Status: fixed-effect bivariate Gaussian implemented and closure-audited;
  matched labelled `mu1`/`mu2` random-intercept covariance blocks are
  implemented as the first bivariate group-level covariance slice.
- Support separate formulas for `mu1 = y1 ~ ...` and `mu2 = y2 ~ ...`.
- `mvbind(y1, y2) ~ x` is implemented as shorthand for identical location
  formulas and expands internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.
- Added `sigma1`, `sigma2`, and constant `rho12`.
- Added predictor-dependent `rho12 ~ x` using an unconstrained correlation
  predictor with a tanh response transform.
- Added simulation tests for positive, near-zero, negative, and
  predictor-dependent residual correlations.
- Added tests and documentation for `rho12()`, `corpairs()`, `fitted()`,
  `sigma()`, `simulate()`, whitened Pearson residuals, and coefficient-level
  `vcov()` names.
- Added complete-row bivariate Gaussian known sampling covariance through
  `meta_known_V(V = V)` and `meta_vcov_bivariate()`, with an independent base R
  MVN likelihood comparator and tests that residual `rho12` stays distinct from
  known sampling correlation.
- Added row likelihood weights for independent bivariate rows; dense known-`V`
  bivariate fits reject non-unit weights until a joint-block weighting design is
  documented.
- Public bivariate family grammar accepts `family = c(gaussian(), gaussian())`
  or `family = list(gaussian(), gaussian())` for the implemented all-Gaussian
  likelihood. Mixed composed families such as `family = c(gaussian(), poisson())`
  remain future work where the joint likelihood is defined.
- Matching labelled random intercepts in `mu1`/`mu2` and `sigma1`/`sigma2`,
  such as `(1 | p | id)` in both same-parameter formulas, now fit group-level
  covariance blocks. The group-level SDs are reported in `sdpars$mu` or
  `sdpars$sigma`, the group-level correlations are reported in `corpars$mu` or
  `corpars$sigma` and `corpairs()`, and residual `rho12` remains separate.
  Targeted simulation coverage now fits both bivariate group-level covariance
  blocks in the same model with predictor-dependent residual `rho12 ~ x`; the
  same regression now checks that `summary(fit)$covariance` reports the two
  group-level covariance rows and omits residual `rho12`.
- One same-response bivariate `mu`/`sigma` random-intercept covariance block is
  implemented, such as matching `(1 | p | id)` terms in `mu1` and `sigma1` or
  in `mu2` and `sigma2`. This is still a pairwise bridge, not the full shared
  labelled block across `mu1`, `mu2`, `sigma1`, and `sigma2`.
- Bivariate random slopes, random effects in `rho12`, bivariate
  `meta_known_V()` plus random effects, multi-term cross-parameter bivariate
  covariance, and structured bivariate covariance remain future work and are
  rejected before optimization.

## Phase 4: Mixed and Double-Hierarchical Models

- Status: random intercepts, independent numeric random slopes written as
  `(0 + x | id)`, and ordinary correlated intercept-slope blocks written as
  `(1 + x | id)` or `(1 + x | p | id)` are implemented for the univariate
  Gaussian location formula. Random intercepts in the residual `sigma` formula
  and independent residual-scale random slopes written as `(0 + x | id)` are
  also implemented, and matching labelled `mu`/`sigma` random intercepts now
  fit the first univariate mean-scale covariance block. Random-effect scale
  formulae are implemented for one or more distinct unlabelled Gaussian `mu`
  random intercepts, such as `sd(id) ~ x_group` and `sd(site) ~ site_type`.
  The bivariate Gaussian path now fits matched labelled `mu1`/`mu2`,
  `sigma1`/`sigma2`, and same-response `mu`/`sigma` random-intercept
  covariance blocks.
- The R-side labelled covariance block registry now records the implemented
  two-member `mu`, `sigma`, and `mu`/`sigma` bridges without changing accepted
  syntax or fitted behaviour. It also carries a dormant TMB-shaped block data
  contract for those bridges. `corpairs()` now derives covered group-level
  rows from the registry, with legacy label parsing as a compatibility
  fallback, and `check_drm()` derives covered covariance diagnostics from
  registry members while preserving current diagnostic rows. `profile_targets()`
  derives covered random-effect correlation targets from registry pairs while
  preserving target names and indices. The design contract remains
  `docs/design/30-labelled-covariance-block-assembler.md`; the two-member
  dormant contract now crosses the C++ boundary as a no-op visibility check.
  The registry can internally enumerate all pair rows for a guarded
  three-member block, but marks that scaffold unimplemented and still blocks
  TMB export for `q > 2`. Larger shared labels still need simulation recovery
  and a positive-definite `q > 2` likelihood path before exposure. Internal TMB
  probes now confirm that `UNSTRUCTURED_CORR_t` plus `VECSCALE_t` can produce a
  positive-definite q=3 correlation, finite objective/gradient, a non-centered
  `sqrt_cov_scale()` transform, a hidden registry-shaped member/group
  contribution map using a dormant TMB parameter, an internal Laplace
  random-effect boundary for that probe parameter, a hidden Gaussian likelihood
  prototype that routes q=3 member contributions into `mu` and `log_sigma`, and
  a hidden Laplace version of that likelihood prototype. A deterministic
  hidden simulation-style check now verifies that this path can recover the
  simulated q=3 predictor signal better than a no-random-effect baseline. The
  first q=4 bridge now confirms that one guarded block can enumerate
  `mu1`/`mu2`/`sigma1`/`sigma2` members, all six pair rows, and a hidden
  positive-definite contribution map. A hidden bivariate Gaussian probe now
  routes those four intercept-level member contributions into `mu1`, `mu2`,
  `log(sigma1)`, and `log(sigma2)` and checks the resulting likelihood against
  an R-side reconstruction. The same hidden branch can now pass the q=4 latent
  vector through TMB's `random` argument and reconstruct the predictors from the
  optimized random-effect mode. A deterministic hidden recovery-style check now
  shows that this bivariate q=4 Laplace path recovers the simulated endpoint
  predictor signals better than no-random-effect baselines. An internal
  `corpairs()` scaffold can now format all six q=4 endpoint rows from
  fitted-like registry metadata, and `profile_targets()` can format the matching
  six endpoint correlation targets. Dormant q > 2 rows remain invisible to
  ordinary extractor/profile output. These probes are not user-facing
  fitted-model support yet and do not cover random-slope q=6 or q=8 endpoint
  blocks. The corresponding constant phylogenetic q=4 state is now fitted for
  matching labelled all-four `phylo()` terms; the next phylogenetic work is
  recovery evidence, diagnostics, and tutorial hardening. q=6 and q=8
  random-slope endpoint blocks can wait.
- Use `docs/design/18-random-effect-scale-models.md` as the design contract:
  the implemented MVP targets one or more distinct unlabelled univariate
  Gaussian `mu` random intercepts, with group-level predictors, simulation
  recovery tests, and an `lme4` overlap test.
- Extend random-effect scale models beyond unlabelled intercept targets, such
  as slope-specific, labelled-block, bivariate, and non-Gaussian targets.
- Respect labelled correlated group syntax such as `(1 + x | p | id)` when
  scale and bivariate random-effect paths are added.
- Add variance-component correlation summaries when identifiable.

## Phase 5: Phylogenetic and Spatial Dependence

- Status: first univariate Gaussian phylogenetic location path implemented;
  first matching bivariate `mu1`/`mu2` phylogenetic location slice implemented;
  first univariate Gaussian coordinate-based spatial location path implemented.
- Treat phylogenetic and spatial terms as one structured-effect module:
  `z ~ MVN(0, sigma_z^2 K)`, with `K = A` for phylogeny and `K = M` for
  spatial dependence.
- Add sparse known-covariance infrastructure beyond the current phylogenetic
  A-inverse path, especially for large known sampling covariance, spatial
  precision matrices, and combined phylogenetic-spatial meta-analysis.
- Implemented `phylo(1 | species, tree = tree)` for univariate Gaussian `mu`
  using an ultrametric branch-length tree, the sparse augmented A-inverse path,
  one CRAN-safe simulation recovery test, and dense marginal likelihood
  comparator tests.
- Implemented matching intercept-only `phylo(1 | species, tree = tree)` terms
  in bivariate Gaussian `mu1` and `mu2`, estimating two phylogenetic location
  SDs and one phylogenetic mean-mean correlation while leaving `sigma1`,
  `sigma2`, and residual `rho12` as ordinary fixed-effect distributional
  parameters. `corpairs()` reports that first fitted phylogenetic mean-mean
  row, `summary(fit)$covariance` reports the matching variance and covariance
  point summaries, and `check_drm()` reports near-boundary `corpars$phylo`,
  weak phylogenetic-SD diagnostics, and ordinary same-species covariance
  overlap for that fitted slice. A CRAN-safe deterministic simulation now
  recovers a positive bivariate phylogenetic mean-mean correlation.
- The first spatial fitted paths are now `spatial(1 | site, coords = coords)`
  and `spatial(1 + x | site, coords = coords)` in univariate Gaussian `mu`.
  They use a fixed exponential coordinate covariance as a small-data foundation.
  The one-slope path estimates independent intercept and slope fields that share
  the coordinate precision, with separate SDs and no intercept-slope
  correlation. `sdpars$mu`, `ranef("spatial_mu")`, `profile_targets()`, and
  `check_drm()` expose those fields with spatial names. Mesh/SPDE, multiple
  spatial slopes, spatial slope correlations, spatial q=4, spatial `sd(...)`,
  and spatial `corpair()` regressions remain planned.
- For bivariate structured models, estimate and report level-specific
  correlations separately: residual `rho12`, phylogenetic correlations,
  non-phylogenetic species correlations, spatial field correlations, and
  ordinary grouped random-effect correlations should not share one namespace.
- The first fitted phylogenetic q=4 location-scale block now shares the same
  matrix-normal prior algebra used by the hidden q=4 scaffold: `mu1`, `mu2`,
  `sigma1`, and `sigma2` effects are stored endpoint-major, with four
  phylogenetic SDs and six unstructured latent correlations. `corpairs()` and
  `summary(fit)$covariance` report all six phylogenetic endpoint rows, while
  `profile_targets()` marks those q=4 correlations as derived `theta_phylo`
  targets rather than direct profile-ready atanh targets. A CRAN-safe recovery
  test now checks broad fixed-effect, SD, residual-correlation, finite-gradient,
  and q=4 diagnostic behavior.
- The univariate Family B `sd_phylo(species) ~ x_species` path is implemented:
  it uses a non-centred unit tree effect, multiplies only observed tip
  contributions by species-level `tau_l = exp(W_l alpha)`, and interprets the
  marginal tip covariance as `D_tip A_tip D_tip`. `check_drm()` now reports
  direct-SD diagnostic rows covering species replication and the fitted
  species-level SD surface range. The bivariate design target is
  now implemented as response-specific location-only direct-SD regression:
  `sd_phylo1()` for the `mu1` phylogenetic location effect, `sd_phylo2()` for
  the `mu2` effect, a constant latent phylogenetic location-location
  correlation, and no mixing with all-four q=4 phylogenetic location-scale
  blocks. `check_drm()` now reports the fitted direct-SD surface range and
  species replication for each univariate or bivariate `sd_phylo*()` endpoint.
- Use the correlation-pair design in
  `docs/design/20-coscale-correlation-pairs.md` before implementing bivariate
  double-hierarchical covariance blocks; pair outputs should identify the
  level, group, block, distributional parameters, responses, and coefficients.
- The first `corpairs()` extractor is implemented for currently fitted
  correlations only: residual `rho12`, ordinary group-level `mu` random-effect
  correlations, the univariate `mu`/`sigma` mean-scale random-intercept
  correlation, and the bivariate `mu1`/`mu2` and `sigma1`/`sigma2`
  random-intercept correlations, plus the fitted bivariate phylogenetic
  mean-mean correlation and all six fitted phylogenetic q=4 endpoint
  correlations when that block is present.
  Extend this table as new correlation likelihoods are added.
- Stage structured phylogenetic and spatial slopes conservatively:
  intercept-only structured effects first, then one `mu` slope, then at most two
  structured `mu` slopes as an advanced path after simulation recovery. Multiple
  random factors should enter as separate additive blocks. Intercept-slope
  `corpair()` rows are distant-future; the more biologically interesting later
  target is a bivariate slope1-slope2 correlation for the same covariate, a
  plasticity-syndrome style model.
- Continue adding identifiability diagnostics for replication by study,
  species, location, and effect-size levels before complex structured models
  are promoted. The first spatial `mu` diagnostic is implemented for the
  coordinate path; mesh/SPDE diagnostics remain tied to the future mesh gate.
- Selectively reuse GPL-compatible ideas or modules from `gllvmTMB` with
  provenance notes and tests.

Phase 5 closure boundary:

| Layer | Implemented before spatial expansion | Still planned |
| --- | --- | --- |
| univariate phylogenetic | `phylo(1 | species, tree = tree)` in Gaussian `mu`, `sd_phylo(species) ~ z`, profile targets and diagnostics | phylogenetic slopes, richer tree-shape recovery grids |
| bivariate phylogenetic | matching `mu1`/`mu2` phylogenetic location correlation, constant q=4 location-scale block, q=2 predictor-dependent `corpair(..., level = "phylogenetic") ~ w`, bivariate `sd_phylo1()` / `sd_phylo2()` | q=4 predictor-dependent location-scale and scale-scale `corpair()` regressions |
| coordinate spatial | `spatial(1 | site, coords = coords)` and one numeric `spatial(1 + x | site, coords = coords)` slope in univariate Gaussian `mu`, `sdpars`, `ranef("spatial_mu")`, direct profile targets, and `check_drm()` rows | mesh/SPDE, multiple spatial slopes, spatial slope correlations, spatial scale, bivariate spatial q=4, spatial direct-SD, spatial `corpair()` |
| inference/output | fixed-effect SEs, direct profile-ready targets where implemented, `corpairs(conf.int = TRUE)` with explicit interval status | derived-profile intervals for q=4 correlations and richer marginal-effect/visualization helpers |

## Phase 5b: Large-Data Memory Strategy

- Status: first storage controls and benchmark harness implemented; Phase 5b
  now hardens those controls for newer structured-effect surfaces. The first
  sparse fixed-effect path is implemented, and the first opt-in Gaussian
  aggregation path is fitted for repeated univariate Gaussian fixed-effect
  rows. Broader sparse matrices, broader aggregation, and repeated
  million-row benchmarks remain planned.
- `drm_control()` now supports optimizer settings plus the first memory-light
  fitted-object controls: `keep_data = FALSE`,
  `keep_model_frame = FALSE`, and `keep_tmb_object = FALSE`.
- `keep_model_frame = FALSE` now also drops nested direct-SD and fitted
  `corpair()` model-frame caches after their model matrices and group metadata
  have been retained.
- `check_drm()` now reports the density of the largest retained fixed-effect
  design block, giving users a concrete sparse-design signal before
  `sparse_fixed` is implemented.
- Internal dense-versus-sparse fixed-effect matrix parity helpers now compare
  `stats::model.matrix()` with `Matrix::sparse.model.matrix()` before any
  sparse fit path is exposed.
- `drm_control(sparse_fixed = TRUE)` now fits the first sparse fixed-effect
  path for univariate Gaussian `mu` fixed effects with intercept-only `sigma`,
  no random effects, no structured effects, and no known covariance.
- The optional large-data benchmark now records the largest fixed-effect design
  block, column count, nonzero count, and density.
- The same benchmark harness now records `structured` and `sparse_fixed`
  settings and can run a non-phylogenetic sparse fixed-effect smoke scenario
  with `--structured none --factor-heavy true --sparse-fixed true`.
- `drm_control(aggregate_gaussian = TRUE)` now fits the first
  sufficient-statistic aggregation path for univariate Gaussian fixed-effect
  models with repeated processed `mu` and `sigma` design rows. Random effects,
  direct-SD formulas, structured effects, known sampling covariance, bivariate
  models, non-Gaussian families, non-unit weights, and combined sparse fixed
  effects remain planned.
- The benchmark harness can run a non-phylogenetic repeated-cell aggregation
  smoke scenario with
  `--structured none --aggregate-gaussian true --aggregation-cells 100`.
- Extend memory-light fit controls for large phylogenetic and spatial
  datasets with broader method-matrix coverage, sparse fixed-effect matrices,
  aggregation, and repeated large-row benchmarks.
- Extend sparse fixed-effect matrix support beyond the first univariate
  Gaussian `mu` path before claiming million-row readiness.
- Use `docs/design/26-sparse-fixed-effect-matrices.md` as the implementation
  contract for sparse fixed-effect matrices.
- Extend aggregation or sufficient-statistic paths beyond the first univariate
  Gaussian fixed-effect route where repeated rows can be collapsed without
  changing the likelihood.
- An initial non-CRAN benchmark harness exists at
  `bench/large-phylo-location.R`; use it to record 100k, 500k, 1M, and 5M
  observation-row runs with 1k-10k species as the implementation matures.
- Treat the sparse A-inverse phylogenetic path and large-row memory path as
  separate scaling problems.

## Phase 6: Profile-Likelihood Inference

- Status: closure-audited for the scoped direct-profile inference surfaces.
- Tracking issue: [#30](https://github.com/itchyshin/drmTMB/issues/30).
- `profile_targets(fit)` lists the current target names and readiness notes for
  confidence-interval and profile-likelihood work, including the first
  bivariate phylogenetic `mu1`/`mu2` SD and correlation targets.
- The target inventory uses a controlled namespace for `target_type`,
  `profile_ready`, `profile_note`, and `transformation`. A row is
  `profile_ready` only when it is direct and the fitted object retained the TMB
  object; memory-light fits report `profile_note = "tmb_object_required"`.
- `confint(fit)` now returns Wald fixed-effect intervals, and
  `confint(fit, parm = "fixef:mu:x", method = "profile")` profiles explicit
  direct fixed-effect, constant `sigma`/`sigma1`/`sigma2`, ordinary
  random-effect SD, ordinary random-effect correlation, phylogenetic `mu` SD,
  bivariate phylogenetic `mu1`/`mu2` correlation, and constant residual `rho12`
  targets.
- `confint(fit, parm = "sigma", method = "profile", newdata = grid)` and
  `confint(fit, parm = "rho12", method = "profile", newdata = grid)` profile
  row-specific response-scale `sigma` and residual-correlation values by
  profiling the fixed-effect linear predictor for each supplied row. The same
  row-specific route is now covered for `sigma1`, `sigma2`, and fitted q=2
  ordinary or phylogenetic `corpair()` values; ambiguous `newdata` requests are
  rejected before profile optimization.
- Direct covariance profile intervals are implemented for the first univariate
  `mu`/`sigma` random-intercept correlation target, the first bivariate
  `mu1`/`mu2` random-intercept correlation target, and the first bivariate
  phylogenetic `mu1`/`mu2` mean-mean correlation target. These intervals are
  available through both `confint(..., method = "profile")` and
  `summary(conf.int = TRUE, method = "profile", ci_parm = ...)`.
- Direct profile calls now wrap `TMB::tmbprofile()` failures with the
  `profile_targets()` target name and block attempts to override the internal
  `obj`, `name`, `lincomb`, or `trace` arguments through `...`.
- Extend profile-likelihood confidence intervals to additional direct TMB
  parameters such as other residual-scale parameters, ordinal cutpoints, and
  multi-row or custom contrasts beyond one `newdata` row at a time.
- Use user-facing target names from the fitted object, for example
  `sd:mu:(1 | id)`, `sd:mu:phylo(1 | species)`,
  `sd:mu:mu1:phylo(1 | species)`,
  `cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)`,
  `cor:mu:cor((Intercept),x | id)`,
  `cor:mu_sigma:cor(mu:(Intercept),sigma:(Intercept) | p | id)`,
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)`,
  `fixef:rho12:(Intercept)`, and `sigma` or `rho12`.
- Prefer `TMB::tmbprofile()` plus `uniroot()` for one-dimensional intervals,
  because it warm-starts constrained optimizations and avoids wasteful grids.
- Support linear combinations through TMB's `lincomb` machinery where possible.
- Treat nonlinear derived quantities, such as ICCs, repeatability,
  phylogenetic signal, and variance-component correlations, as a later
  fix-and-refit problem with boundary and convergence flags.
- Keep parametric bootstrap as a fallback for boundary, non-monotone, or failed
  inner-optimization cases.

Phase 6 should now be closed through small inference slices rather than one
large confidence-interval rewrite:

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 51 | Profile issue and target audit | Create the Phase 6 tracking issue, audit fitted `profile_targets()`, `confint()`, `summary(conf.int = TRUE)`, and `corpairs(conf.int = TRUE)` support, and record direct versus derived boundaries. | GitHub issue, design note, check-log, and after-task note agree. |
| 52 | Target namespace cleanup | Stabilize user-facing target names, transformations, `target_type`, `profile_ready`, and unavailable-status wording. | Target inventory tests cover representative fitted classes. |
| 53 | Direct profile robustness | Harden direct `TMB::tmbprofile()` wrappers, one-target-only errors, and failed-profile messages. | Direct profile tests cover success and clear failure paths. |
| 54 | Response-scale row profiles | Extend and test `newdata` profile intervals for `sigma`, `sigma1`, `sigma2`, `rho12`, and fitted q2 `corpair()` rows. | Done: row-specific intervals transform back to response scales and ambiguous inputs are rejected. |
| 55 | Random-effect SD and correlation intervals | Stabilize direct profile intervals for currently fitted ordinary, phylogenetic, and spatial random-effect SD/correlation targets. | Done: `summary()` and `corpairs()` attach intervals only to profile-ready rows, while modelled and q4 derived rows keep explicit unavailable statuses. |
| 56 | Derived-target status | Make q4 correlations, ICCs, repeatability, phylogenetic signal, and other nonlinear summaries explicit point-estimate or unavailable-CI targets. | Done: simple Gaussian repeatability and phylogenetic-signal rows are reported as derived variance-ratio targets, and unsupported derived intervals fail or report unavailable status before expensive profiling. |
| 57 | Output integration | Align interval columns and status values across `summary()`, `corpairs()`, `confint()`, and `profile_targets()`. | Done: `conf.status` is now part of successful `confint()` rows and interval-aware `summary()` tables, with contract tests for returned and printed parameter tables. |
| 58 | Inference diagnostics | Add diagnostics for boundary, near-correlation-limit, non-monotone, and failed inner-optimization profiles. | Done: profile interval rows carry `profile.boundary` and `profile.message`, and failed profile errors name boundary, one-sided, non-monotone, and failed-inner-optimization possibilities. |
| 59 | Profile inference docs | Update profile-CI design, known limitations, tutorials, and NEWS for any user-facing behavior changes. | Done: README, known limitations, model workflow, model map, bivariate, phylogenetic-spatial, and profile-CI design prose teach `conf.status`, `profile.boundary`, and `profile.message` without claiming derived q4 intervals. |
| 60 | Phase 6 gate | Run focused tests, full package tests when practical, pkgdown checks, after-phase audit, PR, and GitHub Actions. | Done when this gate PR has green local checks, an after-phase report, pkgdown evidence, and GitHub Actions. |

## Phase 6b: Tutorial Quality Upgrade

- Tracking issue: [#31](https://github.com/itchyshin/drmTMB/issues/31).
- Use `docs/design/21-tutorial-style.md` as the tutorial contract.
- Jason should source-map the tutorial examples the project owner provided,
  including location-scale meta-analysis, phylogenetic location-scale, ecology
  location-scale, phylo-spatial, multinomial GLMM, phylogenetic simulation, and
  `glmmTMB::equalto()` examples.
- Pat should user-test each major `drmTMB` tutorial for a concrete question,
  real or transparent simulated data, symbolic equations, model output,
  plots or tables, interpretation, diagnostics, and recovery advice.
- Add more symbolic maths and detailed biological interpretation to each major
  tutorial before calling the tutorial layer mature. The reader should see the
  model equation, the `drmTMB` syntax, the fitted output, and the biological
  meaning together.
- Upgrade the first tutorials in this order: Gaussian location-scale,
  bivariate location-coscale, meta-analysis, phylogenetic location effects,
  and random-effect scale models.

Phase 6b should turn the implemented surfaces into a coherent reader path:

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 61 | Tutorial issue and source map | Create the Phase 6b tracking issue and compare current tutorials with `docs/design/21-tutorial-style.md` and project-owner example priorities. | Done: `docs/design/32-phase-6b-tutorial-source-map.md` maps the tutorial fixes and adds the biological and mathematical interpretation contract for slopes, variance components, `sd(group)`, `rho12`, and `corpairs()` rows. |
| 62 | Tutorial landing path | Improve pkgdown navigation from scientific question to tutorial to reference page. | Done: Getting Started and the model map now share a question-first path from scientific phrase to tutorial, guide, or reference workflow. |
| 63 | Gaussian location-scale polish | Tighten the question, equation, runnable model, fitted output, interpretation, diagnostics, and plot/table guidance. | Done: the Gaussian tutorial now separates fixed mean slopes, fixed residual-scale slopes, random-slope SDs, residual-scale random-slope SDs, and random-effect scale slopes. |
| 64 | Bivariate coscale polish | Make residual `rho12`, `sigma1`/`sigma2`, response-scale interpretation, and intervals easier to read. | Done: the bivariate tutorial now reads `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` slopes as separate biological claims and keeps residual `rho12` distinct from group-level `corpairs()` rows. |
| 65 | Meta-analysis polish | Clarify `meta_known_V(V = V)`, ordinary weights, residual `sigma`, and unsupported combinations. | Done: the meta-analysis tutorial now names known sampling variance, fitted extra heterogeneity SD, heterogeneity variance, and total observation variance as different report scales. |
| 66 | Structured-dependence polish | Refine phylogenetic and spatial examples, mesh/coords guidance, citation notes, and fitted-versus-planned status. | Done: the structured-dependence tutorial now gives a six-row q=4 phylogenetic interpretation table and keeps mesh/SPDE, multiple spatial slopes, q=4 extensions, and derived intervals visibly planned. |
| 67 | Random-effect scale and covariance tutorial | Explain `sd(group)`, `sd(..., level = ...)`, Family A versus Family B, `corpairs()`, and invalid mixed formulations. | Done: the scale guide now explains Family A versus Family B, current `sd_phylo()` naming, the future `sd(..., level = ...)` idea, and invalid mixed formulations. |
| 68 | Phase 6b gate | Run Pat/Rose tutorial audit, pkgdown build/check, stale-wording scan, NEWS/roadmap updates, PR, and GitHub Actions. | Done locally: pkgdown build/check and stale-claim scans passed; GitHub Actions remains the PR-side gate after push. |

## Phase 6c: Random Slopes and Structured-Slope Examples

- Tracking issue: [#33](https://github.com/itchyshin/drmTMB/issues/33).
- Treat Phase 6c as the random-slope bridge between the Phase 6 inference work,
  the Phase 6b tutorial layer, and the later Phase 10-12 structured-dependence
  programmes. It does not replace the later bivariate covariance programme; it
  records the slope policy and should implement only the first slope paths that
  have simulation recovery and readable output.
- Start with one structured `mu` slope for each relevant dependence layer:
  ordinary grouped effects as the baseline, then phylogenetic effects, then
  spatial effects. Design for up to two structured `mu` slopes as an advanced
  path if diagnostics and recovery remain stable.
- Keep three or more structured slopes outside the advertised near-term path.
  The covariance dimension grows quickly, so these models should remain
  distant-future expert use.
- Do not estimate intercept-slope correlations in the first slope path.
  Intercept-slope correlations should still be part of the Phase 6c inference
  roadmap as an advanced, diagnostic-heavy path once the one-slope point
  estimates and recovery tests are stable.
- Include profile-likelihood CI planning for slope quantities. The first
  interval targets should be random-slope SDs and any slope-related
  correlations that are direct, identifiable TMB targets. Derived or weakly
  identified slope correlations should report explicit unavailable-status rows
  in `profile_targets()` or `corpairs()` until a supported interval method
  exists.
- A later high-value biological target is the bivariate slope1-slope2
  correlation for the same environmental covariate, such as a plasticity
  syndrome across species or individuals. This should eventually include both
  point estimates and profile-likelihood intervals where the target is direct
  and recovery evidence is good.
- Phase 6c examples should include symbolic maths, `drmTMB` syntax, output
  interpretation, and biological examples. Good first examples include thermal
  tolerance plasticity along temperature, desiccation tolerance along humidity,
  or behavioural reaction norms along disturbance.
- Core ordinary grouped status: the random-intercept and one-slope baseline is
  now recorded in `docs/design/33-phase-6c-core-random-effects.md`. The fitted
  core covers ordinary Gaussian `mu` random intercepts, independent `mu`
  random slopes, ordinary correlated intercept-slope blocks, residual-scale
  random intercepts and independent residual-scale slopes, matching labelled
  `mu`/`sigma` random-intercept covariance, and direct `sd(group)` models for
  unlabelled Gaussian `mu` random intercepts. The first coordinate spatial
  slope is now implemented in Phase 10; phylogenetic slopes and richer
  structured-slope paths remain later work for Phases 10 and 12.
- Closure boundary: Phase 6c closes the ordinary grouped foundation and hands
  structured random slopes to Phases 10 and 12. It does not fit
  `phylo(1 + x | species, tree = tree)` yet; Phase 10 now fits the first
  coordinate-spatial one-slope `mu` path.

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 69 | Random-slope issue and math contract | Create/maintain the Phase 6c issue, write the ordinary/phylogenetic/spatial one-slope equations, and fix coefficient naming rules. | Done for the ordinary grouped core: `docs/design/33-phase-6c-core-random-effects.md` records the symbolic equations, syntax, output rows, and stable/planned boundary. |
| 70 | Ordinary one-slope baseline | Stabilize ordinary grouped `mu` one-slope syntax, extractor labels, `corpairs()` coefficient columns, and profile-target names. | Done for the ordinary core: tests cover independent and correlated one-slope `mu` blocks, labelled `(1 + x | p | ID)` names, the `mean-slope` `corpairs()` row, and direct profile-target names. |
| 71 | Phylogenetic one-slope design and fit | Extend `phylo()` from intercept-only `mu` to one structured `mu` slope after the algebra and storage order are explicit. | Design handoff done: `docs/design/33-phase-6c-core-random-effects.md` names the minimum Phase 12 implementation contract; fitting remains planned until simulation recovery and diagnostics support the slope SD. |
| 72 | Spatial one-slope design and fit | Extend `spatial()` from intercept-only `mu` to one structured `mu` slope after coordinate/mesh diagnostics are clear. | Done for the coordinate path: Phase 10 fits `spatial(1 + x | site, coords = coords)` as independent intercept and slope fields with separate SDs, direct profile targets, `ranef()` terms, and simulation evidence. Mesh slopes remain planned. |
| 73 | One-slope diagnostics and inference | Add replication, weak-SD, boundary, profile-target, and profile-likelihood CI diagnostics for fitted one-slope paths. | Done for the ordinary core and first coordinate-spatial slope: tests cover weak random-slope design, boundary SDs, ordinary random-slope SD targets, intercept-slope correlation targets where fitted, and spatial one-slope direct SD targets. Phylogenetic slope diagnostics remain planned with Slice 71. |
| 74 | Slope-correlation advanced gate | Design two-slope models, intercept-slope correlations, and bivariate slope1-slope2 correlations without advertising them as routine. | Done for the ordinary core: the source map names the required coefficient-aware `corpair()` syntax, `corpairs()` rows, direct-target interval status, and recovery evidence before bivariate slope correlations are fitted or taught. |
| 75 | Biological examples | Add tutorial examples for reaction norms and bivariate plasticity-syndrome questions, including how to read slope SDs, slope correlations, and interval/status columns. | Done for the ordinary core: the location-scale tutorial now gives a thermal reaction-norm example with fixed slope, random-intercept SD, random-slope SD, group-level intercept-slope correlation, and `profile_targets()` interpretation. Full structured-slope examples wait until Phases 10-13 settle. |
| 76 | Phase 6c gate | Run focused tests, pkgdown checks, after-phase audit, PR, and GitHub Actions. | Done locally for the Phase 6c core: focused tests, pkgdown build/check, stale-claim scans, check-log entry, and after-phase report are complete. GitHub Actions remains the PR-side gate. |

## Phase 6d: Stable-Core Validation and Engine Hardening

- Tracking issue: [#38](https://github.com/itchyshin/drmTMB/issues/38).
- Local closure: Phase 6d is locally closed as of 2026-05-15 with focused
  tests, full package tests, pkgdown build/check, `R CMD check`, stale-claim
  scans, check-log evidence, and the after-phase report
  `docs/dev-log/after-phase/2026-05-15-phase-6d-stable-core-hardening-closure.md`.
  GitHub Actions remains the PR-side gate.
- Treat Phase 6d as the audit-response lane. It should not distract from the
  current profile-CI slices, but it records the cross-cutting work needed before
  `drmTMB` expands too far into new families, broad spatial claims, or
  high-dimensional random-effect structures.
- Add a stable-core matrix for the README, model-map, and pkgdown site. The
  table should make clear which surfaces are stable, which are fitted first
  slices, which are opt-in controls, which are parsed but rejected, which are
  documentation-only roadmap items, and which have profile-likelihood interval
  support.
- Maintain a validation-debt register that links each advertised model surface
  to simulation recovery, malformed-input tests, diagnostics, profile/CI status,
  documentation, and check-log evidence.
- Add failure-safe standard-error handling. A future `se = FALSE` or equivalent
  control should let a useful fit exist without forcing `TMB::sdreport()`, and
  failed standard-error calculations should store an `sdr_error` rather than
  making the whole object unusable.
- Design optimizer controls before importing multi-start behavior. The first
  contract should expose starts, maps or fixed parameters, optimizer controls,
  and a fallback optimizer. Any multi-start implementation must pin
  `report()`, `sdreport()`, summaries, profiles, and extractors to the winning
  `opt$par` rather than the TMB object's last evaluated parameter state.
- Add diagnostics and wording guards for dense known covariance, large-data
  claims, and spatial routes. Dense known covariance should be labelled
  small-to-moderate unless sparse or block-sparse evidence exists.
- Audit count likelihood kernels for avoidable loops over observed counts and
  replace them with stable closed-form `lgamma` expressions where appropriate.
- Plan C++ likelihood modularization before the single TMB template grows much
  further. The first action should be a source map and refactor plan, not a
  broad rewrite during fragile inference work.
- Make `check_drm()` diagnostic status more visible in summaries, tutorials, or
  workflow docs, so users see convergence, Hessian, boundary, and
  near-correlation-limit warnings before interpreting complex fits.

Phase 6d should be closed as small hardening slices:

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 77 | Stable-core feature matrix | Add a README/model-map/pkgdown table for fixed effects, random effects, `sigma`, known covariance, phylogeny, spatial, bivariate `rho12`, latent `corpair()`, profile-CI support, and status. | Done: README and model-map now carry a stable-core matrix that separates stable surfaces, first slices, opt-in controls, and planned or rejected neighbours, with profile/diagnostic status attached to each row. |
| 78 | Validation-debt register | Create a design note or issue-backed register linking each stable, first-slice, or opt-in surface to recovery tests, diagnostics, interval status, docs, and check-log evidence. | Done: `docs/design/34-validation-debt-register.md` maps each stable-core row to evidence, diagnostics, interval status, docs, and explicit debt, with README, model-map, and source-map pointers. |
| 79 | Standard-error and `sdreport()` controls | Design and implement failure-safe uncertainty controls, including `se = FALSE` behavior if compatible with current APIs. | Done: `drm_control(se = FALSE)` skips `TMB::sdreport()` while keeping optimized fits usable for non-Wald post-fit methods, and skipped or failed uncertainty states are explicit in `fit$uncertainty`, `summary()`, `vcov()`, and `check_drm()`. |
| 80 | Optimizer, start, map, and multi-start design | Add the public contract for starts, fixed or mapped parameters, fallback optimizers, and cautious future multi-start support. | Done: `docs/design/35-optimizer-start-map-multistart.md` records the contract, future control names are reserved, and profile callbacks re-pin the TMB object to the selected `opt$par` before profiling. |
| 81 | Dense covariance and large-data guards | Add diagnostics and wording for dense known covariance, sparse/block-sparse expectations, and large-data claim boundaries. | Done: dense `meta_known_V(V = V)` fits now appear as `check_drm()` notes with dense storage, dimension, density, size, rank, and conditioning, and the meta-analysis, large-data, and validation-debt docs label dense known covariance as small-to-moderate until sparse or block-sparse evidence exists. |
| 82 | Count likelihood kernel audit | Review count likelihood sections and replace slow count loops with closed-form expressions where practical. | Done: NB2, zero-inflated NB2, zero-truncated NB2, and hurdle NB2 now share an internal count-kernel helper that avoids observed-count loops with a closed-form `lgamma` ratio and a small-`alpha y` series guard; deterministic high-count tests confirm unchanged likelihood values. |
| 83 | C++ modularization source map | Write the refactor plan for splitting likelihood families, covariance blocks, structured effects, and numerical helpers without changing behavior. | Done: `docs/design/36-cpp-modularization-source-map.md` names the header-only split plan, hidden branch inventory, public branch gates, test gates, and pieces that must not move in the first pass. |
| 84 | Phase 6d gate | Run targeted tests, pkgdown checks, Rose audit, Grace CI gate, and update NEWS/check-log/roadmap. | Done locally: focused tests, full tests, pkgdown build/check, `R CMD check`, stale-claim scans, check-log entry, and after-phase report are complete; GitHub Actions remains the PR-side gate. |

## Phase 7: Robust and Positive Continuous Families

- Status: fixed-effect univariate Student-t location-scale-shape, lognormal
  location-scale, Gamma mean-CV, and beta mean-scale models are implemented.
- Harden and extend Student-t, lognormal, Gamma, beta, Poisson, and
  negative-binomial models before adding skew-normal and skew-t families.
- Use `lognormal()` for positive continuous responses where `mu` and `sigma`
  are defined on the log-response scale and `fitted()` returns the arithmetic
  response mean.
- Use `Gamma(link = "log")` for positive continuous responses where `mu` is
  the response mean and `sigma` is the coefficient of variation.
- Use `beta()` for strict continuous proportions where `mu` is the mean
  proportion and public `sigma` maps internally to `phi = 1 / sigma^2`.
- Add `tweedie()` to the real-data wish list for non-negative semicontinuous
  ecological responses such as biomass, cover, or abundance indices with exact
  zeros and positive continuous values. Stage it after the Gamma/lognormal/count
  contracts are stable. The current working recommendation is public
  `sigma = sqrt(phi)`, so `sigma` remains scale-like while comparator checks can
  square it to compare against Tweedie dispersion `phi`; `nu` is reserved for
  the power parameter constrained between 1 and 2. The future implementation
  gate is recorded in
  `docs/design/27-tweedie-family-plan.md`.
- Extend the implemented family-link helper table before adding ordinal scale,
  denominator-aware, or additional positive-continuous likelihoods, so
  `predict()` and `fitted()` handle non-identity `mu` links consistently.
- Add formulae for shape and tail parameters where stable.
- Add strict starting-value and boundary diagnostics.

## Phase 8: Counts, Proportions, Percentages, and Ordinal Models

- Status: `poisson(link = "log")` is implemented as a fixed-effect baseline
  count model, including optional `zi ~ predictors` for zero-inflated Poisson
  models and standard R `offset(log(exposure))` terms in the `mu` formula.
  `nbinom2()` is implemented as a fixed-effect `mu`/`sigma`
  overdispersed count model with `Var(y) = mu + sigma^2 * mu^2`, including
  standard R `offset(log(exposure))` terms in the `mu` formula and optional
  `zi ~ predictors` for zero-inflated NB2 models.
  `truncated_nbinom2()` is implemented for positive counts where `mu` and
  `sigma` describe the untruncated NB2 component and `fitted()` returns the
  conditional positive-count mean. Adding `hu ~ predictors` to the same family
  route fits the implemented fixed-effect hurdle NB2 model. `beta()` is
  implemented for strict continuous proportions with public `sigma`.
  `beta_binomial()` is implemented for counted successes out of known trial
  totals with public extra-binomial `sigma`.
  `cumulative_logit()` is implemented for fixed-effect univariate ordinal
  location models with ordered cutpoints and fixed latent logistic scale.
- Next family sequence: zero-one-inflated beta after the boundary contract is
  settled, plus ordinal scale or discrimination formulas after their direction
  is documented.
- Add zero-one-inflated beta, ordered logit/probit, COM-Poisson, generalized
  Poisson, and related families according to the distribution roadmap after
  their parameter-link and comparator contracts are documented.

The recent location-scale modelling paper and companion tutorial listed in
`docs/design/11-reference-programme.md` are concrete replication targets for
this phase series. The current package should first reproduce the Gaussian
fixed-effect and Gaussian location-random-effect examples, then add comparator
tests for count and bounded-response examples as the required likelihood and
random-effect features land. The optional local command
`Rscript tools/replicate-location-scale-gaussian.R` writes the current
Gaussian overlap table and records which richer individual-difference examples
remain blocked by future covariance or non-Gaussian random-effect work.

## Phase 9: Ordinal and Denominator-Aware Models

- Status: partially implemented. The location-only `cumulative_logit()` MVP is
  implemented for one ordered response, fixed effects, ordered cutpoints, and
  fixed latent logistic scale. The first `beta_binomial()` path is implemented
  for `cbind(successes, failures)` responses, fixed effects, known trial
  totals, and extra-binomial `sigma`.
- Historical `0.1.0` release decision: Phase 9 closed at this MVP boundary.
  Ordinal scale or discrimination formulae, denominator aliases beyond
  `cbind(successes, failures)`, zero-one-inflated beta, and ordered beta remain
  post-preview work unless they are implemented with tests before the version
  bump.
- Decide whether the next ordinal scale formula is exposed as `sigma ~ ...` or
  a family-specific discrimination parameter before coding starts; the
  direction of interpretation must be unambiguous. The current design note
  prefers `sigma ~ ...` with discrimination reported as derived
  `zeta = 1 / sigma`.
- Keep `cbind(successes, failures)` as the canonical beta-binomial response
  until the denominator-helper design note is implemented with tests.
- Add zero-one-inflated beta or ordered beta for continuous bounded responses
  with exact 0 or 1 values.
- Keep these models univariate until their parameter recovery, boundary
  behaviour, and tutorial interpretation are reliable.

## Phase 10: Spatial Structured Effects

- Status: coordinate-based univariate Gaussian `mu` intercepts and one numeric
  spatial slope implemented; mesh/SPDE, multiple slopes, slope correlations, and
  bivariate spatial paths planned.
- Local coordinate-spatial foundation closure:
  `docs/dev-log/after-phase/2026-05-15-phase-10-coordinate-spatial-foundation-closure.md`
  records the local gate for the coordinate intercept plus one numeric slope
  path. This is not a mesh/SPDE or bivariate spatial closure.
- The first fitted spatial models are univariate Gaussian `mu` structured
  effects, parallel to the implemented phylogenetic path:
  `spatial(1 | site, coords = coords)` and
  `spatial(1 + x | site, coords = coords)`. The slope path uses two independent
  spatial fields, one for the intercept and one for the slope, with no fitted
  intercept-slope correlation.
- Support `spatial(1 | site, mesh = mesh)` only after the coded mesh object
  schema, projection path, and recovery tests are implemented. The design
  contract and provenance policy are recorded in
  `docs/design/09-phylogenetic-and-spatial-speed.md`. `coords` identify
  observation or site locations, while `mesh` is the SPDE/GMRF computational
  scaffold.
- Treat `coords` as the friendly public input and `mesh` as optional expert
  control. A dense coordinate-only Gaussian-process path would not require a
  mesh, but it is not the scalable route. The planned SPDE/GMRF route needs a
  mesh-like finite-element scaffold internally, even if `drmTMB` builds it from
  coordinates for the user.
- Cite the SPDE/GMRF method literature and any software used for mesh or
  precision construction. If code is ported or closely adapted from `sdmTMB`,
  `fmesher`, INLA-related sources, `gllvmTMB`, or another project, record
  provenance in `inst/COPYRIGHTS` before calling the spatial slice complete.
- Use a small comparator or simulation recovery test before exposing spatial
  effects beyond univariate `mu` or beyond one numeric slope.
- Do not add spatial terms in `sigma`, `rho12`, bivariate structured covariance
  blocks, or spatial slope correlations until the one-slope path is stable.

## Phase 11: Bivariate Random Effects and Correlation Pairs

- Status: first slice implemented.
- Matching labelled random intercepts in bivariate `mu1`/`mu2`,
  `sigma1`/`sigma2`, and one same-response `mu`/`sigma` pair are implemented
  after the fixed-effect bivariate Gaussian location-coscale model stabilized.
  Random slopes, full cross-parameter bivariate covariance blocks, and
  structured covariance remain planned.
- Use labelled group-level covariance blocks so residual `rho12`, ordinary
  group-level correlations, phylogenetic correlations, spatial field
  correlations, and mean-scale correlations stay in separate namespaces.
- Keep the first individual-difference covariance target focused on ordinary
  grouped personality and plasticity terms before adding structured
  phylogenetic or non-phylogenetic species correlation layers.
- For future random slopes, start with one slope and allow at most two slopes in
  the near-term advanced path. Do not estimate intercept-slope correlations at
  first. A later coefficient-aware `corpair()` design can target the bivariate
  slope1-slope2 plasticity-syndrome case, but that belongs after intercept-only
  covariance blocks and current `corpair()` rows are stable.
- Extend `corpairs()` before adding complex covariance blocks, so users can see
  the level, group, block, responses, distributional parameters, coefficients,
  estimates, and uncertainty source.
- Start with small ordinary grouped models before adding phylogenetic or spatial
  bivariate covariance structures.
- Use `docs/design/28-double-hierarchical-endpoint.md` as the endpoint map for
  full individual-difference location-scale covariance models. Use
  `docs/design/29-mammal-location-coscale-route.md` as the concrete mammal
  body mass-litter size route for the phylogenetic bivariate covariance
  endpoint. The first
  double-hierarchical slices should add one covariance block at a time, with
  `corpairs()` output and simulation recovery before the next block is added.

## Phase 12: Phylogenetic Location-Scale Extensions

- Status: planned beyond the first fitted bivariate `mu1`/`mu2` phylogenetic
  location slice.
- Extend the implemented `phylo(1 | species, tree = tree)` Gaussian `mu` path to
  one structured `mu` slope, then only later to at most two structured `mu`
  slopes. Three or more structured slopes, intercept-slope correlations, and
  slope-slope `corpair()` regression are distant-future research targets.
- Add phylogenetic terms in `sigma` only after the location path has larger
  simulation evidence and clear identifiability diagnostics.
- Keep phylogenetic location-scale-shape models as a research target, not an
  early production feature.
- Add long optional simulations for many species, near-zero phylogenetic SD,
  high residual noise, and combined phylogenetic plus non-phylogenetic species
  effects.
- For future two-response or two-trait structured models, estimate and report
  phylogenetic correlation, non-phylogenetic species correlation, and residual
  `rho12` as separate layers. The first bivariate phylogenetic mean-mean
  correlation is implemented; residual `rho12` is not a substitute for
  phylogenetic or species-level covariance. Ordinary species covariance can be
  combined with the fitted bivariate phylogenetic mean layer, but
  `check_drm()` notes the identifiability risk when both layers use the same
  grouping factor.
- Predictor-dependent phylogenetic `corpair(species, level = "phylogenetic",
  ...) ~ w` is implemented for the q=2 `mu1`-`mu2` location-location endpoint
  pair. The design uses two independent unit phylogenetic fields and
  species-specific loadings, giving a positive-definite nonstationary covariance
  that reduces to the existing constant bivariate phylogenetic covariance when
  the correlation predictor is constant. A CRAN-safe broad-trend recovery test
  checks that a positive species-level predictor recovers the fitted
  phylogenetic correlation ordering without hitting the correlation guard.
  Phylogenetic location-scale and scale-scale correlation regressions require a
  q=4 contract and remain deferred; spatial siblings remain planned.

## Phase 13: Double-Hierarchical Derived Inference

- Status: planned.
- Build on Phase 6 direct-parameter profile intervals, including the first
  covariance-row profile intervals, and Phase 11 correlation-pair models.
- Add uncertainty for derived quantities that matter in complete
  individual-difference location-scale models: repeatability, phylogenetic
  signal, total variance, and correlations among individual differences in
  average response, mean-model slopes, residual scale, and scale-model slopes.
- Started the derived-summary path with an internal registry-backed table that
  transforms fitted random-effect SDs and correlations into variance and
  covariance point estimates on the fitted random-effect scale.
- The internal derived-summary table can also attach direct profile intervals
  for its component SD and correlation targets, while leaving derived covariance
  intervals unfilled until a valid nonlinear interval method is implemented.
- `summary(fit)$covariance` now provides the first public surface for the
  currently fitted registry-backed variance and covariance point summaries,
  plus the first bivariate phylogenetic `mu1`/`mu2` mean-mean row, without
  exposing q > 2 syntax or derived covariance intervals. Its covariance interval
  columns also include an explicit status so unavailable derived intervals are
  not mistaken for silently omitted support.
- Use fix-and-refit profiles or carefully parameterized direct targets for
  nonlinear quantities; do not treat Wald intervals as the default for boundary
  variance components or correlations.
- Report these intervals through the same `corpairs()` and derived-summary
  namespaces used for point estimates, with explicit boundary, convergence,
  and near-correlation-limit flags.

## Phase 14: Large-Data Engine

- Status: planned.
- Extend memory-light fitted objects for large ecological, evolutionary, and
  environmental datasets beyond the current post-fit storage controls.
- Add sparse fixed-effect matrices before claiming million-row readiness.
- Extend Gaussian aggregation or sufficient-statistic paths beyond the first
  fixed-effect route where repeated rows can be collapsed without changing the
  likelihood.
- Add non-CRAN benchmarks for 100k, 500k, 1M, and 5M rows with 1k-10k species.
- Treat sparse phylogenetic A-inverse scaling, sparse known sampling covariance,
  and large-row model-frame memory as separate engineering problems.

## Phase 15: Mixed-Response Bivariate Families

- Status: planned.
- Design mixed composed families such as `family = c(gaussian(), poisson())` only
  after the joint likelihood and interpretation of cross-response dependence are
  explicit.
- Decide whether mixed-response dependence is residual `rho12`, a latent
  Gaussian copula, a shared random effect, or another likelihood-specific
  construction before coding.
- Keep higher-dimensional response matrices out of scope; they belong to
  `gllvmTMB`.

## Phase 16: Shape and Asymmetry Models

- Status: planned.
- Add skew-normal and skew-t only after Student-t, Gaussian phylogenetic
  location-scale, and the core family-link contract are stable.
- Use GAMLSS-style names: `nu` for the first shape parameter and `tau` for the
  second when needed.
- Start with fixed-effect shape formulae and clear warnings about identifiability
  among location, residual scale, skewness, tail shape, outliers, and unmodelled
  heteroscedasticity.
- Treat phylogenetic location-scale-shape and skewness/kurtosis evolution as a
  later methods programme, not a first implementation target.

## Phase 17: Release Hardening, Teaching, and Papers

- Status: planned.
- Harden the package for CRAN with platform checks, dependency review, examples,
  vignettes, pkgdown, and NEWS.
- Build the teaching sequence around applied ecological, evolutionary, and
  environmental examples, while keeping the package general like `glmmTMB`.
- Prepare benchmark articles comparing `drmTMB` with relevant overlap in
  `glmmTMB`, `brms`, `metafor`, `gamlss`, and phylogenetic/spatial tools.
- Draft methods papers around the package-defining pieces: fast
  location-scale regression, modelled residual `rho12`, and structured
  phylogenetic/spatial distributional regression.

## Phase 18: Visualization, Marginal Effects, and Reader-Facing Inference

- Status: planned; initial long-format prediction surfaces exist through
  `predict_parameters()` and `marginal_parameters()`.
- Build a coherent visualization layer across all implemented `drmTMB` model
  families rather than one-off plotting functions. The target reader is an
  applied ecology, evolution, or environmental-science user who needs to see
  fitted location, scale, shape, coscale, random-effect SD, and latent
  correlation patterns without rebuilding prediction grids by hand.
- Start with data helpers before plotting helpers:
  `prediction_grid()` or equivalent grid builders, `marginal_effects()` for
  averaging over nuisance covariates or groups, and compatibility checks for
  `emmeans` where the fitted parameter and link scale have a clean contract.
- Add ggplot-oriented helpers only after the data contract is stable:
  location curves, scale/variance curves, residual `rho12` curves,
  `sd(group)` or `sd_phylo()` surfaces, `corpairs()` summaries, and eventually
  spatial fields or maps.
- Every visual interval must state its inference source: Wald fixed-effect
  interval, direct profile-likelihood interval, derived nonlinear interval,
  conditional random-effect uncertainty, or parametric-bootstrap interval.
  Fisher's default is to avoid implying full uncertainty when only fixed-effect
  uncertainty is present.
- Pat's usability gate: examples should show the biological question, the
  fitted model, the visualization call, and the interpretation in one path.
  Rose's audit gate: plotting docs must not overclaim support for parameters or
  interval types that the model object cannot yet supply.
