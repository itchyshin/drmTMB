# Family Link and Response-Scale Contract

This note separates three ideas that are easy to confuse once `drmTMB` moves
beyond Gaussian location-scale models:

1. the distributional parameter name, such as `mu` or `sigma`;
2. the link used to map a formula linear predictor to that parameter;
3. the user-facing response summary returned by `fitted()`.

The package should not assume that every `mu` formula has an identity link, or
that every `mu` parameter is the arithmetic expected response. Those assumptions
are true for Gaussian and Student-t models, but not for every useful
distributional-regression family.

## Current Implemented Contract

The implemented families use these parameter meanings:

| Family | Parameter | Link | Response-scale meaning |
|---|---|---|---|
| Gaussian | `mu` | identity | arithmetic mean of `y` |
| Gaussian | `sigma` | log | residual standard deviation of `y` |
| Student-t | `mu` | identity | location parameter and mean when `nu > 1` |
| Student-t | `sigma` | log | Student-t scale parameter |
| Student-t | `nu` | `logm2` | degrees of freedom, `nu = 2 + exp(eta_nu)` |
| Lognormal | `mu` | identity | mean of `log(y)`, not mean of `y` |
| Lognormal | `sigma` | log | standard deviation of `log(y)` |
| Bivariate Gaussian | `mu1`, `mu2` | identity | arithmetic means of `y1` and `y2` |
| Bivariate Gaussian | `sigma1`, `sigma2` | log | residual standard deviations |
| Bivariate Gaussian | `rho12` | guarded atanh | residual response-response correlation |

For lognormal fits:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
E[y_i] = exp(mu_i + sigma_i^2 / 2)
```

Therefore:

- `predict(fit, dpar = "mu")` returns the log-scale location parameter;
- `sigma(fit)` returns the log-scale standard deviation;
- `fitted(fit)` returns `E[y_i]` on the original response scale.

This distinction should guide every future family.

## Prediction Rule

`predict(fit, dpar = "<parameter>", type = "response")` should return the
named distributional parameter on its native parameter scale, after applying
the family-specific inverse link.

`fitted(fit)` should return the expected response where that expectation is
defined and implemented. If a family's expectation is not finite, not unique, or
not the main user-facing target, the documentation must say exactly what
`fitted()` returns.

Examples:

```text
Gaussian:   predict(mu) = E[y] = fitted()
Student-t:  predict(mu) = location; fitted() currently returns mu
Lognormal:  predict(mu) = E[log(y)]; fitted() = exp(mu + sigma^2 / 2)
```

The extractor `sigma(fit)` should return the modelled parameter named `sigma`,
or `sigma1` and `sigma2` for bivariate fits, not silently convert it to a
family-specific residual standard deviation unless the family defines `sigma`
that way. Documentation should translate to residual variance or standard
deviation where useful.

## Registry Requirements

Every family object should eventually declare:

```text
dpars
links
inverse_links
native_parameter_meaning
fitted_response_rule
variance_rule
bounds
```

The current constructors expose only the fields needed by the implemented
builders.

## Implemented R-Side Helpers

The post-fit methods now use internal helpers in `R/methods.R` rather than
scattering link rules across extractors:

```text
drm_dpar_link()       maps model type and dpar to the implemented link
drm_inverse_link()    applies the family-specific inverse link
drm_fitted_response() applies the family-specific fitted-response rule
```

The current helper table is still internal and deliberately small. It records
only implemented model paths. Before adding a new family, update this table and
add tests that check `predict(type = "link")`, response-scale `predict()`, and
`fitted()` for the new family.

## Candidate Positive Continuous Contract

For `gamma()`, the preferred first contract is a mean-CV parameterization:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i^2 sigma_i^2
```

Here `sigma` is the coefficient of variation. This keeps `mu` as the expected
response and gives the scale formula a direct interpretation: predictors change
relative variability. That is useful for ecology and evolution examples such as
biomass, body mass, metabolic rate, and concentration.

This should be treated as a design proposal until implemented and tested. The
implementation must document that `sigma` is not the residual standard
deviation of `y`; the residual standard deviation is `mu * sigma`.

## Candidate Count Contract

Counts need log links for the mean. The first count family should probably be
negative binomial rather than Poisson because overdispersion is often the
scientific target.

Candidate contracts:

```text
Poisson:
  y_i ~ Poisson(mu_i)
  log(mu_i) = X_mu[i, ] beta_mu
  Var[y_i] = mu_i

Negative binomial 2:
  log(mu_i) = X_mu[i, ] beta_mu
  log(sigma_i) = X_sigma[i, ] beta_sigma
  Var[y_i] = mu_i + sigma_i^2 mu_i^2
```

The `nbinom2()` `sigma` proposal makes `sigma` an overdispersion scale, with
larger values meaning greater extra-Poisson variation. Before implementation,
compare this with `glmmTMB` and other conventions and document the translation.

Zero inflation should use a separate parameter such as `zi`:

```text
logit(zi_i) = X_zi[i, ] beta_zi
```

`zi` is a probability, not a scale parameter.

## Candidate Proportion Contract

For continuous proportions, `mu` should live in `(0, 1)`:

```text
logit(mu_i) = X_mu[i, ] beta_mu
```

The scale/precision parameterization needs a separate design decision before
coding. Two candidates are:

```text
Beta mean-precision:
  phi_i = exp(X_phi[i, ] beta_phi)
  alpha_i = mu_i phi_i
  beta_i = (1 - mu_i) phi_i

Beta mean-dispersion:
  sigma_i = inverse_link(X_sigma[i, ] beta_sigma)
  Var[y_i] = function(mu_i, sigma_i)
```

The public grammar can still use `sigma ~ predictors` if we document how it
maps to precision or dispersion. Do not add `phi ~` as a second public grammar
without a design decision, because `sigma` is the package's stable scale name.

For percentages derived from counts, `beta_binomial()` should take successes
and trials rather than forcing users to convert to a continuous proportion.

## Candidate Ordinal Contract

Ordinal models introduce cutpoints. Cutpoints are direct model parameters, not
ordinary fixed-effect formulas in the first implementation.

First univariate ordinal path:

```text
Pr(y_i <= k) = link^{-1}(theta_k - eta_i)
eta_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

Distributional extensions such as threshold scale or discrimination models are
later phases. Bivariate ordinal correlation is a research project because the
latent correlation is harder to identify and validate.

## Implementation Checklist Before New Families

Before implementing Gamma, count, beta, or ordinal families:

1. Add the family to `drm_dpar_link()` and `drm_inverse_link()`.
2. Add the fitted-response rule to `drm_fitted_response()` where `fitted()` is
   supported.
3. Add documentation that states whether `mu` is an expected response,
   location, log-location, probability, or latent location.
4. Add tests for `predict(type = "link")`, `predict(type = "response")`, and
   `fitted()` so those quantities cannot drift silently.
5. Add an independent likelihood check against base R or a hand-coded density.
6. Add edge-case tests for the family-specific parameter bounds.

This is a prerequisite for growing the family list without weakening the
package grammar.
