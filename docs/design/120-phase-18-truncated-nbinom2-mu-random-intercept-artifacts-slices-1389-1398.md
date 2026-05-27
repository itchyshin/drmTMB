# Phase 18 Truncated NB2 Mu Random-Intercept Artifacts, Slices 1389-1398

This note records the artifact lane for fitted zero-truncated NB2 ordinary
`mu` random intercepts. The reader is an applied user with positive count data
where zeros cannot be observed, and a package contributor deciding which
neighbouring count mixed models remain outside the fitted surface.

## Implemented Claim

Slices 1389-1398 add a Phase 18 artifact path for ordinary unlabelled `mu`
random intercepts in `truncated_nbinom2()` models:

```r
drmTMB(
  bf(count ~ x + (1 | id), sigma ~ z),
  family = truncated_nbinom2(),
  data = dat
)
```

The random intercept enters the untruncated NB2 log-mean predictor. The
observed response is then conditioned on being positive. The public fitted
mean remains the conditional positive-count mean, while `mu` and `sigma`
describe the untruncated NB2 component.

## A - Aims

Primary aim: check fixed-effect `mu`, fixed-effect `sigma`, and public
random-intercept SD recovery for the fitted zero-truncated NB2 ordinary
`mu` random-intercept route.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald, direct-SD profile, and coverage artifacts used by the
other ordinary `mu` random-intercept lanes.

## D - Data-Generating Mechanism

Each simulated data set has repeated observations within `id`. The DGP draws
one Gaussian intercept per group and centres the realized intercept vector so
the fixed intercept stays interpretable in small smoke cells:

```text
b_id ~ Normal(0, sd_id)
eta_mu_i = beta0 + beta1 * x_i + b_id[i]
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
Y_i^* ~ NB2(mu_i, sigma_i)
Y_i = Y_i^* | Y_i^* > 0
```

The NB2 component uses `Var(Y_i^*) = mu_i + sigma_i^2 * mu_i^2`. The
conditional positive-count mean is:

```text
E[Y_i | Y_i > 0] = mu_i / (1 - Pr(Y_i^* = 0))
```

The varied conditions are number of groups, repeats per group, baseline
overdispersion, overdispersion slope, and true random-intercept SD.

## E - Estimands

The estimands are fixed `mu` and `sigma` formula coefficients on their
modelled link scales plus the public random-intercept SD:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-overdispersion intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-overdispersion slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| `mu` random-intercept SD | `sd_id` | `fit$sdpars$mu["(1 | id)"]` |

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time,
fixed-effect Wald interval status and coverage, and direct-SD profile
interval status and coverage. Larger formal grids still need enough
replicates to make Monte Carlo standard errors meaningful, especially in
cells with low means and strong truncation.

## Implemented Path

Slices 1389-1398 add:

- `phase18_dgp_truncated_nbinom2_mu_ri()`;
- `phase18_summarise_truncated_nbinom2_mu_ri_fit()`;
- `phase18_run_truncated_nbinom2_mu_ri_smoke()`;
- `phase18_summarise_truncated_nbinom2_mu_ri_smoke()`;
- `phase18_write_truncated_nbinom2_mu_ri_grid_outputs()`;
- focused DGP, smoke, grid-writer, and malformed-input tests;
- first-wave summary runner inclusion; and
- a manual `truncated_nbinom2_mu_random_intercept` Actions task.

## Boundaries

This slice deliberately keeps the following outside the admitted surface:

- zero-truncated NB2 random slopes;
- labelled covariance blocks;
- `sigma` random effects;
- hurdle random effects;
- zero-inflated zero-truncated models;
- structured zero-truncated count effects; and
- bivariate or mixed zero-truncated count models.

Those neighbours remain failure-ledger or future-design surfaces until they
have separate likelihood, syntax, diagnostic, interval, and simulation gates.
