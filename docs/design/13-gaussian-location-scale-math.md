# Gaussian Location-Scale Math

This note is the source-of-truth mathematical specification for the first
`drmTMB` model class. Every implementation and tutorial should be checkable
against these equations.

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

## Scale Names

Use `sigma_i` only for the residual or within-observation standard deviation.
Random-effect scales need separate names:

```text
sd_mu_id          # random-intercept SD in the mean model
sd_mu_x_id        # future random-slope SD in the mean model
sigma_i           # residual SD
```

This distinction matters for double-hierarchical models. An animal-behaviour
model may have individual differences in personality and plasticity through
the mean formula, plus residual predictability through `sigma`. These are
related but not the same parameter.

Meta-analysis keeps the same naming rule:

```text
yi_i | mu_i, sigma_i, v_i ~ Normal(mu_i, v_i + sigma_i^2)
```

where `v_i` is known sampling variance from `meta_known_V(V = vi)` and
`sigma_i` is the estimated extra heterogeneity SD. This is traditionally called
`tau` in much of the meta-analysis literature, but the package API keeps
`sigma` for residual-scale consistency.

## Implementation Mapping

Current R-side objects:

- `X$mu` maps to `X_mu`.
- `X$sigma` maps to `X_sigma`.
- `random_effects$mu` maps to the location random-intercept design.
- `sdpars` reports group-level standard deviations.
- `predict(fit, dpar = "sigma")` returns residual `sigma_i`.

Current TMB-side objects:

- `beta_mu` estimates `beta_mu`.
- `beta_sigma` estimates `beta_sigma`.
- `theta_mu` estimates `log(sd_mu_group)`.
- `u_mu` is integrated by the Laplace approximation.

## Test Obligations

For every change to this model class:

1. Write down the symbolic model.
2. Match every equation term to an R syntax component.
3. Match every R syntax component to a TMB data or parameter object.
4. Simulate from the equations.
5. Fit with `drmTMB`.
6. Check recovery and comparator agreement where another package overlaps.
