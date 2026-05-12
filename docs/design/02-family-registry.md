# Family Registry

Each family should be represented by a small structured object.

## Required Fields

- `name`
- `n_response`
- `dpars`
- `links`
- `inverse_links`
- `bounds`
- `density_id`
- `simulate`
- `starting_values`
- `check_data`
- `native_parameter_meaning`
- `fitted_response_rule`
- `variance_rule`

## Link and Response-Scale Contract

Distributional parameter names do not determine links by themselves. For
Gaussian and Student-t models, `mu` currently uses an identity link and
`fitted()` returns `mu`. For lognormal models, `mu` is still identity-link on
the modelled parameter, but the modelled parameter is the mean of `log(y)`;
`fitted()` returns `exp(mu + sigma^2 / 2)` instead.

Families must declare both the native parameter scale and the fitted response
rule. The implemented Gamma mean-CV family uses `log(mu)` and `log(sigma)`,
with `sigma` interpreted as a coefficient of variation. The implemented
Poisson mean family uses `log(mu)` and has no fitted `sigma` distributional
parameter. The implemented zero-inflated Poisson extension uses the same
Poisson route with `logit(zi)` and `fitted()` returning `(1 - zi) * mu`. The
implemented negative-binomial 2 family uses `log(mu)` and `log(sigma)`, with
`sigma` interpreted as an overdispersion scale; its zero-inflated extension
adds `logit(zi)` and the same fitted-response rule `(1 - zi) * mu`. Beta and
beta-binomial models use `logit(mu)` and `log(sigma)`, with `sigma` mapped to
internal precision through `phi = 1 / sigma^2`. The first cumulative-logit
ordinal path uses an identity-link latent `mu`, ordered cutpoints, and
`fitted()` returning the expected ordered-category score.

The detailed contract is in `docs/design/19-family-link-contract.md`. Treat it
as a prerequisite before implementing additional count, ordinal-scale,
denominator-aware, or positive-continuous families.

## Distributional Parameter Naming

Use the GAMLSS convention from Rigby and Stasinopoulos (2005) as the default
parameter vocabulary:

- `mu`: location or mean-like parameter;
- `sigma`: residual scale, dispersion, or standard-deviation-like parameter;
- `nu`: first shape parameter;
- `tau`: second shape parameter.

The interpretation of `nu` and `tau` is family specific. In a skew-normal-like
family, `nu` can be the skewness/shape parameter. In a Student-t-like family,
`nu` may instead be tail shape or degrees of freedom. In a skew-t family, the
preferred direction is `mu`, `sigma`, `nu`, and `tau`, with documentation
explaining which shape controls asymmetry and which controls tails.

For a future Tweedie family, `nu` should be considered for the power parameter
constrained between 1 and 2, while `sigma` should stay the public scale or
dispersion parameter only after a design note fixes the final mapping. The
current working recommendation is `sigma = sqrt(phi)`, so Tweedie variance
would be reported to users as `Var[y] = sigma^2 * mu^nu` while comparator tests
against software that reports Tweedie `phi` would square public `sigma`
explicitly. Do not add comparator tests against related software until that
scale convention is confirmed.

Human-readable aliases such as `skew` or `df` can be considered later, but the
canonical internal and documented names should stay consistent unless there is a
strong reason not to.

## Implemented: Gaussian Location-Scale

The first implementation accepts `stats::gaussian()` and maps it internally to:

```r
drm_family(
  name = "gaussian",
  n_response = 1,
  dpars = c("mu", "sigma"),
  links = c(mu = "identity", sigma = "log")
)
```

This is implemented for fixed-effect models, univariate Gaussian `mu` random
intercepts, independent numeric `mu` random slopes, one-slope correlated `mu`
random intercept-slope blocks with optional covariance-block labels,
univariate Gaussian residual-scale random intercepts and independent random
slopes in `sigma`, and optional
known sampling covariance through `meta_known_V(V = V)`. Random-effect scale
formulae such as `sd(id) ~ x_group` and `sd(site) ~ site_type` are implemented
for distinct unlabelled Gaussian `mu` random intercepts. Sparse known
covariance, correlated residual-scale slope blocks, slope-specific or labelled
random-effect scale formulae, and additional families are later phases.

## Implemented: Student-t Location-Scale-Shape

The first robust continuous family is univariate and fixed-effect only:

```r
student <- function() {
  drm_family(
    name = "student",
    n_response = 1,
    dpars = c("mu", "sigma", "nu"),
    links = c(mu = "identity", sigma = "log", nu = "logm2")
  )
}
```

The response-scale degrees of freedom are
`nu_i = 2 + exp(eta_nu_i)`. This keeps the model in the finite-variance region
and makes Student-t a robust continuous extension of the Gaussian
location-scale MVP. Random effects, known sampling covariance, phylogenetic
terms, and bivariate Student-t models are later phases.

## Planned: Skew-Normal Location-Scale-Shape

The first skew-normal family is planned as a univariate fixed-effect path:

```r
skew_normal <- function() {
  drm_family(
    name = "skew_normal",
    n_response = 1,
    dpars = c("mu", "sigma", "nu"),
    links = c(mu = "identity", sigma = "log", nu = "identity")
  )
}
```

This contract treats `mu` as the native skew-normal location parameter,
`sigma` as positive residual scale, and `nu` as the unrestricted native
asymmetry shape used in the density in `docs/design/03-likelihoods.md`.
Positive `nu` means right-skewed residuals, `nu = 0` reduces to the Gaussian
location-scale likelihood, and negative `nu` means left-skewed residuals. This
sign convention is a design assumption until checked against the first trusted
comparator.

Random effects, known sampling covariance, phylogenetic terms, spatial terms,
bivariate skew-normal models, `rho12`, and aliases such as `skew ~ x` are later
phases. Examples and reference documentation should teach canonical `nu ~ x`
before any alias is added.

## Implemented: Lognormal Location-Scale

The first positive continuous family is univariate and fixed-effect only:

```r
lognormal <- function() {
  drm_family(
    name = "lognormal",
    n_response = 1,
    dpars = c("mu", "sigma"),
    links = c(mu = "identity", sigma = "log")
  )
}
```

The fitted distribution is Gaussian on the log-response scale:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
```

Here `mu` is the mean of `log(y)`, not the arithmetic mean of `y`. The
response-scale mean is `exp(mu_i + sigma_i^2 / 2)`, which is what `fitted()`
returns for lognormal fits. Random effects, known sampling covariance,
phylogenetic terms, and bivariate or mixed lognormal models are later phases.

## Implemented: Gamma Mean-CV

The first Gamma path uses the existing R family constructor rather than
exporting `gamma()`, which would mask `base::gamma()`:

```r
family = Gamma(link = "log")
```

The implemented model is fixed-effect, univariate, and positive-response only:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
```

Here `mu` is the expected response. `sigma` is the coefficient of variation,
not the residual standard deviation; the residual standard deviation is
`mu_i * sigma_i`. Non-log `Gamma()` links, random effects, known sampling
covariance, phylogenetic terms, and bivariate or mixed Gamma models are later
phases.

## Implemented: Beta Mean-Scale

`beta()` is the first strict-proportion family:

```r
family = beta()
```

The implemented model is fixed-effect, univariate, and requires response
values strictly inside `(0, 1)`:

```text
y_i | mu_i, sigma_i ~ Beta(alpha_i, beta_i)
logit(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
phi_i = 1 / sigma_i^2
alpha_i = mu_i phi_i
beta_i = (1 - mu_i) phi_i
E[y_i] = mu_i
Var[y_i] = mu_i (1 - mu_i) sigma_i^2 / (1 + sigma_i^2)
```

Here `mu` is the mean proportion. `sigma` is the public scale parameter, not
beta precision. Internally, `phi = 1 / sigma^2`, so larger `sigma` means more
variation around the mean. Boundary responses equal to 0 or 1, random effects,
known sampling covariance, phylogenetic terms, and bivariate or mixed beta
models are later phases.

## Implemented: Beta-Binomial Mean-Overdispersion

`beta_binomial()` keeps denominators inside the likelihood for counted
successes and failures:

```r
family = beta_binomial()
```

The implemented model is fixed-effect and univariate:

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

The response syntax is `cbind(successes, failures) ~ predictors`; `n_i` is the
row total. Counts must be finite non-negative integers and each row must have
positive trials. `fitted()` returns the success probability `mu`,
`sigma(fit)` returns the public extra-binomial variation scale, and
`simulate()` returns success counts for the fitted trial totals. Random
effects, known sampling covariance, phylogenetic terms, bivariate or mixed
beta-binomial models, and a possible successes/trials response alias are later
phases. The alias design guardrails are in
`docs/design/24-denominator-response-syntax.md`.

## Implemented: Cumulative-Logit Ordinal Location

`cumulative_logit()` is the first ordinal family:

```r
family = cumulative_logit()
```

The implemented model is fixed-effect, univariate, and location-only:

```text
Pr(y_i <= k) = logit^{-1}(theta_k - mu_i)
mu_i = X_mu[i, ] beta_mu
theta_1 < theta_2 < ... < theta_{K-1}
```

The response must be an ordered factor or finite integer category scores
`1, ..., K`, and every category must appear after missing-row filtering. The
location intercept is dropped internally because a free intercept and free
cutpoints are not jointly identifiable. With ordinary treatment contrasts,
factor predictors keep their contrast columns after the intercept is removed.

Here `mu` is a latent ordinal location, not an arithmetic response mean.
`fitted()` returns the expected ordered-category score
`sum_k k * Pr(y_i = k)`, and `simulate()` returns ordered factors with the
fitted category labels. `sigma(fit)` returns a fixed unit vector because this
MVP has no fitted ordinal scale parameter. Ordinal scale or discrimination
formulas, random effects, known sampling covariance, phylogenetic terms,
bivariate ordinal models, and mixed-response ordinal models are later phases.
The scale/discrimination direction is recorded in
`docs/design/25-ordinal-scale-discrimination.md`.

## Implemented: Poisson Mean

The first count path uses the existing R family constructor:

```r
family = poisson(link = "log")
```

The implemented model is fixed-effect and univariate:

```text
y_i | mu_i ~ Poisson(mu_i)
log(mu_i) = o_i + X_mu[i, ] beta_mu
E[y_i] = Var[y_i] = mu_i
```

For exposure models, `o_i` is a known offset from standard R syntax such as
`offset(log(trap_nights))`; otherwise `o_i = 0`.

This path is mostly a baseline count-regression model and a comparator for
later overdispersed count families. It deliberately has no fitted `sigma`
distributional parameter. `sigma(fit)` returns a fixed unit dispersion vector
for base-R method compatibility, not a modelled residual scale. Random effects,
known sampling covariance, overdispersion, phylogenetic terms, and bivariate or
mixed Poisson models are later phases.

The same Poisson route also supports fixed-effect structural-zero regression by
adding a `zi` formula:

```r
family = poisson(link = "log")
drm_formula(count ~ habitat + offset(log(trap_nights)), zi ~ treatment)
```

Here `mu` is the conditional Poisson mean and `zi` is the structural-zero
probability:

```text
log(mu_i) = o_i + X_mu[i, ] beta_mu
logit(zi_i) = X_zi[i, ] beta_zi
E[y_i] = (1 - zi_i) mu_i
```

There is intentionally no exported `zi_poisson()` constructor at this stage;
zero inflation is a distributional parameter of the existing Poisson family.

## Implemented: Negative Binomial 2 Mean-Dispersion

`nbinom2()` is the first overdispersed count family:

```r
family = nbinom2()
```

The implemented model is fixed-effect and univariate:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
log(mu_i) = o_i + X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

Here `sigma` is an extra-Poisson scale, not a residual standard deviation and
not the native NB size or precision parameter. Larger `sigma` means greater
overdispersion. This direction is deliberate so `sigma` continues to mean
"more scale" across `drmTMB` families.

Adding `zi ~ predictors` fits the implemented zero-inflated NB2 extension:

```text
log(mu_i) = o_i + X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
logit(zi_i) = X_zi[i, ] beta_zi
E[y_i] = (1 - zi_i) mu_i
```

Random effects, known sampling covariance, phylogenetic terms, and bivariate
or mixed negative-binomial models are later phases.

## Implemented: Zero-Truncated Negative Binomial 2 Mean-Dispersion

`truncated_nbinom2()` handles positive counts where zero is absent by design:

```r
family = truncated_nbinom2()
```

The implemented model is fixed-effect and univariate:

```text
y_i | y_i > 0, mu_i, sigma_i ~ NB2(mu_i, size_i) truncated at zero
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
size_i = 1 / sigma_i^2
Pr(y_i = k | y_i > 0) = Pr_NB2(y_i = k) / (1 - Pr_NB2(0))
E[y_i | y_i > 0] = mu_i / (1 - Pr_NB2(0))
```

Here `mu` and `sigma` describe the untruncated NB2 component. This keeps the
count-scale `sigma` interpretation aligned with `nbinom2()`, while `fitted()`
returns the observed positive-count mean.

Adding `hu ~ predictors` fits the implemented hurdle NB2 extension:

```text
logit(hu_i) = X_hu[i, ] beta_hu
Pr(y_i = 0) = hu_i
Pr(y_i = k > 0) =
  (1 - hu_i) Pr_NB2(y_i = k | y_i > 0, mu_i, sigma_i)
E[y_i] = (1 - hu_i) mu_i / (1 - Pr_NB2(0))
```

```r
drmTMB(
  bf(count ~ habitat, sigma ~ treatment, hu ~ survey_method),
  family = truncated_nbinom2(),
  data = dat
)
```

Use `hu` when zeros are generated by a separate hurdle process and all nonzero
counts are positive-count observations. Use `zi` when the count distribution
can itself still generate sampling zeros and the model adds extra structural
zeros.

## Implemented: Bivariate Gaussian Location-Coscale

The stable public direction for two-response models is composed response
families:

```r
family = c(gaussian(), gaussian())
family = list(gaussian(), gaussian())
```

Mixed ecological responses such as body mass plus fecundity counts remain a
planned use case. A composed family must still declare a coherent joint
likelihood and state what `rho12` means: observed residual correlation, latent
residual correlation, a copula parameter, or unsupported. The all-Gaussian
composed case is implemented for both `c()` and `list()` spellings and routes
to the same likelihood as `biv_gaussian()`. The `biv_gaussian()` object remains
a convenience and internal testing target, not a commitment to one named family
for every response combination.

```r
biv_gaussian <- function() {
  drm_family(
    name = "biv_gaussian",
    n_response = 2,
    dpars = c("mu1", "mu2", "sigma1", "sigma2", "rho12"),
    links = c(
      mu1 = "identity",
      mu2 = "identity",
      sigma1 = "log",
      sigma2 = "log",
      rho12 = "atanh_guarded"
    )
  )
}
```

This family is implemented for fixed-effect models with separate location,
scale, and residual-correlation formulas:

```r
bf(
  mu1 = y1 ~ x1 + x2,
  mu2 = y2 ~ x1,
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

`rho12` uses a guarded atanh-style link internally:
`rho12 = 0.99999999 * tanh(eta_rho12)` on the response scale.
`mvbind(y1, y2) ~ x` is implemented as shorthand for identical `mu1` and
`mu2` location formulas. Bivariate random effects are planned but not
implemented.

## Design Principle

Do not expose a large distribution zoo before the fitting, prediction,
simulation, and diagnostic machinery is stable.
