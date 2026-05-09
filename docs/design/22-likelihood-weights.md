# Likelihood Weights

## Purpose

`drmTMB` should eventually support a top-level `weights =` argument, but the
meaning must be narrow and explicit. In this package, `weights =` will mean
ordinary likelihood weights: observation-level multipliers on log-likelihood
contributions.

This is different from known sampling variances or known sampling covariance.
Those belong in `meta_known_V(V = V)`.

## Planned Public Syntax

Univariate models will use one weight per observed response:

```r
drmTMB(
  drm_formula(
    y ~ x1 + x2,
    sigma ~ x1
  ),
  family = gaussian(),
  data = dat,
  weights = w
)
```

Bivariate models will initially use one weight per complete response pair:

```r
drmTMB(
  drm_formula(
    mu1 = y1 ~ x1,
    mu2 = y2 ~ x1,
    sigma1 = ~ x1,
    sigma2 = ~ x1,
    rho12 = ~ x1
  ),
  family = c(gaussian(), gaussian()),
  data = dat,
  weights = w
)
```

Response-specific bivariate weights are not part of the first design. They
would need a separate likelihood and interpretation note.

## Mathematical Contract

For independent univariate rows, the unweighted negative log-likelihood is:

```text
nll = sum_i -log f(y_i | theta_i)
```

With likelihood weights:

```text
nll = sum_i w_i {-log f(y_i | theta_i)}
```

where `w_i` is supplied by `weights =`. The first implementation should require
all `w_i` to be finite and non-negative. Rows with `w_i = 0` contribute nothing
to the objective but should still pass data-shape validation unless a later
decision explicitly drops them.

For complete-row bivariate Gaussian models:

```text
nll = sum_i w_i {-log f([y1_i, y2_i]' | mu1_i, mu2_i, sigma1_i, sigma2_i, rho12_i)}
```

The weight belongs to the response pair, not to `y1_i` or `y2_i` separately.

## Distinction From Known Sampling Covariance

For meta-analysis and other known-uncertainty models, `meta_known_V(V = V)`
changes the covariance used inside the likelihood:

```text
y ~ N(mu, diag(sigma_i^2) + V)
```

or, for bivariate row-paired models:

```text
y_stack ~ MVN(mu_stack, Omega_stack + V_stack)
```

That is not the same operation as multiplying log-likelihood contributions by
`w_i`. A known sampling variance `vi_i` should not be silently converted to
`weights = 1 / vi_i` inside `drmTMB`. Users who want inverse-variance
meta-analysis should use `meta_known_V(V = vi)`, because the known uncertainty
then enters the covariance model directly.

## Related-Package Caution

Several modelling packages expose something called weights, but the convention
differs by model class. Some use frequency or prior weights. Some variance
function systems represent weights as inverse standard deviations. Because of
that ambiguity, `drmTMB` documentation should not say simply "precision
weights" unless the likelihood equation is also shown.

The first public contract should therefore be:

```text
weights = row likelihood multipliers
meta_known_V(V = V) = known sampling covariance
sigma ~ x = modelled extra residual or heterogeneity scale
sd(group) ~ x = modelled group-level random-effect scale
```

## Implementation Notes

- Add `weights = NULL` to `drmTMB()`, not to `drm_formula()`.
- Evaluate `weights` in the model-fitting environment using the same row
  filtering as the response and model matrices.
- Store the processed vector in `fit$model$weights` and expose it through a
  `weights.drmTMB()` method.
- Pass weights to TMB as `DATA_VECTOR(weights)`.
- Multiply per-row likelihood contributions inside each implemented family.
- Keep family tests simple at first: a weight of 2 on every row should match
  doubling the objective value at the same parameter vector.
- Add malformed-input tests for missing values, negative weights, non-finite
  weights, wrong length, and bivariate incomplete-row filtering.

## Open Questions

- Should zero weights keep rows for prediction alignment or be dropped before
  fitting? The safer first design is to keep them after validation and let them
  contribute zero likelihood.
- Should frequency weights be documented as a special case of likelihood
  weights? This is true for some independent models but needs caution once
  random effects, known covariance, or structured effects are present.
- Should response-specific bivariate weights ever be allowed? This should wait
  until mixed-response bivariate families are designed.
