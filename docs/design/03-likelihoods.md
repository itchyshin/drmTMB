# Likelihoods

Likelihoods are implemented in TMB templates and called from R wrappers.

## Parameter Scales

- Positive parameters use log links.
- Unit-interval parameters use logit links.
- Residual correlations use Fisher-z/atanh on the linear predictor and `tanh()`
  on the response scale.
- Shape parameters use family-specific stable links.

## Implemented Gaussian Location-Scale

Gaussian location-scale is implemented for fixed-effect models and for
univariate Gaussian location random intercepts:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

With one or more random intercepts in the location model:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + sum_j b_{j, g_j[i]}
sigma_i = exp(X_sigma[i, ] beta_sigma)
b_{j, g} = sd_j * u_{j, g}
u_{j, g} ~ Normal(0, 1)
sd_j = exp(theta_j)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | site) + (1 | observer), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

Residuals are not part of the formula grammar. They are computed downstream
from the fitted likelihood.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma` uses `log(sigma_i) = X_sigma beta_sigma`.
- Simulation recovery tests live in
  `tests/testthat/test-gaussian-location-scale.R`.
- Random-intercept recovery tests live in
  `tests/testthat/test-gaussian-random-intercepts.R`.
- The univariate likelihood supports optional diagonal known sampling variance via
  `meta_known_V(V = vi)`. It has no residual correlation parameter.

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
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = biv_gaussian(),
  data = dat
)
```

Planned double-hierarchical bivariate syntax:

```r
drmTMB(
  formula = drm_formula(
    mu1 = y1 ~ x1 + x2 + (1 + x2 | p | ID),
    mu2 = y2 ~ x1      + (1 + x2 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

Here `sigma1` and `sigma2` are residual scales. Random-intercept and
random-slope standard deviations from the mean block are group-level scale
components and should be exposed separately.

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
