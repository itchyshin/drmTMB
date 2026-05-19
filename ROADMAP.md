# drmTMB Roadmap

`drmTMB` is a focused R package for fast univariate and bivariate
distributional regression models using TMB.

## Version 0.1.2 Preview Release

- Current preview version: `0.1.2`.
- Meaning of `0.1.2`: a preview that includes the Phase 6 profile-inference
  hardening, Phase 6e tutorial maturation, and the Phase 17-20 roadmap reorder.
  It is not the final double-hierarchical individual-difference endpoint.
- Release boundary: Phase 9 is closed at the implemented ordinal and
  denominator-aware MVPs. The first Phase 11 bivariate `mu1`/`mu2`
  random-intercept covariance slice is now implemented. Phase 17 now records the
  visualization and marginal-effects layer because the later simulation and
  comparator phases need stable plotting/data helpers from the start. Phase 18
  is the comprehensive simulation, power, accuracy, and coverage evidence layer,
  but the Slice 202 gate keeps broad Phase 18 closed until the post-202 Phase
  17 return block, especially meta-analysis hardening, is complete. A narrow
  Poisson random-effect pilot simulation may start earlier as a scoped
  operating-characteristics grid. Phase 19 is the one-off comparator
  demonstration layer; Phase 20 is CRAN and paper preparation. Richer bivariate
  random slopes, residual-scale slope covariance, structured covariance, and the
  full double-hierarchical endpoint remain roadmap work for later releases.
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
- Keep parser support for `sd(group) ~`, known sampling covariance
  (`meta_V(V = V)` preferred, `meta_known_V(V = V)` as a compatibility alias),
  `phylo()`, and `spatial()` terms from the start.
- Prediction for `mu` and `sigma` is implemented.
- Simulation and parameter-recovery tests are implemented for the first
  Gaussian case.

## Phase 2: Meta-Analytic Gaussian Regression

- Status: diagonal and dense full known sampling covariance implemented.
- Treat meta-analysis as `family = gaussian()` plus known sampling covariance.
  The preferred implemented spelling is `meta_V(V = V)`, with vectors accepted
  for diagonal sampling variances and matrices accepted for dense sampling
  covariance. `meta_known_V(V = V)` remains a compatibility alias for the same
  additive known-covariance likelihood path.
- Support known sampling covariance through vectors, columns, diagonal matrices,
  dense block-diagonal matrices, or dense full matrices.
- Reserve, but do not fully implement for `0.1.2`, a `meta_V()` umbrella that
  can unify additive known covariance `meta_V(V = V)` with proportional
  sampling-variance models such as
  `meta_V(w = w, scale = "proportional")`.
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
- Keep likelihood weights separate from known sampling covariance: weights
  multiply observation log-likelihood contributions, whereas `meta_V(V = V)`
  supplies known sampling covariance. `meta_known_V(V = V)` remains a
  compatibility alias for the same additive path.
- Coexistence rule: diagonal/vector known `V` may be combined with ordinary
  likelihood weights, but those weights do not create proportional sampling
  variance. Full dense matrix-`V` fits reject non-unit top-level weights until
  joint-block weighting is designed; proportional sampling variance through a
  future `meta_V(..., scale = "proportional")` is also not ordinary likelihood
  weighting.
- Implemented design rule: univariate models use one non-negative finite
  weight per observation; bivariate models use one weight per complete response
  pair.
- Do not add response-specific bivariate weights until the likelihood and
  interpretation are documented.
- Full dense `meta_V(V = V)` covariance paths reject non-unit `weights =`
  until a joint-block weighting design is documented.

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
  `meta_V(V = V)` and `meta_vcov_bivariate()`, with an independent base R MVN
  likelihood comparator and tests that residual `rho12` stays distinct from
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
  in `mu2` and `sigma2`.
- Matching labelled random intercepts across all four bivariate location-scale
  parameters, `mu1`, `mu2`, `sigma1`, and `sigma2`, now fit one all-four
  intercept block and report six `corpairs()` rows: one `mu1`-`mu2` row, four
  mean-scale rows (`mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and
  `mu2`-`sigma2`), and one `sigma1`-`sigma2` row. This is still
  random-intercept support, not bivariate random slopes or the full
  double-hierarchical endpoint.
- Bivariate random slopes, random effects in `rho12`, bivariate known-`V` plus
  random effects, multi-term cross-parameter bivariate covariance, and
  structured bivariate covariance remain future work and are rejected before
  optimization.

## Phase 4: Mixed and Double-Hierarchical Models

- Status: random intercepts, independent numeric random slopes written as
  `(0 + x | id)`, and ordinary correlated intercept-slope blocks written as
  `(1 + x | id)` or `(1 + x | p | id)` are implemented for the univariate
  Gaussian location formula. Random intercepts in the residual `sigma` formula
  and independent residual-scale random slopes written as `(0 + x | id)` are
  also implemented, and matching labelled `mu`/`sigma` random intercepts now
  fit one or more independent univariate mean-scale covariance blocks.
  Random-effect scale formulae are implemented for one or more distinct
  unlabelled Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and
  `sd(site) ~ site_type`.
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
  first ordinary bivariate q=4 random-intercept block now routes
  `mu1`/`mu2`/`sigma1`/`sigma2` member contributions through the fitted
  bivariate Gaussian path. It reports all six endpoint rows through
  `corpairs()` and `summary(fit)$covariance`: one `mu1`-`mu2` row, four
  mean-scale rows (`mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and
  `mu2`-`sigma2`), and one `sigma1`-`sigma2` row. `profile_targets()` can
  format the matching six endpoint correlation targets, while q=4 intervals
  remain direct-correlation or derived-row work rather than a closed
  double-hierarchical endpoint. Dormant q=3 scaffolds, q > 4 blocks, and q=6 or
  q=8 random-slope endpoint blocks remain invisible to ordinary
  extractor/profile output. The corresponding constant phylogenetic q=4 state
  is now fitted for matching labelled all-four `phylo()` terms; the next
  phylogenetic work is recovery evidence, diagnostics, and tutorial hardening.
  q=6 and q=8 random-slope endpoint blocks can wait.
- Use `docs/design/18-random-effect-scale-models.md` as the design contract:
  the implemented MVP targets one or more distinct unlabelled univariate
  Gaussian `mu` random intercepts, with group-level predictors, simulation
  recovery tests, and an `lme4` overlap test.
- Extend random-effect scale models beyond unlabelled intercept targets, such
  as slope-specific, labelled-block, bivariate, and non-Gaussian targets.
- Respect labelled correlated group syntax such as `(1 + x | p | id)` when
  scale and bivariate random-effect paths are added.
- Ordinary grouped random-slope boundary: the univariate Gaussian `mu` path now
  accepts blocks such as `(1 + x1 + x2 | id)` as unstructured covariance blocks
  with SD/correlation summaries, profile targets for the SDs, recovery tests
  for the q=3 path, and explicit derived-unavailable status for q > 2 direct
  correlation profile intervals. This is the ordinary location-model
  compatibility boundary with `lme4`/`glmmTMB` syntax. Larger q blocks remain
  advanced and sample-size hungry until Phase 18 quantifies convergence,
  boundary, bias, and interval failure rates. With `q` coefficients in a block,
  the fitted surface has `q` SDs and `q * (q - 1) / 2` constant correlations.
- One-slope baseline policy: every random-effect layer that `drmTMB` supports
  should eventually accept at least one numeric random slope, or report an
  explicit unsupported status and fallback. During the first expansion,
  slope-related random-effect correlations are constant block hyperparameters,
  not modelled formulae. This cap does not remove the separate
  predictor-dependent `corpair()` lane for intercept-level group,
  phylogenetic, or future spatial correlations when those likelihoods and
  recovery tests are implemented.
- Cross-distributional-parameter correlation gate: keep residual `rho12`,
  ordinary group-level covariance, structured covariance, and known sampling
  covariance `V` as separate layers. Current fitted correlation surfaces are
  Gaussian-heavy and mostly constant block correlations, with special
  predictor-dependent routes for residual `rho12` and q=2 intercept-level
  `corpair()` models. Random effects in `rho12`, non-Gaussian covariance among
  `mu`, `sigma`, `zi`, `hu`, `zoi`, `coi`, or `nu`, slope-level
  cross-parameter covariance, and mixed-distribution bivariate covariance stay
  outside Phase 18 Wave A until their focused gates close.
- Add variance-component correlation summaries when identifiable.

## Phase 5: Animal, Phylogenetic, Spatial, and Known-Dependence Effects

- Status: first univariate Gaussian phylogenetic location path implemented;
  first matching bivariate `mu1`/`mu2` phylogenetic location slice implemented;
  first univariate Gaussian coordinate-based spatial location path implemented.
  Animal-model and user-supplied relatedness inputs are design-only until the
  shared structured-effect layer has parser, validation, extractor, profile,
  and recovery-test evidence.
- Teach structural dependence in the biological order readers are likely to
  ask for it: animal models first, then phylogenetic dependence, then spatial
  dependence, then combined phylogenetic-spatial layers, with lower-level
  `relmat()` reserved for other validated known-dependence matrices. The common
  mathematical module is `z ~ MVN(0, sigma_z^2 K)`, with `K = A_ped` for
  additive pedigree or animal relatedness, `K = A_phylo` for phylogeny, `K = M`
  for spatial dependence, and `K = K_user` for a validated user-supplied
  relatedness matrix.
- Add sparse known-covariance infrastructure beyond the current phylogenetic
  A-inverse path, especially for large known sampling covariance, spatial
  precision matrices, and combined phylogenetic-spatial meta-analysis.
- Reserve animal-model and generic known-relatedness syntax as siblings of
  `phylo()` and `spatial()`, not as new response families:
  `animal(1 | id, pedigree = ped)`, `animal(1 | id, A = A)`,
  `animal(1 | id, Ainv = Ainv)`, and a lower-level
  `relmat(1 | id, K = K)` or `relmat(1 | id, Q = Q)` escape hatch. Treat
  `relmat()` as the likely public replacement for older `gr()`-style
  low-level wording rather than teaching both names. Keep `V` for known
  sampling covariance in the preferred `meta_V(..., V = V)` design; do not
  reuse `V` for additive genetic or phylogenetic relatedness.
- When animal-model support becomes fitted, pair the syntax with eco-evo
  examples rather than matrix-only demonstrations: heritable trait means in a
  wild pedigree, additive genetic variance in behavioural predictability or
  residual scale, and bivariate genetic covariance/evolvability examples are
  higher-value teaching targets than an abstract `A` matrix smoke test.
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
  `check_drm()` expose those fields with spatial names. Phase 18 now has a
  smoke surface for the coordinate spatial one-slope path, covering seeded DGP,
  fit, parameter summaries, aggregate output, manifest, and failure ledger.
  Mesh/SPDE, multiple spatial slopes, spatial slope correlations, spatial q=4,
  spatial `sd(...)`, and spatial `corpair()` regressions remain planned.
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
- Structured-dependence random-slope boundary: do not claim phylogenetic/spatial
  slope parity until each structured layer has at least one fitted Gaussian
  `mu` random slope with SD summaries, direct profile targets, diagnostics, and
  simulation recovery. The coordinate spatial path has this first one-slope
  baseline; the phylogenetic path does not yet.
- Keep structured-effect correlations constant during the one-slope baseline.
  Do not add predictor-dependent phylogenetic or spatial slope correlations
  until the fixed-correlation one-slope paths recover reliably. This does not
  block predictor-dependent intercept-level structured correlations that
  already have their own `corpair()` design.
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
| animal and user-supplied relatedness | design boundary only; no fitted `animal()` or `relmat()` path yet | `animal(1 | id, pedigree = ped)`, `animal(1 | id, A = A)`, `animal(1 | id, Ainv = Ainv)`, optional `phylo(..., A/Ainv = ...)` input, a lower-level `relmat()` route, diagnostics, profile targets, and recovery tests |
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
- The model-workflow article now shows the profile-example boundary directly:
  constant `sigma` uses a fitted-object target, predictor-dependent `sigma`,
  `sigma1`, `sigma2`, and `rho12` use supplied `newdata` rows, and
  random-effect SD/correlation examples copy exact target names from
  `profile_targets()`.
- Direct covariance profile intervals are implemented for the first univariate
  `mu`/`sigma` random-intercept correlation target, the first bivariate
  `mu1`/`mu2` random-intercept correlation target, and the first bivariate
  phylogenetic `mu1`/`mu2` mean-mean correlation target. These intervals are
  available through both `confint(..., method = "profile")` and
  `summary(conf.int = TRUE, method = "profile", ci_parm = ...)`.
- Direct profile calls now wrap `TMB::tmbprofile()` failures with the
  `profile_targets()` target name and block attempts to override the internal
  `obj`, `name`, `lincomb`, or `trace` arguments through `...`.
- The interval-readiness gate now keeps q4 derived correlations and covariance
  products explicitly unavailable for intervals, rejects unsupported bootstrap
  interval method requests before interval work begins, and checks that returned
  interval status/source values stay inside the current shared vocabulary.
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
| 66 | Structural-dependence polish | Refine phylogenetic and spatial examples, mesh/coords guidance, citation notes, and fitted-versus-planned status. | Done: the structural-dependence tutorial now gives a six-row q=4 phylogenetic interpretation table and keeps mesh/SPDE, multiple spatial slopes, q=4 extensions, and derived intervals visibly planned. |
| 67 | Random-effect scale and covariance tutorial | Explain `sd(group)`, `sd(..., level = ...)`, Family A versus Family B, `corpairs()`, and invalid mixed formulations. | Done: the scale guide now explains Family A versus Family B, current `sd_phylo()` naming, the future `sd(..., level = ...)` idea, and invalid mixed formulations. |
| 68 | Phase 6b gate | Run Pat/Rose tutorial audit, pkgdown build/check, stale-wording scan, NEWS/roadmap updates, PR, and GitHub Actions. | Done locally: pkgdown build/check and stale-claim scans passed; GitHub Actions remains the PR-side gate after push. |

## Phase 6c: Random Slopes and Structured-Slope Examples

- Tracking issue: [#33](https://github.com/itchyshin/drmTMB/issues/33).
- Treat Phase 6c as the random-slope bridge between the Phase 6 inference work,
  the Phase 6b tutorial layer, and the later Phase 10-12 structural-dependence
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
- Core ordinary grouped status: the random-intercept, one-slope, and q > 2
  ordinary Gaussian `mu` baseline is
  now recorded in `docs/design/33-phase-6c-core-random-effects.md`. The fitted
  core covers ordinary Gaussian `mu` random intercepts, independent `mu`
  random slopes, ordinary correlated intercept-slope blocks, ordinary
  unstructured numeric multi-slope `mu` blocks, residual-scale random
  intercepts and independent residual-scale slopes, matching labelled
  `mu`/`sigma` random-intercept covariance, and direct `sd(group)` models for
  unlabelled Gaussian `mu` random intercepts. The first coordinate spatial
  slope is now implemented in Phase 10; phylogenetic slopes and richer
  structured-slope paths remain later work for Phases 10 and 12.
- Closure boundary: Phase 6c now includes the ordinary grouped q > 2 Gaussian
  `mu` block path, with q=3 recovery and extractor coverage. Larger ordinary
  blocks remain advanced, sample-size hungry fits. Structured random slopes
  are handed to Phases 10 and 12; `spatial(1 + x | site, coords = coords)` now
  fits the first coordinate spatial one-slope `mu` path, but
  `phylo(1 + x | species, tree = tree)` still does not fit.

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

## Phase 6e: Worked-Example Maturation

- Status: started after PR #46 merged the Phase 10-13 foundations into `main`.
- Tracking anchor: continue from Phase 6b issue
  [#31](https://github.com/itchyshin/drmTMB/issues/31) unless a separate
  teaching issue becomes useful.
- Treat Phase 6e as a tutorial-quality follow-through lane. It should not add
  formula grammar, likelihood code, or new model claims.
- Keep guides and tutorials distinct. `model-map`, `which-scale`,
  `distribution-families`, `model-workflow`, `large-data`, and
  `testing-likelihoods` are guides unless a future slice deliberately turns a
  section into a full worked analysis.
- Use `docs/design/37-worked-example-inventory.md` before adding a new example.
  The next tutorial should fill a named gap in question, equation, syntax,
  output, plot/table, interpretation, diagnostics, or unsupported-boundary
  advice.

| Slice | Goal | Main work | Done when |
| --- | --- | --- | --- |
| 89 | Worked-example inventory | Audit the current tutorials and guides against the tutorial contract, then name the next highest-value tutorial slices. | Done: `docs/design/37-worked-example-inventory.md` records which pages are worked tutorials versus guides, names the major gaps, and prioritizes Slice 90 for the flagship location-scale tutorial and Slice 91 for the structural-dependence reader route. |
| 90 | Flagship location-scale tutorial | Deepen `vignettes/location-scale.Rmd` with a compact response-scale table or figure linking mean slopes, residual-scale slopes, random-slope SDs, `sd(group)`, diagnostics, and report-scale interpretation. | Done: the location-scale tutorial now has a response-scale interpretation table, trait-named parrot beak-length equations with parameter definitions, `profile_targets(fit_growth)` gate, fitted growth translation table, and hierarchical interpretation checklist distinguishing `sigma ~ temperature`, `(0 + temperature | population)`, and `sd(population) ~ habitat`. |
| 91 | Structural-dependence reader route | Add a phylogeny, spatial, and planned phylogeny-plus-spatial route through `vignettes/phylogenetic-spatial.Rmd` and make the coordinate-spatial example self-contained without widening structural-effect claims. | Done: the tutorial and navigation now use "Structural dependence", the article starts with a phylogeny/spatial/planned-combined route, and simultaneous `phylo()` plus `spatial()` remains visibly planned until multiple structural `mu` layers have identifiability checks. |
| 92 | Tutorial maturation gate | Run pkgdown build/check, stale-status scans, Rose audit, and after-phase notes for the Phase 6e tutorial follow-through. | Done locally: source and rendered pages agree on implemented surfaces, planned neighbours, diagnostics, and next examples; stale Slice 91 future wording and old pre-Slice-91 dependence labels were cleaned up. |
| 93 | `0.1.2` release gate | Align the active public preview surface with `0.1.2` and create the release checklist and after-task report without changing APIs, likelihoods, or tutorials. | Done: PR #53 bumped active preview docs to `0.1.2`, passed local tests, pkgdown, `R CMD check`, and PR CI, then merged to `main`. |
| 94 | `0.1.2` release evidence | Tag `v0.1.2`, watch tag CI, run install smoke, and record release evidence. | Done: `v0.1.2` points to the Slice 93 merge commit, tag CI and pkgdown deploy passed, `tools/install-smoke.R v0.1.2 0.1.2` passed, and PR #54 recorded the evidence. |
| 95 | Meta-analysis source-map polish | Return to examples with the meta-analysis lane: equations, exact syntax, parameter definitions, categorical heterogeneous-heterogeneity interpretation, and future `meta_V()` boundaries. | Done locally: the meta-analysis tutorial now defines `yi`, `vi`, `V`, `mu`, `sigma`, `sd(study)`, and `weights = w`; design docs record the Nakagawa et al., Yang and Nakagawa, Rodriguez et al., and unifying-model anchors. |
| 96 | Count NB2 source-map tutorial | Add the first non-Gaussian count worked example using fixed-effect `nbinom2()` and optional `zi ~` syntax, with source-grounded equations, parameter definitions, biological interpretation, diagnostics, and unsupported-boundary text. | Done locally: `vignettes/count-nbinom2.Rmd` now works through a soil-invertebrate count example, links `sigma` to NB2 `size = 1 / sigma^2`, fits NB2 and zero-inflated NB2 models, and keeps non-Gaussian random effects, structured count effects, mixed-response families, and COM-Poisson planned. |
| 97 | Proportion source-map tutorial | Add a bounded-response worked example using fixed-effect `beta_binomial()` and `beta()` syntax, with source-grounded equations, denominator/boundary guidance, response-scale interpretation, diagnostics, and unsupported-boundary text. | Done locally: `vignettes/proportion-beta-binomial.Rmd` now works through seed-germination successes out of trials and strict continuous vegetation-cover proportions, links public `sigma` to beta precision `phi = 1 / sigma^2`, and keeps exact 0/1 continuous boundaries, non-Gaussian random effects, structured bounded responses, and mixed-response families planned. |
| 98 | Bivariate group-level covariance polish | Deepen `vignettes/bivariate-coscale.Rmd` with a compact repeated-individual example that fits matching labelled `mu1`/`mu2` random intercepts, separates group-level covariance from residual `rho12`, and reports `corpairs()` plus `summary(fit)$covariance`. | Done locally: the bivariate tutorial now fits an activity-boldness individual-difference model with `(1 | p | ID)` in both location formulas, shows the covariance diagnostic row, reads residual and group-level rows through `corpairs()`, and keeps bivariate random slopes, `rho12` random effects, mixed-response models, and ordinary spatial covariance planned. |

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
- Ordinal random effects remain planned as a separate non-Gaussian mixed-model
  lane. The first ordinal target is `(1 | id)` in `mu`; ordinary grouped
  multi-slope covariance belongs to the Phase 4/6c boundary, not to the ordinal
  MVP itself.
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

- Status: ordinary bivariate random-intercept and `corpairs()` foundation
  locally closed. See
  `docs/dev-log/after-phase/2026-05-15-phase-11-bivariate-corpairs-foundation-closure.md`.
- Matching labelled random intercepts in bivariate `mu1`/`mu2`,
  `sigma1`/`sigma2`, and one same-response `mu`/`sigma` pair are implemented
  after the fixed-effect bivariate Gaussian location-coscale model stabilized.
  The ordinary q=4 all-four intercept block reports all six fitted
  `corpairs()` rows as derived summaries. Random slopes, full cross-parameter
  slope covariance, direct q=4 profile intervals, `rho12` random effects, and
  structured spatial covariance remain planned.
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

- Status: phylogenetic correlation foundation locally closed. See
  `docs/dev-log/after-phase/2026-05-15-phase-12-phylogenetic-correlation-foundation-closure.md`.
- The fitted foundation covers bivariate `mu1`/`mu2` phylogenetic
  location-location covariance, q=2 predictor-dependent phylogenetic
  `corpair()` regression, bivariate `sd_phylo1()` / `sd_phylo2()` direct-SD
  surfaces, and the first constant all-four q=4 phylogenetic
  location-scale block. These are intercept-level phylogenetic correlation
  paths, not phylogenetic random slopes.
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

- Status: derived-summary and interval-status foundation locally closed. See
  `docs/dev-log/after-phase/2026-05-15-phase-13-derived-inference-foundation-closure.md`.
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

- Status: planned; Slice 209 adds the ADEMP-style entry blueprint in
  `docs/design/41-phase-18-simulation-programme.md`.
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
  location-scale, and the core family-link contract are stable. The first
  asymmetry slice should be fixed-effect and univariate, not a random-effect or
  structured-dependence endpoint.
- Use GAMLSS-style names: `nu` for the first shape parameter and `tau` for the
  second when needed. For `skew_normal()`, `nu` should be the asymmetry or
  skewness parameter and the documentation must map it to the native skew
  parameter used by the chosen density. For `skew_t()`, `nu` should remain
  the asymmetry parameter and `tau` should control tail thickness or degrees of
  freedom, so the Student-t `nu` convention does not silently change meaning.
- Current research anchors: `sn` provides the classic skew-normal density with
  location `xi`, scale `omega`, and slant `alpha`;
  `gamlss.dist::SN2()` uses `mu`, `sigma`, and `nu`; GAMLSS exposes several
  skew-t variants, so `drmTMB` must choose and document one parameterization;
  `brms::skew_normal()` uses `mu`, `sigma`, and `alpha`; `RTMBdist` exposes
  AD-compatible skew-normal and skew-t densities that are useful comparator and
  implementation references. The `RTMBdist` skew-t warning about not
  initializing skew exactly at zero should be treated as a numerical-starting
  guard for any TMB implementation.
- Start with fixed-effect shape formulae and clear warnings about
  identifiability among location, residual scale, skewness, tail shape,
  outliers, and unmodelled heteroscedasticity. Shape random effects are a later
  evidence-gated lane, not the first skew-normal or skew-t slice.
- Preserve the two scale logics when skew families arrive: `sigma ~ ...`
  models residual or distributional scale, while `sd(group) ~ ...` models the
  SD of a latent group-level effect. The first skew-family slice should not add
  `sigma` random effects, `nu` random effects, `sd(group)` scale models, or
  `phylo()`/`spatial()` terms until fixed-effect likelihood recovery, normal or
  Student-t limit behaviour, and false-positive heteroscedasticity checks pass.
- Treat phylogenetic location-scale-shape and skewness/kurtosis evolution as a
  later methods programme, not a first implementation target.

## Phase 17: Visualization, Marginal Effects, and Reader-Facing Inference

- Status: planned; initial long-format prediction surfaces exist through
  `prediction_grid()`, `predict_parameters()`, and `marginal_parameters()`.
- Slice 100 research note:
  `docs/design/39-visualization-grammar.md` records the external lessons from
  `ggplot2`, `tidybayes`, `ggdist`, `emmeans`, `ggeffects`,
  `marginaleffects`, diagnostic plotting packages, and figure-composition
  tools. It does not add dependencies or claim plotting support; it sharpens
  the data-first contract for future helpers.
- Build a coherent visualization layer across all implemented `drmTMB` model
  families rather than one-off plotting functions. The target reader is an
  applied ecology, evolution, or environmental-science user who needs to see
  fitted location, scale, shape, coscale, random-effect SD, and latent
  correlation patterns without rebuilding prediction grids by hand.
- Start with data helpers before plotting helpers:
  `prediction_grid()` or equivalent grid builders, `marginal_effects()` for
  averaging over nuisance covariates or groups, and compatibility checks for
  `emmeans` where the fitted parameter and link scale have a clean contract.
- Slice 101 adds the first `prediction_grid()` contract: focal terms, supplied
  `at` values, conditioned nuisance predictors, mean-reference grids, empirical
  counterfactual grids, and metadata that records the grid rule. It does not add
  plotting, EMM contrasts, slopes, or interval columns.
- Slice 102 adds the first reader-facing empirical-grid workflow to the
  model-workflow article. The example separates a conditioned prediction grid
  for direct `predict_parameters()` rows from an empirical grid that
  `marginal_parameters(..., by = "temperature")` reduces over the fitted-row
  covariate distribution.
- Slice 103 adds interval provenance columns to `predict_parameters()` and
  `marginal_parameters()`. The current point-estimate tables report
  `conf.status = "not_requested"` and
  `interval_source = "not_available"` until a later slice computes real
  intervals.
- Slice 104 adds `plot_parameter_surface()`, the first optional `ggplot2`
  helper for `predict_parameters()` tables. The helper returns a composable
  `ggplot` object, lives on the Reference page under Visualization, and does
  not compute intervals, EMMs, contrasts, or slopes.
- Slice 105 makes the ordinary `summary()` workflow more visible in the
  model-workflow guide. It now shows a random-intercept model where
  `summary()` prints response-scale random-effect SDs, derived repeatability,
  and profile-likelihood confidence-interval status without describing those
  intervals as Bayesian credible intervals.
- Slice 106 adds delta-method standard errors to direct response-scale
  `summary()` parameter rows when `TMB::sdreport()` succeeds. Descriptive
  fitted ranges and derived variance ratios keep missing standard errors, and
  profile-likelihood confidence intervals remain the recommended interval route
  for fitted SD and correlation targets.
- Slice 107 adds a reader-facing `summary()` map to the model-workflow guide.
  The guide names what `coefficients`, `parameters`, `covariance`, `derived`,
  and `confint` report, then points readers to `fixef()`, `sigma()`,
  `rho12()`, `ranef()`, `corpairs()`, and `profile_targets()` when the ordinary
  summary has identified the row they need to inspect further.
- Slice 108 audits and clarifies the pkgdown Reference index for post-fit and
  plotting helpers. Fitting, checking, summaries, predictions, uncertainty, and
  extractors are grouped under "Model fitting and post-fit tools"; exported
  plotting helpers appear under "Visualization"; at the Slice 108 boundary,
  `plot_parameter_surface()` was the exported plotting helper with a stable
  data contract.
- Slice 108 also tightens the `summary()` reference example after reader review:
  profile summaries keep fixed-effect Wald 95% confidence intervals while
  adding direct-profile `sigma` 95% confidence intervals, and direct constant
  parameter rows no longer print duplicated `minimum` and `maximum` values that
  equal the estimate.
- Slice 109 translates the visualization landscape into raw-data-plus-model
  display rules. The model-workflow article now pairs an observed-response
  scatter plot with separate fitted `mu` and `sigma` surfaces, keeps the
  prediction table visible, and warns not to place raw response points on
  `sigma`, `sigma^2`, `rho12`, random-effect SD, or correlation axes.
- Slice 110 improves `plot_parameter_surface()` labels for single-parameter
  panels. When a filtered prediction table contains one `dpar`, the default
  y-axis label now names the parameter and, when unique, the prediction scale.
- Slice 111 adds a Phase 17 visualization decision map to the model-map
  article. It routes observed responses, fitted parameter surfaces, empirical
  marginal summaries, correlation rows, interval tables, and diagnostics to the
  current data helpers before any plotting style is chosen.
- Slice 112 records the `corpairs()` plotting preflight contract. The
  `plot_corpairs()` helper consumes an explicit `corpairs()` table, keeps
  correlation `level` and `class` visible, draws intervals only from finite
  confidence bounds, and was tested for residual, ordinary group-level,
  phylogenetic, empty-table, and missing-`ggplot2` cases before export.
- Slice 113 implements the first narrow `plot_corpairs()` helper. It consumes
  explicit `corpairs()` tables, draws one point per correlation row, adds
  interval segments only for finite `conf.low` and `conf.high` bounds, keeps
  correlation `level` and `class` visible, and lives in the Visualization
  reference section.
- Slice 114 adds optional `facet` support to `plot_corpairs()` so residual,
  group-level, phylogenetic, spatial, or future study-level rows can be separated
  by an explicit table column without changing the extraction contract.
- Slice 115 adds the first `facet = "level"` Reference example for
  `plot_corpairs()`, keeping the example table explicit while making the layer
  separation option visible to readers.
- Slice 116 adds a fitted bivariate-coscale tutorial path where `corpairs()`
  feeds `plot_corpairs(..., facet = "level")`, visually separating residual
  `rho12` from group-level random-intercept correlation rows.
- Slice 117 adds the first `emmeans` preflight test for the existing
  reference-grid and link-scale contract. Small fixed-effect fits now check
  that `prediction_grid()` plus `predict_parameters(type = "link")` and
  `predict_parameters(type = "response")` preserve the documented inverse-link
  relationship across implemented univariate, count, proportion, ordinal, and
  bivariate Gaussian families without adding an `emmeans` dependency or
  contrast API.
- Slice 118 records the planned `emmeans` interface contract in
  `docs/design/40-emmeans-interface-contract.md`. The first public method should
  be a narrow fixed-effect univariate `mu` path using the official
  `recover_data()` and `emm_basis()` extension API, with bivariate,
  zero-inflated, hurdle, ordinal expected-score, random-effect, structured-effect,
  slope, and interval-aware targets staying blocked until their algebra and
  tests are explicit. Broader contrast helpers should stay separate from the
  first EMM grid.
- Slice 119 adds an internal fixed-effect basis helper for the future
  `emm_basis()` path. `drm_fixed_effect_basis()` returns the requested `dpar`
  model matrix, coefficients, optional covariance submatrix, offset, link, and
  linear predictor, and `predict.drmTMB()` now uses that helper for its
  fixed-effect component. This remains internal plumbing, not public `emmeans`
  support.
- Slice 120 adds an internal preflight gate for the first possible `emmeans`
  basis path. `drm_emmeans_mu_basis()` is still private, but it now accepts only
  fixed-effect univariate `mu` targets with covariance available and rejects
  unsupported `dpar`, missing covariance, zero-inflated, and random-effect paths
  before any future method could return an `emmGrid`.
- Slice 121 adds the matching private recover-data preflight. The internal
  helper recovers the retained `mu` model frame, terms, predictor names,
  response name, factor levels, and row names for the same first eligible target
  and errors when memory-light fits did not retain model frames.
- Slice 122 implements the first public `emmeans` bridge. `emmeans` is now a
  suggested package with conditional method registration, and
  `emmeans::emmeans()` works for fixed-effect univariate `mu` targets when model
  frames and fixed-effect covariance are retained. The method still rejects
  non-`mu`, missing-covariance, memory-light, zero-inflated, random-effect, and
  other unsupported paths before returning an `emmGrid`.
- Slice 123 cleans the `plot_corpairs()` R CMD check hygiene left visible by
  Slice 122. The interval segment layer now builds its `ggplot2` aesthetics from
  symbols, matching the existing `plot_parameter_surface()` pattern, so
  `conf.low`, `conf.high`, and `.drmTMB_pair_label` are no longer treated as
  undeclared global variables.
- Slice 124 adds the first reader-facing `emmeans::emmeans()` example to the
  model-workflow article. The example estimates habitat-level EMMs for the
  fixed-effect univariate `mu` path at a supplied temperature and explicitly
  separates that target from `sigma`, random-effect, bivariate, zero-inflated,
  hurdle, ordinal, and slope workflows. Generic `emmeans` contrasts on the
  returned `mu` grid are possible, but drmTMB-specific contrast helpers remain a
  separate future contract.
- Slice 125 extends `emmeans()` parity tests across the remaining univariate
  model types already admitted by the fixed-effect `mu` gate: Student-t,
  lognormal, Gamma, beta-binomial, NB2, and zero-truncated NB2. The tests keep
  link-scale and response-scale EMMs aligned with `predict(dpar = "mu")`
  without widening the gate to unsupported model structures.
- Slice 126 clarifies the downstream contrast boundary. A new test confirms
  that generic `emmeans` pairwise contrasts use differences among the returned
  fixed-effect `mu` EMMs, while docs avoid treating contrast itself as a
  pre-grid unsupported target and keep broader contrast and slope helpers
  separate.
- Slice 127 adds explicit offset parity coverage for the first `emmeans()`
  bridge. A Poisson fixed-effect `mu` model with `offset(log(exposure))` now
  checks that `emmeans(..., at = list(exposure = 2))` matches
  `predict(dpar = "mu")` on link and response scales, without widening support
  to non-`mu`, random-effect, bivariate, zero-inflated, hurdle, ordinal, slope,
  or fitted-response targets.
- Slice 128 adds transformed-predictor recovery coverage for the same first
  `emmeans()` bridge. A Gaussian fixed-effect `mu` model with `log(size)` now
  checks that `emmeans(..., at = list(size = 1.5))` matches
  `predict(dpar = "mu")`, and the recover-data preflight confirms that raw
  source variables for transformed predictors are restored from stored data.
- Slice 129 adds explicit default numeric covariate-reduction coverage for the
  first `emmeans()` bridge. A Gaussian fixed-effect `mu` model with an
  asymmetric numeric covariate now checks that `emmeans(fit, ~ habitat)` matches
  `predict(dpar = "mu")` at `mean(x)`, keeping this as ordinary `emmeans`
  reference-grid behaviour rather than a drmTMB-specific marginalisation rule.
- Slice 130 adds direct `type` argument coverage for the first `emmeans()`
  bridge. A Poisson fixed-effect `mu` model now checks that
  `emmeans(..., type = "response")` matches
  `predict(dpar = "mu", type = "response")`, while `type = "link"` remains on
  the formula linear-predictor scale.
- Slice 131 adds custom numeric covariate-reduction coverage for the first
  `emmeans()` bridge. A skewed Gaussian fixed-effect `mu` example now checks
  that `emmeans(..., cov.reduce = stats::median)` matches
  `predict(dpar = "mu")` at `median(x)`, keeping custom reduction as ordinary
  `emmeans` reference-grid behaviour rather than drmTMB empirical averaging.
- Slice 132 adds unreduced numeric covariate-grid coverage for the first
  `emmeans()` bridge. A Gaussian fixed-effect `mu` example now checks that
  `emmeans(..., cov.reduce = FALSE)` matches `predict(dpar = "mu")` averaged
  over the observed `x` levels in the reference grid, keeping this separate
  from drmTMB row-wise empirical marginalisation.
- Slice 133 adds multiple explicit `at` value coverage for the first
  `emmeans()` bridge. A Gaussian fixed-effect `mu` example now checks that
  `emmeans(fit, ~ habitat | x, at = list(x = c(-0.25, 0.75)))` matches
  row-wise `predict(dpar = "mu")` on the same conditional reference grid.
- Slice 134 adds public zero-inflated boundary coverage for the first
  `emmeans()` bridge. A zero-inflated Poisson model now checks that
  `emmeans()` errors before returning an `emmGrid`, names the unsupported
  `"zi_poisson"` model type, and points users back to `prediction_grid()` plus
  `predict_parameters()`.
- Slice 135 adds public hurdle boundary coverage for the first `emmeans()`
  bridge. A hurdle NB2 model now checks that `emmeans()` errors before
  returning an `emmGrid`, names the unsupported `"hurdle_nbinom2"` model type,
  and points users back to `prediction_grid()` plus `predict_parameters()`.
- Slice 136 adds public ordinal boundary coverage for the first `emmeans()`
  bridge. A cumulative-logit model now checks that `emmeans()` errors before
  returning an `emmGrid`, names the unsupported `"cumulative_logit"` model
  type, and points users back to `prediction_grid()` plus
  `predict_parameters()`.
- Slice 137 improves the public bivariate boundary for the first `emmeans()`
  bridge. Bivariate Gaussian fits now error as unsupported `"biv_gaussian"`
  fits before returning an `emmGrid`, with the same prediction-table guidance,
  instead of falling through to a generic missing-`mu` message.
- Slice 138 blocks transformed-response formulas in the first `emmeans()`
  bridge. Fits such as `log(y) ~ x` now error before returning an `emmGrid`,
  with guidance toward explicit transformed-scale prediction tables through
  `prediction_grid()` plus `predict_parameters()`.
- Slice 139 extends the public zero-inflated `emmeans()` boundary to NB2.
  Zero-inflated NB2 fits now error as unsupported `"zi_nbinom2"` fits before
  returning an `emmGrid`, matching the zero-inflated Poisson boundary.
- Slice 140 adds interaction-formula coverage for the fixed-effect univariate
  `mu` `emmeans()` bridge. A Gaussian `habitat * x` fit now checks that
  conditional EMMs at an explicit `x` value match `predict(dpar = "mu")` on the
  same interaction grid.
- Slice 141 adds factor-conditioned reference-grid coverage for the
  fixed-effect univariate `mu` `emmeans()` bridge. A Gaussian `habitat` by
  `season` grid at `x = 0.25` now checks that returned EMM rows preserve factor
  levels and match `predict(dpar = "mu")` on the same grid.
- Slice 142 fixes and covers ordered-factor predictor coding in fixed-effect
  prediction matrices and the first `emmeans()` bridge. A Gaussian model with
  an ordered `condition` predictor now checks that `emmeans(fit, ~ condition |
  habitat, at = list(x = 0.2))` preserves ordered polynomial coding and matches
  `predict(dpar = "mu")` on the same grid.
- Slice 143 adds explicit validation for fixed-effect prediction factor levels.
  Character `newdata` values that match fitted factor levels now route through
  the fitted factor coding, while unknown levels such as `habitat = "forest"`
  error before model-matrix construction with the offending predictor and
  level named. Missing values in fitted factor predictors also error early, and
  extra factor columns not used by the requested distributional parameter are
  ignored.
- Slice 144 extends fixed-effect prediction `newdata` validation to all
  required predictors. Missing required columns and missing values in required
  numeric predictors now error before model-matrix construction, while extra
  unused columns remain harmless.
- Slice 145 adds the corresponding finite-value guard for required numeric
  predictors. Values such as `x = Inf` now error before fixed-effect prediction
  matrices are built.
- Slice 147 extends that finite-value guard to transformed-predictor design
  columns. Values such as `size = 0` in a model with `log(size)` now error
  after formula evaluation names the affected model column, rather than
  returning a non-finite prediction.
- Slice 148 applies the same finite design-matrix guard to random-effect scale
  prediction. Direct `sd(id)` predictions with `newdata` such as `w_pos = 0`
  in a model with `sd(id) ~ log(w_pos)` now error before returning infinite
  link- or response-scale SD predictions.
- Slice 149 extends fitted factor-level validation to random-effect scale
  prediction. Direct `sd(id)` predictions now accept character values that
  match fitted `sd(id)` factor levels and reject unknown levels before base R
  contrast or matrix-conformability errors.
- Slice 150 pins the raw-predictor side of random-effect scale prediction
  `newdata` validation. Missing required `sd(id)` predictor columns, missing
  required values, and non-finite required numeric values now have explicit
  tests and design text before random-effect scale model-matrix construction.
- Slice 151 pins the positive direct-SD `newdata` output contract. Multi-row
  `sd(id)` prediction grids now have explicit tests for one output per row,
  `rownames(newdata)` preservation, default response scale, and response
  predictions equalling `exp(link)` from `type = "link"`.
- Slice 152 pins direct-SD `newdata` container boundaries. Non-data-frame
  `newdata` inputs now have explicit error coverage, while zero-row data-frame
  grids return named length-zero numeric vectors on both link and response
  scales.
- Slice 153 pins multiple direct-SD formula prediction boundaries. Fits with
  both `sd(id) ~ w_id` and `sd(site) ~ w_site` now have explicit tests that
  each requested `dpar` validates its own predictors, ignores sibling-target
  extra columns, and names the missing target-specific predictor.
- Slice 154 pins direct-SD long-table helpers. `predict_parameters()` and
  `marginal_parameters()` now have explicit tests and reference docs for fitted
  random-effect scale model names such as `sd(id)`, with component
  `random-effect-sd-model`, row-label preservation, and marginal averaging over
  supplied direct-SD prediction rows.
- Slice 155 pins the direct-SD prediction-grid helper chain. A grid over a
  predictor such as `w` in `sd(id) ~ w` now has explicit coverage through
  `prediction_grid()`, `predict_parameters(..., dpar = "sd(id)")`, and
  `marginal_parameters(..., by = "w")`.
- Slice 156 adds the first reader-facing model-workflow example for a
  direct-SD prediction surface. The article fits `sd(site) ~ reef_cover`,
  builds a `prediction_grid()` over reef cover, reports
  `predict_parameters(..., dpar = "sd(site)")`, and reduces the same grid with
  `marginal_parameters(..., by = "reef_cover")` while keeping random-effect SD
  separate from residual `sigma` and raw responses.
- Slice 157 updates the model-map article so fitted random-effect SD surfaces
  route through `prediction_grid()`, `predict_parameters(..., dpar =
  "sd(group)")`, and `marginal_parameters()`, with component
  `random-effect-sd-model` kept separate from residual `sigma`.
- Slice 158 adds the first confidence-band path for prediction surfaces.
  `predict_parameters(conf.int = TRUE)` now fills Wald fixed-effect
  `std.error`, `conf.low`, and `conf.high` columns for supplied `newdata` grids
  when the requested distributional parameter has an ordinary fixed-effect
  basis. `plot_parameter_surface()` consumes those columns, drawing confidence
  bands for continuous x-values and interval bars for discrete x-values;
  `not_available` rows remain interval-free. The model-workflow and model-map
  articles now show the table-first band workflow and leave `conf.status`,
  `conf.level`, and `interval_source` visible.
- Slice 159 clarifies the confidence-band example boundary. The
  model-workflow article now prints interval provenance for explicit
  fixed-effect `mu`/`sigma` grids, and contrasts that with a direct
  `sd(site)` surface that reports `conf.status = "wald_unavailable"` when Wald
  intervals are requested. The point is reader-facing: fixed-effect parameter
  surfaces can draw 95% Wald bands on explicit grids; direct random-effect SD
  surfaces need a profile or bootstrap route before a ribbon is honest.
- Revised Phase 18 entry gate after Slice 159: do not jump directly into
  comprehensive simulation while profile/bootstrap intervals, Gaussian
  double-hierarchical random-slope limits, and non-Gaussian
  location-scale-shape surfaces are still uneven. Treat Slices 159-202 as a
  stabilization bridge before resuming Phase 17. Phase 18 comprehensive
  simulation should start only after that resumed Phase 17 closure gate, unless
  a deliberately smaller pilot simulation is opened earlier.
- Next 30-slice stabilization map:

| Slice | Lane | Target |
| --- | --- | --- |
| 159 | Confidence bands | Clarify fixed-effect Wald bands versus explicit unavailable direct-SD surfaces. |
| 160 | Confidence bands | Add or test discrete-x interval-bar examples for factor predictors. |
| 161 | Confidence bands | Document `newdata_required` for fitted-row interval requests. |
| 162 | Confidence bands | Tighten `conf.level` examples and interval-status display conventions. |
| 163 | Confidence bands | Gate the confidence-band docs with render, pkgdown, and stale-wording checks. |
| 164 | Profile intervals | Refresh the profile-target inventory for fixed effects, SDs, correlations, and row-specific parameters. |
| 165 | Profile intervals | Done: the workflow and profile-CI design notes now pin `newdata` examples for row-specific `sigma`, `sigma1`, `sigma2`, and `rho12`. |
| 166 | Profile intervals | Done: direct constant-`sigma` examples are separated from predictor-dependent scale profiles, with `profile.boundary` and `profile.message` interpretation kept visible. |
| 167 | Profile intervals | Done: direct random-effect SD examples now point users to exact `profile_targets()` names, including random-slope suffixes. |
| 168 | Profile intervals | Done: random-effect correlation examples now stay separate from residual `rho12`, with direct targets gated by `profile_targets()`. |
| 169 | Derived intervals | Done: q4 derived correlation and covariance-product rows remain explicit `derived_interval_unavailable` targets until a reparameterized or fix-and-refit derived interval method exists. |
| 170 | Bootstrap intervals | Done: the audit found bootstrap needs a deterministic simulate-refit harness, target extractor, failure ledger, and runtime/reproducibility policy before coding. |
| 171 | Bootstrap intervals | Done by deferral: the audit did not pass, so no public `method = "bootstrap"` prototype was added. |
| 172 | Bootstrap intervals | Done by boundary: no bootstrap interval-status columns are emitted yet because unsupported bootstrap requests error before interval-table creation. |
| 173 | Interval evidence | Done: focused tests now cover unsupported-bootstrap errors, q4 derived-unavailable boundaries, direct profile paths, and shared interval-status/source vocabulary. |
| 174 | Interval diagnostics | Done: profile diagnostics remain `profile.boundary`/`profile.message`, and unsupported bootstrap requests now report that bootstrap intervals are not implemented. |
| 175 | Interval harmonization | Done: internal status/source vocabulary helpers now align `summary()`, `confint()`, `corpairs()`, and prediction-table interval outputs. |
| 176 | Phase 6/13 gate | Done: the interval-readiness revisit is closed with tests, docs, known-limitations updates, check-log evidence, and an after-phase note. |
| 177 | Gaussian random slopes | Done: ordinary Gaussian `mu` supports multiple independent numeric slopes and one correlated intercept-plus-one-slope block; arbitrary correlated multi-slope blocks were moved to Slices 178-181. |
| 178 | Gaussian random slopes | Done: the parser/API accepts ordinary Gaussian `mu` blocks such as `(1 + x1 + x2 | id)` and labelled variants while keeping residual-scale correlated slope blocks outside scope. |
| 179 | Gaussian random slopes | Done: q > 2 ordinary Gaussian `mu` blocks use the registry-backed positive-definite unstructured covariance path with constant block correlations. |
| 180 | Gaussian random slopes | Done: q=3 recovery, malformed-input, conditional prediction, summary, `corpairs()`, and `profile_targets()` tests cover the first public path. |
| 181 | Gaussian random slopes | Done: user docs state the q=3 evidence, q > 2 output names, profile-ready SDs, derived-unavailable unstructured correlations, and sample-size boundary. |
| 182 | Scale random slopes | Done: multiple independent residual-scale Gaussian `sigma` terms are tested as separate log-`sigma` SDs with correlations fixed at zero; correlated and labelled residual-scale slope covariance blocks remain planned. |
| 183 | Location-scale covariance | Done: two independent matched univariate `mu`/`sigma` random-intercept covariance blocks can be fitted and reported through `corpars$mu_sigma`, `corpairs()`, `summary()`, and `profile_targets()`. |
| 184 | Location-scale covariance | Done: `check_drm()` now reports each independent univariate `mu`/`sigma` block separately, and profile tests cover the second `eta_cor_mu_sigma` interval target. |
| 185 | Bivariate random slopes | Done: matching slope-only `mu1`/`mu2` blocks such as `(0 + x | p | id)` are documented as the first future slope target, while `(1 + x | p | id)` q=4 location blocks and all-four q=8 location-scale slope blocks remain explicitly rejected. |
| 186 | Phylogenetic random slopes | Done: audit confirms phylogenetic slopes remain rejected/intercept-only while coordinate spatial already fits one independent `mu` slope; the error, docs, and tests now state this parity gap explicitly. |
| 187 | Spatial random slopes | Done: coordinate-spatial one-slope support now has a direct profile-interval test for the slope-field SD plus explicit boundary tests for multiple slopes, spatial scale terms, and bivariate spatial syntax. |
| 188 | Random-effect gate | Done: the one-slope-per-layer status table and remaining Gaussian double-hierarchical limits are published below before the non-Gaussian revisit. |

- Slice 189 is done: the double-hierarchical endpoint map now reflects the
  current Gaussian boundary after Slices 177-188, including q > 2 ordinary
  `mu`, multiple univariate mean-scale intercept blocks, coordinate-spatial
  one-slope support, and the still-closed bivariate slope, q=6/q=8, and spatial
  q=4 endpoints.
- Slices 190-202 are the pre-simulation non-Gaussian gate. The purpose is not
  to implement every attractive family feature before Phase 18. It is to decide
  which non-Gaussian, scale, shape, zero-inflation, hurdle, ordinal, structured,
  and interval surfaces are fitted, which are explicitly unsupported, and which
  have enough recovery evidence to enter the comprehensive simulation grid.
  Treat the table below as the current working map; each row should become more
  specific as earlier random-effect slices close.

### Slice 188 One-Slope Gate

This is the current random-effect status before the non-Gaussian revisit:

| Layer | One-Slope Status | Inference and Diagnostics | Remaining Gaussian DH Limit |
| --- | --- | --- | --- |
| Ordinary Gaussian `mu` | Fitted for independent slopes, one-slope correlated blocks, and ordinary q > 2 numeric location blocks. | q=3 recovery, `sdpars$mu`, `corpars$re_cov`, `corpairs()`, `summary()`, `profile_targets()`, and direct SD profiles are covered. | Larger q blocks are advanced and sample-size hungry; q > 2 correlations remain derived-unavailable for direct profile intervals. |
| Gaussian `sigma` | Fitted for random intercepts and multiple independent numeric slopes on `log(sigma)`. | `sdpars$sigma`, prediction contributions, direct `log_sd_sigma` profile targets, and tests cover the independent-slope boundary. | Correlated residual-scale slope blocks and labelled residual-scale slope covariance are planned. |
| Univariate `mu`/`sigma` covariance | Fitted for one or more matched labelled random-intercept blocks. | `corpars$mu_sigma`, `corpairs(class = "mean-scale")`, `summary()`, `check_drm()`, and second-block profile tests are covered. | Slope-level mean-scale covariance is planned. |
| Bivariate ordinary covariance | Fitted for matching labelled random intercepts in `mu1`/`mu2`, `sigma1`/`sigma2`, same-response `mu`/`sigma`, and all-four q=4 intercept blocks. | Constant q=2 correlation targets are profile-ready; q=4 correlations are derived-only with explicit unavailable interval status. | First future slope target is matching slope-only `mu1`/`mu2`; q=4 location-slope and q=8 all-four slope endpoints remain closed. |
| Phylogenetic structured effects | Intercept-level univariate, bivariate, direct-SD, q=2 correlation-regression, and q=4 location-scale paths are fitted. | Direct phylogenetic SDs and q=2 correlations have profile targets; q=4 correlations are derived-only. | `phylo(1 + x | species, tree = tree)` remains planned pending recovery and diagnostics. |
| Coordinate spatial structured effects | Fitted for univariate Gaussian `mu` intercept and one numeric slope, with independent coordinate fields. | `sdpars$mu`, `ranef("spatial_mu")`, `profile_targets()`, `check_drm()`, and a slope-field profile interval are covered. | Mesh/SPDE, multiple slopes, slope correlations, spatial `sigma`, bivariate spatial covariance, and spatial `corpair()` remain planned. |
| Non-Gaussian families | Fixed-effect likelihoods are fitted; ordinary Poisson and NB2 `mu` random intercepts plus independent numeric slopes are fitted for non-zero-inflated count models; non-Gaussian `sigma` plus shape random effects are explicitly blocked. | Poisson and NB2 `mu` random-effect SDs appear in `sdpars$mu`, random effects, and direct `profile_targets()` rows; family-specific fixed-effect summaries and intervals exist where already implemented. | Zero-inflation, hurdle, ordinal, structured, cross-parameter covariance, non-Gaussian scale random effects, and shape random effects still need separate implementation evidence before broad simulation. |

| Slice | Lane | Target Before Phase 18 |
| --- | --- | --- |
| 190 | Non-Gaussian `mu` random effects | Done: first candidates are ordinary `mu` random intercepts for Poisson and NB2-style count likelihoods; lognormal/Gamma/Student-t follow only after count recovery, while beta, beta-binomial, ordinal, zero-inflation, hurdle, shape, and structured non-Gaussian paths retain explicit unsupported messages. |
| 191 | Non-Gaussian `mu` implementation | Done: ordinary Poisson `mu` random intercepts now fit as `(1 | group)` in the log-mean predictor for non-zero-inflated Poisson models, with recovery, lme4 comparator, random-effect extraction, `sdpars$mu`, and direct SD profile-target coverage. |
| 192 | Non-Gaussian `mu` slopes | Done: ordinary Poisson `mu` now fits independent numeric random slopes such as `(0 + x | group)` on the log-mean predictor, with recovery, lme4 comparator, random-effect extraction, `sdpars$mu`, and direct SD profile-target coverage; correlated Poisson slope blocks and all labelled/cross-parameter covariance remain planned. |
| 193 | Non-Gaussian residual scale | Done: Student-t, lognormal, Gamma, beta, beta-binomial, NB2, truncated NB2, and hurdle NB2 `sigma` formulas retain fixed-effect-only scale paths; random-effect bar terms now error with a scale-specific boundary and tests until family-specific scale-random-effect likelihood and recovery evidence exists. |
| 194 | Shape and skew boundary | Done: Student-t `nu` random-effect bar terms now have a shape-specific boundary; residual shape/skewness remains fixed-effect-first, future `tau` is second-shape vocabulary only, and ID-level skewness such as `skew(id) ~ x` stays design-only until simulation separates it from residual skewness and heteroscedasticity. |
| 195 | Zero-inflation, hurdle, and one-inflation random effects | Done: `zi`, `hu`, planned `zoi`, and planned `coi` random-effect requests now receive component-specific boundaries. Fixed-effect zero-inflation and hurdle paths remain implemented; count-side random effects in zero-inflated or hurdle routes, bounded-response `zoi`/`coi` likelihoods, and covariance among `mu`, `sigma`, shape, inflation, hurdle, or one-inflation random effects remain future work until likelihood, interval, and recovery evidence exists. |
| 196 | Ordinal mixed models | Done: cumulative-logit `mu` random-effect bar terms now have an ordinal-specific boundary. The first future ordinal mixed target remains a random intercept such as `(1 | id)`; ordinal random slopes, scale/discrimination formulas, known covariance, phylo/spatial ordinal effects, and `ordinal::clmm` comparator recovery stay planned. |
| 197 | Structured non-Gaussian random effects | Done: phylogenetic, spatial, planned animal, and planned `relmat()` structured markers now have a structured non-Gaussian boundary. Structured count, bounded, ordinal, shape, inflation, and hurdle paths stay deferred until ordinary family-specific random effects and their intervals are stable. |
| 197a | Animal/relmat reference surface | Done locally: `animal()` and `relmat()` are documented and parsed as planned structured-effect markers, the reference index leads with animal/phylo/spatial/relmat rather than `gr()`, and `gr()` is demoted to a reserved legacy marker. |
| 198 | Non-Gaussian interval readiness | Done locally: `summary(conf.int = TRUE)` now handles fitted non-Gaussian paths with no summary-level parameter rows, including cumulative-logit ordinal fits with fixed effects or cutpoints only; Wald coefficient intervals remain available, empty coefficient/parameter tables keep explicit interval-status columns, and profile targets stay discoverable through `profile_targets()`/`confint()`. |
| 199 | Reader-facing family docs | Done locally: the model map, family chooser, and structural-dependence article now show implemented, planned, and unsupported states for non-Gaussian random effects and the structural-dependence ladder: animal, phylogeny, spatial, phylogeny plus spatial, then lower-level `relmat()` known-dependence matrices. |
| 200 | Focused non-Gaussian recovery tests | Done locally: ordinary non-zero-inflated Poisson `mu` random-effect recovery now includes a factor-predictor random-intercept case and a weak-SD boundary case that exercises `check_drm()` lower-boundary diagnostics. |
| 201 | Failure ledger | Done locally: `docs/design/34-validation-debt-register.md` now names the convergence, boundary, identifiability, interval, and runtime failures that Phase 18 should measure or exclude for ordinary Poisson, NB2, non-Gaussian scale, shape/skewness, inflation, ordinal, structured, cross-parameter covariance, interval, and runtime surfaces. |
| 202 | Pre-simulation decision gate | Done locally: do not start broad comprehensive Phase 18 yet. Permit only a narrow Poisson `mu` random-effect pilot grid if simulation begins now; otherwise return after Slice 202 to the Phase 17 hardening block, especially meta-analysis `meta_V()`/known-`V` API and interval safety. |

### Slice 202 Pre-Simulation Decision Gate

The Slices 190-202 non-Gaussian gate closes with a narrow decision. The package
has enough evidence to simulate the currently fitted ordinary Poisson `mu`
random-effect path, but not enough evidence to call the next phase a broad
comprehensive simulation.

| Decision Area | Slice 202 Decision | Reason |
| --- | --- | --- |
| Broad Phase 18 comprehensive simulation | Wait. | Too many neighbouring surfaces remain planned or blocked: non-Gaussian `sigma` random effects, shape/skew random effects, inflation and hurdle random effects, ordinal mixed models, structured non-Gaussian effects, cross-parameter non-Gaussian covariance, bootstrap intervals, and derived nonlinear interval coverage. |
| Narrow pilot simulation | Implemented smoke surface for Poisson; NB2 admitted as fitted first slice. | Ordinary non-zero-inflated Poisson `mu` random intercepts and independent numeric slopes have implementation, extractors, `sdpars$mu`, direct profile targets, focused recovery tests, factor-predictor coverage, weak-SD boundary diagnostics, and a Phase 18 smoke runner with manifests and failure ledgers. NB2 now has the same fitted ordinary `mu` random-effect class and focused recovery test, but not yet the full smoke runner/interval-coverage surface. |
| Post-202 work direction | Return to Phase 17 before full Phase 18. | Reader-facing inference and examples still need hardening before large simulation reports are useful. The first return block should focus on meta-analysis: preferred `meta_V(V = V)` spelling, vector and matrix `V`, proportional `meta_V(w = w, scale = "proportional")` design boundaries, profile/summary safety, and clear examples. |
| Phase 18 entry rule | Open full grids only surface by surface. | Each surface needs a fitted likelihood, parser validation, extractors, diagnostics, direct or explicitly unavailable interval targets, focused recovery tests, and a failure-ledger row before it appears in a comprehensive simulation table. |

The immediate next block is therefore a Phase 17 return block, not a leap into
full Phase 18. If a simulation task starts before that block closes, it should
be labelled as a Poisson `mu` random-effect pilot with explicitly limited
estimands, not as the comprehensive drmTMB simulation programme.

### Post-202 Phase 17 Return: Meta-Analysis Hardening

The first return block after Slice 202 is meta-analysis hardening. This block
keeps meta-analysis as Gaussian regression with known sampling covariance while
making the public grammar and examples match the preferred long-term name.

| Slice | Lane | Target |
| --- | --- | --- |
| 203 | Meta-analysis return map | Done locally: record the post-202 return block, keep broad Phase 18 closed, and make `meta_V()`/known-`V` hardening the first Phase 17 target. |
| 204 | `meta_V()` API decision | Done locally: `meta_V(V = V)` is the preferred additive known-covariance spelling, the marker should not take a positional response/value argument, and `meta_known_V(V = V)` is a compatibility alias rather than a separate likelihood path. |
| 205 | Additive known `V` implementation | Done locally: `meta_V(V = vi_or_V)` is accepted for the additive known-covariance route by sharing the existing `meta_known_V(V = V)` path; proportional `meta_V(w = w, scale = "proportional")` remains rejected before fitting. |
| 206 | Proportional sampling-variance boundary | Done locally: keep `meta_V(w = w, scale = "proportional")`, `meta_V(w = w)`, and `meta_V(V = V, scale = "exact")` reserved before fitting; clarify that diagonal/vector `meta_V(V = V)` may use ordinary likelihood weights, full matrix-`V` rejects non-unit weights, and neither route mimics proportional sampling variance. |
| 207 | Meta-analysis interval safety | Done locally: add profile-target and summary interval tests proving `meta_V()` fits expose estimated `sigma`, random-effect SD, and bivariate `rho12` targets while never treating known `V` as an estimated interval target. |
| 208 | Reader examples | Done locally: refresh the meta-analysis tutorial and design examples around preferred `meta_V(V = V)`, vector `V`, matrix `V`, residual heterogeneity `sigma`, random effects, random-effect scale, bivariate known `V`, and the unsupported proportional branch. |

Do not introduce `meta_gaussian()` or `tau ~` syntax in this block. Keep
`sigma` as the fitted extra heterogeneity SD, and explain the translation to
meta-analytic `tau` only in prose and tables.

Slice 190 decision: the first non-Gaussian implementation target should be
ordinary `mu` random intercepts for the count families whose fixed-effect
likelihoods already have focused tests and clear response-scale interpretation.
Use this order unless Slice 191 evidence overturns it:

| Priority | Family Surface | Slice 190 Decision |
| --- | --- | --- |
| 1 | Poisson `mu` | Implemented in Slices 191-192 for ordinary `(1 | group)` and independent numeric `(0 + x | group)` terms in the log-mean predictor, with recovery, lme4 comparator, and direct SD profile target coverage. Correlated slope blocks, labelled blocks, zero-inflation random effects, and cross-parameter covariance remain planned. |
| 2 | NB2 and zero-truncated NB2 `mu` | NB2 ordinary `mu` random intercepts and independent numeric slopes are now fitted for non-zero-inflated models, keeping public `sigma` as fixed-effect NB2 dispersion. Zero-truncated NB2 `mu`, zero-inflated NB2 random effects, and NB2 `sigma` random effects remain planned. |
| 3 | Lognormal, Gamma, and Student-t `mu` | Later continuous-response candidates after count recovery, because scale/tail interaction and boundary diagnostics need their own grids. |
| 4 | Beta and beta-binomial `mu` | Later bounded-response candidates; boundary values, denominators, and overdispersion need separate recovery checks. |
| 5 | Zero-inflation, one-inflation, hurdle, ordinal, shape, and structured non-Gaussian paths | Keep unsupported for now; revisit in Slices 194-197. For proportion data, `zoi` and `coi` are the planned zero-one-inflation lane rather than part of the Poisson count gate. |

- After Slice 202, return to Phase 17 to close the remaining visualization,
  marginal-effect, contrast, slope, and reader-facing inference surfaces. Phase
  18 comprehensive simulation starts only after that resumed Phase 17 closure
  gate, unless the project deliberately opens a smaller pilot simulation with a
  narrower estimand.
- Slices 160-164 close the first confidence-band documentation block and reopen
  the profile-interval inventory. Slice 160 adds the factor-predictor
  interval-bar example and a real prediction-table test. Slice 161 makes
  fitted-row `newdata_required` visible as an action status. Slice 162 shows a
  non-default `conf.level` and states that the level must be read with
  `conf.status` and `interval_source`. Slice 163 is the render/pkgdown/stale
  wording gate for this confidence-band block. Slice 164 refreshes the
  profile-target inventory for fixed effects, constant distributional
  parameters, row-specific `newdata` profiles, ordinary random-effect SDs and
  correlations, modelled `sd(group)` surfaces, q2 and q4 covariance rows,
  phylogenetic/spatial SDs, derived summaries, and ordinal cutpoint internals.
- Slices 169-176 close the interval-readiness gate before random-slope work.
  The important boundary is negative but useful: q4 correlations and covariance
  products remain derived interval-unavailable rows, and bootstrap intervals are
  not a public method until a deterministic simulate-refit harness, target
  extractor, failure ledger, and runtime policy exist.
- Add additional ggplot-oriented helpers only after the data contract is stable:
  location curves, scale/variance curves, residual `rho12` curves,
  `sd(group)` or `sd_phylo()` surfaces, `corpairs()` summaries, and eventually
  spatial fields or maps.
- Treat predictions, adjusted predictions, estimated marginal means, contrasts,
  slopes, and diagnostics as separate estimands. Do not hide reference grids,
  marginalization rules, weighting choices, or link-versus-response scale
  decisions inside a plotting call.
- Every visual interval must state its inference source: Wald fixed-effect
  interval, direct profile-likelihood interval, derived nonlinear interval,
  conditional random-effect uncertainty, or parametric-bootstrap interval.
  Fisher's default is to avoid implying full uncertainty when only fixed-effect
  uncertainty is present.
- Pat's usability gate: examples should show the biological question, the
  fitted model, the visualization call, and the interpretation in one path.
  Rose's audit gate: plotting docs must not overclaim support for parameters or
  interval types that the model object cannot yet supply.
- Design visualization helpers with Phase 18 simulations in mind. Simulation
  studies need plots for bias, root-mean-square error, empirical coverage,
  convergence, interval width, and power curves, so the visualization layer
  should expose reusable data frames rather than only polished figures.
- Slice 259 reopens the public visualization route after the first count-pilot
  diagnostics page proved too narrow to be called a gallery. The user-facing
  `vignettes/figure-gallery.Rmd` should be the Florence showcase for raw data
  plus fitted slopes, 95% confidence bands, categorical and continuous
  interactions, `emmeans` displays, fitted correlation layers, and simulation
  operating-characteristic plots. Simulation and comparator outputs get their
  own pkgdown section, "Simulation & Comparison", so power, bias, coverage,
  runtime, convergence, and failure-ledger articles do not compete with
  tutorials.

### Florence Figure-Gallery Slice Map

| Slice | Target | Done When |
| --- | --- | --- |
| 259 | First public figure gallery route | Done locally: `figure-gallery` is a Tutorials article, `convergence` is a Model Guides article, and `testing-likelihoods` moved to Simulation & Comparison. |
| 260 | Interaction plot polish | The gallery shows categorical x continuous, categorical x categorical, and continuous x continuous examples with fitted values, raw data where useful, 95% confidence intervals, and clear conditioning labels. |
| 261 | Distributional-parameter panels | Done locally: the gallery now labels `mu` and `sigma` panels by estimand and adds fitted Student-t `nu`, zero-inflation probability `zi`, and residual `rho12` examples with explicit response-scale wording and interval provenance. |
| 262 | Random-effect and variance-component figures | Done locally: the gallery now compares residual `sigma` with ordinary group-level intercept and slope SDs, shows conditional random-slope deviations, and plots a fitted `sd(site)` surface while keeping unavailable interval status explicit. |
| 263 | Correlation-layer figures | Done locally: the gallery now facets implemented residual, ordinary group, and phylogenetic `corpairs()`-style rows, then shows spatial, animal, and `relmat()` as planned support boundaries rather than fitted estimates. |
| 264 | `emmeans` and marginal-effects figures | Done locally: the gallery now shows the supported fixed-effect univariate `mu` `emmeans` route, factor-conditioned and interaction grids, an empirical `marginal_parameters()` summary, and unsupported boundaries for `sigma`, bivariate, zero-inflated, hurdle, ordinal, and random-effect targets. |
| 265 | Simulation plot grammar | Done locally: `simulation-plot-grammar` is a Simulation & Comparison article with display contracts for bias, RMSE, coverage, power, convergence, runtime, and warning/error ledgers across continuous, proportion, count, and meta-analysis examples. |
| 266 | Gallery source-map and QA | Done locally: the figure gallery now has a source-map table mapping each display to its fitted object or fixture, extractor or plotter, interval source, and support boundary, with render, pkgdown, and visual checks recorded. |
| 267 | Florence closeout | Done locally: the visualization grammar now records that `plot_parameter_surface()` and `plot_corpairs()` remain the exported helpers, most gallery displays stay tutorial-level `ggplot2` recipes, and simulation/failure-ledger helpers wait for stable Phase 18 result schemas. |

### Pre-Simulation Readiness Slice Map

This table is the working contract before full Phase 18 simulation begins. It
keeps three lanes separate: user-facing plots, model-feature hardening, and
simulation evidence. A narrow internal pilot, such as the Slice 258 count
simulation diagnostics, should not be promoted as the general figure gallery or
as the whole comprehensive simulation programme.

| Slice | Block | Target | Done When |
| --- | --- | --- | --- |
| 260 | Figure gallery | Interaction plot polish | Done locally: the gallery now shows categorical x continuous, categorical x categorical, and continuous x continuous examples with raw data where useful, fitted values, 95% confidence intervals, clear conditioning labels, alt text, and a cleaner correlation figure using `plot_corpairs(label = ...)`. |
| 261 | Figure gallery | Distributional-parameter panels | Done locally: the gallery labels `mu` and `sigma` by estimand and adds fitted Student-t `nu`, zero-inflation probability `zi`, and residual `rho12` panels with explicit response-scale wording and interval provenance. |
| 262 | Figure gallery | Random-effect and variance-component figures | Done locally: the gallery separates ordinary grouped SDs, random-slope summaries, `sd(group)` surfaces, residual `sigma`, and group-level SDs instead of visually collapsing them. |
| 263 | Figure gallery | Correlation-layer figures | Done locally: `corpairs()`-style examples distinguish implemented residual, ordinary group, and phylogenetic estimate rows from planned spatial, animal, and `relmat()` boundaries. |
| 264 | Figure gallery | `emmeans` and marginal-effects figures | Done locally: the gallery shows the supported fixed-effect univariate `mu` `emmeans` route, factor-conditioned and interaction grids, an empirical `marginal_parameters()` summary, and unsupported boundaries for `sigma`, bivariate, zero-inflated, hurdle, ordinal, and random-effect targets. |
| 265 | Simulation plot grammar | Operating-characteristic plot design | Done locally: the Simulation & Comparison route has reusable plot grammar for bias, RMSE, coverage, power, convergence, runtime, and warning/error ledgers across continuous, proportion, count, and meta-analysis examples. |
| 266 | Figure QA | Gallery source map | Done locally: each figure maps to the fitted object or fixture, extractor or plotter, interval source, support status, and current limitation. |
| 267 | Florence closeout | Plot helper backlog | Done locally: the helper backlog keeps `plot_parameter_surface()` and `plot_corpairs()` as the exported helpers, leaves gallery-specific plots as tutorial recipes, and defers simulation/failure-ledger helpers until result schemas stabilize. |
| 268 | Support audit | Pre-simulation capability matrix | Done locally: `docs/design/46-pre-simulation-readiness-matrix.md` now has one capability audit table that says which Gaussian, non-Gaussian, shape, inflation, bivariate, random-slope, meta-analysis, phylogenetic, spatial, animal, and `relmat()` surfaces are implemented, tested, planned, or unsupported before Phase 18 grids admit them. |
| 269 | Random slopes | Ordinary location random slopes | Done locally: a q=4 ordinary Gaussian `mu` block test now confirms multi-slope SD/correlation names, `corpairs()` classes, and profile-target status, while README/model-map/which-scale wording names q > 2 as fitted but sample-size hungry. |
| 270 | Random slopes | Scale random effects | Done locally: a cross-group Gaussian `sigma` test now confirms two independent residual-scale slope terms, direct `log_sd_sigma` targets, and no residual-scale correlation rows, while docs keep correlated residual-scale slope blocks planned. |
| 271 | Random slopes | Shape and inflation random effects | Done locally by audit: random-slope requests in Student-t `nu`, zero-inflation `zi`, hurdle `hu`, future `zoi`, and future `coi` stay blocked with component-specific tests; no identifiable likelihood path was opened. |
| 272 | Random slopes | Structured random slopes | Done locally: parser checks now confirm one-slope `animal()` and `relmat()` planned markers, multi-slope structured terms remain rejected, Gaussian fit-time boundaries still block animal/`relmat()` likelihoods, and the design/readiness notes keep predictor-modelled structured slope correlations out of Phase 18 Wave A. |
| 273 | Bivariate | Bivariate random-slope combinations | Done locally: bivariate Gaussian boundary tests now cover matching slope-only `mu1`/`mu2` requests, intercept-plus-slope q=4 location blocks, residual-scale slope pairs, same-response location-scale slope combinations, and all-four q=8-style slope requests before Phase 18 treats any bivariate slope grid as fitted. |
| 274 | Convergence | Control presets and defaults | Done locally: `drm_control(optimizer_preset = "careful")` and `"robust"` now expand to explicit recorded `nlminb()` `iter.max`/`eval.max` budgets, user optimizer values can override a preset, and the convergence guide documents when to use the presets without changing ordinary defaults. |
| 275 | Convergence | Warm starts from simpler models | Done locally by design boundary: warm-start names such as `start_from`, `warm_start`, `warm_starts`, and `warm_start_from` are now reserved, the simpler-fit ladder and provenance contract are documented, and no source-fit start is copied before target namespaces, row handling, diagnostics, and selected-optimum provenance are implemented. |
| 276 | Convergence | Multi-optimizer fallback | Done locally by design boundary: fallback-control names such as `fallback_optimizer`, `fallback_optimizers`, `optimizer_fallback`, and `optimizer_fallbacks` are now reserved, the future `nlminb`/BFGS/L-BFGS-B comparison and selected-optimizer provenance contract is documented, and fallback refits remain planned rather than automatic. |
| 277 | Convergence | Hessian and boundary diagnostics | Done locally: `check_drm()` now reports the largest fixed-gradient component in the `fixed_gradient` row, preserving the existing gradient/Hessian boundary status while making non-converged fits easier to triage before Wald or Hessian-based inference. |
| 278 | CIs and profiles | Interval hardening | Done locally: the interval contract now states which fixed-effect, scale, `rho12`, direct SD/correlation, Fisher-z simulation, derived-variance, and bootstrap routes are supported or deliberately unavailable, with Student-t `nu` fixed-effect interval and Fisher-z helper tests. |
| 279 | Known issues | Bergmann report fixes | Done locally: invalid fixed-effect Wald variances now produce `NA` intervals with `conf.status = "wald_unavailable"`; univariate `sigma ~ phylo()` gives a targeted unsupported message; labelled q4 block-diagonal fallback is tested as separate `mu` and `sigma` q2 blocks; convergence guidance now covers long iteration histories. |
| 280 | Meta-analysis | `meta_V(V = V)` hardening | Done locally: vector and full-matrix `meta_V(V = V)` routes now have alias and Wald fixed-effect interval coverage, `scale = "exact"` gets a targeted remove-`scale` error because additive exact known-`V` is the default, and `drmTMB()` / `meta_vcov_bivariate()` documentation now leads with `meta_V()` while keeping `meta_known_V()` as a compatibility alias. |
| 281 | Structural dependence | Animal and `relmat()` user surface | Done locally by documentation hardening: the structural-dependence article now gives concrete planned animal/`relmat()` questions, planned syntax, fitted sensitivity actions to use now, and the boundary that observation-level known sampling covariance belongs to `meta_V(V = V)`, not latent relatedness. |
| 282 | Structural dependence | Sparse precision path | Done locally by documentation hardening: ASReml efficiency notes and user docs now separate dense covariance inputs (`A`, `K`) from sparse precision or inverse-relatedness inputs (`Ainv`, `Q`), keep `meta_V(V = V)` as observation-level sampling covariance, and block large-pedigree or large-matrix speed claims until sparse-precision recovery and benchmark evidence exists. |
| 283 | Non-Gaussian audit | Family and parameter map | Done locally by documentation audit: `docs/design/02-family-registry.md` now lists each public family route, distributional-parameter links, shape or coscale slots, fitted random-effect allowance, and test evidence state, while correcting stale beta-binomial, Poisson, NB2, bivariate, and `meta_V()` wording. |
| 284 | Counts | Count-model hardening | Done locally: Poisson, NB2, zero-truncated NB2, zero-inflated Poisson, zero-inflated NB2, and hurdle NB2 tests now assert fixed-effect Wald interval rows for the fitted count dpars (`mu`, `sigma`, `zi`, and `hu` where relevant), while existing Poisson/NB2 `mu` random-effect tests and Phase 18 smoke surfaces remain the fitted mixed-count evidence; the count tutorial now states that boundary explicitly. |
| 285 | Proportions | Beta, binomial, and one-inflation hardening | Done locally: fixed-effect beta and beta-binomial `mu`/`sigma` coefficients now have Wald interval row tests, the family registry names that evidence, and the proportion tutorial keeps the fitted path to `beta()` and `beta_binomial()` while leaving fixed-effect `zoi`/`coi`, zero-one-inflation, random effects, and bounded-response `meta_V(V = V)` routes planned or blocked. |
| 286 | Continuous shape | Heavy-tail and skewness design | Done locally by design hardening: `docs/design/02-family-registry.md` now separates fitted fixed-effect Student-t `nu`, planned fixed-effect skew-normal `nu`, planned skew-t `nu`/future `tau`, and design-only latent-effect `skew(id) ~ ...`; likelihood, tutorial, readiness, NEWS, and formula-grammar text keep shape/skewness random effects out of Phase 18 until fixed-effect density, recovery, false-positive, diagnostic, and interval evidence exists. |
| 287 | Ordinal | Ordinal readiness | Done locally: `docs/design/25-ordinal-scale-discrimination.md` now records the fixed-effect `cumulative_logit()` evidence ledger for likelihood, cutpoints, prediction, expected-score summaries, simulation, fixed-effect Wald intervals, internal cutpoint profile targets, malformed inputs, and unsupported random-effect boundaries; README, the family registry, the distribution-family tutorial, and the pre-simulation matrix keep ordinal random effects, scale/discrimination formulas, structured ordinal effects, bivariate ordinal, and mixed-response ordinal models planned or unsupported. |
| 288 | Bivariate mixed families | Mixed-response combinations | Done locally by boundary hardening: mixed-response combinations such as Gaussian-count, Gaussian-proportion, count-proportion, ordinal mixed, and other two-response families remain planned, tests now cover mixed-family errors for both `c()` and `list()` spellings plus reversed Gaussian-Poisson order, and the family registry, distribution-family tutorial, NEWS, and pre-simulation matrix require a joint likelihood or copula/latent-variable contract, prediction, simulation, extractors, intervals, examples, and comparator checks before any mixed-response route is fitted. |
| 289 | Extractors | Prediction and plotting contracts | Done locally: `corpairs()` now returns `conf.status` and `interval_source` by default, `corpairs(conf.int = TRUE)` marks profiled rows with `interval_source = "profile"`, `plot_corpairs()` draws finite bounds only when status and source mark a real interval, and the readiness matrix records how this shared provenance rule relates to `predict_parameters()`, `vcov()`, the narrow `emmeans()` bridge, and plotting helpers. |
| 290 | Documentation | User-facing boundaries | Done locally: README, the model-map article, the package reference topic, the getting-started article, source-map guidance, and pkgdown reference-section descriptions now share a status vocabulary for stable, first-slice, opt-in, planned or reserved, and unsupported or blocked surfaces. |
| 291 | Pre-simulation gate | Evidence ledger | Rose and Fisher sign off that every advertised feature has implementation, tests, examples or docs, limitations, and simulation status. |
| 292 | Phase 18 start | Comprehensive simulation blueprint | Start the full design only after the gate, covering continuous, proportion, count, ordinal, meta-analysis, bivariate, random-slope, shape, phylogenetic, spatial, animal, and `relmat()` scenarios. |

## Phase 18: Comprehensive Simulation, Power, Accuracy, and Coverage Evidence

- Status: planned.
- Build a documented simulation programme that lets project leaders, reviewers,
  and applied readers understand when `drmTMB` is accurate enough for the
  models it claims to fit.
- Treat simulation as a scientific communication layer, not only a test layer.
  Each simulation should name the biological or methodological question, the
  data-generating model, the estimand, the fitted model, and the failure modes
  being probed.
- Add reusable simulation helpers that can also support earlier examples:
  scenario builders, transparent data-generating functions, seed control,
  compact result summaries, and plot-ready output for fitted parameters,
  convergence, diagnostics, and interval status.
- Include power analysis where it answers a reader question: for example, how
  many groups, species, sites, repeated observations, or effect sizes are needed
  to detect a change in `sigma`, `rho12`, `sd(group)`, phylogenetic SD, spatial
  SD, or a structured correlation with acceptable uncertainty.
- Report operating characteristics alongside power: bias, empirical standard
  error, root-mean-square error, profile or Wald interval coverage, convergence
  rate, boundary-hit rate, and diagnostic false-positive or false-negative
  rates.
- Keep routine CRAN tests small and deterministic. The comprehensive grids
  should live in optional scripts, scheduled CI, rendered reports, or paper
  supplements, with compact CRAN smoke tests proving that the simulation
  helpers still run.
- Curie's gate: every simulation helper needs tests for reproducibility,
  malformed input, and summary shape. Fisher's gate: every power or coverage
  statement must name the data-generating scenario and the uncertainty measure.
  Pat's gate: every simulation report should include an interpretation that a
  new applied user can read without reverse-engineering the code.
- First three implementation slices after the blueprint: the `inst/sim/`
  skeleton and seed/cell registry are done locally in Slice 210; the Gaussian
  location-scale DGP and pilot summariser are done locally in Slice 211; the
  Gaussian meta-analysis `meta_V(V = V)` DGP with vector and dense matrix `V`
  is done locally in Slice 212; a generic resumable replicate runner is done
  locally in Slice 213; the first end-to-end Gaussian location-scale smoke
  runner is done locally in Slice 214; the matching vector/dense `meta_V(V = V)`
  smoke runner is done locally in Slice 215; the first parameter-level
  aggregation helper is done locally in Slice 216; MCSE and explicit
  interval-coverage helpers are done locally in Slice 217; the first Gaussian
  location-scale summary-smoke run is done locally in Slice 218; the matching
  vector/dense `meta_V(V = V)` summary-smoke run is done locally in Slice 219.
  A reader-facing smoke report template is done locally in Slice 220. A compact
  result manifest helper is done locally in Slice 222 so resumed runs can be
  audited without opening every RDS object. A warning/error failure-ledger
  helper is done locally in Slice 223. Result-directory loading is done locally
  in Slice 224 so manifests and ledgers can be rebuilt from saved RDS output.
  Summary-smoke helpers return manifests and failure ledgers locally in Slice
  225. Synthetic interval-coverage smoke plumbing is done locally in Slice 226.
  The smoke report template accepts aggregate, manifest, and warning/error
  ledger CSVs locally in Slice 227. A skip-aware report-render test with tiny
  CSV fixtures is done locally in Slice 228. The interval-producer contract is
  recorded locally in Slice 229. A generic Wald interval-table helper is done
  locally in Slice 230 for summaries that already contain estimates and
  standard errors. A Fisher-z back-transformed correlation Wald helper is done
  locally in Slice 231. Gaussian location-scale pilot summaries carry
  fixed-effect standard errors locally in Slice 232. Next, connect those
  standard errors to Gaussian location-scale Wald coverage summaries. Gaussian
  location-scale summary smoke returns formula-coefficient Wald intervals and
  coverage locally in Slice 233. `meta_V(V = V)` pilot summaries carry standard
  errors for estimated `mu` coefficients and fitted residual `sigma` locally in
  Slice 234. `meta_V(V = V)` summary smoke returns Wald intervals and coverage
  locally in Slice 235. The random-slope promise audit is done locally in Slice
  236, reconciling the ordinary Gaussian `mu` q > 2 fitted path with the
  remaining Gaussian `sigma`, structured, bivariate, and non-Gaussian
  random-slope gates before broader Phase 18 grids begin. A Gaussian `mu` q=3
  random-slope smoke surface is done locally in Slice 237, giving the fitted
  ordinary multi-slope block a seeded DGP, runner, summary, aggregate, manifest,
  and failure-ledger path before larger grids are allowed. A Gaussian `sigma`
  independent one-slope smoke surface is done locally in Slice 238, giving the
  fitted residual-scale `(0 + w | id)` path the same Phase 18 bookkeeping while
  leaving correlated scale-slope covariance outside Wave A. Slice 239 records
  the structured-slope parity gate: coordinate spatial has one fitted Gaussian
  `mu` slope, while phylogenetic, animal, and `relmat()` one-slope paths remain
  planned until their implementation, profile targets, diagnostics, recovery
  tests, and biological examples exist. Slice 240 records the
  cross-distributional-parameter correlation gate. Slice 241 adds a coordinate
  spatial Gaussian `mu` one-slope smoke surface. Slice 242 adds a Poisson `mu`
  random-effect smoke surface; Slice 243 adds fixed-effect Wald interval
  coverage for that smoke output; Slice 244 adds direct profile-likelihood SD
  interval coverage for the Poisson random-effect SD targets. Slice 245 fits
  ordinary non-zero-inflated NB2 `mu` random intercepts and independent numeric
  slopes with extractor and direct profile-target coverage, while keeping NB2
  `sigma`, zero-inflated NB2 random effects, and correlated or labelled NB2
  slope blocks outside Wave A. Slice 246 adds the matching NB2 `mu`
  random-effect smoke surface with seeded DGP, live fit, parameter summaries,
  aggregate output, manifest, failure ledger, and tests. Slice 247 attaches
  fixed-effect Wald interval rows and coverage summaries to that NB2 smoke
  output for `mu` and `sigma` coefficients, while leaving random-effect SD
  profile coverage as the next evidence step. Slice 248 attaches direct
  profile-likelihood interval rows and coverage summaries for the two fitted
  NB2 `sd:mu` targets in that smoke output. Slice 249 adds a focused weak-SD
  boundary diagnostic for fitted NB2 `mu` random intercepts and keeps larger
  NB2 operating-characteristic grids as future Phase 18 work. Slice 250 records
  a pre-simulation readiness matrix that separates surfaces ready for small
  grids from planned or blocked surfaces before broad Phase 18 reports are
  written. Slice 251 starts the first paired count pilot, combining ready
  Poisson and NB2 `mu` random-effect surfaces into one optional output with
  aggregate, manifest, failure-ledger, Wald-coverage, and profile-coverage
  tables. Slice 252 makes the Poisson and NB2 condition helpers true grid
  builders, allowing optional count pilots to vary group count, repeats, true
  random-effect SDs, fixed mean effects, and NB2 overdispersion settings. Slice
  253 adds the first simulation plot-data contract for the paired count pilot,
  preparing aggregate, coverage, manifest, and failure tables for Florence's
  later figure gallery. Slice 254 adds the first Florence-facing count pilot
  gallery template for bias, RMSE, interval coverage, manifests, and
  warning/error ledgers. Slice 255 adds helper plumbing that writes the
  plot-ready CSV inputs and renders a checked local HTML gallery artifact from
  a paired count pilot object. Slice 256 adds the end-to-end smoke runner that
  runs a tiny paired count pilot, writes gallery inputs, renders the gallery,
  and returns both the pilot and artifact paths. Slice 257 applies the first
  Florence visual polish to that gallery, replacing default diagnostic panels
  with horizontal estimand labels, shared palette/theme helpers, plot captions,
  and MCSE-aware coverage ranges when available. Slice 258 built a narrow
  pkgdown-facing count simulation diagnostics draft, but that page was removed
  from the public site for now because it was not the broad figure gallery the
  user intended. Count diagnostics should return later as a Simulation &
  Comparison article after continuous, proportion, count, meta-analysis, and
  other surfaces are ready to be compared in one framework.

## Structured Slope Parity Gate

- `docs/design/44-structured-slope-parity-gate.md` records the current
  structured-effect slope boundary before Phase 18. Spatial one-slope Gaussian
  `mu` can enter a focused Wave A grid; phylogenetic, animal, and `relmat()`
  one-slope models should remain in the failure ledger as planned surfaces.
- The intended public order remains biological: `animal()` for pedigree or
  additive relatedness, `phylo()` for shared ancestry, `spatial()` for
  coordinate or mesh structure, combined structural layers when required, and
  `relmat()` as the lower-level known-relatedness escape hatch.

## ASReml Efficiency Lessons For Future Animal Models

- `docs/design/42-asreml-efficiency-lessons.md` records a design-only
  inspection of the local ASReml-R archive. The main lesson is that large
  animal-model performance depends on sparse inverse relationship structures,
  row-name matching metadata, log-determinant bookkeeping, and clear
  covariance-versus-precision contracts.
- For `drmTMB`, `animal()` should remain biological sugar, while `relmat()`
  should become the lower-level known-matrix surface with explicit `K`
  covariance and `Q` precision paths. Do not claim ASReml-like large-pedigree
  speed until the sparse-precision route exists and passes recovery and scaling
  tests.

## Phase 19: Comparator Demonstrations With Other Packages

- Status: planned.
- Compare `drmTMB` with related packages on the same simulated or transparent
  example datasets, but do not make this a repeated simulation phase. Phase 19
  should be a model-overlap and communication layer; Phase 18 is the operating
  characteristics layer.
- For each comparator example, fit one or a few matched datasets with the
  closest defensible model in `drmTMB` and relevant overlap packages such as
  `glmmTMB`, `lme4`, `brms`, `MCMCglmm`, `metafor`, `gamlss`, `sdmTMB`, or
  package-specific TMB examples.
- Report model syntax, model class, fitted parameter estimates on comparable
  scales, standard errors or intervals when available, optimizer or sampler
  diagnostics, and elapsed fitting time.
- Be explicit about non-overlap. If a comparator package cannot fit
  predictor-dependent residual `rho12`, a location-scale phylogenetic block, a
  known dense meta-analytic covariance, or a structured random-effect scale
  model, say so rather than forcing a misleading comparison.
- Use the same simulation helpers and visualization data contracts from Phases
  17 and 18, so comparator articles can reuse datasets, plots, timing summaries,
  and parameter-scale conversions.
- Jason's gate: every comparator must cite the comparator package capability or
  documentation it relies on. Grace's gate: optional heavy packages and MCMC
  fits must stay outside routine CRAN checks. Rose's gate: comparator articles
  must not turn one-off examples into broad speed or accuracy claims.

## Phase 20: CRAN Release and Paper Preparation

- Status: planned.
- Harden the package for CRAN with platform checks, dependency review, examples,
  vignettes, pkgdown, NEWS, reverse-dependency awareness where relevant, and a
  final implemented-versus-planned audit.
- Build the teaching sequence around applied ecological, evolutionary, and
  environmental examples, while keeping the package general like `glmmTMB`.
- Use Phase 18 simulation reports and Phase 19 comparator demonstrations as the
  evidence base for release notes, paper figures, supplementary material, and
  reviewer responses.
- Draft methods papers around the package-defining pieces: fast
  location-scale regression, modelled residual `rho12`, structured
  phylogenetic/spatial distributional regression, and documented simulation
  evidence for accuracy, coverage, and power.
- Grace's gate: release preparation should not begin until the site, examples,
  check logs, known limitations, and roadmap agree about supported syntax and
  fitted model classes. Rose's gate: paper text must not describe roadmap
  features as implemented unless code, tests, docs, examples, and validation
  evidence exist.
