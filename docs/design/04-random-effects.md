# Random Effects

Random effects are implemented after fixed-effect likelihoods are tested, but
the grammar must support them from the start.

## Order of Implementation

1. No random effects.
2. Random intercepts in location.
3. Random slopes in location.
4. Random intercepts in scale.
5. Random-effect scale formulae such as `sd(id) ~ x`.
6. Correlations among location and scale random effects when identifiable.

## Initial Syntax

```r
bf(
  y ~ x + (1 | id),
  sigma ~ z
)
```

Double-hierarchical syntax should be explicit:

```r
bf(
  y ~ x + (1 | id),
  sigma ~ z,
  sd(id) ~ z
)
```

Multiple random-effect variance components get separate `sd()` formulas:

```r
bf(
  y ~ x + (1 | id1) + (1 | id2),
  sd(id1) ~ x,
  sd(id2) ~ x
)
```

This models the standard deviations of the two random-effect components. It
does not put random effects inside the residual `sigma` model.

## Correlation Blocks

`drmTMB` follows brms-style group-level ID syntax:

```r
(1 + x | p | id)
```

The middle label `p` ties terms into a shared group-level covariance block.
When the same label appears in multiple parameter formulas, for example in
`mu` and `sigma`, the model estimates constant correlations among those
group-level effects. These are the correlations used in O'Dea-style
double-hierarchical models for personality, plasticity, and predictability.

Residual `rho12 ~` is separate and belongs to bivariate response likelihoods.

## Numerical Caution

Random-effect variance components are often weakly identified, especially near
zero. Simulation tests must include small group counts, sparse groups, and
boundary cases.
