# Phase 18 Student-T Shape ADEMP Sheet

This sheet is the seventh one-page design unit under the Slice 292
comprehensive blueprint. It follows the ADEMP structure of Morris, White, and
Crowther (2019) and the transparent-reporting checklist of Williams et al.
(2024). It records the admitted fixed-effect Student-t `nu` lane before larger
shape-parameter Phase 18 grids are added.

## A - Aims

Primary aim: estimate bias, RMSE, Wald interval coverage, convergence rate,
and runtime for fixed-effect Student-t models with `mu ~ x`, `sigma ~ z`, and
`nu ~ w`.

Secondary aims: measure how sample size, tail heaviness, predictor-dependent
shape, residual-scale variation, and mean-shape predictor overlap affect
recovery of location, scale, and shape coefficients; keep skew-normal,
skew-t, second-shape `tau`, shape random effects, latent-effect skewness such
as `skew(id) ~ x`, zero-inflated shape surfaces, and mixed-response shape
models outside this grid until their likelihood, interval, and recovery-test
gates close.

## D - Data-Generating Mechanism

For observations `i = 1, ..., n`, generate standardized predictors for the
mean, public scale, and degrees-of-freedom shape parameter. The mean-shape
predictors may be correlated:

```text
x_i ~ Normal(0, 1)
w_i = rho_xw * x_i + sqrt(1 - rho_xw^2) * epsilon_i,
epsilon_i ~ Normal(0, 1)
z_i ~ Normal(0, 1)
mu_i = beta0 + beta1 * x_i
log(sigma_i) = gamma0 + gamma1 * z_i
eta_nu_i = delta0 + delta1 * w_i
nu_i = 2 + exp(eta_nu_i)
y_i = mu_i + sigma_i * t_i,  t_i ~ Student-t(df = nu_i)
```

The lower bound `nu_i > 2` gives finite variance and matches the fitted
Student-t shape transform used by `drmTMB`.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n` | 180, 360 | Small and moderate samples for shape recovery. |
| `delta0` | `log(4)`, `log(10)` | Heavy-tailed versus lighter-tailed Student-t errors after the `2 + exp()` transform. |
| `delta1` | 0, 0.35 | Constant shape versus predictor-dependent tail weight. |
| `gamma1` | 0.15, 0.35 | Mild and stronger residual-scale heterogeneity. |
| `rho_xw` | 0, 0.5 | Orthogonal versus partially confounded location and shape predictors. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for formal Wald-coverage tables once the smoke surface is stable.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Shape-link intercept | `delta0` | `coef(fit, dpar = "nu")["(Intercept)"]` |
| Shape-link slope | `delta1` | `coef(fit, dpar = "nu")["w"]` |
| Row-specific degrees of freedom | `2 + exp(delta0 + delta1 * w)` on a named grid | `predict(fit, dpar = "nu", newdata = grid)` when a report explicitly stores the grid truth |

The primary operating-characteristic rows stay on the fitted formula scale.
Response-scale `nu` rows should be reported only on named prediction grids with
stored truths.

## M - Methods

Fit the intended Student-t shape model:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  data = dat,
  family = student()
)
```

The first formal grid should not add external comparators. Skew and two-shape
families need separate ADEMP sheets after their likelihoods, syntax, and
interval routes are implemented and tested.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | fixed `mu`, `sigma`, and `nu` coefficient rows whose interval status is `wald` |
| Response-scale error | mean error for named-grid `nu` predictions only when stored truths exist |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Failure ledger | weak shape identification, invalid or missing Wald standard errors, unsupported skew or latent-shape requests, and failed fits reported beside the grid |

Every aggregate metric should carry an MCSE. Failed, warning-bearing, and
interval-failed fits remain in the manifest, warning/error ledger, and interval
status tables.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | The Student-t hierarchy, shape transform, predictor overlap, and varied factors are explicit. |
| 3. Estimands | Mean, public scale, shape-link, and named-grid response-scale `nu` rows are named. |
| 4. Methods | The intended `student()` `drmTMB` model is stated. |
| 5. Performance measures | Bias, RMSE, Wald coverage, response-scale error, convergence, warning rate, runtime, and failure ledgers are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | A dedicated DGP, runner, summariser, and grid writer live under `inst/sim/`. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | A final report should connect heavy-tailed residuals to ecological outliers and measurement-process heterogeneity. |
| 10. Complete results | Manifests, warning/error ledgers, and interval status tables keep hard cases visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about one percentage point coverage MCSE. |
