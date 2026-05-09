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
| Gamma | `mu` | log | arithmetic mean of `y` |
| Gamma | `sigma` | log | coefficient of variation; residual SD is `mu * sigma` |
| Poisson | `mu` | log | arithmetic mean and variance of the count response |
| Zero-inflated Poisson | `mu` | log | conditional Poisson mean |
| Zero-inflated Poisson | `zi` | logit | structural-zero probability |
| Negative binomial 2 | `mu` | log | arithmetic mean of the count response |
| Negative binomial 2 | `sigma` | log | overdispersion scale; `Var(y) = mu + sigma^2 * mu^2` |
| Zero-inflated negative binomial 2 | `mu` | log | conditional NB2 count mean |
| Zero-inflated negative binomial 2 | `sigma` | log | conditional NB2 overdispersion scale |
| Zero-inflated negative binomial 2 | `zi` | logit | structural-zero probability |
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
Poisson:    predict(mu) = E[y] = fitted()
ZIP:        predict(mu) = conditional count mean; fitted() = (1 - zi) * mu
NB2:        predict(mu) = E[y] = fitted()
ZINB2:      predict(mu) = conditional count mean; fitted() = (1 - zi) * mu
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

## Implemented Gamma Positive Continuous Contract

For `Gamma(link = "log")`, the implemented first contract is a mean-CV
parameterization:

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

The implementation rejects non-log `stats::Gamma()` links so that the symbolic
equations, `predict()`, and `fitted()` stay aligned. It also deliberately does
not export `gamma()`, because `base::gamma()` is already the special gamma
function.

## Implemented Poisson Count Contract

Counts need log links for the mean. The first implemented count family is a
fixed-effect Poisson mean model:

```text
Poisson:
  y_i ~ Poisson(mu_i)
  log(mu_i) = X_mu[i, ] beta_mu
  E[y_i] = mu_i
  Var[y_i] = mu_i
```

This path has no fitted `sigma` distributional parameter. `sigma(fit)` returns
a fixed unit dispersion vector for base-R method compatibility only. It should
not be interpreted as a modelled residual scale.

The first overdispersed count family is fixed-effect NB2 regression:

```text
Negative binomial 2:
  y_i ~ NB2(mu_i, sigma_i)

  log(mu_i) = X_mu[i, ] beta_mu
  log(sigma_i) = X_sigma[i, ] beta_sigma
  size_i = 1 / sigma_i^2
  E[y_i] = mu_i
  Var[y_i] = mu_i + sigma_i^2 mu_i^2
```

The `nbinom2()` `sigma` parameter is an overdispersion scale, with larger
values meaning greater extra-Poisson variation. This is not the usual NB size
or precision parameter; the implementation uses `size = 1 / sigma^2` in the
`stats::dnbinom(mu = mu, size = size)` mean parameterization.

Zero inflation should use a separate parameter such as `zi`:

```text
logit(zi_i) = X_zi[i, ] beta_zi
```

`zi` is a probability, not a scale parameter. The implemented zero-inflated
Poisson path is:

```text
Zero-inflated Poisson:
  y_i ~ ZIP(mu_i, zi_i)
  log(mu_i) = X_mu[i, ] beta_mu
  logit(zi_i) = X_zi[i, ] beta_zi
  E[y_i] = (1 - zi_i) mu_i
  Var[y_i] = (1 - zi_i) mu_i (1 + zi_i mu_i)
```

For this model, `predict(fit, dpar = "mu")` returns the conditional Poisson
mean and `predict(fit, dpar = "zi")` returns the structural-zero probability.
`fitted(fit)` returns the unconditional response mean `(1 - zi) * mu`.

Zero-inflated NB2 uses the same `zi` contract while retaining the NB2
overdispersion scale:

```text
Zero-inflated negative binomial 2:
  y_i ~ ZINB2(mu_i, sigma_i, zi_i)
  log(mu_i) = X_mu[i, ] beta_mu
  log(sigma_i) = X_sigma[i, ] beta_sigma
  logit(zi_i) = X_zi[i, ] beta_zi
  E[y_i] = (1 - zi_i) mu_i
  Var[y_i] = (1 - zi_i) (mu_i + sigma_i^2 mu_i^2) +
             zi_i (1 - zi_i) mu_i^2
```

## Candidate Beta Proportion Contract

For continuous proportions, `mu` should live in `(0, 1)`:

```text
logit(mu_i) = X_mu[i, ] beta_mu
```

The public scale parameter should be `sigma`, not `phi`. This keeps the grammar
consistent with Gaussian, Student-t, Gamma, lognormal, and NB2 models, where
larger `sigma` means more residual or distributional variation. Internally,
beta precision is:

```text
Beta mean-scale:
  y_i ~ Beta(alpha_i, beta_i)
  logit(mu_i) = X_mu[i, ] beta_mu
  log(sigma_i) = X_sigma[i, ] beta_sigma
  phi_i = 1 / sigma_i^2
  alpha_i = mu_i phi_i
  beta_i = (1 - mu_i) phi_i
  E[y_i] = mu_i
  Var[y_i] = mu_i (1 - mu_i) / (phi_i + 1)
           = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

Matching R syntax:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment),
  family = beta(),
  data = dat
)
```

This parameterization makes `beta()` parallel to `nbinom2()`: both expose
`sigma` as a positive scale and use a reciprocal-squared precision internally.
It also gives a direct comparator transform for packages that report beta
precision:

```text
log(phi_i) = -2 log(sigma_i)
```

Therefore an intercept-only precision coefficient from a mean-precision
package corresponds to `beta_sigma = -0.5 * beta_phi`. Slope coefficients have
the same `-0.5` multiplier when the linear predictors use the same columns.

The beta implementation should reject `y <= 0`, `y >= 1`, non-finite responses,
and missing or unsupported denominator syntax. Boundary responses should be
handled later through zero/one-inflated beta or ordered beta models.

Do not add `phi ~` as a second public grammar without a design decision,
because `sigma` is the package's stable scale name.

For percentages derived from counts, `beta_binomial()` should keep the
denominator rather than forcing users to convert to a continuous proportion.
The public syntax is not settled yet; candidates include
`cbind(successes, failures) ~ predictors` and a two-column successes/trials
interface. The design decision should be made before implementation because it
controls how missing values, totals, and predictions are checked.

## Candidate Truncated and Hurdle Count Contract

Truncated count models describe positive counts:

```text
y_i | y_i > 0, mu_i, sigma_i ~ truncated NB2(mu_i, sigma_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
Pr_trunc(y_i) = Pr_NB2(y_i) / (1 - Pr_NB2(0))
```

Here `mu` and `sigma` describe the untruncated NB2 count component. The
expected observed positive count is the NB2 mean conditional on `y > 0`, so
`fitted()` should document whether it returns that conditional positive-count
mean or another user-facing target.

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment),
  family = truncated_nbinom2(),
  data = dat
)
```

Hurdle models add a separate probability for observing zero:

```text
logit(hu_i) = X_hu[i, ] beta_hu

Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) = (1 - hu_i) Pr_trunc(k | mu_i, sigma_i)
E[y_i] = (1 - hu_i) E_trunc[y_i | y_i > 0]
```

Matching R syntax:

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment, hu ~ survey_method),
  family = truncated_nbinom2(),
  data = dat
)
```

This mirrors the implemented zero-inflation grammar while keeping the
interpretation distinct. Use `zi` when the count distribution can still
generate sampling zeros and the model adds an extra structural-zero process.
Use `hu` when zeros are modelled separately and all nonzero counts come from a
zero-truncated count distribution. The first implementation should not export
separate `hurdle_nbinom2()` or `hurdle_poisson()` constructors unless that
choice is revisited in the formula-grammar design.

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

Before implementing additional count, beta, ordinal, or positive-continuous
families:

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
