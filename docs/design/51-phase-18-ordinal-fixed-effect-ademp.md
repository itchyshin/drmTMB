# Phase 18 Ordinal Fixed-Effect ADEMP Sheet

This sheet is the fifth one-page design unit under the Slice 292 comprehensive
blueprint. It follows the ADEMP structure of Morris, White, and Crowther
(2019) and the transparent-reporting checklist of Williams et al. (2024). It
records the admitted fixed-effect `cumulative_logit()` lane before any larger
ordinal Phase 18 grid is added.

## A - Aims

Primary aim: estimate bias, RMSE, Wald fixed-effect coverage, cutpoint
recovery, convergence rate, and runtime for fixed-effect cumulative-logit
ordinal location models.

Secondary aims: measure how sample size, category count, cutpoint spacing,
location-effect size, and sparse category frequencies affect recovery of the
latent location coefficient and expected ordered-score summaries; keep ordinal
random effects, ordinal `sigma` or discrimination formulas, cutpoint-specific
predictors, known sampling covariance, bivariate ordinal models, and
mixed-response ordinal models outside this grid.

## D - Data-Generating Mechanism

For observations `i = 1, ..., n`, generate one standardized predictor:

```text
x_i ~ Normal(0, 1)
mu_i = beta1 * x_i
theta_1 < theta_2 < ... < theta_{K-1}
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i), k = 1, ..., K - 1
Pr(y_i = 1) = Pr(y_i <= 1)
Pr(y_i = k) = Pr(y_i <= k) - Pr(y_i <= k - 1), 1 < k < K
Pr(y_i = K) = 1 - Pr(y_i <= K - 1)
```

The location intercept is not a DGP estimand because the fitted
`cumulative_logit()` path removes it before optimization; free cutpoints and a
free location intercept are not jointly identifiable. Category labels should be
stored as an ordered factor so simulation output can preserve the original
level names.

The fixed-effect tests in `tests/testthat/test-cumulative-logit.R` use this
likelihood contract. The Phase 18 artifact helper
`inst/sim/dgp/sim_dgp_ordinal_fixed_effect.R` now provides the explicit
simulation DGP, so formal grids should use that helper rather than borrowing a
test fixture as simulation code.

| Factor | Initial levels | Reason |
| --- | --- | --- |
| `n` | 240, 720 | Small and moderate samples for ordinal fixed-effect recovery. |
| `K` | 3, 5 | Simple low/medium/high scores versus a richer ordered severity scale. |
| `beta1` | 0, 0.75 | Null location effect for false-positive checks and a moderate latent effect. |
| `cutpoint_spacing` | moderate, close | Ordinary category separation versus a harder close-cutpoint case. |
| `category_balance` | balanced, sparse-middle | Typical ordered scores versus a low-frequency middle-category stress cell. |

Use 20 replicates per cell for local smoke checks. Use 500 replicates per cell
for a formal Wald-coverage table, giving MCSE about 1 percentage point for 95%
coverage before failed-fit uncertainty is considered.

## E - Estimands

| Estimand | Truth | Estimator output |
| --- | --- | --- |
| Latent location slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Ordered cutpoints | generated `theta_1, ..., theta_{K-1}` | `fit$ordinal$cutpoints` |
| Category probabilities | generated `Pr(y_i = k)` | `ordinal_category_probabilities(fit, newdata = ...)` or a public wrapper if exported later |
| Expected ordered score | `sum_k k * Pr(y_i = k)` | `fitted(fit)` or `ordinal_expected_score(fit, newdata = ...)` |
| Fixed latent scale | 1 | `sigma(fit)` returns a unit vector and is not an estimated scale parameter |

The primary interval target is the fixed `mu` slope on the latent location
scale. Cutpoints can be summarized for bias and RMSE, but polished
response-scale cutpoint intervals, ordinal-scale intervals, and category-
probability intervals remain later work.

## M - Methods

Fit the intended ordinal location model:

```r
drmTMB(
  bf(score ~ x),
  data = dat,
  family = cumulative_logit()
)
```

The first formal grid should not add an external comparator. A later comparator
sheet can add `ordinal::clm()` or `ordinal::clmm()` checks only when the
reported parameterization, intercept/cutpoint convention, and fitted scale are
matched explicitly.

## P - Performance Measures

Report metrics by condition cell and estimand:

| Measure | Formula or rule |
| --- | --- |
| Bias | `mean(estimate - truth)` |
| RMSE | `sqrt(mean((estimate - truth)^2))` |
| Wald coverage | `mean(conf.low <= truth & truth <= conf.high)` for fixed `mu` rows whose interval status is `wald` |
| Cutpoint ordering | `mean(all(diff(cutpoints) > 0))` and any minimum-gap diagnostics |
| Category-probability error | mean absolute probability error over rows and categories for labelled stress cells |
| Expected-score error | mean error in `sum_k k * Pr(y_i = k)` on named prediction grids |
| Convergence rate | `mean(converged & pdHess)` |
| Warning rate | `mean(warning_count > 0)` |
| Runtime | median and high quantiles of elapsed seconds |
| Boundary ledger | malformed ordered responses, empty categories, correlated/labelled or structured ordinal random effects outside the ordinary `mu` and exact phylogenetic gates, ordinal `sigma`, `sd(group)`, `meta_V(V = V)`, denominator syntax, and mixed-response requests reported beside the grid |

Every aggregate metric should carry an MCSE. Failed or warning-bearing fits
remain in the manifest and warning/error ledger. Expected ordered scores are
model summaries for ordered categories, not continuous measurements.

## Williams-Style Self-Audit

| Item | Coverage in this sheet |
| --- | --- |
| 1. Aims | Primary and secondary aims are stated above. |
| 2. DGP | The cumulative-logit hierarchy, cutpoints, category probabilities, and varied factors are explicit. |
| 3. Estimands | Location slope, cutpoints, category probabilities, expected scores, and fixed latent scale are named. |
| 4. Methods | The intended `cumulative_logit()` `drmTMB` model is stated. |
| 5. Performance measures | Bias, RMSE, Wald coverage, cutpoint ordering, probability error, expected-score error, convergence, warning rate, runtime, and boundary ledgers are defined. |
| 6. Software/settings | Per-run session metadata remains the runner responsibility. |
| 7. Code availability | Existing fixed-effect tests document the likelihood contract; a new DGP helper should live under `inst/sim/` before broad runs. |
| 8. Replicability | Seeded cells and replicate-level seeds remain required by the runner contract. |
| 9. Real-data motivation | The distribution-family tutorial supplies the reader-facing ordinal motivation; a final report should cite it. |
| 10. Complete results | Manifests and warning/error ledgers keep failed and unsupported cases visible. |
| 11. Monte Carlo uncertainty | The formal grid target is 500 replicates per cell for about 1 percentage point coverage MCSE. |
