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
- `bf()` and `drmTMB()` support fixed-effect Gaussian location-scale models.
- Supported syntax: `bf(y ~ x, sigma ~ z)`.
- Keep parser support for future `sd(group) ~`, `meta_known_V(V = V)`,
  `phylo()`, and `spatial()` terms from the start.
- Prediction for `mu` and `sigma` is implemented.
- Simulation and parameter-recovery tests are implemented for the first
  Gaussian case.

## Phase 2: Meta-Analytic Gaussian Regression

- Status: diagonal known sampling variance implemented.
- Treat meta-analysis as `family = gaussian()` plus `meta_known_V(V = V)`.
- Support diagonal known sampling variance through vectors, columns, or diagonal
  matrices.
- Add full or block-diagonal known covariance after diagonal tests pass.
- Use `sigma ~ moderator` for heterogeneous heterogeneity, even when papers
  describe the same unknown SD as `tau`.
- Tests based on fixed known sampling variance and known extra heterogeneity
  are implemented.

## Phase 3: Bivariate Gaussian Coscale

- Status: fixed-effect bivariate Gaussian implemented.
- Support separate formulas for `mu1 = y1 ~ ...` and `mu2 = y2 ~ ...`.
- Keep `mvbind(y1, y2) ~ x` only as shorthand for identical location formulas.
- Added `sigma1`, `sigma2`, and constant `rho12`.
- Added predictor-dependent `rho12 ~ x` using the Fisher-z/atanh scale.
- Added simulation tests for positive, near-zero, negative, and
  predictor-dependent residual correlations.
- Random effects and `mvbind()` shorthand remain future work.

## Phase 4: Mixed and Double-Hierarchical Models

- Add random intercepts in the location formula.
- Add random intercepts in scale formulae.
- Add random-effect scale formulae such as `sd(id) ~ x`.
- Support multiple random-effect scale components, such as `sd(study) ~ x` and
  `sd(species) ~ 1`.
- Respect brms-style correlated group syntax such as `(1 + x | p | id)`.
- Add variance-component correlation summaries when identifiable.

## Phase 5: Phylogenetic and Spatial Dependence

- Add sparse known-covariance infrastructure.
- Add phylogenetic models using the A-inverse speed path.
- Add spatial SPDE/GMRF fields after the core Gaussian and known-covariance
  path is reliable.
- Selectively reuse GPL-compatible ideas or modules from `gllvmTMB` with
  provenance notes and tests.

## Phase 6: Robust Continuous and Shape Families

- Add Student-t, lognormal, gamma, skew-normal, and skew-t families.
- Add formulae for shape and tail parameters where stable.
- Add strict starting-value and boundary diagnostics.

## Phase 7: Counts, Proportions, Percentages, and Ordinal Models

- Add negative binomial, COM-Poisson, beta, beta-binomial, zero-one-inflated
  beta, ordered logit/probit, and related families according to the distribution
  roadmap.
