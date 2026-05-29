# Phase 18 Count Structured q1 Artifacts, Slices 1721-1732

This note records the opt-in artifact lane, manual Actions task, and first
manual smoke audit for ordinary Poisson and NB2 count models with one q=1
structured `mu` intercept. The reader is an R package contributor deciding
whether the fitted source gate for `spatial()`, `animal()`, and `relmat()`
count routes has enough simulation infrastructure to audit smoke runs.

## Implemented Claim

Slices 1721-1732 add a repeatable Phase 18 artifact path for ordinary
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

## Slice Status

| Slice | Status | Evidence |
| --- | --- | --- |
| 1721-1728 | Done locally as smoke artifacts | `inst/sim/dgp/sim_dgp_count_structured_q1.R`, `inst/sim/fit/sim_summarise_count_structured_q1.R`, `inst/sim/run/sim_run_count_structured_q1_smoke.R`, `inst/sim/run/sim_summary_count_structured_q1_smoke.R`, and `inst/sim/run/sim_write_count_structured_q1_grid.R` add DGP, summariser, smoke, summary, and grid-writer artifacts for ordinary Poisson/NB2 q=1 `spatial()`, `animal()`, and `relmat()` `mu` intercepts. |
| 1729-1730 | Done locally as manual Actions task | `.github/workflows/phase18-simulation-grid.yaml` and `inst/sim/run/sim_run_actions_cell.R` expose `task=count_structured_q1`, keep it excluded from `task = "all"`, and add dry-run, dependency, workflow exposure, and workflow-exclusion tests. |
| 1731-1732 | Done as manual Actions smoke audit | GitHub Actions run `26622840562` completed `task=count_structured_q1` with `n_reps=2`, `cores=2`, and `backend=multicore`; the downloaded artifact had 24 cells, 48 `ok` manifest rows, 192 converged parameter rows, 187 positive-Hessian parameter rows, 48 ready profile-target rows, 144 ok Wald interval rows, and one warning-level ledger row for `count_structured_q1_020` replicate 2. |

## Next Implementation Gate

The manual workflow route is operational, but the first audit is not a clean
statistical validation run. Before larger recovery or coverage grids, Curie and
Fisher should inspect the warning and non-positive Hessian in NB2 spatial cell
`count_structured_q1_020`, replicate 2, and decide whether that is ordinary
small-replicate smoke noise or a condition that needs a targeted diagnostic
cell.
