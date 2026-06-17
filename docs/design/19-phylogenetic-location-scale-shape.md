# Phylogenetic Location-Scale-Shape Models

This note records the cautious design direction for future shape models in
`drmTMB`. It is a planning note, not an implemented feature contract.

## Core Position

Shape models should build on the implemented Gaussian and Student-t
location-scale paths. In `drmTMB`, a shape parameter should be treated like any
other distributional parameter, but it is harder to interpret and harder to
identify than `sigma`.

For a skew-normal-like family:

```text
y_i ~ SkewNormal(mu_i, sigma_i, nu_i)
mu_i = X_mu[i, ] beta_mu
log(sigma_i) = X_sigma[i, ] beta_sigma
eta_nu_i = X_nu[i, ] beta_nu
nu_i = inverse_link_nu(eta_nu_i)
```

Matching future R syntax:

```r
drmTMB(
  bf(y ~ x1, sigma ~ x2, nu ~ x3),
  family = skew_normal(),
  data = dat
)
```

The family documentation must explain what `nu` means for that likelihood. It
should not assume that `nu` is universally interpretable as biological
skewness.

## Why Shape Is Harder Than Scale

Scale has a stable role in the current Gaussian implementation:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma
```

Shape is family-specific. The same observed asymmetry can arise from skewed
residuals, heterogeneous residual SDs, non-Gaussian random effects, selective
disappearance, outliers, unmodelled predictors, or mixtures of subgroups. A
shape formula can therefore be scientifically useful, but it can also absorb
misspecified scale or location structure.

For phylogenetic models, this risk is larger. A species-level skewness
parameter usually requires within-species distributions, not only one species
mean. A phylogenetic shape model for species averages should not be advertised
without a specific likelihood and simulation evidence.

## Naming

Use the GAMLSS-style names:

```text
mu     location
sigma  scale
nu     first shape parameter
tau    second shape parameter
```

For `skew_normal()`, `nu` can be the asymmetry parameter if the family help page
documents the mapping to the native skew-normal parameterization.

For `skew_t()`, `nu` and `tau` must be assigned explicitly in the family help
page. One should control asymmetry and the other tail shape. Do not rely on the
names alone to communicate the biology.

Aliases such as `skew ~ x` or `shape ~ x` may be considered after the canonical
grammar is stable, but examples should teach `nu` first.

## Residual Versus Latent-Effect Skewness

The first skewness target is residual or observation-level asymmetry:

```r
bf(y ~ x1, sigma ~ x2, nu ~ x3)
```

Here `nu ~ x3` changes the conditional residual or response distribution for
each observation. In the fixed-effect `skew_normal()` first slice, that means
the fitted residual density is asymmetric after accounting for `mu` and
`sigma`; phylogenetic skew-normal shape models remain future work.

A different question is whether the distribution of a latent group effect is
asymmetric. A possible future spelling is:

```r
skew(id) ~ x_group
```

That would be analogous to `sd(id) ~ x_group`, but it would model the shape of
the `id` random-effect distribution rather than the residual distribution.
This is scientifically useful for ID-level skewness, but it is not the same
parameter as residual `nu`. Do not implement both in the same slice: skewed
residuals, heteroscedastic residuals, and skewed random effects can mimic each
other unless the data include enough within-group replication and the
simulation design separates those mechanisms.

## Staged Implementation

1. Harden the implemented fixed-effect `student()` path with `mu`, `sigma`,
   and tail `nu`.
2. Implement fixed-effect `skew_normal()` with `mu`, `sigma`, and `nu`.
3. Add skew-normal `nu ~ predictors` only after density, simulation,
   prediction, and residual diagnostics are stable.
4. Implement Gaussian phylogenetic `mu` and `sigma` before any phylogenetic
   shape model.
5. Fit skew-normal models with phylogenetic `mu` or `sigma` but fixed `nu`.
6. Explore phylogenetic, species-level, or group-level effects in `nu` only
   when data include enough within-species or within-group replication.
7. Implement `skew_t()` last because asymmetry and tail shape can trade off.
8. Treat ID-level skewness grammar such as `skew(id) ~ x` as a separate later
   family of latent-effect models, not as an alias for residual `nu ~ x`.

## Minimum Tests

Before release, shape families need:

- density checks against trusted reference implementations;
- simulation checks for positive and negative asymmetry;
- normal-limit tests where the shape parameter reduces to a Gaussian-like case;
- false-positive tests where data are Gaussian but heteroscedastic;
- separation tests where both `sigma ~ x` and `nu ~ x` are present;
- stress tests for sparse species replication before any phylogenetic shape
  model is promoted.

## Sources To Keep Connected

Local sources:

```text
/Users/z3437171/Downloads/s41559-022-01694-2.pdf
/Users/z3437171/Downloads/journal.pbio.3003653.pdf
/Users/z3437171/Desktop/dis_reg_models/Phylogenetic_location_scale_shape_models.pdf
/Users/z3437171/Desktop/dis_reg_models/Royal Stata Society Series C - 2005 - Rigby - Generalized additive models for location scale and shape.pdf
```

The PLOS Biology paper on meta-analysing differences in skewness, kurtosis, and
correlation belongs in the same evidence set. It should inform future
meta-analytic shape examples, but it does not change the immediate
implementation order.
