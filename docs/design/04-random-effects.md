# Random Effects

Random effects are implemented after fixed-effect likelihoods are tested, but
the grammar must support them from the start.

## Order of Implementation

1. No random effects.
2. Random intercepts in location. Implemented for univariate Gaussian `mu`.
3. Simple numeric random slopes in location. Implemented for univariate
   Gaussian `mu` as separate uncorrelated terms.
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

Also implemented for simple numeric random slopes in `mu`:

```r
bf(
  y ~ x1 + (0 + x1 | id),
  sigma ~ x1
)
```

To fit an independent random intercept and random slope in the current
implementation, write them as separate terms:

```r
bf(
  y ~ x1 + (1 | id) + (0 + x1 | id),
  sigma ~ x1
)
```

Several ordinary random slopes are allowed as separate independent variance
components:

```r
bf(
  y ~ x1 + x2 + (1 | id) + (0 + x1 | id) + (0 + x2 | id),
  sigma ~ x1
)
```

Interaction slopes are not parsed as formula expressions yet. The temporary
safe workflow is to create the interaction column before fitting:

```r
dat$x1_x2 <- dat$x1 * dat$x2
bf(
  y ~ x1 * x2 + (0 + x1_x2 | id),
  sigma ~ x1
)
```

Current implementation details:

- supported only for univariate Gaussian `mu`;
- random-slope terms must be written as `0 + x`, with a single numeric
  predictor;
- `(1 + x | id)` and labelled blocks such as `(1 + x | p | id)` are reserved
  for correlated covariance-block support;
- random effects are integrated with TMB's Laplace approximation;
- the TMB parameterization is non-centered:
  `b_{term,group} = sd_term * u_{term,group}`, where
  `u_{term,group} ~ Normal(0, 1)`;
- fitted-data `predict(fit, dpar = "mu")` includes conditional modes;
- `newdata` prediction currently uses fixed effects only;
- grouping variables with fewer than two levels or only singleton groups are
  rejected.

## Correlated Multi-Slope Blocks

Future correlated ordinary random-effect blocks should support:

```r
bf(
  y ~ x1 * x2 + (1 + x1 + x2 + x1:x2 | id),
  sigma ~ x1
)
```

and labelled covariance-block syntax:

```r
bf(
  y ~ x1 * x2 + (1 + x1 + x2 + x1:x2 | p | id),
  sigma ~ x1
)
```

If a block contains `q` random coefficients, it has `q * (q + 1) / 2`
covariance parameters. For example, intercept, `x1`, `x2`, and `x1:x2` have
four coefficients and therefore ten covariance parameters. These models should
come with simulation recovery tests and warnings when the number of groups or
within-group replication is weak.

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

`drmTMB` will use labelled group-level covariance blocks:

```r
(1 + x1 | p | id)
```

The middle label `p` ties terms into a shared group-level covariance block.
When the same label appears in multiple parameter formulas, for example in
`mu` and `sigma`, the model estimates constant correlations among those
group-level effects. These are the correlations used in double-hierarchical
models of personality, plasticity, predictability, and malleability.

Residual `rho12 ~` is separate and belongs to bivariate response likelihoods.
It models the residual coupling between two responses after their location and
scale predictors have been accounted for.

## Double-Hierarchical Correlation Taxonomy

The individual-differences framework of O'Dea et al. (2022) distinguishes
correlations among individual differences:

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
double-hierarchical bivariate model, each response can therefore have multiple
scale quantities: at least the random-intercept SD, the random-slope SD, and
the residual `sigma`. These should not be collapsed into one `sigma` namespace.

## Numerical Caution

Random-effect variance components are often weakly identified, especially near
zero. Simulation tests must include small group counts, sparse groups, and
boundary cases.
