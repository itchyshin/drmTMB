# Phase 18 Bivariate Residual Rho12 ADEMP Sheet

This sheet is the sixth one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther
(2019) and the transparent-reporting checklist of Williams et al. (2024). It
records the admitted bivariate Gaussian residual-correlation lane before any
larger `rho12` Phase 18 grid is added.

## A - Aims

Primary aim: estimate bias, RMSE, interval coverage, convergence rate, and
runtime for fixed-effect bivariate Gaussian models with residual correlation
`rho12`.

Secondary aims: measure how sample size, residual-correlation strength,
predictor-dependent `rho12`, residual-scale imbalance, and mean/scale
predictor overlap affect recovery of response-specific means, residual scales,
and the residual coscale `rho12`; keep group-level `corpairs()`, phylogenetic
or spatial correlations, known sampling covariance `V`, random effects in
`rho12`, mixed-response families, and bivariate random-slope covariance outside
this residual-correlation grid.

## D - Data-Generating Mechanism

For observations `i = 1, ..., n`, generate predictors for the two response
means, the two residual scales, and residual correlation:

```text
x_i, z1_i, z2_i, w_i ~ standardized Normal predictors
mu1_i = beta10 + beta11 * x_i
mu2_i = beta20 + beta21 * x_i
log(sigma1_i) = gamma10 + gamma11 * z1_i
log(sigma2_i) = gamma20 + gamma21 * z2_i
eta_rho12_i = delta0 + delta1 * w_i
rho12_i = tanh(eta_rho12_i)
```

The observation-level residual covariance matrix is:

```text
Omega_i[1, 1] = sigma1_i^2
Omega_i[2, 2] = sigma2_i^2
Omega_i[1, 2] = Omega_i[2, 1] = rho12_i * sigma1_i * sigma2_i
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)
```

The TMB implementation uses a tiny guarded transform for numerical stability,
`rho12_i = 0.99999999 * tanh(eta_rho12_i)`. A first formal grid should add an
explicit bivariate `rho12` DGP helper under `inst/sim/` before broad runs,
rather than borrowing test fixtures from `tests/testthat/test-biv-gaussian.R`.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n` | 180, 540 | Small and moderate samples for bivariate fixed-effect recovery. |
| `delta0` | `atanh(-0.35)`, `atanh(0.35)` | Negative and positive baseline residual correlation. |
| `delta1` | 0, 0.35 | Constant residual correlation versus predictor-dependent coscale. |
| `sigma_ratio` | 0.7, 1.4 | Similar versus imbalanced residual scales across responses. |
| `rho_xw` | 0, 0.5 | Orthogonal versus partially confounded mean and residual-correlation predictors. |
| missingness | complete rows first; row-missing stress later | Complete-row bivariate fitting is the first admitted grid. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for formal coefficient-level coverage. Row-specific or constant response-scale
`rho12` profile coverage should state its profile method and runtime budget
separately.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Response 1 mean coefficients | `beta10`, `beta11` | `coef(fit, dpar = "mu1")` |
| Response 2 mean coefficients | `beta20`, `beta21` | `coef(fit, dpar = "mu2")` |
| Response 1 log-scale coefficients | `gamma10`, `gamma11` | `coef(fit, dpar = "sigma1")` |
| Response 2 log-scale coefficients | `gamma20`, `gamma21` | `coef(fit, dpar = "sigma2")` |
| Residual-correlation link coefficients | `delta0`, `delta1` | `coef(fit, dpar = "rho12")` |
| Row-specific residual correlation | generated `rho12_i` on a named grid | `rho12(fit, newdata = grid)` |
| Row-specific residual covariance | generated `rho12_i * sigma1_i * sigma2_i` | `rho12(fit, newdata = grid) * predict(fit, newdata = grid, dpar = "sigma1") * predict(fit, newdata = grid, dpar = "sigma2")` |

The primary fixed-effect operating-characteristic rows stay on their fitted
link scales. Response-scale `rho12` and residual covariance rows should be
reported only on named prediction grids with stored truths.

## M - Methods

Fit the intended bivariate Gaussian residual-correlation model:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ x,
    sigma1 = ~ z1,
    sigma2 = ~ z2,
    rho12 = ~ w
  ),
  data = dat,
  family = biv_gaussian()
)
```

The first formal grid should not add external comparators or group-level
covariance. Group-level `corpairs()`, phylogenetic or spatial correlations,
and known sampling covariance `V` need separate ADEMP sheets so residual
`rho12` does not borrow evidence from another correlation layer.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | fixed `mu1`, `mu2`, `sigma1`, `sigma2`, and `rho12` coefficient rows whose interval status is `wald` |
| Profile coverage | constant or row-specific response-scale `rho12` rows only when the interval producer reports `profile` status |
| Response-scale error | mean error for `rho12(fit, newdata = grid)` and residual covariance on named grids |
| Boundary rate | `check_drm()` `rho12_boundary` rows where available |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Failure ledger | random effects in `rho12`, mixed-response families, bivariate random-slope covariance outside the admitted slope-only and source-tested q=4 location routes, q=8 slope covariance, and structured-correlation requests reported beside the grid |

Every aggregate metric should carry an MCSE. Failed, warning-bearing, boundary,
and interval-failed fits remain in the manifest, warning/error ledger, and
interval status tables.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | The bivariate Gaussian hierarchy, residual covariance matrix, guarded `rho12` transform, and varied factors are explicit. |
| 3. Estimands | Response-specific means, residual scales, link-scale `rho12`, response-scale `rho12`, and residual covariance rows are named. |
| 4. Methods | The intended `biv_gaussian()` `drmTMB` model is stated. |
| 5. Performance measures | Bias, RMSE, Wald/profile coverage, response-scale error, boundary rate, convergence, warning rate, runtime, and failure ledgers are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing bivariate tests document the likelihood contract; a new DGP helper should live under `inst/sim/` before broad runs. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The bivariate-coscale tutorial supplies the reader-facing residual-correlation motivation; a final report should cite it. |
| 10. Complete results | Manifests, warning/error ledgers, boundary rows, and interval status tables keep hard cases visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for coefficient-level coverage; response-scale profile coverage needs a separate runtime decision. |
