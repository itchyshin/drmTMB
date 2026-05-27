# Phase 18 Bounded-Response Mu Random-Intercept Artifacts, Slices 1359-1368

This note records the first artifact lane for fitted bounded-response ordinary
`mu` random intercepts. The reader is an applied user asking whether repeated
proportion observations are ready for small simulation grids, and a package
contributor deciding which neighbouring bounded-response mixed models still
belong in the failure ledger.

## Implemented Claim

Slices 1359-1368 add a Phase 18 artifact path for ordinary unlabelled
`mu` random intercepts in `beta()` and `beta_binomial()` models:

```r
drmTMB(
  bf(prop ~ x + (1 | id), sigma ~ z),
  family = beta(),
  data = dat
)

drmTMB(
  bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z),
  family = beta_binomial(),
  data = dat
)
```

The fitted mean uses `logit(mu_i) = eta_mu_i`, the public scale uses
`log(sigma_i) = eta_sigma_i`, and the group effect is a Gaussian intercept on
the logit-mean scale. For beta and beta-binomial likelihoods the internal beta
precision remains `phi_i = 1 / sigma_i^2`.

## A - Aims

Primary aim: check fixed-effect and public random-intercept SD recovery for the
two fitted bounded-response ordinary `mu` random-intercept families.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald, and direct-SD profile artifacts used by the first-wave count
random-effect lane.

## D - Data-Generating Mechanism

Each simulated data set has repeated observations within `id`. The DGP draws
one Gaussian intercept per group and centres the realized intercept vector so
the fixed intercept stays interpretable in small smoke cells:

```text
b_id ~ Normal(0, sd_id)
eta_mu_i = beta0 + beta1 * x_i + b_id[i]
mu_i = logit^-1(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
```

For strict continuous proportions:

```text
prop_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

For denominator-aware observations:

```text
p_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
success_i ~ Binomial(trials_i, p_i)
failure_i = trials_i - success_i
```

The varied conditions are family, number of groups, repeats per group,
baseline public `sigma`, scale slope, true random-intercept SD, trial range for
beta-binomial data, and mean-scale predictor correlation.

## E - Estimands

The estimands are fixed `mu` and `sigma` formula coefficients on their modelled
link scales plus the public random-intercept SD:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Logit-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Logit-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Logit-mean random-intercept SD | `sd_id` | `fit$sdpars$mu["(1 | id)"]` |

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time,
fixed-effect Wald interval status and coverage, and direct-SD profile interval
status and coverage. Larger formal grids still need enough replicates to make
Monte Carlo standard errors meaningful.

## Implemented Path

Slices 1359-1368 add:

- `phase18_dgp_bounded_response_mu_ri()`;
- `phase18_summarise_bounded_response_mu_ri_fit()`;
- `phase18_run_bounded_response_mu_ri_smoke()`;
- `phase18_summarise_bounded_response_mu_ri_smoke()`;
- `phase18_write_bounded_response_mu_ri_grid_outputs()`;
- focused DGP, smoke, grid-writer, and malformed-input tests;
- first-wave summary runner inclusion; and
- a manual `bounded_response_mu_random_intercept` Actions task.

## Boundaries

This slice deliberately keeps the following outside the admitted surface:

- bounded-response random slopes;
- labelled covariance blocks;
- `sigma` random effects;
- exact 0/1 boundary mass in `beta()`;
- zero-one beta random effects in `mu`, `sigma`, `zoi`, or `coi`;
- structured bounded-response effects;
- known covariance for bounded responses; and
- bivariate or mixed-response bounded models.

Those neighbours remain failure-ledger or future-design surfaces until they
have separate likelihood, syntax, diagnostic, interval, and simulation gates.
