# Phase 18 Count Structured q1 Artifacts, Slices 1721-1738

This note records the opt-in artifact lane, manual Actions task, first manual
smoke audit, warning-diagnostic hardening, and post-merge diagnostic smoke
audit, and boundary-rate gate for ordinary Poisson and NB2 count models with
one q=1 structured `mu` intercept. The reader is an R package contributor
deciding whether the fitted source gate for `spatial()`, `animal()`, and
`relmat()` count routes has enough simulation infrastructure to audit smoke
runs.

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
fit-level Hessian and random-effect-SD boundary status, Wald interval status
and coverage for rows with standard errors, direct profile-target status for
the structured SD, optional profile interval status and coverage, and
interval-failure diagnostics. These are smoke artifacts, not formal recovery
or coverage claims.

## Implemented Path

Slices 1721-1728 add:

- `phase18_dgp_count_structured_q1()`;
- `phase18_summarise_count_structured_q1_fit()`;
- `phase18_run_count_structured_q1_smoke()`;
- `phase18_summarise_count_structured_q1_smoke()`;
- `phase18_write_count_structured_q1_grid_outputs()`;
- a manual `count_structured_q1` Actions task that is excluded from
  `task = "all"`;
- replicate-table fit diagnostics for Hessian status, random-effect-SD
  boundary status, and their warning/error rollup; and
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
| 1733-1734 | Done locally as warning diagnostic hardening | The exact seed and cell for `count_structured_q1_020` replicate 2 replayed locally with the same near-zero spatial SD estimate and fixed-effect estimates, but the local Hessian was positive definite while the Ubuntu Actions artifact had `pdHess = FALSE` and warning `NaNs produced`. The replicate table now records `fit_diagnostic_status`, `hessian_status`, and `sd_boundary_status`; the new focused test asserts that this seed is a random-effect-SD boundary case even when the platform-specific Hessian status changes. |
| 1735-1736 | Done as post-diagnostic Actions smoke audit | GitHub Actions run `26626333581` completed after the warning-diagnostic columns merged to `main`. The selected `count_structured_q1` job succeeded in 3m33s, and the downloaded artifact had the expected 24 cells, 48 `ok` manifest rows, 192 converged parameter rows, and one warning-ledger row for `count_structured_q1_020` replicate 2. The new diagnostic columns were present. `fit_diagnostic_status` and `sd_boundary_status` each had 169 `ok` and 23 `warning` parameter rows, which collapse to five boundary-sensitive replicate fits; `hessian_status` had 187 `ok` and 5 `warning` parameter rows, all from `count_structured_q1_020` replicate 2. |
| 1737-1738 | Done locally as pre-grid boundary gate | The post-diagnostic smoke is promoted to a decision rule, not to recovery evidence. Larger `count_structured_q1` pilots must collapse replicate-table rows to one row per fitted replicate, report fit-diagnostic, SD-boundary, Hessian, and warning-ledger rates overall and by condition, and stop before formal recovery claims if the thresholds below trigger. |

## Next Implementation Gate

The manual workflow route is operational, and the first warning has been traced
to boundary-sensitive fits rather than to a parser or DGP failure. The
post-merge smoke shows that SD-boundary warnings are broader than the single
`NaNs produced` warning ledger: five replicate fits hit the random-effect-SD
boundary, while only one also had a non-positive Hessian. Before larger
recovery or coverage grids, Curie and Fisher should set an explicit review
threshold for `sd_boundary_status = "warning"` and `hessian_status != "ok"`.
If those rates concentrate in low-count or high-structured-SD cells, the next
design decision should adjust the pilot condition table or split boundary
cases into a diagnostic stress lane rather than promoting them to recovery
evidence.

## Pre-Grid Boundary Gate

Slices 1737-1738 define the admission rule for the next `count_structured_q1`
pilot. The counting unit is a fitted replicate, not a parameter row. Any audit
must collapse the replicate table by `cell_id` and `replicate` before computing
rates, because fixed-effect and structured-SD rows repeat the same fit-level
diagnostics.

The next pilot may remain a diagnostic pilot if it widens the condition table
or increases replicates. It must not be described as formal recovery or
coverage evidence until the audit reports these quantities:

- the number and rate of fitted replicates with
  `fit_diagnostic_status != "ok"`;
- the number and rate with `sd_boundary_status != "ok"`;
- the number and rate with `hessian_status != "ok"`;
- the number of warning-ledger rows and their warning messages; and
- the same counts by `family`, `structured_type`, `n_level`,
  `sd_structured`, `mean_count`, and `sigma_baseline` where those columns are
  present.

The pilot must stop at diagnostic evidence, and the next design decision must
split unstable cells into a stress lane or revise the condition table, if any
of these triggers occur:

- more than 5% of fitted replicates have `hessian_status != "ok"`;
- any condition cell has at least two Hessian-warning fits;
- 15% or more of fitted replicates have `sd_boundary_status != "ok"`;
- any condition cell with at least five attempted replicates has 40% or more
  SD-boundary warnings;
- any condition cell with fewer than five attempted replicates has two or more
  SD-boundary warnings; or
- warning-ledger rows contain optimizer, `NaNs produced`, or non-finite
  messages that are not explained by an SD-boundary diagnostic.

If none of those triggers occur, the next slice may propose a larger recovery
pilot, but it still needs a separate design note or addendum naming the
condition table, replicate count, MCSE target, interval policy, and runtime
budget before a formal grid is dispatched.
