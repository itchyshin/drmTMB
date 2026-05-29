# Phase 18 Student-t Mu Random-Intercept Artifacts, Slices 1379-1388

This note records the artifact lane for fitted Student-t ordinary `mu` random
intercepts. The reader is an applied user with repeated continuous
measurements that may have heavy-tailed residuals, and a package contributor
deciding which Student-t mixed-model neighbours remain outside the fitted
surface.

## Implemented Claim

Slices 1379-1388 add a Phase 18 artifact path for ordinary unlabelled `mu`
random intercepts in `student()` models:

```r
drmTMB(
  bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
  family = student(),
  data = dat
)
```

The random intercept enters the response location `mu`. The residual scale is
modelled with `log(sigma_i) = eta_sigma_i`, and the Student-t shape remains a
fixed-effect formula with `nu = 2 + exp(eta_nu)`.

## A - Aims

Primary aim: check fixed-effect `mu`, fixed-effect `sigma`, fixed-effect `nu`,
and public random-intercept SD recovery for the fitted Student-t ordinary
`mu` random-intercept route.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
fixed-effect Wald, direct-SD profile, and coverage artifacts used by the
bounded-response and positive-continuous ordinary `mu` random-intercept lanes.

## D - Data-Generating Mechanism

Each simulated data set has repeated observations within `id`. The DGP draws
one Gaussian intercept per group and centres the realized intercept vector so
the fixed intercept stays interpretable in small smoke cells:

```text
b_id ~ Normal(0, sd_id)
mu_i = beta0 + beta1 * x_i + b_id[i]
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
eta_nu_i = delta0
nu_i = 2 + exp(eta_nu_i)
y_i = mu_i + sigma_i * t_i
t_i ~ Student-t(df = nu_i)
```

The varied conditions are number of groups, repeats per group, baseline
public `sigma`, scale slope, baseline Student-t tail thickness on the fitted
`eta_nu` scale, true random-intercept SD, and mean-scale predictor
correlation.

## E - Estimands

The estimands are fixed `mu`, `sigma`, and `nu` formula coefficients on their
modelled link scales plus the public random-intercept SD:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Location intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Location slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Shape intercept | `delta0` | `coef(fit, dpar = "nu")["(Intercept)"]` |
| `mu` random-intercept SD | `sd_id` | `fit$sdpars$mu["(1 | id)"]` |

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time,
fixed-effect Wald interval status and coverage, and direct-SD profile
interval status and coverage. Larger formal grids still need enough
replicates to make Monte Carlo standard errors meaningful, especially for the
tail-thickness parameter.

## Implemented Path

Slices 1379-1388 add:

- `phase18_dgp_student_mu_ri()`;
- `phase18_summarise_student_mu_ri_fit()`;
- `phase18_run_student_mu_ri_smoke()`;
- `phase18_summarise_student_mu_ri_smoke()`;
- `phase18_write_student_mu_ri_grid_outputs()`;
- focused DGP, smoke, grid-writer, and malformed-input tests;
- first-wave summary runner inclusion; and
- a manual `student_mu_random_intercept` Actions task.

## Boundaries

This slice deliberately keeps the following outside the admitted surface:

- correlated Student-t random slopes;
- labelled covariance blocks;
- `sigma` random effects;
- `nu` random effects;
- skew-normal and skew-t likelihoods;
- structured Student-t effects;
- known covariance for Student-t responses; and
- bivariate or mixed Student-t models.

Those neighbours remain failure-ledger or future-design surfaces until they
have separate likelihood, syntax, diagnostic, interval, and simulation gates.
