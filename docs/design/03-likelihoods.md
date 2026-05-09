# Likelihoods

Likelihoods are implemented in TMB templates and called from R wrappers.

## Parameter Scales

- Positive parameters use log links.
- Unit-interval parameters use logit links.
- Residual correlations use a Fisher-z-like linear predictor and a guarded
  `0.99999999 * tanh()` response transform.
- Shape parameters use family-specific stable links.

## Notation

In mathematical prose, `Normal(a, b)` uses variance as the second argument.
The corresponding R density call uses standard deviation, as in
`dnorm(y, mean = a, sd = sqrt(b), log = TRUE)`.

## Implemented TMB Routing

The R builders use descriptive model labels, such as `"gaussian"`,
`"student"`, `"lognormal"`, `"gamma"`, `"beta"`, `"poisson"`, `"zi_poisson"`,
`"nbinom2"`, `"zi_nbinom2"`, and `"biv_gaussian"`. Before calling the TMB template, `make_tmb_data()` turns
those labels into integer branches in `src/drmTMB.cpp`. Unknown labels are
rejected before they can fall through to a wrong likelihood branch. This table
is the current routing contract:

| TMB `model_type` | User-facing route | R builder | TMB branch purpose |
|---:|---|---|---|
| `1` | `family = gaussian()` | `drm_build_gaussian_ls_spec()` | Univariate Gaussian location-scale models, including ordinary `mu` random effects, residual-scale `sigma` random effects, `sd(group) ~ ...` random-effect scale models, `meta_known_V(V = V)`, and the implemented intercept-only `phylo()` location effect. |
| `2` | `family = biv_gaussian()`, `family = c(gaussian(), gaussian())`, or `family = list(gaussian(), gaussian())` | `drm_build_biv_gaussian_spec()` | Bivariate Gaussian location-scale-coscale models with `mu1`, `mu2`, `sigma1`, `sigma2`, and residual `rho12`, including complete-row dense known sampling covariance. |
| `3` | `family = student()` | `drm_build_student_ls_spec()` | Univariate Student-t location-scale-shape models with `mu`, `sigma`, and `nu = 2 + exp(eta_nu)`. |
| `4` | `family = lognormal()` | `drm_build_lognormal_ls_spec()` | Univariate fixed-effect lognormal location-scale models for positive responses, with `mu` and `sigma` defined on the log-response scale. |
| `5` | `family = Gamma(link = "log")` | `drm_build_gamma_ls_spec()` | Univariate fixed-effect Gamma mean-CV models for positive responses, with `mu` as the response mean and `sigma` as the coefficient of variation. |
| `6` | `family = poisson(link = "log")` | `drm_build_poisson_spec()` | Univariate fixed-effect Poisson mean models for non-negative integer counts, with `mu` as the count mean. |
| `7` | `family = nbinom2()` | `drm_build_nbinom2_spec()` | Univariate fixed-effect negative-binomial 2 models for overdispersed counts, with `mu` as the count mean and `sigma` as an overdispersion scale. |
| `8` | `family = poisson(link = "log")` plus `zi ~ ...` | `drm_build_poisson_spec()` | Univariate fixed-effect zero-inflated Poisson models, with `mu` as the conditional count mean and `zi` as the structural-zero probability. |
| `9` | `family = nbinom2()` plus `zi ~ ...` | `drm_build_nbinom2_spec()` | Univariate fixed-effect zero-inflated negative-binomial 2 models, with `mu` as the conditional count mean, `sigma` as the NB2 overdispersion scale, and `zi` as the structural-zero probability. |
| `10` | `family = beta()` | `drm_build_beta_ls_spec()` | Univariate fixed-effect beta mean-scale models for strict continuous proportions, with `mu` as the mean proportion and public `sigma` mapped internally to `phi = 1 / sigma^2`. |
| `99` | no public route | direct test construction only | Hidden phylogenetic precision-prior parity branch used to test the sparse augmented A-inverse objective in isolation. |

The hidden `model_type = 99` branch is not a family and should not appear in
user examples. Public phylogenetic Gaussian fits stay on `model_type = 1`; the
hidden branch exists only so tests can compare the isolated TMB prior objective
against the R algebra helper.

## Implemented Gaussian Location-Scale

Gaussian location-scale is implemented for fixed-effect models and for
univariate Gaussian location random intercepts, labelled random intercepts,
independent numeric random slopes, and labelled or unlabelled ordinary
correlated random intercept-slope blocks, residual-scale random intercepts in
the univariate Gaussian `sigma` formula, and random-effect scale models for
one or more distinct unlabelled `mu` random intercepts:

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

The implemented random-effect scale grammar can target one or more distinct
unlabelled univariate Gaussian `mu` random intercepts. For one target:

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

For several distinct random-intercept targets, the likelihood uses the same
non-centered construction for each component:

```text
mu_i = X_mu[i, ] beta_mu + b_id[id_i] + b_site[site_i]
b_id[j] = sd_mu_id,j u_id,j
b_site[k] = sd_mu_site,k u_site,k
u_id,j, u_site,k ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
log(sd_mu_site,k) = W_site[k, ] alpha_site
```

Matching R syntax:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id) + (1 | site),
    sigma ~ x2,
    sd(id) ~ x_group,
    sd(site) ~ site_type
  ),
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
y_i ~ Normal(mu_i, vi_i + sigma_i^2)
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

## Implemented Student-t Location-Scale-Shape

The first robust continuous likelihood is fixed-effect Student-t regression:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
nu_i = 2 + exp(eta_nu_i)
```

The TMB likelihood includes all Student-t normalizing constants:

```text
z_i = (y_i - mu_i) / sigma_i
log f(y_i) =
  lgamma((nu_i + 1) / 2) - lgamma(nu_i / 2)
  - 0.5 log(nu_i pi) - log(sigma_i)
  - 0.5 (nu_i + 1) log(1 + z_i^2 / nu_i)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = student(),
  data = dat
)
```

This first implementation deliberately rejects random effects, known sampling
covariance, phylogenetic terms, and bivariate Student-t families until the
fixed-effect likelihood and recovery tests remain stable.

## Implemented Lognormal Location-Scale

The first positive continuous likelihood is fixed-effect lognormal regression:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
```

The TMB likelihood is evaluated on the original positive response scale with
the log-Jacobian term:

```text
log_y_i = log(y_i)
log f(y_i) =
  log Normal(log_y_i | mu_i, sigma_i^2) - log_y_i
```

The arithmetic response mean is:

```text
E[y_i] = exp(mu_i + sigma_i^2 / 2)
```

Matching R syntax:

```r
drmTMB(
  bf(biomass ~ habitat, sigma ~ treatment),
  family = lognormal(),
  data = dat
)
```

For lognormal fits, `predict(fit, dpar = "mu")` returns the log-scale
location parameter, `sigma(fit)` returns the log-scale standard deviation, and
`fitted(fit)` returns `E[y_i]` on the original response scale. The response
must be positive and finite after missing-row filtering. Random effects, known
sampling covariance, phylogenetic terms, and bivariate lognormal models are
later phases.

## Implemented Gamma Mean-CV

The first Gamma path is fixed-effect mean-CV regression:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i^2 sigma_i^2
```

The TMB likelihood is:

```text
log f(y_i) =
  (shape_i - 1) log(y_i) - y_i / scale_i -
  log Gamma(shape_i) - shape_i log(scale_i)
```

Matching R syntax:

```r
drmTMB(
  bf(biomass ~ habitat, sigma ~ treatment),
  family = Gamma(link = "log"),
  data = dat
)
```

For Gamma fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
response mean. `sigma(fit)` returns the coefficient of variation, not the
residual standard deviation; the fitted residual standard deviation is
`mu_i * sigma_i`. The response must be positive and finite after missing-row
filtering. Random effects, known sampling covariance, phylogenetic terms, and
bivariate or mixed Gamma models are later phases.

## Implemented Beta Mean-Scale

The first beta path is fixed-effect mean-scale regression for strict
continuous proportions:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

The TMB likelihood is:

```text
log f(y_i) =
  log Gamma(phi_i) - log Gamma(alpha_i) - log Gamma(beta_i) +
  (alpha_i - 1) log(y_i) + (beta_i - 1) log(1 - y_i)
```

Matching R syntax:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment),
  family = beta(),
  data = dat
)
```

For beta fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the mean
proportion. `sigma(fit)` returns the public scale parameter, not beta
precision; internally `phi_i = 1 / sigma_i^2`. The response must be finite and
strictly between 0 and 1 after missing-row filtering. Boundary responses,
denominator syntax, random effects, known sampling covariance, phylogenetic
terms, and bivariate or mixed beta models are later phases.

## Implemented Poisson Mean

The first count path is fixed-effect mean regression:

```text
y_i | mu_i ~ Poisson(mu_i)
eta_mu_i = X_mu[i, ] beta_mu
mu_i = exp(eta_mu_i)
E[y_i] = Var[y_i] = mu_i
```

The TMB likelihood is:

```text
log f(y_i) = y_i log(mu_i) - mu_i - log(y_i!)
```

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat),
  family = poisson(link = "log"),
  data = dat
)
```

For Poisson fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
count mean. There is no fitted `sigma` distributional parameter; `sigma(fit)`
returns a fixed unit dispersion vector for compatibility with base-R method
expectations. The response must contain non-negative integer counts after
missing-row filtering. Random effects, known sampling covariance,
overdispersion, phylogenetic terms, and bivariate or mixed Poisson models are
later phases.

## Implemented Zero-Inflated Poisson Mean

Zero-inflated Poisson models reuse the ordinary Poisson family route and add a
formula for the structural-zero probability:

```text
y_i | mu_i, zi_i ~ zero-inflated Poisson(mu_i, zi_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_zi_i = X_zi[i, ] beta_zi
mu_i = exp(eta_mu_i)
zi_i = logit^{-1}(eta_zi_i)
```

The probability mass is:

```text
Pr(y_i = 0) = zi_i + (1 - zi_i) exp(-mu_i)
Pr(y_i = y > 0) = (1 - zi_i) Poisson(y | mu_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) mu_i (1 + zi_i mu_i)
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, zi ~ treatment),
  family = poisson(link = "log"),
  data = dat
)
```

Here `mu` is the conditional count mean among observations that are not
structural zeros. The structural-zero probability is `zi`, not a scale
parameter. Consequently, `predict(fit, dpar = "mu")` returns the conditional
mean, `predict(fit, dpar = "zi")` returns the zero-inflation probability, and
`fitted(fit)` returns the unconditional response mean `(1 - zi) * mu`.
`sigma(fit)` returns a fixed unit dispersion vector because no residual scale
parameter is fitted.

## Implemented Negative Binomial 2 Mean-Dispersion

The first overdispersed count path is fixed-effect NB2 regression:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

The TMB likelihood matches the `stats::dnbinom(mu = mu_i, size = size_i)`
mean parameterization:

```text
log f(y_i) =
  log Gamma(y_i + size_i) - log Gamma(size_i) - log Gamma(y_i + 1) +
  size_i [log(size_i) - log(size_i + mu_i)] +
  y_i [log(mu_i) - log(size_i + mu_i)]
```

The C++ template evaluates an algebraically equivalent form that cancels the
unstable `size_i = 1 / sigma_i^2` terms. With
`alpha_i = sigma_i^2`, it uses

```text
log f(y_i) =
  y_i eta_mu_i - log Gamma(y_i + 1)
  + sum_{j = 0}^{y_i - 1} log(1 + alpha_i j)
  - y_i log(1 + alpha_i mu_i)
  - log(1 + alpha_i mu_i) / alpha_i
```

This form has the correct Poisson limit as `alpha_i` approaches zero and avoids
overflow from computing very large `size_i`.

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment),
  family = nbinom2(),
  data = dat
)
```

For `nbinom2()` fits, `predict(fit, dpar = "mu")` and `fitted(fit)` return the
count mean. `sigma(fit)` returns the overdispersion scale in the variance
equation, not a residual standard deviation. Larger `sigma` means greater
extra-Poisson variation. Random effects, known sampling covariance, hurdle
components, phylogenetic terms, and bivariate or mixed negative-binomial models
are later phases.

## Implemented Zero-Inflated Negative Binomial 2

Zero-inflated NB2 models reuse `nbinom2()` and add a formula for the
structural-zero probability:

```text
y_i | mu_i, sigma_i, zi_i ~ zero-inflated NB2(mu_i, sigma_i, zi_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_zi_i = X_zi[i, ] beta_zi
mu_i = exp(eta_mu_i)
sigma_i = exp(eta_sigma_i)
zi_i = logit^{-1}(eta_zi_i)
size_i = 1 / sigma_i^2
```

The probability mass is:

```text
Pr(y_i = 0) = zi_i + (1 - zi_i) NB2(0 | mu_i, size_i)
Pr(y_i = y > 0) = (1 - zi_i) NB2(y | mu_i, size_i)
E[y_i] = (1 - zi_i) mu_i
Var[y_i] = (1 - zi_i) (mu_i + sigma_i^2 mu_i^2) + zi_i (1 - zi_i) mu_i^2
```

Matching R syntax:

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment, zi ~ survey_method),
  family = nbinom2(),
  data = dat
)
```

Here `mu` is the conditional NB2 mean among observations that are not
structural zeros, `sigma` is the conditional NB2 overdispersion scale, and `zi`
is the structural-zero probability. Consequently, `predict(fit, dpar = "mu")`
returns the conditional mean, `sigma(fit)` returns the conditional
overdispersion scale, `predict(fit, dpar = "zi")` returns the zero-inflation
probability, and `fitted(fit)` returns `(1 - zi) * mu`.

## Implemented Bivariate Meta-Analytic Gaussian Regression

Bivariate meta-analysis must add known sampling covariance to the bivariate
Gaussian location-coscale likelihood. For observation or study `i`:

```text
y_i = [y1_i, y2_i]'
mu_i = [mu1_i, mu2_i]'

y_i | mu_i, S_i, Omega_i ~ MVN(mu_i, S_i + Omega_i)

S_i =
  [v1_i,   c12_i;
   c12_i, v2_i]

Omega_i =
  [sigma1_i^2,                  rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,   sigma2_i^2]
```

`S_i` is known within-study sampling covariance supplied by
`meta_known_V(V = V)`. `Omega_i` is unknown residual or between-study
heterogeneity covariance. The fitted `rho12_i` therefore remains the residual
or heterogeneity correlation; it is not the known within-study sampling
correlation.

Equivalently, with row-paired stacking:

```text
y_stack = [y1_1, y2_1, y1_2, y2_2, ..., y1_n, y2_n]'
y_stack ~ MVN(mu_stack, V_stack + Omega_stack)
```

where `V_stack` is the supplied known sampling covariance and `Omega_stack`
contains the fitted `sigma1`, `sigma2`, and `rho12` blocks.

The current implementation:

- requires complete bivariate rows;
- accepts a `2n` by `2n` dense or block-diagonal `V` in row-paired order;
- rejects duplicate `meta_known_V()` markers across `mu1` and `mu2`;
- provides `meta_vcov_bivariate()` to build the common block-diagonal `V` from
  `v1`, `v2`, and
  either `cov12` or `cor12`;
- documents sensitivity analysis when within-study correlations are unknown.

## Implemented Bivariate Gaussian Location-Coscale

Bivariate Gaussian location-coscale:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
mu1_i = X_mu1[i, ] beta_mu1
mu2_i = X_mu2[i, ] beta_mu2
log(sigma1_i) = X_sigma1[i, ] beta_sigma1
log(sigma2_i) = X_sigma2[i, ] beta_sigma2
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.99999999 * tanh(eta_rho12_i)
Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i
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
  `rho12 = 0.99999999 * tanh(eta_rho12)` on the response scale so the
  covariance matrix stays positive definite even for extreme linear predictors.
- Simulation recovery tests live in `tests/testthat/test-biv-gaussian.R`.
- `mvbind(y1, y2) ~ x` is implemented as a formula shorthand that creates
  identical `mu1` and `mu2` design matrices.
- Dense known sampling covariance is implemented for complete-row bivariate
  Gaussian models through `meta_known_V(V = V)`, where `V` is a row-paired
  `2n` by `2n` matrix added to the fitted residual covariance.
- Random effects are not implemented for this bivariate family yet.

## Review Requirements

Every likelihood must have simulation recovery tests before being treated as
implemented.
