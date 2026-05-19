# Phase 18 Proportion Fixed-Effect ADEMP Sheet

This sheet is the fourth one-page design unit under the Slice 292
comprehensive blueprint. It follows the ADEMP structure of Morris, White, and
Crowther (2019) and the transparent-reporting checklist of Williams et al.
(2024). It records the admitted fixed-effect `beta()` and `beta_binomial()`
lane for bounded responses before any larger Phase 18 grid is added.

## A - Aims

Primary aim: estimate bias, RMSE, Wald interval coverage, convergence rate, and
runtime for fixed-effect beta and beta-binomial models with `mu ~ x` and
`sigma ~ z`.

Secondary aims: separate strict continuous proportions from successes out of
known trial totals, measure sensitivity to denominator size, baseline mean,
scale effect size, and mean-scale predictor correlation, and keep exact 0/1
continuous boundary mass, `zoi`/`coi`, random effects, structured effects,
known sampling covariance, and mixed-response bounded models outside this
grid.

## D - Data-Generating Mechanism

Use one covariate for the mean and one covariate for the public scale. For rows
`i = 1, ..., n`, generate standardized predictors with correlation `rho_xz`:

```text
x_i ~ Normal(0, 1)
z_i = rho_xz * x_i + sqrt(1 - rho_xz^2) * epsilon_i,
epsilon_i ~ Normal(0, 1)
eta_mu_i = beta0 + beta1 * x_i
eta_sigma_i = gamma0 + gamma1 * z_i
mu_i = logit^{-1}(eta_mu_i)
sigma_i = exp(eta_sigma_i)
phi_i = 1 / sigma_i^2
alpha_i = mu_i * phi_i
beta_shape_i = (1 - mu_i) * phi_i
```

For strict continuous proportions:

```text
prop_i ~ Beta(alpha_i, beta_shape_i)
```

For successes out of known trials:

```text
trials_i ~ sampled from a bounded integer design distribution
p_i ~ Beta(alpha_i, beta_shape_i)
success_i ~ Binomial(trials_i, p_i)
failure_i = trials_i - success_i
```

The existing fixed-effect tests use the same likelihood contracts in
`tests/testthat/test-beta-location-scale.R` and
`tests/testthat/test-beta-binomial.R`. A first formal grid should add explicit
DGP helpers before broad runs rather than borrowing test fixtures as simulation
code.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `family` | `beta()`, `beta_binomial()` | Separate continuous strict proportions from denominator-aware success counts. |
| `n` | 160, 480 | Small and moderate samples for fixed-effect bounded-response recovery. |
| `trials` | 8-12, 20-30 for beta-binomial cells | Low versus moderate denominator information; not used for strict beta cells. |
| `beta0`, `beta1` | `-0.20`, `0.60` | Baseline away from exact boundaries with a moderate mean effect on the logit scale. |
| `gamma0` | `-0.90`, `-0.55` | Lower and higher public `sigma`, mapped internally to beta precision. |
| `gamma1` | 0, 0.25 | Null scale effect for false-positive checks and a moderate log-scale effect. |
| `rho_xz` | 0, 0.6 | Orthogonal versus confounded mean and scale predictors. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for a formal Wald-coverage table, giving MCSE about 1 percentage point for 95%
coverage before failed-fit uncertainty is considered.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Mean intercept | `beta0` | `coef(fit, dpar = "mu")["(Intercept)"]` |
| Mean slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Log-scale intercept | `gamma0` | `coef(fit, dpar = "sigma")["(Intercept)"]` |
| Log-scale slope | `gamma1` | `coef(fit, dpar = "sigma")["z"]` |
| Public scale ratio for one-unit `z` increase | `exp(gamma1)` | `exp(coef(fit, dpar = "sigma")["z"])` |
| Beta precision | generated `phi_i = 1 / sigma_i^2` | derived only when a report explicitly states the transform |
| Beta-binomial expected success proportion | generated `mu_i` | `fitted(fit)` or `predict(fit, dpar = "mu")` |

The primary operating-characteristic rows should stay on the link scale for
fixed coefficients and on the public `sigma` scale for any response-scale
summary. Precision `phi` is an internal transform, not the public scale.

## M - Methods

Fit the strict continuous-proportion model:

```r
drmTMB(
  bf(prop ~ x, sigma ~ z),
  data = dat,
  family = beta()
)
```

Fit the denominator-aware success-count model:

```r
drmTMB(
  bf(cbind(success, failure) ~ x, sigma ~ z),
  data = dat,
  family = beta_binomial()
)
```

The first formal grid should not add external comparators. A later comparator
sheet can add a binomial or quasibinomial route for beta-binomial sensitivity,
but only if the report states that those models do not estimate the same
extra-binomial public `sigma`.

## P - Performance Measures

Report metrics by family, condition cell, and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | `mean(conf.low <= truth & truth <= conf.high)` for fixed `mu` and `sigma` rows whose interval status is `wald` |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Boundary ledger | malformed response, exact-boundary, unsupported `zoi`/`coi`, random-effect, and mixed-response failures reported beside the grid |

Every aggregate metric should carry an MCSE. Failed or warning-bearing fits
remain in the manifest and warning/error ledger. Exact 0 or 1 continuous
proportions should be recorded as unsupported strict-beta boundary cases, not
silently adjusted.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | Strict beta and beta-binomial mechanisms, denominator generation, and varied factors are explicit. |
| 3. Estimands | Mean, public scale, scale-ratio, precision-transform, and fitted proportion rows are named. |
| 4. Methods | The intended `beta()` and `beta_binomial()` `drmTMB` models are stated. |
| 5. Performance measures | Bias, RMSE, Wald coverage, convergence, warning rate, runtime, and boundary ledgers are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing fixed-effect tests document the likelihood contracts; new DGP helpers should live under `inst/sim/` before broad runs. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The proportion tutorial supplies the reader-facing measurement-process motivation; a final report should cite it. |
| 10. Complete results | Manifests and warning/error ledgers keep failed and unsupported cases visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about 1 percentage point coverage MCSE. |
