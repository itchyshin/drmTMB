# Gaussian Location-Scale Math

This note is the source-of-truth mathematical specification for the first
`drmTMB` model class. Every implementation and tutorial should be checkable
against these equations.

Notation convention: `Normal(a, b)` uses variance as the second argument.
Thus `Normal(mu_i, sigma_i^2)` has mean `mu_i` and residual standard deviation
`sigma_i`.

## Fixed-Effect Location-Scale

For observation `i`:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
```

Equivalent response-scale expression:

```text
sigma_i = exp(X_sigma[i, ] beta_sigma)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The first formula creates `X_mu`. The `sigma` formula creates `X_sigma`.
Coefficients are parameter specific even when the same biological predictor
appears in both formulas.

Documentation pattern:

| Equation term | User-facing syntax | Internal object |
|---|---|---|
| `y_i` | left-hand side of `y ~ ...` | response vector |
| `X_mu[i, ] beta_mu` | right-hand side of `y ~ ...` | `X$mu`, `beta_mu` |
| `X_sigma[i, ] beta_sigma` | right-hand side of `sigma ~ ...` | `X$sigma`, `beta_sigma` |
| `sigma_i` | `sigma` distributional parameter | `exp(X$sigma %*% beta_sigma)` |

## Location Random Intercepts

For observation `i` in group `g[i]`:

```text
y_i | mu_i, sigma_i, b_g[i] ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + b_g[i]
log(sigma_i) = X_sigma[i, ] beta_sigma
b_g = sd_mu_group * u_g
u_g ~ Normal(0, 1)
sd_mu_group = exp(theta_group)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

With two additive random-intercept terms:

```text
mu_i = X_mu[i, ] beta_mu + b_site[site_i] + b_observer[observer_i]
b_site[k] ~ Normal(0, sd_mu_site^2)
b_observer[l] ~ Normal(0, sd_mu_observer^2)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | site) + (1 | observer), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

## Location Random Slopes

For a simple random slope in the location part:

```text
y_ij | mu_ij, sigma_ij, b_j ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + x_ij b_j
log(sigma_ij) = X_sigma[ij, ] beta_sigma
b_j = sd_mu_x_id * u_j
u_j ~ Normal(0, 1)
sd_mu_x_id = exp(theta_x_id)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (0 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

The random-effect design value is `x1_i`, not 1. The implemented TMB
contribution is therefore:

```text
mu_i = X_mu[i, ] beta_mu + sum_j z_j[i] sd_j u_{j, g_j[i]}
```

where `z_j[i] = 1` for `(1 | group)` and `z_j[i] = x_i` for
`(0 + x | group)`.

## Residual-Scale Random Effects

For observation `i` in group `g[i]`, residual-scale random intercepts enter the
log residual standard deviation:

```text
y_i | mu_i, sigma_i, a_g[i] ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma + a_g[i]
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

This is residual-scale heterogeneity. It should not be confused with
`sd(id) ~ x2`, which models the standard deviation of a group-level random
effect in the location model.

Residual-scale random slopes use the same log-`sigma` predictor. For a
one-slope ordinary correlated block:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + a_0,g[i] + x_i a_1,g[i]
a_0,g = sd_sigma0 * v_0,g
a_1,g = sd_sigma1 * (rho_sigma v_0,g +
        sqrt(1 - rho_sigma^2) v_1,g)
rho_sigma = 0.999999 * tanh(eta_cor_sigma)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2 + (1 + x2 | id)),
  family = gaussian(),
  data = dat
)
```

This reports SDs in `sdpars$sigma` and the scale-slope correlation in
`corpars$sigma`.

## Random-Effect Scale Formula

For the first implemented double-hierarchical scale model, observation `i`
belongs to group `g[i]`:

```text
y_i | mu_i, sigma_i, b_g[i] ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + b_g[i]
log(sigma_i) = X_sigma[i, ] beta_sigma

b_g = sd_mu_group,g u_g
u_g ~ Normal(0, 1)
log(sd_mu_group,g) = W_group[g, ] alpha_group
sd_mu_group,g = exp(W_group[g, ] alpha_group)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x2, sd(id) ~ x_group),
  family = gaussian(),
  data = dat
)
```

The `sd(id)` formula creates a group-level design matrix `W_id`, one row per
retained `id` level. The implementation accepts this formula when `id` targets
exactly one unlabelled Gaussian `mu` random intercept; several distinct
unlabelled targets such as `sd(id) ~ x_id` and `sd(site) ~ x_site` can appear
in the same model. If a predictor on the right-hand side varies within its
target group after missing-row filtering, the model is rejected.

For two distinct group-level scale formulas:

```text
y_i | mu_i, sigma_i, b_j[i], c_k[i] ~ Normal(mu_i, sigma_i^2)
mu_i = X_mu[i, ] beta_mu + b_j[i] + c_k[i]
log(sigma_i) = X_sigma[i, ] beta_sigma

b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id

c_k = sd_mu_site,k r_k
r_k ~ Normal(0, 1)
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

This is one location model with three separate scale quantities:

```text
sigma_i          # residual SD
sd_mu_id,j       # SD of id-level random intercepts in the mean model
sd_mu_site,k     # SD of site-level random intercepts in the mean model
```

The current TMB implementation receives one stacked `X_sd_mu` matrix and one
stacked `beta_sd_mu` vector. The R layer builds this matrix as a block diagonal
combination of `W_id`, `W_site`, and any other distinct supported `sd(group)`
targets, then maps each group level to the coefficient block for its target.

For an independent random intercept and random slope in the current
implementation:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j
b_0j ~ Normal(0, sd_mu_id^2)
b_1j ~ Normal(0, sd_mu_x_id^2)
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

This is intentionally an independent random-intercept and random-slope model.
The correlated block syntax is also implemented for one numeric slope:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j
[b_0j, b_1j]' ~ MVN(0, Sigma_id)
Sigma_id =
  [sd0^2,          rho_re sd0 sd1;
   rho_re sd0 sd1, sd1^2]
```

Matching R syntax:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

or with a covariance-block label retained in the fitted object:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x2),
  family = gaussian(),
  data = dat
)
```

In the current implementation, the label `p` names the group-level covariance
block. For `(1 + x1 | p | id)` inside `mu`, it fits the same likelihood as the
unlabelled intercept-slope block while preserving the block label. For matching
labelled `mu` and `sigma` random intercepts or one-slope blocks, it estimates a
group-level covariance block and reports the implied correlations through
`corpars$mu_sigma` and `corpairs()`.

## Scale Names

Use `sigma_i` only for the residual or within-observation standard deviation.
Random-effect scales need separate names:

```text
sd_mu_id          # random-intercept SD in the mean model
sd_mu_x_id        # random-slope SD in the mean model
sigma_i           # residual SD
```

This distinction matters for double-hierarchical models. An animal-behaviour
model may have individual differences in personality and plasticity through
the mean formula, plus residual predictability through `sigma`. These are
related but not the same parameter.

Meta-analysis keeps the same naming rule. For diagonal known sampling variance:

```text
yi_i | mu_i, sigma_i, v_i ~ Normal(mu_i, v_i + sigma_i^2)
```

where `v_i` is known sampling variance from `meta_known_V(V = vi)` and
`sigma_i` is the estimated extra heterogeneity SD. This is traditionally called
`tau` in much of the meta-analysis literature, but the package API keeps
`sigma` for residual-scale consistency.

For full known sampling covariance:

```text
y | mu, sigma, V ~ MVN(mu, V + diag(sigma_i^2))
```

## Implementation Mapping

Current R-side objects:

- `X$mu` maps to `X_mu`.
- `X$sigma` maps to `X_sigma`.
- `random_effects$mu` maps to the location random-effect design.
- `model$random$mu$value` maps to the random-effect design value `z_j[i]`.
- `random_effects$sigma` maps to residual-scale random-effect conditional
  modes when the `sigma` formula contains ordinary random-effect terms.
- `model$random$sigma$value` maps the residual-scale random-effect design
  value, with `1` for intercepts and the predictor value for random slopes.
- `model$random_scale$mu$X` maps to the group-level `W_group` matrix for
  implemented `sd(group)` formulas.
- `sdpars` reports group-level standard deviations. For `sd(id) ~ x_group`,
  `sdpars$sd(id)` reports the fitted group-specific random-intercept SDs.
- `predict(fit, dpar = "sigma")` returns residual `sigma_i`.

Current TMB-side objects:

- `beta_mu` estimates `beta_mu`.
- `beta_sigma` estimates `beta_sigma`.
- `log_sd_mu` estimates `log(sd_mu_group)` for each simple random-effect term.
  If that term is targeted by `sd(id) ~ x_group`, its scalar `log_sd_mu` entry
  is fixed and replaced by `beta_sd_mu`.
- `beta_sd_mu` estimates `alpha_group` for implemented `sd(group)` formulas.
- `u_mu` is integrated by the Laplace approximation.
- `log_sd_sigma` estimates `log(sd_sigma_group)` for each implemented
  residual-scale random-effect coefficient.
- `eta_cor_sigma` estimates ordinary residual-scale intercept-slope
  correlations on the guarded tanh scale.
- `u_sigma` is integrated by the Laplace approximation and added to
  `log(sigma_i)`.

Random-effect scale objects for syntax such as `sd(id) ~ x_group` are separate
from residual-scale objects. The standardized `u_mu` values remain the latent
random effects in the location model.

## Test Obligations

For every change to this model class:

1. Write down the symbolic model.
2. Match every equation term to an R syntax component.
3. Match every R syntax component to a TMB data or parameter object.
4. Simulate from the equations.
5. Fit with `drmTMB`.
6. Check recovery and comparator agreement where another package overlaps.
