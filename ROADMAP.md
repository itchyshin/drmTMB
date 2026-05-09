# drmTMB Roadmap

`drmTMB` is a focused R package for fast univariate and bivariate
distributional regression models using TMB.

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
  residual-scale random intercepts in `sigma`.
- Supported syntax: `bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1)`.
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
- Add sparse known covariance after dense covariance tests pass.
- Use `sigma ~ x1` for heterogeneous heterogeneity, even when papers
  describe the same unknown SD as `tau`.
- Tests based on fixed known sampling variance and known extra heterogeneity
  are implemented.

## Phase 3: Bivariate Gaussian Coscale

- Status: fixed-effect bivariate Gaussian implemented.
- Support separate formulas for `mu1 = y1 ~ ...` and `mu2 = y2 ~ ...`.
- `mvbind(y1, y2) ~ x` is implemented as shorthand for identical location
  formulas and expands internally to `mu1 = y1 ~ x` and `mu2 = y2 ~ x`.
- Added `sigma1`, `sigma2`, and constant `rho12`.
- Added predictor-dependent `rho12 ~ x` using the Fisher-z/atanh scale.
- Added simulation tests for positive, near-zero, negative, and
  predictor-dependent residual correlations.
- Public bivariate family grammar accepts `family = c(gaussian(), gaussian())`
  or `family = list(gaussian(), gaussian())` for the implemented all-Gaussian
  likelihood. Mixed composed families such as `family = c(gaussian(), poisson())`
  remain future work where the joint likelihood is defined.
- Random effects remain future work.

## Phase 4: Mixed and Double-Hierarchical Models

- Status: random intercepts, independent numeric random slopes written as
  `(0 + x | id)`, and ordinary correlated intercept-slope blocks written as
  `(1 + x | id)` or `(1 + x | p | id)` are implemented for the univariate
  Gaussian location formula. Random intercepts in the residual `sigma` formula
  are also implemented. Random-effect scale formulae are implemented for one or
  more distinct unlabelled Gaussian `mu` random intercepts, such as
  `sd(id) ~ x_group` and `sd(site) ~ site_type`.
- Add cross-formula or cross-parameter covariance sharing for labelled blocks,
  following `docs/design/17-correlated-random-effect-blocks.md`.
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

- Status: first univariate Gaussian phylogenetic location path implemented.
- Treat phylogenetic and spatial terms as one structured-effect module:
  `z ~ MVN(0, sigma_z^2 K)`, with `K = A` for phylogeny and `K = M` for
  spatial dependence.
- Add sparse known-covariance infrastructure.
- Implemented `phylo(1 | species, tree = tree)` for univariate Gaussian `mu`
  using an ultrametric branch-length tree, the sparse augmented A-inverse path,
  and simulation recovery tests.
- Add spatial SPDE/GMRF fields after the core Gaussian and known-covariance
  path is reliable.
- For bivariate structured models, estimate and report level-specific
  correlations separately: residual `rho12`, phylogenetic correlations,
  non-phylogenetic species correlations, spatial field correlations, and
  ordinary grouped random-effect correlations should not share one namespace.
- Stage structured phylogenetic and spatial slopes conservatively:
  intercept-only structured effects first, then one `mu` slope, then only small
  slope sets or interaction slopes after simulation recovery.
- Add identifiability diagnostics for replication by study, species, location,
  and effect-size levels before complex structured models are promoted.
- Selectively reuse GPL-compatible ideas or modules from `gllvmTMB` with
  provenance notes and tests.

## Phase 6: Profile-Likelihood Inference

- Add profile-likelihood confidence intervals for direct TMB parameters such as
  log SDs, variance components, and ordinal cutpoints.
- Prefer `TMB::tmbprofile()` plus `uniroot()` for one-dimensional intervals,
  because it warm-starts constrained optimizations and avoids wasteful grids.
- Support linear combinations through TMB's `lincomb` machinery where possible.
- Treat nonlinear derived quantities, such as ICCs and variance-component
  correlations, as a later fix-and-refit problem with boundary and convergence
  flags.
- Keep parametric bootstrap as a fallback for boundary, non-monotone, or failed
  inner-optimization cases.

## Phase 7: Robust Continuous and Shape Families

- Status: fixed-effect univariate Student-t location-scale-shape models are
  implemented.
- Harden and extend Student-t models before adding lognormal, gamma,
  skew-normal, and skew-t families.
- Add formulae for shape and tail parameters where stable.
- Add strict starting-value and boundary diagnostics.

## Phase 8: Counts, Proportions, Percentages, and Ordinal Models

- Add negative binomial, COM-Poisson, beta, beta-binomial, zero-one-inflated
  beta, ordered logit/probit, and related families according to the distribution
  roadmap.
