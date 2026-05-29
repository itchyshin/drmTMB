# Phase 18 Count Structured q1 Artifacts, Slices 1721-1728

This note records the opt-in artifact lane for ordinary Poisson and NB2 count
models with one q=1 structured `mu` intercept. The reader is an R package
contributor deciding whether the fitted source gate for `spatial()`,
`animal()`, and `relmat()` count routes has enough simulation infrastructure to
audit smoke runs.

## Implemented Claim

Slices 1721-1728 add a repeatable Phase 18 artifact path for ordinary
non-zero-inflated count models with one structured log-mean intercept:

```r
drmTMB(
  bf(count ~ x + spatial(1 | site, coords = coords), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The same artifact lane can fit `poisson(link = "log")` or `nbinom2()`, and it
can swap the structured term among `spatial(1 | site, coords = coords)`,
`animal(1 | id, Ainv = Q)`, and `relmat(1 | id, Q = Q)`. The structured effect
enters the location `mu`, which is the log mean for these count models. NB2
keeps overdispersion as a fixed-effect `sigma` formula.

## A - Aims

Primary aim: stage smoke artifacts for fixed `mu` coefficients, fixed NB2
`sigma` coefficients when present, and the public structured `mu` SD for the
new non-phylogenetic count structured q=1 routes.

Secondary aim: keep profile-target status, `check_drm()` diagnostic status,
manifest rows, failure-ledger rows, fixed-effect Wald intervals, and optional
direct-SD profile intervals in the same table family used by the existing
Poisson and NB2 phylogenetic q=1 lanes.

## D - Data-Generating Mechanism

Each simulated data set has repeated observations within `site` or `id`. The
structured latent effect is Gaussian with known covariance:

```text
b_g ~ Normal(0, sd_structured^2 K)
eta_mu_i = beta0 + beta1 * x_i + b_g[i]
mu_i = exp(eta_mu_i)
eta_sigma_i = gamma0 + gamma1 * z_i
sigma_i = exp(eta_sigma_i)
count_i ~ Poisson(mu_i) or NB2(mu_i, sigma_i)
```

For coordinate-spatial cells, `K` comes from the same coordinate precision
helper used by fitted `spatial()` models. For `animal()` and `relmat()` cells,
`K` is an AR(1)-like dense relatedness matrix and `Q = solve(K)` is passed to
the fitted model.

## E - Estimands

The artifact tables record link-scale fixed effects and the public structured
SD:

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Log-mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| NB2 log-`sigma` intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| NB2 log-`sigma` slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Structured `mu` SD | `sd_structured` | `fit$sdpars$mu["<marker>(1 | <group>)"]` |

## P - Performance Measures

The smoke summaries record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time,
Wald interval status and coverage for rows with standard errors, direct
profile-target status for the structured SD, optional profile interval status
and coverage, and interval-failure diagnostics. These are smoke artifacts, not
formal recovery or coverage claims.

## Implemented Path

Slices 1721-1728 add:

- `phase18_dgp_count_structured_q1()`;
- `phase18_summarise_count_structured_q1_fit()`;
- `phase18_run_count_structured_q1_smoke()`;
- `phase18_summarise_count_structured_q1_smoke()`;
- `phase18_write_count_structured_q1_grid_outputs()`;
- a manual `count_structured_q1` Actions task that is excluded from
  `task = "all"`; and
- focused DGP, smoke-runner, grid-writer, and malformed-input tests.

## Boundaries

This slice deliberately keeps the following outside the admitted artifact
surface:

- zero-inflated or hurdle structured count effects;
- structured count slopes;
- labelled q=2 or q=4 count covariance blocks;
- simultaneous structured count types;
- structured NB2 `sigma`;
- formal recovery or coverage promotion; and
- inclusion in the default `task = "all"` Actions matrix.

Those neighbours remain future slices until they have separate likelihood,
syntax, diagnostic, interval, and simulation gates.
