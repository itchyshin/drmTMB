# Random Effects

Random effects are implemented after fixed-effect likelihoods are tested, but
the grammar must support them from the start.

## Order of Implementation

1. No random effects.
2. Random intercepts in location. Implemented for univariate Gaussian `mu`.
3. Random slopes in location.
4. Random intercepts in scale.
5. Random-effect scale formulae such as `sd(id) ~ x`.
6. Correlations among location and scale random effects when identifiable.

## Initial Syntax

Implemented:

```r
bf(
  y ~ x1 + (1 | id),
  sigma ~ x1
)
```

Also implemented for multiple additive grouping factors:

```r
bf(
  y ~ x1 + (1 | site) + (1 | observer),
  sigma ~ x1
)
```

Current implementation details:

- supported only for univariate Gaussian `mu`;
- random effects are integrated with TMB's Laplace approximation;
- the TMB parameterization is non-centered:
  `b_{group} = sd_group * u_group`, where `u_group ~ Normal(0, 1)`;
- fitted-data `predict(fit, dpar = "mu")` includes conditional modes;
- `newdata` prediction currently uses fixed effects only;
- grouping variables with fewer than two levels or only singleton groups are
  rejected.

Double-hierarchical syntax should be explicit:

```r
bf(
  y ~ x1 + (1 | id),
  sigma ~ x1,
  sd(id) ~ x1
)
```

Multiple random-effect variance components get separate `sd()` formulas:

```r
bf(
  y ~ x1 + x2 + (1 | id1) + (1 | id2),
  sd(id1) ~ x1,
  sd(id2) ~ x1 + x2
)
```

This models the standard deviations of the two random-effect components. It
does not put random effects inside the residual `sigma` model.

## Correlation Blocks

`drmTMB` follows brms-style group-level ID syntax:

```r
(1 + x1 | p | id)
```

The middle label `p` ties terms into a shared group-level covariance block.
When the same label appears in multiple parameter formulas, for example in
`mu` and `sigma`, the model estimates constant correlations among those
group-level effects. These are the correlations used in O'Dea-style
double-hierarchical models for personality, plasticity, and predictability.

Residual `rho12 ~` is separate and belongs to bivariate response likelihoods.
It models the residual coupling between two responses after their location and
scale predictors have been accounted for.

## O'Dea Correlation Taxonomy

The O'Dea et al. double-hierarchical framework distinguishes correlations among
individual differences:

- personality: random intercepts in mean models;
- plasticity: random slopes in mean models;
- predictability: random intercepts in dispersion or scale models;
- malleability: random slopes in dispersion or scale models.

In bivariate models these can produce behavioural syndromes, plasticity
syndromes, predictability syndromes, and cross-associations among personality,
plasticity, predictability, and malleability. These are group-level covariance
parameters and should be named/extracted as group-level correlations, not as
`rho12`.

Initial random-intercept/slope correlations should be constant covariance-block
parameters. Predictor-dependent correlation formulae should be reserved for
residual or response-level `rho12` until identifiability is demonstrated.

## Scale Naming

Use `sigma`, `sigma1`, and `sigma2` for residual or within-observation scale.
Use group-level names for random-effect scale components, for example
`sd_mu_intercept(ID)`, `sd_mu_slope(ID)`, and their correlation. In an
O'Dea-style bivariate model, each response can therefore have multiple scale
quantities: at least the random-intercept SD, the random-slope SD, and the
residual `sigma`. These should not be collapsed into one `sigma` namespace.

## Numerical Caution

Random-effect variance components are often weakly identified, especially near
zero. Simulation tests must include small group counts, sparse groups, and
boundary cases.
