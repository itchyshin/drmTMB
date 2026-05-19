# Phase 18 Gaussian Location-Scale ADEMP Sheet

This sheet is the first one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). It does not
add code; it records what the existing Gaussian location-scale Phase 18 helpers
are allowed to estimate before larger grids run.

## A - Aims

Primary aim: estimate bias, RMSE, Wald interval coverage, convergence rate, and
runtime for fixed-effect Gaussian location-scale models with `mu ~ x` and
`sigma ~ z`.

Secondary aims: measure how sample size, residual-scale slope size, and
correlation between `x` and `z` affect recovery of the public scale parameter
`sigma`; keep this surface separate from random-effect, phylogenetic, spatial,
and shape/skewness models.

## D - Data-Generating Mechanism

For observations `i = 1, ..., n`, generate standardized predictors with
correlation `rho_xz`:

```text
x_i ~ Normal(0, 1)
z_i = rho_xz * x_i + sqrt(1 - rho_xz^2) * epsilon_i,
epsilon_i ~ Normal(0, 1)
mu_i = beta0 + beta1 * x_i
log(sigma_i) = gamma0 + gamma1 * z_i
y_i ~ Normal(mu_i, sigma_i^2)
```

The current helper `phase18_dgp_gaussian_ls()` already implements this DGP.
The current condition helper uses `n = {120, 360}`, `gamma1 = {0, 0.35}`, and
`rho_xz = {0, 0.6}`. A formal first grid can use the same eight cells before
adding larger `n` or stronger scale slopes.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n` | 120, 360 | Small ecological sample versus a moderate sample for fixed-effect scale recovery. |
| `gamma1` | 0, 0.35 | Null scale effect for false-positive checks and a moderate log-scale effect. |
| `rho_xz` | 0, 0.6 | Orthogonal versus confounded location and scale predictors. |
| `beta0`, `beta1` | 0.25, 0.60 | Existing helper defaults; keep the mean effect nonzero but not extreme. |
| `gamma0` | -0.30 | Existing helper default; baseline `sigma = exp(-0.30)`. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for a formal coverage table, giving MCSE about 1 percentage point for 95%
coverage before any extra uncertainty from failed fits.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Location intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Location slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Scale ratio for one-unit `z` increase | `exp(gamma1)` | `exp(coef(fit, dpar = "sigma")["z"])` |
| Fitted row scale | generated `sigma_i` or grid-specific summaries of it | `sigma(fit, newdata = ...)` only when the report defines the grid rows |

The existing summariser stores coefficient truths and estimates on the link
scale. A response-scale `sigma` grid should be added only when the report
stores the corresponding truth rows.

## M - Methods

Fit the intended model:

```r
drmTMB(
  bf(y ~ x, sigma ~ z),
  data = dat,
  family = gaussian()
)
```

The first formal grid should not add an external comparator. A constant-scale
nested `drmTMB` model, `bf(y ~ x, sigma ~ 1)`, can be added later for power and
false-positive questions about `gamma1`, but it should be labelled as a nested
drmTMB comparison rather than a competing method.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | `mean(conf.low <= truth & truth <= conf.high)` for rows whose interval status is `wald` |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Boundary and diagnostic ledger | `check_drm()` rows where available, reported beside aggregate summaries |

Every mean, proportion, coverage estimate, and convergence rate should carry an
MCSE. Failed or warning-bearing fits remain in the manifest and warning/error
ledger; they should not be dropped from denominators without a labelled
sensitivity analysis.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | The Gaussian location-scale hierarchy and varied factors are explicit. |
| 3. Estimands | Link-scale coefficients and optional response-scale `sigma` rows are named. |
| 4. Methods | The intended `drmTMB` model is stated; comparator scope is limited. |
| 5. Performance measures | Bias, RMSE, coverage, convergence, warning rate, runtime, and diagnostics are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing helpers live under `inst/sim/`; this sheet links their intended use. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The location-scale vignette supplies the reader-facing motivation; a final report should cite it. |
| 10. Complete results | Manifests and warning/error ledgers keep failed fits visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about 1 percentage point coverage MCSE. |
