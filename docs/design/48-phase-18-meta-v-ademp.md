# Phase 18 Meta-Analysis Known-V ADEMP Sheet

This sheet is the second one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). It records
the admitted Gaussian meta-analysis lane with additive known sampling covariance
`meta_V(V = V)`.

## A - Aims

Primary aim: estimate bias, RMSE, Wald interval coverage, convergence rate, and
runtime for Gaussian meta-analysis models with known sampling covariance `V`
and fitted residual heterogeneity `sigma`.

Secondary aims: compare vector and dense known-`V` inputs, measure how
sampling-error scale and residual heterogeneity affect recovery of fixed
effects and public residual `sigma`, and keep known sampling covariance separate
from latent relatedness, animal models, and proportional sampling-variance
models.

## D - Data-Generating Mechanism

For study or effect-size rows `i = 1, ..., n_study`, generate:

```text
x_i ~ Normal(0, 1)
mu_i = beta0 + beta1 * x_i
e ~ MVN(0, V)
u_i ~ Normal(0, sigma^2)
yi_i = mu_i + e_i + u_i
```

For vector known-`V` cells, `V` is the supplied vector of known sampling
variances and `sampling_rho = 0`. For dense known-`V` cells, `V` is a dense
sampling covariance matrix with exponentially decaying correlation controlled
by `sampling_rho`. The current helper `phase18_dgp_meta_v()` already implements
this DGP and stores `V` as an attribute on the simulated data.

The current condition helper uses the following design:

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n_study` | 36, 72 | Small and moderate evidence collections. |
| `known_v_type` | vector, dense | Diagonal known variances versus dense known sampling covariance. |
| `sigma` | 0.15, 0.35 | Lower and higher residual heterogeneity on the public `sigma` scale. |
| `sampling_sd` | 0.12, 0.22 | Lower and higher known sampling-error scale. |
| `sampling_rho` | 0, 0.25 | Dense known covariance sensitivity; vector cells use only 0. |
| `beta0`, `beta1` | 0.20, 0.45 | Existing helper defaults for the mean model. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for a formal coverage table, giving MCSE about 1 percentage point for 95%
coverage before failed-fit uncertainty is considered.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Residual heterogeneity | public `sigma` used in the DGP | `unique(as.numeric(sigma(fit)))` |
| Known sampling covariance | supplied `V` | no estimator; `V` is input data and must not receive interval coverage |

The existing summariser stores `mu` coefficients and public residual `sigma`.
It deliberately does not create truth or coverage rows for known sampling
covariance `V`.

## M - Methods

Fit the intended model:

```r
V <- attr(dat, "V", exact = TRUE)
drmTMB(
  bf(yi ~ x + meta_V(V = V), sigma ~ 1),
  family = gaussian(),
  data = dat
)
```

The first formal grid should not add proportional sampling-variance models,
animal models, or user-supplied latent relatedness comparators. A later
comparator sheet can add a conventional meta-analysis route only if it targets
the same fixed effects and residual heterogeneity scale honestly.

This sheet validates the constant-`sigma` `meta_V(V = V)` lane. It does not
validate `meta_V(V = vi)` with predictor-dependent `sigma`, which issue #417
reports can return plausible point estimates while `TMB::sdreport()` reports
`pdHess = FALSE`.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | `mean(conf.low <= truth & truth <= conf.high)` for estimated `mu` and `sigma` rows whose interval status is `wald` |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Known-`V` diagnostics | dense-`V` size, rank, conditioning, and storage status from `check_drm()` where available |

Every aggregate metric should carry an MCSE. Failed or warning-bearing fits
remain in the manifest and warning/error ledger. Dense known-`V` failures should
be interpreted as storage or conditioning failures, not as residual
heterogeneity estimates.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | Mean model, residual heterogeneity, and vector/dense known `V` generation are explicit. |
| 3. Estimands | Mean coefficients, public residual `sigma`, and non-estimated `V` status are named. |
| 4. Methods | The intended `drmTMB` model is stated; comparator scope is limited. |
| 5. Performance measures | Bias, RMSE, coverage, convergence, warning rate, runtime, and known-`V` diagnostics are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing helpers live under `inst/sim/`; this sheet links their intended use. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The meta-analysis vignette supplies the reader-facing motivation; a final report should cite it. |
| 10. Complete results | Manifests and warning/error ledgers keep failed fits visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about 1 percentage point coverage MCSE. |
