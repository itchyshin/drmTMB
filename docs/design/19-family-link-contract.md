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
| Student-t | `mu` | identity | location parameter and arithmetic mean of `y` (`nu = 2 + exp(eta_nu) > 2` is enforced, so the mean always exists) |
| Student-t | `sigma` | log | Student-t scale parameter |
| Student-t | `nu` | `logm2` | degrees of freedom, `nu = 2 + exp(eta_nu)` |
| Skew-normal | `mu` | identity | arithmetic mean of `y` |
| Skew-normal | `sigma` | log | response standard deviation of `y` |
| Skew-normal | `nu` | identity | residual slant/asymmetry; positive values indicate right skew |
| Lognormal | `mu` | identity | mean of `log(y)`, not mean of `y` |
| Lognormal | `sigma` | log | standard deviation of `log(y)` |
| Gamma | `mu` | log | arithmetic mean of `y` |
| Gamma | `sigma` | log | coefficient of variation; residual SD is `mu * sigma` |
| Tweedie | `mu` | log | unconditional arithmetic mean of `y` |
| Tweedie | `sigma` | log | public scale; internal dispersion is `phi = sigma^2` |
| Tweedie | `nu` | `logit12` | Tweedie power, `nu = 1 + plogis(eta_nu)`, constrained to `1 < nu < 2` |
| Beta | `mu` | logit | arithmetic mean of the strict proportion response |
| Beta | `sigma` | log | public scale; internal precision is `phi = 1 / sigma^2` |
| Zero-one beta | `mu` | logit | interior beta mean for continuous `[0, 1]` proportions |
| Zero-one beta | `sigma` | log | public interior beta scale; internal precision is `phi = 1 / sigma^2` |
| Zero-one beta | `zoi` | logit | probability of an exact 0 or exact 1 response |
| Zero-one beta | `coi` | logit | probability of an exact 1 conditional on an exact-boundary response |
| Beta-binomial | `mu` | logit | success probability for counted successes out of known trials |
| Beta-binomial | `sigma` | log | extra-binomial variation scale; internal precision is `phi = 1 / sigma^2` |
| Binomial | `mu` | logit | event probability for 0/1 responses or counted successes out of known trials |
| Cumulative logit | `mu` | identity | latent ordinal location; `fitted()` returns expected category score |
| Poisson | `mu` | log | arithmetic mean and variance of the count response |
| Zero-inflated Poisson | `mu` | log | conditional Poisson mean |
| Zero-inflated Poisson | `zi` | logit | structural-zero probability |
| Negative binomial 2 | `mu` | log | arithmetic mean of the count response |
| Negative binomial 2 | `sigma` | log | overdispersion scale; `Var(y) = mu + sigma^2 * mu^2` |
| Zero-truncated negative binomial 2 | `mu` | log | untruncated NB2 component mean |
| Zero-truncated negative binomial 2 | `sigma` | log | untruncated NB2 overdispersion scale |
| Zero-inflated negative binomial 2 | `mu` | log | conditional NB2 count mean |
| Zero-inflated negative binomial 2 | `sigma` | log | conditional NB2 overdispersion scale |
| Zero-inflated negative binomial 2 | `zi` | logit | structural-zero probability |
| Bivariate Gaussian | `mu1`, `mu2` | identity | arithmetic means of `y1` and `y2` |
| Bivariate Gaussian | `sigma1`, `sigma2` | log | residual standard deviations |
| Bivariate Gaussian | `rho12` | guarded atanh | residual response-response correlation |

## Implemented Plain Binomial Response Contract

The first primary Bernoulli/binomial response family is ordinary logit
binomial, owned by `drmTMB#569`. The public route is deliberately the base R
family:

```r
drmTMB(bf(y01 ~ x), family = stats::binomial(), data = dat)
drmTMB(bf(cbind(successes, failures) ~ x), family = stats::binomial(), data = dat)
```

The first slice has one distributional parameter:

| Family | Parameter | Link | Response-scale meaning |
|---|---|---|---|
| Binomial | `mu` | logit | event probability; `fitted()` returns `mu` |

The statistical contract is:

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = eta_i = X_mu[i, ] beta_mu
```

For a 0/1 response, `n_i = 1` and `Y_i` is the event indicator. For
`cbind(successes, failures)`, `Y_i = successes_i` and
`n_i = successes_i + failures_i`. The implementation includes the
binomial normalizing constant so `logLik()`, AIC, and BIC match
`stats::glm()` on overlapping fixed-effect logit models.

The first slice rejects non-logit links, factor-response ordering,
proportions plus `weights`, `weights = trials`, `successes / trials`, `sigma`,
`nu`, `zi`, `zoi`, `coi`, random effects, structured effects, bivariate or
mixed responses, and `engine = "julia"`. Top-level `weights` remain likelihood
weights, not trial totals.

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
Skew-normal: predict(mu) = E[y] = fitted(); predict(nu) = residual slant
Lognormal:  predict(mu) = E[log(y)]; fitted() = exp(mu + sigma^2 / 2)
Poisson:    predict(mu) = E[y] = fitted()
Beta:       predict(mu) = E[y] = fitted()
Zero-one beta: predict(mu) = E[y | 0 < y < 1]; fitted() = (1 - zoi) * mu + zoi * coi
ZIP:        predict(mu) = conditional count mean; fitted() = (1 - zi) * mu
NB2:        predict(mu) = E[y] = fitted()
Trunc NB2:  predict(mu) = untruncated component mean; fitted() = mu / (1 - Pr_NB2(0))
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

## Implemented Tweedie Semicontinuous Contract

For `tweedie()`, the first implementation is a univariate fixed-effect
compound Poisson-Gamma model for non-negative responses with exact zeros:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
nu_i = 1 + plogis(eta_nu_i)
phi_i = sigma_i^2
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

Here `sigma` is the square root of the usual Tweedie dispersion `phi`, not
`phi` itself. `fitted()` returns the unconditional mean `mu`, including the
exact-zero mass, and `sigma(fit)` returns public `sigma`. The first slice keeps
`nu ~ 1` intercept-only; predictor-dependent power models, random effects,
structured effects, bivariate Tweedie models, zero-inflation aliases, and
hurdle aliases remain separate gates.

## Implemented Skew-Normal Continuous Contract

For `skew_normal()`, the first implementation is a univariate fixed-effect
moment-parameterized skew-normal model:

```text
y_i | mu_i, sigma_i, nu_i ~ SkewNormalMoment(mu_i, sigma_i, nu_i)
eta_mu_i = X_mu[i, ] beta_mu
eta_sigma_i = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
mu_i = eta_mu_i
sigma_i = exp(eta_sigma_i)
nu_i = eta_nu_i
delta_i = nu_i / sqrt(1 + nu_i^2)
omega_i = sigma_i / sqrt(1 - 2 * delta_i^2 / pi)
xi_i = mu_i - omega_i * delta_i * sqrt(2 / pi)
z_i = (y_i - xi_i) / omega_i
log f(y_i) = log(2) - log(omega_i) + log phi(z_i) + log Phi(nu_i z_i)
```

Here `mu` is the arithmetic response mean and `sigma` is the response standard
deviation by construction. The native density scale is `xi`, `omega`, and
`alpha = nu`, but those are implementation details rather than user-facing
distributional parameters. `fitted()` returns `mu`, `sigma(fit)` returns public
`sigma`, and `predict(fit, dpar = "nu")` returns the residual slant on the
identity scale. Positive `nu` indicates right-skewed residuals, negative `nu`
indicates left-skewed residuals, and `nu = 0` reduces to the Gaussian
location-scale likelihood.

The first route rejects random effects, structured effects, known sampling
covariance, bivariate responses, residual `rho12`, aliases such as `skew ~ x`,
and latent `skew(id)` syntax. Those neighbours need their own likelihood,
diagnostic, interval, and recovery evidence before they can share this
contract.

## Implemented Poisson Count Contract

Counts need log links for the mean. The first implemented count family is a
fixed-effect Poisson mean model:

```text
Poisson:
  y_i ~ Poisson(mu_i)
  log(mu_i) = o_i + X_mu[i, ] beta_mu
  E[y_i] = mu_i
  Var[y_i] = mu_i
```

Here `o_i` is a known offset supplied by standard R formula syntax such as
`offset(log(trap_nights))`; if no offset is present, `o_i = 0`. This preserves
the familiar exposure/rate convention from `glm()` while keeping the public
parameter as the expected count `mu_i`.

This path has no fitted `sigma` distributional parameter. `sigma(fit)` returns
a fixed unit dispersion vector for base-R method compatibility only. It should
not be interpreted as a modelled residual scale.

The first overdispersed count family is fixed-effect NB2 regression:

```text
Negative binomial 2:
  y_i ~ NB2(mu_i, sigma_i)

  log(mu_i) = o_i + X_mu[i, ] beta_mu
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
  log(mu_i) = o_i + X_mu[i, ] beta_mu
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
  log(mu_i) = o_i + X_mu[i, ] beta_mu
  log(sigma_i) = X_sigma[i, ] beta_sigma
  logit(zi_i) = X_zi[i, ] beta_zi
  E[y_i] = (1 - zi_i) mu_i
  Var[y_i] = (1 - zi_i) (mu_i + sigma_i^2 mu_i^2) +
             zi_i (1 - zi_i) mu_i^2
```

## Implemented Beta Proportion Contract

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

The implemented beta path rejects `y <= 0`, `y >= 1`, and non-finite
responses. Boundary responses should use `zero_one_beta()` when exact zeroes or
ones are structural outcomes rather than denominator outcomes.

Do not add `phi ~` as a second public grammar without a design decision,
because `sigma` is the package's stable scale name.

For continuous proportions with exact structural zeroes or ones,
`zero_one_beta()` adds two fixed-effect boundary parameters:

```r
drmTMB(
  bf(prop ~ habitat, sigma ~ treatment, zoi ~ drought, coi ~ canopy),
  family = zero_one_beta(),
  data = dat
)
```

The interior beta component uses `mu` and `sigma` as above. `zoi` is the
probability that an observation is exactly 0 or exactly 1; `coi` is the
conditional probability that a boundary observation is exactly 1. The fitted
response is therefore:

```text
fitted_i = (1 - zoi_i) mu_i + zoi_i coi_i
```

This is a fixed-effect first slice. Boundary random effects, covariance blocks,
known sampling covariance, bivariate zero-one beta models, and denominator
syntax remain outside the fitted surface.

For percentages derived from counts, `beta_binomial()` keeps the denominator
rather than forcing users to convert to a continuous proportion:

```text
y_i | n_i, p_i ~ Binomial(n_i, p_i)
p_i | mu_i, sigma_i ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
E[y_i / n_i] = mu_i
Var(y_i / n_i) =
  mu_i (1 - mu_i) (1 + n_i sigma_i^2) /
  (n_i (1 + sigma_i^2))
```

The implemented syntax is `cbind(successes, failures) ~ predictors`; `n_i` is
the row total. `fitted()` returns the success probability `mu`, and
`sigma(fit)` returns the public extra-binomial variation scale. A two-column
successes/trials interface remains a possible later alias, with design
guardrails in `docs/design/24-denominator-response-syntax.md`.

## Implemented Truncated Count Contract

Truncated count models describe positive counts:

```text
y_i | y_i > 0, mu_i, sigma_i ~ truncated NB2(mu_i, sigma_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
Pr_trunc(y_i) = Pr_NB2(y_i) / (1 - Pr_NB2(0))
E[y_i | y_i > 0] = mu_i / (1 - Pr_NB2(0))
```

Here `mu` and `sigma` describe the untruncated NB2 count component. The
expected observed positive count is the NB2 mean conditional on `y > 0`.
`predict(fit, dpar = "mu")` returns the untruncated component mean, while
`fitted(fit)` returns `mu / (1 - Pr_NB2(0))`.

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
zero-truncated count distribution. The implemented NB2 hurdle path does not
export a separate `hurdle_nbinom2()` constructor; any future
`hurdle_poisson()` constructor would need a separate formula-grammar decision.

## Implemented Cumulative-Logit Ordinal Contract

Ordinal models introduce cutpoints. Cutpoints are direct model parameters, not
ordinary fixed-effect formulas in the first implementation.

First univariate ordinal path:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

This MVP fixes the latent logistic scale and exposes only the location formula.
The location intercept is removed internally because a free intercept and free
cutpoints are not jointly identifiable. `predict(fit, dpar = "mu")` returns
the latent location, while `fitted(fit)` returns the expected ordered-category
score `sum_k k * Pr(y_i = k)`.

An ordinal scale or discrimination formula remains planned. One candidate is:

```text
Pr(y_i <= k) = logit^{-1}((theta_k - mu_i) / sigma_i)
log(sigma_i) = X_sigma[i, ] beta_sigma
```

With this convention, larger `sigma_i` spreads the latent cumulative
distribution across cutpoints and means less consistent ordinal outcomes. A
discrimination or consistency summary can be reported as `zeta_i = 1 / sigma_i`.
This matches the seabird nest-success example of Ortega et al. (2026), where
higher discrimination means clearer separation among ordered fledging
categories.

An alternative implementation could expose a native `zeta` parameter directly,
but that would require an explicit formula-grammar decision. Do not silently
reuse `sigma` for a parameter where larger values mean more consistency unless
the documentation and tests make that direction unavoidable.

Bivariate ordinal correlation is a research project because the latent
correlation is harder to identify and validate. The planned scale direction and
acceptance criteria are recorded in
`docs/design/25-ordinal-scale-discrimination.md`.

## Implementation Checklist Before New Families

Before implementing additional count, beta, ordinal-scale, or
positive-continuous families:

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
