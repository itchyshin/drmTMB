# Phase 18 NB2 Sigma Random-Intercept ADEMP Sheet

This sheet records the small Phase 18 evidence lane for ordinary NB2 grouped
overdispersion:

```r
drmTMB(
  bf(count ~ x, sigma ~ z + (1 | id)),
  family = nbinom2(),
  data = dat
)
```

The route is one response, one count family, one ordinary grouped random
intercept, and one distributional parameter: `sigma`, the NB2 overdispersion
parameter on a log link. It does not open NB2 `sigma` slopes, joint `mu`/
`sigma` random effects, zero-inflated or hurdle scale random effects,
structured NB2 `sigma`, or Poisson scale effects.

## A - Aims

Primary aim: estimate bias, RMSE, convergence, Hessian status, warning/error
rate, fixed-effect Wald coverage, and direct `log_sd_sigma` profile-target
status for the first ordinary NB2 log-`sigma` random-intercept gate.

Secondary aim: keep overdispersion heterogeneity separate from log-mean
heterogeneity. This lane varies group count, repeats per group, mean count,
baseline overdispersion `sigma`, and the true grouped overdispersion SD before
the NB2 phylogenetic q1 lane starts mixing overdispersion and structured SD.

## D - Data-Generating Mechanism

For groups `j = 1, ..., J` and observations `k = 1, ..., m`, use balanced
within-group predictors `x_jk` and `z_jk`:

```text
a_j ~ Normal(0, sd_sigma_intercept^2)
eta_mu_jk = beta0 + beta1 * x_jk
mu_jk = exp(eta_mu_jk)
eta_sigma_jk = gamma0 + gamma1 * z_jk + a_j
sigma_jk = exp(eta_sigma_jk)
count_jk ~ NB2(mu_jk, size = 1 / sigma_jk^2)
```

The helper `phase18_dgp_nbinom2_sigma_re()` implements this DGP. Its condition
helper `phase18_nbinom2_sigma_re_conditions()` names the first smoke factors:

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n_group` | 32, 48 | Enough groups for a public SD row without turning the smoke lane into a benchmark. |
| `n_per_group` | 12, 18 | Enough within-group information to separate fixed `z` from grouped scale heterogeneity. |
| `mean_count` | 2.0, 4.0 | Low and moderate count means where overdispersion is visible. |
| `sigma_baseline` | 0.45, 0.80 | Moderate and high extra-Poisson variation on the public `sigma` scale. |
| `sd_sigma_intercept` | 0.25, 0.45 | Small and clearer grouped overdispersion heterogeneity. |
| `beta_mu_x`, `beta_sigma_z` | -0.18, 0.16 | Fixed slopes keep the model identifiable without becoming the main target. |

Use one replicate per cell for routine package smoke tests, 20 replicates per
cell for local opt-in grid checks, and 500 replicates per cell before writing
formal coverage claims.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Log-mean intercept and slope | `beta_mu` | `coef(fit, dpar = "mu")` |
| Log-`sigma` intercept and slope | `beta_sigma` | `coef(fit, dpar = "sigma")` |
| Grouped log-`sigma` random-intercept SD | `sd_sigma_intercept` | `fit$sdpars$sigma["(1 | id)"]` |
| Direct profile target | `log_sd_sigma` | `profile_targets(fit)` row `sd:sigma:(1 | id)` |
| Replication diagnostic | group count and minimum repeats | `check_drm()` row `sigma_random_effect_replication` |

## M - Methods

Fit only the intended ordinary non-zero-inflated NB2 model:

```r
drmTMB(
  bf(count ~ x, sigma ~ z + (1 | id)),
  family = nbinom2(),
  data = dat
)
```

The smoke runner `phase18_run_nbinom2_sigma_re_smoke()` wires the DGP, fit,
summariser, registry, and bounded replicate runner. The grid writer
`phase18_write_nbinom2_sigma_re_grid_outputs()` saves aggregate, replicate,
manifest, failure-ledger, Wald interval, Wald coverage, direct profile-target,
optional profile-interval, interval-evidence, interval-diagnostics, and
interval-failure CSVs beside resumable replicate RDS files.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Fixed-effect Wald coverage | `mu` and fixed `sigma` rows with usable standard errors |
| Profile-target status | `sd:sigma:(1 | id)` row maps to direct `log_sd_sigma` and is marked ready or not ready |
| Optional profile coverage | Direct random-effect SD rows when `profile_parameters` requests `log_sd_sigma` |
| Convergence and Hessian rate | `mean(converged)` and `mean(pdHess)` |
| Warning/error rate | manifest and failure-ledger rows, not dropped from summaries |
| Runtime | replicate elapsed seconds, summarized beside the operating metrics |

Failed fits, failed profiles, and unavailable intervals are part of the result.
Do not compute coverage after silently removing them.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Bias, RMSE, coverage, diagnostics, and overdispersion heterogeneity are named. |
| 2. DGP | The NB2 log-mean and log-`sigma` hierarchy is explicit. |
| 3. Estimands | Fixed `mu`, fixed `sigma`, grouped `sigma` SD, profile target, and diagnostic rows are named. |
| 4. Methods | The exact `drmTMB()` model is stated. |
| 5. Performance measures | Bias, RMSE, intervals, convergence, warnings, and runtime are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | The implemented helpers live under `inst/sim/`. |
| 8. Replicability | Seeded cells and replicate seeds are handled by the Phase 18 runner registry. |
| 9. Real-data motivation | The count tutorial supplies the applied count-model motivation. |
| 10. Complete results | Manifests, failure ledgers, and interval-status tables keep failed rows visible. |
| 11. Monte Carlo uncertainty | Formal coverage claims require a 500-replicate gate with MCSEs. |
