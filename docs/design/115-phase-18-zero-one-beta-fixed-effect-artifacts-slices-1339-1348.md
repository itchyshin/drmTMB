# Phase 18 Zero-One Beta Fixed-Effect Artifacts, Slices 1339-1348

This note records the first Phase 18 artifact lane for fitted
`zero_one_beta()` models. The reader is an applied user with continuous
proportions on `[0, 1]` where exact 0 and 1 values are structural outcomes,
and a package contributor deciding whether `zoi` and `coi` are ready for
simulation artifacts before any random-effect route is opened.

## A - Aims

Primary aim: check fixed-effect recovery for the implemented zero-one beta
route with interior `mu` and `sigma`, exact-boundary probability `zoi`, and
conditional-one probability `coi`.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
Wald interval, and Wald coverage artifacts used by the neighbouring
fixed-effect proportion, positive-continuous, and ordinal lanes.

## D - Data-Generating Mechanism

Each simulated data set has one row level only. The mean predictor `x`, scale
predictor `z`, exact-boundary predictor `w`, and conditional-one predictor `v`
are standardized normal variables. The artifact condition table varies sample
size, baseline interior `sigma`, scale slope, baseline `zoi`, and predictor
correlation `rho_xz`.

```text
logit(mu_i) = beta0 + beta1 * x_i
log(sigma_i) = gamma0 + gamma1 * z_i
logit(zoi_i) = zeta0 + zeta1 * w_i
logit(coi_i) = kappa0 + kappa1 * v_i
phi_i = 1 / sigma_i^2
Pr(y_i = 0) = zoi_i * (1 - coi_i)
Pr(y_i = 1) = zoi_i * coi_i
Pr(0 < y_i < 1) = 1 - zoi_i
y_i | 0 < y_i < 1 ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

The unconditional response mean is:

```text
E[y_i] = (1 - zoi_i) * mu_i + zoi_i * coi_i
```

The smoke and grid defaults keep replicate counts low for local and Actions
runtime. Formal operating-characteristic claims still require larger audited
grids with Monte Carlo standard errors.

## E - Estimands

The estimands are fixed formula coefficients on their modelled link scales:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Interior logit-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Interior logit-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Interior log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Interior log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Boundary-probability logit intercept | `zeta0` | `coef(fit, dpar = "zoi")["(Intercept)"]` |
| Boundary-probability logit slope | `zeta1` | `coef(fit, dpar = "zoi")["w"]` |
| Conditional-one logit intercept | `kappa0` | `coef(fit, dpar = "coi")["(Intercept)"]` |
| Conditional-one logit slope | `kappa1` | `coef(fit, dpar = "coi")["v"]` |

Here `mu` and `sigma` describe the interior beta component. `zoi` is the
probability of an exact 0 or exact 1 outcome, and `coi` is the probability
that an exact-boundary outcome is 1.

## M - Methods

The fitted method is:

```r
drmTMB(
  bf(prop ~ x, sigma ~ z, zoi ~ w, coi ~ v),
  family = zero_one_beta(),
  data = dat
)
```

The lane is fixed-effect only. Random effects in `mu`, `sigma`, `zoi`, or
`coi`, known sampling covariance, structured bounded responses, denominators,
bivariate bounded responses, and mixed bounded-response models remain separate
future gates.

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time,
Wald interval status, and Wald coverage for each coefficient. Aggregate bias
MCSE is `sd(error) / sqrt(n_replicate)`. Coverage MCSE is reported through the
existing interval summary helpers when larger grids are run.

## Implemented Path

Slices 1339-1348 add:

- `phase18_dgp_zero_one_beta_fe()`;
- `phase18_summarise_zero_one_beta_fe_fit()`;
- `phase18_run_zero_one_beta_fe_smoke()`;
- `phase18_summarise_zero_one_beta_fe_smoke()`;
- `phase18_write_zero_one_beta_fe_grid_outputs()`;
- a focused test file;
- first-wave summary runner inclusion; and
- a manual `zero_one_beta_fixed_effect` Actions task.

## Boundaries

This is not a broader bounded-response expansion. The artifact lane does not
add random effects, covariance blocks, denominator syntax, known covariance,
structured effects, or bivariate bounded responses. Those routes need their
own likelihood, diagnostic, interval, and simulation gates before users should
see them as runnable Phase 18 surfaces.
