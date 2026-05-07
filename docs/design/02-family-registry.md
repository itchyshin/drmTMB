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

## Distributional Parameter Naming

Use the GAMLSS convention from Rigby and Stasinopoulos (2005) as the default
parameter vocabulary:

- `mu`: location or mean-like parameter;
- `sigma`: residual scale, dispersion, or standard-deviation-like parameter;
- `nu`: first shape parameter;
- `tau`: second shape parameter.

The interpretation of `nu` and `tau` is family specific. In a skew-normal-like
family, `nu` can be the skewness/shape parameter. In a Student-t-like family,
`nu` may instead be tail weight or degrees of freedom. In a skew-t family, the
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

This is implemented for fixed-effect models, optional univariate simple `mu`
random effects, and optional known sampling covariance through
`meta_known_V(V = V)`. Sparse known covariance and additional families are later
phases.

## Implemented: Bivariate Gaussian Location-Coscale

The stable public direction for two-response models is composed response
families:

```r
family = c(gaussian(), gaussian())
family = c(gaussian(), poisson())
```

This is easier for mixed ecological responses such as body mass plus fecundity
counts. A composed family must still declare a coherent joint likelihood and
state what `rho12` means: observed residual correlation, latent residual
correlation, a copula parameter, or unsupported. The current `biv_gaussian()`
object is the implemented all-Gaussian prototype and a useful internal testing
target, not a commitment to one named family for every response combination.

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
      rho12 = "atanh"
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

`rho12` uses an atanh link internally and `tanh()` on the response scale.
Univariate Gaussian simple `mu` random effects are implemented; bivariate
random effects and `mvbind()` shorthand are planned but not implemented.

## Design Principle

Do not expose a large distribution zoo before the fitting, prediction,
simulation, and diagnostic machinery is stable.
