# Phase 18 Count Mu Random-Effect ADEMP Sheet

This sheet is the third one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther (2019)
and the transparent-reporting checklist of Williams et al. (2024). It records
the admitted ordinary non-zero-inflated Poisson and NB2 `mu` random-effect lane.

## A - Aims

Primary aim: estimate bias, RMSE, Wald fixed-effect coverage, profile
random-effect SD coverage, convergence rate, and runtime for ordinary count
models with random intercepts and independent numeric random slopes in `mu`.

Secondary aims: compare Poisson and NB2 recovery under the same grouped design,
measure sensitivity to group count, observations per group, true random-effect
SDs, mean count, and NB2 overdispersion, and keep zero-inflated, hurdle,
structured, correlated-slope, and cross-parameter covariance models out of this
grid.

## D - Data-Generating Mechanism

For groups `j = 1, ..., J` and observations `k = 1, ..., m`, use a balanced
within-group predictor `x_jk`:

```text
b0_j ~ Normal(0, sd_intercept^2)
bx_j ~ Normal(0, sd_x^2)
eta_mu_jk = beta0 + beta1 * x_jk + b0_j + bx_j * x_jk
mu_jk = exp(eta_mu_jk)
```

For Poisson cells:

```text
count_jk ~ Poisson(mu_jk)
```

For NB2 cells:

```text
eta_sigma_jk = gamma0 + gamma1 * z_jk
sigma_jk = exp(eta_sigma_jk)
count_jk ~ NB2(mu_jk, size = 1 / sigma_jk^2)
```

The current helpers `phase18_dgp_poisson_mu_re()` and
`phase18_dgp_nbinom2_mu_re()` already implement these DGPs. The paired pilot
wrapper `phase18_summarise_count_mu_re_pilot()` combines the two families into
aggregate, manifest, failure-ledger, Wald-coverage, and profile-coverage tables.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n_group` | Poisson 36, 48; NB2 44, 56 in the paired pilot | Moderate group counts for random-effect SD recovery without turning the first grid into a benchmark. |
| `n_per_group` | Poisson 9; NB2 10 in the paired pilot | Enough within-group spread for independent numeric slope checks. |
| `sd_intercept` | 0.40 | Existing helper default for group-level intercept heterogeneity. |
| `sd_x` | Poisson 0.30; NB2 0.28 | Existing helper defaults for independent slope heterogeneity. |
| `beta_mu` | Poisson `(0.30, -0.25)`; NB2 `(0.30, -0.22)` | Existing helper defaults for the log-mean model. |
| `beta_sigma` | NB2 `(-0.75, 0.15)` | Existing helper default for fixed-effect log-overdispersion. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for a formal Wald-coverage table. Profile coverage for random-effect SDs should
state the configured profile level; the current summariser default is 0.70, and
a 0.95 profile grid should be a separate runtime-budget decision.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Poisson log-mean intercept and slope | `beta_mu` | `coef(fit, dpar = "mu")` |
| NB2 log-mean intercept and slope | `beta_mu` | `coef(fit, dpar = "mu")` |
| NB2 log-overdispersion intercept and slope | `beta_sigma` | `coef(fit, dpar = "sigma")` |
| Random-intercept SD in `mu` | `sd_intercept` | `fit$sdpars$mu["(1 | id)"]` |
| Independent random-slope SD in `mu` | `sd_x` | `fit$sdpars$mu["(0 + x | id)"]` |

The existing summarisers report fixed-effect standard errors where available
and attach profile intervals for direct random-effect SD targets when profiling
is requested.

## M - Methods

Fit the intended Poisson model:

```r
drmTMB(
  bf(count ~ x + (1 | id) + (0 + x | id)),
  family = stats::poisson(link = "log"),
  data = dat
)
```

Fit the intended NB2 model:

```r
drmTMB(
  bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z),
  family = nbinom2(),
  data = dat
)
```

The first formal grid should use only ordinary non-zero-inflated count models.
Zero-inflated, hurdle, zero-truncated, structured, correlated-slope, and
labelled covariance count models stay in the failure ledger until their own
likelihood and recovery gates close.

## P - Performance Measures

Report metrics by family, condition cell, and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | Fixed `mu` and NB2 `sigma` rows with interval status `wald` |
| Profile coverage | Direct `sd:mu` rows with profile interval status and the configured profile level |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Boundary and weak-SD diagnostics | `check_drm()` boundary rows where available, reported beside aggregate summaries |

Every aggregate metric should carry an MCSE. Failed, warning-bearing, and
profile-failed fits remain in the manifest, warning/error ledger, and interval
status tables.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | Poisson and NB2 grouped count mechanisms are explicit. |
| 3. Estimands | Fixed `mu`, NB2 fixed `sigma`, and direct `mu` random-effect SD targets are named. |
| 4. Methods | The intended Poisson and NB2 `drmTMB` models are stated. |
| 5. Performance measures | Bias, RMSE, Wald/profile coverage, convergence, warning rate, runtime, and diagnostics are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing helpers live under `inst/sim/`; this sheet links their intended use. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | Count-model tutorials supply the reader-facing motivation; a final report should cite them. |
| 10. Complete results | Manifests, failure ledgers, and interval status tables keep failed fits visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for fixed-effect Wald coverage; profile-level targets must state the requested confidence level. |
