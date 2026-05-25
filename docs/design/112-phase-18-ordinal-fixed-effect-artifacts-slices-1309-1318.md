# Phase 18 Ordinal Fixed-Effect Artifacts, Slices 1309-1318

This note records the first artifact lane for fitted ordinal one-response
models. The reader is an applied ecology, evolution, or environmental-science
user asking whether ordered severity, condition, or abundance scores have
simulation evidence, and a package contributor deciding which ordinal neighbours
still belong in the failure ledger.

## A - Aims

Primary aim: check fixed-effect recovery for the fitted univariate
`cumulative_logit()` location model with ordered cutpoints and fixed latent
logistic scale.

Secondary aim: stage the same aggregate, replicate, manifest, failure-ledger,
Wald interval, and Wald coverage artifacts used by the other first-wave lanes,
while adding ordinal-specific cutpoint and cutpoint-ordering diagnostics.

## D - Data-Generating Mechanism

Each simulated data set has one standardized location predictor:

```text
x_i ~ Normal(0, 1)
mu_i = beta1 * x_i
theta_1 < theta_2 < ... < theta_{K-1}
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
```

The category probabilities are:

```text
Pr(y_i = 1) = Pr(y_i <= 1)
Pr(y_i = k) = Pr(y_i <= k) - Pr(y_i <= k - 1), 1 < k < K
Pr(y_i = K) = 1 - Pr(y_i <= K - 1)
```

The DGP stores the ordered response labels, the expected ordered score, the
true latent slope, and the true ordered cutpoints. The location intercept is not
a truth target because the fitted `cumulative_logit()` path removes the
intercept before optimization; free cutpoints and a free location intercept are
not jointly identifiable.

## E - Estimands

| Quantity | Truth | Estimator output |
| --- | --- | --- |
| Latent location slope | `beta1` | `coef(fit, dpar = "mu")["x"]` |
| Ordered cutpoints | `theta_1, ..., theta_{K-1}` | `fit$ordinal$cutpoints` |
| Expected ordered score | `sum_k k * Pr(y_i = k)` | `fitted(fit)` |
| Fixed latent scale | 1 | `sigma(fit)` returns a unit vector |

The first Wald interval rows are for fixed `mu` formula coefficients only.
Cutpoints are summarized for bias, RMSE, and ordering diagnostics, but polished
cutpoint intervals and category-probability intervals remain later work.

## M - Methods

The fitted method is:

```r
drmTMB(
  bf(score ~ x),
  family = cumulative_logit(),
  data = dat
)
```

The first lane is fixed-effect and location-only. It does not add ordinal
random effects, ordinal scale or discrimination formulas, cutpoint-specific
predictors, known sampling covariance, bivariate ordinal models, or
mixed-response ordinal models.

## P - Performance Measures

The artifact tables record bias, RMSE, mean absolute error, empirical standard
error, convergence rate, positive-Hessian rate, warning rate, elapsed time, Wald
interval status, Wald coverage for the latent location slope, minimum fitted
cutpoint gap, and whether fitted cutpoints remain ordered. Aggregate bias MCSE
is `sd(error) / sqrt(n_replicate)`.

Expected ordered scores are ordinal response summaries, not continuous
measurements. They are useful for plotting and checking direction, but the
primary recovery target remains the latent location coefficient.

## Implemented Path

Slices 1309-1318 add:

- `phase18_dgp_ordinal_fe()`;
- `phase18_summarise_ordinal_fe_fit()`;
- `phase18_run_ordinal_fe_smoke()`;
- `phase18_summarise_ordinal_fe_smoke()`;
- `phase18_write_ordinal_fe_grid_outputs()`;
- a focused test file;
- first-wave summary runner inclusion; and
- a manual `ordinal_fixed_effect` Actions task.

## Boundaries

This is not a broader ordinal expansion. Ordinal random effects, ordinal scale
or discrimination formulas, cutpoint-specific predictors, known-covariance
ordinal models, phylogenetic/spatial/animal/`relmat()` ordinal effects,
bivariate ordinal models, and mixed-response ordinal models remain unsupported
or planned until their own likelihood, diagnostic, interval, comparator, and
simulation gates land.
