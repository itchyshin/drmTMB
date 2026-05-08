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
univariate Gaussian location random intercepts, labelled random intercepts,
independent numeric random slopes, and labelled or unlabelled ordinary
correlated random intercept-slope blocks, residual-scale random intercepts in
the univariate Gaussian `sigma` formula, and a first random-effect scale model
for one `mu` random intercept:

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

With one or more simple random-effect terms in the location model:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + sum_j z_j[i] b_{j, g_j[i]}
sigma_i = exp(X_sigma[i, ] beta_sigma)
b_{j, g} = sd_j * u_{j, g}
u_{j, g} ~ Normal(0, 1)
sd_j = exp(theta_j)
```

For a random intercept, `z_j[i] = 1`. For a simple random slope written as
`(0 + x | id)`, `z_j[i] = x_i`.

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | site) + (0 + x1 | observer), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

For an ordinary correlated random intercept-slope block:

```text
mu_i = X_mu[i, ] beta_mu + b_0,g[i] + x_i b_1,g[i]

[b_0,g, b_1,g]' ~ MVN(0, Sigma_g)
Sigma_g =
  [sd0^2,          rho_re sd0 sd1;
   rho_re sd0 sd1, sd1^2]

u_g ~ Normal([0, 0]', I)
b_0,g = sd0 * u_0,g
b_1,g = sd1 * (rho_re * u_0,g + sqrt(1 - rho_re^2) * u_1,g)
rho_re = 0.999999 * tanh(eta_cor)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

or, with an explicit covariance-block label:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

Here `rho_re` is a group-level random-effect correlation. It is extracted via
`corpars$mu` and is not residual `rho12`. In the current univariate Gaussian
implementation, the middle label `p` is retained for naming and future
cross-formula covariance matching; the likelihood is otherwise the same as the
unlabelled `(1 + x1 | id)` block.

Residual-scale random intercepts are implemented on the log-`sigma` scale:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + a_{g[i]}
a_g = sd_sigma_group * v_g
v_g ~ Normal(0, 1)
sd_sigma_group = exp(theta_sigma_group)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2 + (1 | id)),
  family = gaussian(),
  data = dat
)
```

This is residual-scale heterogeneity. It is distinct from random-effect scale
models such as `sd(id) ~ x_group`.

The implemented random-effect scale MVP targets exactly one unlabelled
univariate Gaussian `mu` random intercept:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
sd_mu_id,j = exp(W_id[j, ] alpha_id)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2, sd(id) ~ x_group),
  family = gaussian(),
  data = dat
)
```

The right-hand side of `sd(id) ~ x_group` is evaluated once per `id` level.
Predictors must be constant within `id` after missing-row filtering. This
models among-group variation in the location random intercept; it is not a
residual-scale model and it is not a second `sigma` formula.

Residuals are not part of the formula grammar. They are computed downstream
from the fitted likelihood.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma` uses `log(sigma_i) = X_sigma beta_sigma`.
- Simulation recovery tests live in
  `tests/testthat/test-gaussian-location-scale.R`.
- Random-effect recovery tests live in
  `tests/testthat/test-gaussian-random-intercepts.R`.
- Random-effect scale recovery tests live in
  `tests/testthat/test-gaussian-random-effect-scale.R`.
- Comparator tests against `lme4` for overlapping Gaussian ML random-effect
  models live in `tests/testthat/test-comparators.R`.
- The univariate likelihood supports optional known sampling covariance via
  `meta_known_V(V = V)`. It has no residual correlation parameter.

## Implemented Meta-Analytic Gaussian Regression

Meta-analysis uses the ordinary Gaussian family plus known sampling covariance.
It is not a separate family.

```text
y ~ MVN(mu, V_known + Sigma_unknown)
```

For diagonal `V`, written as `meta_known_V(V = vi)` in the location formula:

```text
y_i ~ Normal(mu_i, sqrt(vi_i + sigma_i^2))
log(sigma_i) = X_sigma beta_sigma
```

For dense full or block-diagonal `V`, the implemented likelihood is:

```text
y ~ MVN(mu, V + diag(sigma_i^2))
```

Implementation notes:

- `vi` means known sampling variances, not known standard errors.
- A vector or data column supplies diagonal known sampling variances.
- A matrix supplies dense known sampling covariance and must be symmetric
  positive semidefinite after retained-row subsetting.
- `sigma_i` is the extra heterogeneity SD after known sampling error is added.
- `meta_known_V()` must be treated as a covariance marker, not as an ordinary
  fixed-effect predictor.
- The marker is removed before model-matrix construction.
- `predict(fit, dpar = "sigma")` returns the unknown heterogeneity SD;
  likelihood, Pearson residuals, and simulation include the known covariance.
- Simulation, missing-row, and likelihood-agreement tests with known `vi` and
  full `V` live in
  `tests/testthat/test-meta-known-v.R`.
- Sparse known covariance is planned for larger phylogenetic and spatial
  workloads.

In meta-analysis prose, `sigma` is the extra heterogeneity SD traditionally
called `tau`. The public API still uses `sigma` for consistency.

## Implemented Bivariate Gaussian Location-Coscale

Bivariate Gaussian location-coscale:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1
mu2_i = X_mu2[i, ] beta_mu2
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
atanh(rho12_i) = X_rho12[i, ] beta_rho12
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
  family = c(gaussian(), gaussian()),
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

For example, a future correlated random-intercept and random-slope block in
the two mean formulas would add:

```text
mu1_ij = X_mu1[ij, ] beta_mu1 + b_0_1j + b_x_1j x_ij
mu2_ij = X_mu2[ij, ] beta_mu2 + b_0_2j + b_x_2j x_ij
[b_0_1j, b_x_1j, b_0_2j, b_x_2j]' ~ MVN(0, Sigma_mu_ID)
```

The correlations inside `Sigma_mu_ID` are group-level correlations among
random effects. They are not residual `rho12`, and the first implementation
should estimate them as constant covariance-block quantities rather than
predictor-dependent `rho12` formulae.

Implementation notes:

- TMB template: `src/drmTMB.cpp`.
- R builder: `R/drmTMB.R`.
- Positive `sigma1` and `sigma2` use log links.
- `rho12` uses `eta_rho12 = X_rho12 beta_rho12` and a bounded tanh transform
  on the response scale so the covariance matrix stays positive definite even
  for extreme linear predictors.
- Simulation recovery tests live in `tests/testthat/test-biv-gaussian.R`.
- Random effects, known sampling covariance, and `mvbind()` shorthand are not
  implemented for this bivariate family yet.

## Review Requirements

Every likelihood must have simulation recovery tests before being treated as
implemented.
