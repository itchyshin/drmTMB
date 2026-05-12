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
  random-intercept covariance slice is now implemented, while richer
  bivariate random slopes, residual-scale covariance, structured covariance,
  and the full double-hierarchical endpoint remain roadmap work for later
  releases.
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
- Matching labelled random intercepts in `mu1` and `mu2`, such as
  `(1 | p | id)` in both location formulas, now fit one group-level
  covariance block. The two group-level SDs are reported in `sdpars$mu`, the
  group-level `mu1`/`mu2` correlation is reported in `corpars$mu` and
  `corpairs()`, and residual `rho12` remains separate.
- Bivariate random slopes, random effects in `sigma1`/`sigma2` or `rho12`,
  bivariate `meta_known_V()` plus random effects, and structured bivariate
  covariance remain future work and are rejected before optimization.

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
  The bivariate Gaussian path now fits matched labelled `mu1`/`mu2` random
  intercept covariance blocks.
- Add larger cross-formula or cross-parameter covariance sharing for labelled
  blocks, following `docs/design/17-correlated-random-effect-blocks.md`.
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

- Status: first univariate Gaussian phylogenetic location path implemented and
  Phase 5 closure-audited.
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
- Add spatial SPDE/GMRF fields after the core Gaussian and known-covariance
  path is reliable.
- For bivariate structured models, estimate and report level-specific
  correlations separately: residual `rho12`, phylogenetic correlations,
  non-phylogenetic species correlations, spatial field correlations, and
  ordinary grouped random-effect correlations should not share one namespace.
- Use the correlation-pair design in
  `docs/design/20-coscale-correlation-pairs.md` before implementing bivariate
  double-hierarchical covariance blocks; pair outputs should identify the
  level, group, block, distributional parameters, responses, and coefficients.
- The first `corpairs()` extractor is implemented for currently fitted
  correlations only: residual `rho12`, ordinary group-level `mu` random-effect
  correlations, the univariate `mu`/`sigma` mean-scale random-intercept
  correlation, and the bivariate `mu1`/`mu2` random-intercept correlation.
  Extend this table as new correlation likelihoods are added.
- Stage structured phylogenetic and spatial slopes conservatively:
  intercept-only structured effects first, then one `mu` slope, then only small
  slope sets or interaction slopes after simulation recovery.
- Add identifiability diagnostics for replication by study, species, location,
  and effect-size levels before complex structured models are promoted.
- Selectively reuse GPL-compatible ideas or modules from `gllvmTMB` with
  provenance notes and tests.

## Phase 5b: Large-Data Memory Strategy

- Status: first storage controls and benchmark harness implemented; sparse and
  aggregation paths
  planned.
- `drm_control()` now supports optimizer settings plus the first memory-light
  fitted-object controls: `keep_data = FALSE`,
  `keep_model_frame = FALSE`, and `keep_tmb_object = FALSE`.
- Extend memory-light fit controls for large phylogenetic and spatial
  datasets with broader method-matrix coverage, sparse fixed-effect matrices,
  aggregation, and repeated large-row benchmarks.
- Add sparse fixed-effect matrix support before claiming million-row readiness.
- Use `docs/design/26-sparse-fixed-effect-matrices.md` as the implementation
  contract for sparse fixed-effect matrices.
- Add optional aggregation or sufficient-statistic paths for Gaussian models
  where repeated rows can be collapsed without changing the likelihood.
- An initial non-CRAN benchmark harness exists at
  `bench/large-phylo-location.R`; use it to record 100k, 500k, 1M, and 5M
  observation-row runs with 1k-10k species as the implementation matures.
- Treat the sparse A-inverse phylogenetic path and large-row memory path as
  separate scaling problems.

## Phase 6: Profile-Likelihood Inference

- Status: partly implemented.
- `profile_targets(fit)` lists the current target names and readiness notes for
  confidence-interval and profile-likelihood work.
- `confint(fit)` now returns Wald fixed-effect intervals, and
  `confint(fit, parm = "fixef:mu:x", method = "profile")` profiles explicit
  direct fixed-effect, constant `sigma`/`sigma1`/`sigma2`, ordinary
  random-effect SD, ordinary random-effect correlation, phylogenetic `mu` SD,
  and constant residual `rho12` targets.
- `confint(fit, parm = "sigma", method = "profile", newdata = grid)` and
  `confint(fit, parm = "rho12", method = "profile", newdata = grid)` profile
  row-specific response-scale `sigma` and residual-correlation values by
  profiling the fixed-effect linear predictor for each supplied row.
- Direct covariance profile intervals are implemented for the first univariate
  `mu`/`sigma` random-intercept correlation target and the first bivariate
  `mu1`/`mu2` random-intercept correlation target. These intervals are available
  through both `confint(..., method = "profile")` and
  `summary(conf.int = TRUE, method = "profile", ci_parm = ...)`.
- Extend profile-likelihood confidence intervals to additional direct TMB
  parameters such as other residual-scale parameters, ordinal cutpoints, and
  multi-row or custom contrasts beyond one `newdata` row at a time.
- Use user-facing target names from the fitted object, for example
  `sd:mu:(1 | id)`, `sd:mu:phylo(1 | species)`,
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

## Phase 6b: Tutorial Quality Upgrade

- Use `docs/design/21-tutorial-style.md` as the tutorial contract.
- Jason should source-map the tutorial examples the project owner provided,
  including location-scale meta-analysis, phylogenetic location-scale, ecology
  location-scale, phylo-spatial, multinomial GLMM, phylogenetic simulation, and
  `glmmTMB::equalto()` examples.
- Pat should user-test each major `drmTMB` tutorial for a concrete question,
  real or transparent simulated data, symbolic equations, model output,
  plots or tables, interpretation, diagnostics, and recovery advice.
- Upgrade the first tutorials in this order: Gaussian location-scale,
  bivariate location-coscale, meta-analysis, phylogenetic location effects,
  and random-effect scale models.

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

- Status: planned.
- Implement the first fitted spatial model as an intercept-only univariate
  Gaussian `mu` structured effect, parallel to the implemented phylogenetic path.
- Support either `spatial(1 | site, coords = coords)` or
  `spatial(1 | site, mesh = mesh)` only after the data contract is documented:
  `coords` identify observation or site locations, while `mesh` is the SPDE/GMRF
  computational scaffold.
- Use a small comparator or simulation recovery test before exposing spatial
  effects beyond `mu`.
- Do not add spatial terms in `sigma`, `rho12`, or bivariate structured
  covariance blocks until the intercept-only path is stable.

## Phase 11: Bivariate Random Effects and Correlation Pairs

- Status: first slice implemented.
- Matching labelled random intercepts in bivariate `mu1` and `mu2` are
  implemented after the fixed-effect bivariate Gaussian location-coscale model
  stabilized. Random slopes, residual-scale bivariate random effects, and
  structured covariance remain planned.
- Use labelled group-level covariance blocks so residual `rho12`, ordinary
  group-level correlations, phylogenetic correlations, spatial field
  correlations, and mean-scale correlations stay in separate namespaces.
- Keep the first individual-difference covariance target focused on ordinary
  grouped personality and plasticity terms before adding structured
  phylogenetic or non-phylogenetic species correlation layers.
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

- Status: planned.
- Extend the implemented `phylo(1 | species, tree = tree)` Gaussian `mu` path to
  one structured `mu` slope, then only later to small structured slope sets.
- Add phylogenetic terms in `sigma` only after the location path has larger
  simulation evidence and clear identifiability diagnostics.
- Keep phylogenetic location-scale-shape models as a research target, not an
  early production feature.
- Add long optional simulations for many species, near-zero phylogenetic SD,
  high residual noise, and combined phylogenetic plus non-phylogenetic species
  effects.
- For future two-response or two-trait structured models, estimate and report
  phylogenetic correlation, non-phylogenetic species correlation, and residual
  `rho12` as separate layers. Residual `rho12` is not a substitute for
  phylogenetic or species-level covariance.

## Phase 13: Double-Hierarchical Derived Inference

- Status: planned.
- Build on Phase 6 direct-parameter profile intervals, including the first
  covariance-row profile intervals, and Phase 11 correlation-pair models.
- Add uncertainty for derived quantities that matter in complete
  individual-difference location-scale models: repeatability, phylogenetic
  signal, total variance, and correlations among individual differences in
  average response, mean-model slopes, residual scale, and scale-model slopes.
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
- Add Gaussian aggregation or sufficient-statistic paths where repeated rows can
  be collapsed without changing the likelihood.
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
