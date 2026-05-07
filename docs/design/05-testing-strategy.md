# Testing Strategy

Testing must constrain the modelling ambitions of `drmTMB`.

## Test Layers

- Unit tests for formula parsing and family validation.
- Simulation tests for each likelihood.
- Comparative smoke tests against established packages where parameterizations
  match.
- Prediction and simulation method tests.
- Snapshot tests for clear user-facing errors.
- Optional long simulation tests outside CRAN checks.

## Two-Tier Validation

`drmTMB` should validate models in two complementary ways.

Tier 1 is comparison against established software. These checks are useful for
simple overlapping models:

- `lme4` or `glmmTMB` for homoscedastic Gaussian random effects;
- `glmmTMB`, `gamlss`, and sometimes `brms` for Gaussian location-scale models;
- `metafor` for standard Gaussian meta-analysis and known sampling variances or
  covariance matrices;
- `glmmTMB::equalto()` for TMB-based meta-analysis with supplied known sampling
  covariance matrices, following Williams et al. (2026);
- analytic maximum-likelihood calculations for simple bivariate Gaussian
  residual correlations;
- `brms` for occasional long-running Bayesian comparisons of bivariate
  distributional models;
- later, `MCMCglmm`, `brms`, `phyr`, `sdmTMB`, or `gllvmTMB` examples for
  phylogenetic A-inverse and SPDE spatial modules.

Fast package tests should use `skip_if_not_installed()` and only tiny comparator
cases. Full comparator sweeps belong in optional local scripts or scheduled CI,
because package conventions, likelihood constants, priors, and optimizer
settings can differ.

Implemented comparator smoke tests:

- homoscedastic Gaussian random intercepts against `lme4::lmer(..., REML = FALSE)`;
- Gaussian ML meta-analysis with known sampling variances against
  `metafor::rma.uni(..., method = "ML")`.

Planned comparator smoke tests:

- homoscedastic Gaussian random slopes against `lme4::lmer(..., REML = FALSE)`
  once the exact correlated versus independent covariance semantics are matched;
- dense known sampling covariance against `metafor::rma.mv(...)`;
- dense known sampling covariance against `glmmTMB::equalto()` when the
  likelihood and residual heterogeneity parameterization overlap cleanly.

Tier 2 is simulation recovery. This is the primary truth source:

- simulate from known parameters;
- fit the matching `drmTMB` model;
- check convergence and Hessian diagnostics;
- check parameter recovery on the link and response scales;
- check edge cases such as near-zero scale components, high or negative
  `rho12`, sparse grouping, uneven sampling variances, and missing rows.

## Simulation Recovery

Each family should have tests that:

1. simulate from known parameters;
2. fit the corresponding model;
3. check convergence;
4. check estimates within tolerance;
5. cover boundary-prone cases.

## Bivariate Required Cases

- `rho12 = 0`;
- moderate positive `rho12`;
- moderate negative `rho12`;
- predictor-dependent `rho12`;
- unequal `sigma1` and `sigma2`.

## CRAN Constraints

Routine tests should be deterministic, fast, and small. Larger recovery studies
belong in optional scripts or scheduled CI.

## Fast Versus Long Tests

Fast CRAN tests answer: is the likelihood wired correctly and does it recover a
small set of known cases?

Long local or scheduled tests answer: does the estimator behave across the
parameter space?

Examples of long-test grids:

- Gaussian location-scale across sample size, scale slopes, factors, and
  missingness;
- meta-analysis across small, moderate, and large heterogeneity, uneven `V`,
  and categorical moderators in `sigma`;
- bivariate `rho12` across negative, near-zero, positive, and high
  correlations;
- random effects across group counts, unbalanced groups, and boundary SDs;
- phylogenetic A-inverse sparse-vs-dense equivalence and tree-size sweeps;
- SPDE spatial recovery across mesh density, range, field SD, and sampling
  design.

## Profile-Likelihood CI Tests

When profile-likelihood intervals are implemented, tests should check:

- direct TMB parameters recover sensible intervals on the transformed response
  scale;
- `uniroot()` bounds agree with a small diagnostic grid in simple models;
- boundary variance components return flagged one-sided intervals;
- failed constrained optimizations produce informative fallbacks;
- profile CIs have better small-sample behavior than Wald intervals in targeted
  long simulations.
