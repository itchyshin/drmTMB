# Likelihoods

Likelihoods are implemented in TMB templates and called from R wrappers.

## Parameter Scales

- Positive parameters use log links.
- Unit-interval parameters use logit links.
- Residual correlations use Fisher-z/atanh on the linear predictor and `tanh()`
  on the response scale.
- Shape parameters use family-specific stable links.

## Current Gaussian Location-Scale MVP

Gaussian location-scale is implemented for fixed-effect models:

```text
y_i ~ Normal(mu_i, sigma_i)
mu_i = X_mu beta_mu
log(sigma_i) = X_sigma beta_sigma
```

Residuals are not part of the formula grammar. They are computed downstream
from the fitted likelihood.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma` uses `log(sigma_i) = X_sigma beta_sigma`.
- Simulation recovery tests live in
  `tests/testthat/test-gaussian-location-scale.R`.
- The univariate likelihood supports optional diagonal known sampling variance via
  `meta_known_V(V = vi)`. It has no random effects and no residual correlation
  parameter.

## Implemented Diagonal Meta-Analytic Gaussian Regression

Meta-analysis uses the ordinary Gaussian family plus known sampling variance.
It is not a separate family.

```text
y ~ MVN(mu, V_known + Sigma_unknown)
```

The implemented first path is diagonal `V`, written as `meta_known_V(V = vi)`
in the location formula:

```text
y_i ~ Normal(mu_i, sqrt(vi_i + sigma_i^2))
log(sigma_i) = X_sigma beta_sigma
```

Implementation notes for the diagonal path:

- `vi` means known sampling variances, not known standard errors.
- `vi_i` must be finite, non-negative, and aligned with the retained model rows.
- `sigma_i` is the extra heterogeneity SD after known sampling error is added.
- `meta_known_V()` must be treated as a covariance marker, not as an ordinary
  fixed-effect predictor.
- The marker is removed before model-matrix construction.
- `predict(fit, dpar = "sigma")` returns the unknown heterogeneity SD;
  likelihood, Pearson residuals, and simulation use
  `sqrt(vi_i + sigma_i^2)`.
- Simulation recovery tests with known `vi` live in
  `tests/testthat/test-meta-known-v.R`.

For later full or block-diagonal `V`:

```text
y ~ MVN(mu, V + diag(sigma_i^2))
```

In meta-analysis prose, `sigma` is the extra heterogeneity SD traditionally
called `tau`. The public API still uses `sigma` for consistency.

## Implemented Bivariate Gaussian Location-Coscale

Bivariate Gaussian location-coscale:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i
rho12_i = tanh(eta_rho12_i)
```

Location formulas for the two responses may differ. `rho12` is residual
response-response correlation, not a group-level random-effect correlation.

Implemented fixed-effect syntax:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ z1,
    sigma2 = ~ z2,
    rho12 = ~ w
  ),
  family = biv_gaussian(),
  data = dat
)
```

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma1` and `sigma2` use log links.
- `rho12` uses `eta_rho12 = X_rho12 beta_rho12` and a bounded tanh transform
  on the response scale so the covariance matrix stays positive definite even
  for extreme linear predictors.
- Simulation recovery tests live in `tests/testthat/test-biv-gaussian.R`.
- Random effects, known sampling covariance, and `mvbind()` shorthand are not
  implemented for this family yet.

## Review Requirements

Every likelihood must have simulation recovery tests before being treated as
implemented.
