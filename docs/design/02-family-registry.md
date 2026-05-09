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
adds `logit(zi)` and the same fitted-response rule `(1 - zi) * mu`. Beta
models would use `logit(mu)`.

The detailed contract is in `docs/design/19-family-link-contract.md`. Treat it
as a prerequisite before implementing additional count, beta, ordinal, or
positive-continuous families.

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
univariate Gaussian residual-scale random intercepts in `sigma`, and optional
known sampling covariance through `meta_known_V(V = V)`. Random-effect scale
formulae such as `sd(id) ~ x_group` and `sd(site) ~ site_type` are implemented
for distinct unlabelled Gaussian `mu` random intercepts. Sparse known
covariance, residual-scale random slopes, slope-specific or labelled
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
variation around the mean. Boundary responses equal to 0 or 1, denominator
syntax such as `cbind(successes, failures)`, random effects, known sampling
covariance, phylogenetic terms, and bivariate or mixed beta models are later
phases.

## Implemented: Poisson Mean

The first count path uses the existing R family constructor:

```r
family = poisson(link = "log")
```

The implemented model is fixed-effect and univariate:

```text
y_i | mu_i ~ Poisson(mu_i)
log(mu_i) = X_mu[i, ] beta_mu
E[y_i] = Var[y_i] = mu_i
```

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
drm_formula(count ~ habitat, zi ~ treatment)
```

Here `mu` is the conditional Poisson mean and `zi` is the structural-zero
probability:

```text
log(mu_i) = X_mu[i, ] beta_mu
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
log(mu_i) = X_mu[i, ] beta_mu
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
log(mu_i) = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
logit(zi_i) = X_zi[i, ] beta_zi
E[y_i] = (1 - zi_i) mu_i
```

Random effects, known sampling covariance, hurdle components, phylogenetic
terms, and bivariate or mixed negative-binomial models are later phases.

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
