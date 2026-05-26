# Phase 18 Positive-Continuous Fixed-Effect Artifacts, Slices 1299-1308

This note records the first artifact lane for fitted positive-continuous
one-response models. The reader is an applied user asking whether `drmTMB` has
simulation evidence for positive biomass, rates, or concentrations, and a
package contributor deciding which neighbouring families remain outside the
first-wave claim.

## A - Aims

Primary aim: check fixed-effect recovery for the two fitted
positive-continuous location-scale families, `lognormal()` and
`Gamma(link = "log")`.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
Wald interval, and Wald coverage artifacts used by the Gaussian, count,
Student-t, and proportion lanes.

## D - Data-Generating Mechanism

Each simulated data set has one row level only. The mean predictor `x` and
scale predictor `z` are standardized normal variables with optional correlation
`rho_xz`.

For lognormal data:

```text
eta_mu_i = beta0 + beta1 * x_i
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
y_i ~ LogNormal(meanlog = eta_mu_i, sdlog = sigma_i)
```

For Gamma data:

```text
eta_mu_i = beta0 + beta1 * x_i
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
y_i ~ Gamma(shape = 1 / sigma_i^2, scale = mu_i * sigma_i^2)
```

The varied conditions are sample size, baseline public `sigma`, scale slope,
family, and mean-scale predictor correlation. The smoke/grid defaults keep
replicate counts low for local and Actions runtime; formal operating
characteristic claims still require a larger audited grid with Monte Carlo
standard errors.

## E - Estimands

The estimands are fixed `mu` and `sigma` formula coefficients on their modelled
link scales:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Lognormal log-location intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Lognormal log-location slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Gamma log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Gamma log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |

For lognormal fits, `mu` is on the log-response scale and `fitted()` returns
the arithmetic response mean. For Gamma fits, `mu` is the response mean and
public `sigma` is the coefficient of variation.

## M - Methods

The fitted methods are:

```r
drmTMB(
  bf(y ~ x, sigma ~ z),
  family = lognormal(),
  data = dat
)

drmTMB(
  bf(y ~ x, sigma ~ z),
  family = Gamma(link = "log"),
  data = dat
)
```

The first lane is fixed-effect only. Random effects, known sampling covariance,
phylogenetic/spatial/animal/`relmat()` terms, bivariate positive-continuous
models, and Tweedie-like semicontinuous models remain separate future gates.

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time, Wald
interval status, and Wald coverage for each coefficient. Aggregate bias MCSE is
`sd(error) / sqrt(n_replicate)`. Coverage MCSE is reported through the existing
first-wave interval summary helpers when larger grids are run.

## Implemented Path

Slices 1299-1308 add:

- `phase18_dgp_positive_continuous_fe()`;
- `phase18_summarise_positive_continuous_fe_fit()`;
- `phase18_run_positive_continuous_fe_smoke()`;
- `phase18_summarise_positive_continuous_fe_smoke()`;
- `phase18_write_positive_continuous_fe_grid_outputs()`;
- a focused test file;
- first-wave summary runner inclusion; and
- a manual `positive_continuous_fixed_effect` Actions task.

## Boundaries

This is not a broader positive-response expansion. Tweedie, generalized Gamma,
positive-response random effects, positive-response known covariance,
structured positive-response effects, and mixed-response positive-continuous
models remain unsupported or planned until their own likelihood, diagnostic,
interval, and simulation gates land.
