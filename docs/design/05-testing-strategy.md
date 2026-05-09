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
- planned `glmmTMB::equalto()` checks for TMB-based meta-analysis with supplied
  known sampling covariance matrices, following Williams et al. (2026);
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
- homoscedastic Gaussian independent random intercept/slope models against
  `lme4::lmer(..., REML = FALSE)`;
- labelled and unlabelled correlated Gaussian random-slope blocks against
  `lme4::lmer(..., REML = FALSE)`;
- intercept-only Gaussian random-effect scale formulae such as `sd(id) ~ 1`
  against `lme4::lmer(..., REML = FALSE)`;
- Gaussian ML meta-analysis with known sampling variances against
  `metafor::rma.uni(..., method = "ML")`;
- dense known sampling covariance with constant residual heterogeneity against
  `metafor::rma.mv(..., random = ~ 1 | obs, method = "ML")`.
- lognormal fixed-effect likelihood against an independent `stats::dlnorm()`
  calculation at the fitted coefficients.

Planned comparator smoke tests:

- bivariate meta-analysis with known within-study covariance against
  `metafor::rma.mv(...)` or another established multivariate meta-analysis
  implementation for fixed-effect and simple random-effect cases;
- dense known sampling covariance against `glmmTMB::equalto()` when the
  likelihood and residual heterogeneity parameterization overlap cleanly.

Tier 2 is simulation recovery. This is the primary truth source:

- simulate from known parameters;
- fit the matching `drmTMB` model;
- check convergence and Hessian diagnostics;
- check parameter recovery on the link and response scales;
- check edge cases such as near-zero scale components, high or negative
  `rho12`, sparse grouping, uneven sampling variances, and missing rows.

Bivariate meta-analysis tests must separate two correlations:

```text
S_i[1,2] = known within-study sampling covariance
Omega_i[1,2] = rho12_i sigma1_i sigma2_i
```

Recovery tests should show that fitted `rho12` targets residual or
between-study correlation after the known sampling covariance has been added,
not the sampling correlation supplied in `V`.

Residual-scale random intercept tests stay separate from random-effect scale
tests. `sigma ~ z + (1 | id)` checks group-to-group variation in residual
scale, whereas `sd(id) ~ z_group` checks predictors of a `mu` random-effect
standard deviation.

## Random-Effect Scale Formula Tests

The simplest implemented random-effect scale model is:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id),
    sigma ~ x2,
    sd(id) ~ x3
  ),
  family = gaussian(),
  data = dat
)
```

The test-generating equation should be:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = beta_0 + beta_1 x1_ij + b_j
log(sigma_ij) = gamma_0 + gamma_1 x2_ij
b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = alpha_0 + alpha_1 x3_j
```

Fast CRAN tests should include:

- a moderate recovery case for `alpha_0` and `alpha_1`;
- a multi-target case such as `sd(id) ~ x_id` plus `sd(site) ~ x_site`;
- a near-constant random-effect scale case with `alpha_1 = 0`;
- a factor predictor on the `sd(id)` right-hand side;
- malformed-input tests for absent targets, duplicate targets, ambiguous
  random-intercept/slope targets, bivariate models, non-Gaussian models, and
  `sd(id)` predictors that vary within `id`;
- a homoscedastic comparator against `lme4` when `alpha_1 = 0`.

These tests are implemented in
`tests/testthat/test-gaussian-random-effect-scale.R` and
`tests/testthat/test-comparators.R`.

Larger recovery grids should stay out of CRAN checks and vary group count,
within-group replication, unbalanced groups, small random-effect SDs, large
random-effect SDs, and missingness.

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
