# Phase 18 Positive-Continuous Mu Random-Intercept Artifacts, Slices 1369-1378

This note records the artifact lane for fitted positive-continuous ordinary
`mu` random intercepts. The reader is an applied user with repeated positive
biomass, rate, or concentration observations, and a package contributor
deciding which neighbouring positive-continuous mixed models still belong in
the failure ledger.

## Implemented Claim

Slices 1369-1378 add a Phase 18 artifact path for ordinary unlabelled
`mu` random intercepts in `lognormal()` and `Gamma(link = "log")` models:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z),
  family = lognormal(),
  data = dat
)

drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z),
  family = Gamma(link = "log"),
  data = dat
)
```

For lognormal fits, the random intercept enters the log-response location. For
Gamma fits, it enters the log-mean predictor. In both families the public
scale uses `log(sigma_i) = eta_sigma_i`, and `sigma` remains fixed-effect in
this lane.

## A - Aims

Primary aim: check fixed-effect and public random-intercept SD recovery for the
two fitted positive-continuous ordinary `mu` random-intercept families.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald, and direct-SD profile artifacts used by the neighbouring
bounded-response random-intercept lane.

## D - Data-Generating Mechanism

Each simulated data set has repeated observations within `id`. The DGP draws
one Gaussian intercept per group and centres the realized intercept vector so
the fixed intercept stays interpretable in small smoke cells:

```text
b_id ~ Normal(0, sd_id)
eta_mu_i = beta0 + beta1 * x_i + b_id[i]
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
```

For lognormal data:

```text
y_i ~ LogNormal(meanlog = eta_mu_i, sdlog = sigma_i)
E[y_i] = exp(eta_mu_i + 0.5 * sigma_i^2)
```

For Gamma data:

```text
mu_i = exp(eta_mu_i)
y_i ~ Gamma(shape = 1 / sigma_i^2, scale = mu_i * sigma_i^2)
E[y_i] = mu_i
```

The varied conditions are family, number of groups, repeats per group,
baseline public `sigma`, scale slope, true random-intercept SD, and mean-scale
predictor correlation.

## E - Estimands

The estimands are fixed `mu` and `sigma` formula coefficients on their modelled
link scales plus the public random-intercept SD:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Lognormal log-location intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Lognormal log-location slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Gamma log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Gamma log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| `mu` random-intercept SD | `sd_id` | `fit$sdpars$mu["(1 | id)"]` |

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time,
fixed-effect Wald interval status and coverage, and direct-SD profile interval
status and coverage. Larger formal grids still need enough replicates to make
Monte Carlo standard errors meaningful.

## Implemented Path

Slices 1369-1378 add:

- `phase18_dgp_positive_continuous_mu_ri()`;
- `phase18_summarise_positive_continuous_mu_ri_fit()`;
- `phase18_run_positive_continuous_mu_ri_smoke()`;
- `phase18_summarise_positive_continuous_mu_ri_smoke()`;
- `phase18_write_positive_continuous_mu_ri_grid_outputs()`;
- focused DGP, smoke, grid-writer, and malformed-input tests;
- first-wave summary runner inclusion; and
- a manual `positive_continuous_mu_random_intercept` Actions task.

## Boundaries

This slice deliberately keeps the following outside the admitted surface:

- positive-continuous random slopes;
- labelled covariance blocks;
- `sigma` random effects;
- Tweedie or generalized Gamma likelihoods;
- structured positive-continuous effects;
- known covariance for positive-continuous responses; and
- bivariate or mixed positive-continuous models.

Those neighbours remain failure-ledger or future-design surfaces until they
have separate likelihood, syntax, diagnostic, interval, and simulation gates.
