# Ordinal Scale And Discrimination

This note records the direction of the planned ordinal scale extension before
the likelihood or formula grammar changes.

## Implemented Contract

The implemented `cumulative_logit()` path is a univariate fixed-effect ordinal
location model:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The latent logistic scale is fixed. The location intercept is removed
internally because a free intercept and free cutpoints are not jointly
identifiable. `predict(fit, dpar = "mu")` returns latent location, and
`fitted(fit)` returns the expected ordered-category score.

## Preferred First Scale Extension

The first planned scale extension should use the package's stable scale grammar:

```text
Pr(y_i <= k) = logit^{-1}((theta_k - mu_i) / sigma_i)
log(sigma_i) = X_sigma[i, ] beta_sigma
```

With this parameterization, larger `sigma_i` means a wider latent distribution
relative to the cutpoints, so outcomes are less sharply separated across
categories. A discrimination or consistency summary can be reported as the
derived quantity:

```text
zeta_i = 1 / sigma_i
```

This keeps the fitted model grammar aligned with the rest of `drmTMB`, where
`sigma ~ predictors` describes scale, while still letting papers or tutorials
talk about discrimination when that is the reader's target.

## What Not To Expose Yet

Do not add a native `zeta ~ predictors` formula without a separate design
decision. A native discrimination formula reverses the direction of the public
coefficient interpretation: larger `zeta` means clearer category separation,
whereas larger `sigma` means more latent spread. Both can be valid, but mixing
them without a precise grammar would make tutorials and comparator tests easy to
misread.

Do not let the cutpoints carry ordinary fixed-effect terms in the first scale
extension. Cutpoint-specific covariates are a larger ordinal-model design and
should wait until the location-plus-scale path has parameter recovery evidence.

## Acceptance Criteria Before Coding

- `docs/design/01-formula-grammar.md` documents the accepted `sigma ~` ordinal
  grammar and any rejected aliases.
- `docs/design/19-family-link-contract.md` states the native meaning of
  `sigma`, the `fitted()` rule, and the derived `zeta = 1 / sigma` summary.
- Tests cover coefficient recovery, malformed categories, missing categories,
  no-intercept handling in the location formula, stable probabilities under
  large positive or negative predictors, `predict()`, `fitted()`, `sigma()`,
  `simulate()`, and `newdata`.
- Documentation pairs the symbolic equation, R syntax, and interpretation of a
  positive `sigma` coefficient.
- Comparator or independent-likelihood checks are added before the model is
  described as implemented in tutorials.

Until those criteria are met, `cumulative_logit()` remains location-only with a
fixed latent logistic scale.
