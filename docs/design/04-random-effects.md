# Random Effects

Random effects are implemented after fixed-effect likelihoods are tested, but
the grammar must support them from the start.

## Order of Implementation

1. No random effects.
2. Random intercepts in location. Implemented for univariate Gaussian `mu`.
3. Simple numeric random slopes in location. Implemented for univariate
   Gaussian `mu` as separate uncorrelated terms.
4. Ordinary correlated random intercept-slope blocks in location. Implemented
   for univariate Gaussian `mu`, with optional covariance-block labels.
5. Random intercepts in residual scale. Implemented for univariate Gaussian
   `sigma`.
6. Random-effect scale formulae such as `sd(id) ~ x`.
7. Correlations among location and scale random effects when identifiable.

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

Ordinary correlated random intercept-slope blocks are implemented for one
numeric slope:

```r
bf(
  y ~ x1 + (1 + x1 | id),
  sigma ~ x1
)
```

The fitted group-level intercept-slope correlation is reported under
`corpars$mu`. It is not residual `rho12`.

The same block can carry a covariance-block label:

```r
bf(
  y ~ x1 + (1 + x1 | p | id),
  sigma ~ x1
)
```

In the current univariate Gaussian `mu` implementation, `p` is retained in
output names and future design metadata. It does not yet create covariance
sharing across `mu`, `sigma`, `mu1`, or `mu2` formulas.

Residual-scale random intercepts are implemented in `sigma`:

```r
bf(
  y ~ x1 + (1 | id),
  sigma ~ x1 + (1 | id)
)
```

This means:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + a_{id[i]}
a_id = sd_sigma_id * v_id
v_id ~ Normal(0, 1)
```

It models residual-scale heterogeneity. It does not model the standard
deviation of the `mu` random intercept.

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

- random effects are supported only for univariate Gaussian `mu` and residual
  `sigma`;
- random-slope terms must be written as `0 + x`, with a single numeric
  predictor, for independent slope terms;
- ordinary correlated intercept-slope blocks are written as `(1 + x | id)` or
  `(1 + x | p | id)` and currently support one numeric slope;
- labelled blocks are implemented only within univariate Gaussian `mu`; using
  the same label for cross-formula or cross-parameter covariance-block support
  is reserved for later;
- residual `sigma` random effects are limited to unlabelled random intercepts
  such as `(1 | id)`;
- random effects are integrated with TMB's Laplace approximation;
- the TMB parameterization is non-centered; independent terms use
  `b_{term,group} = sd_term * u_{term,group}`, while correlated two-coefficient
  blocks use a Cholesky transform of standardized normal random effects;
- fitted-data `predict(fit, dpar = "mu")` includes conditional modes;
- fitted-data `predict(fit, dpar = "sigma")` includes conditional residual
  scale random-effect modes;
- `newdata` prediction currently uses fixed effects only;
- grouping variables with fewer than two levels or only singleton groups are
  rejected.

## Larger Correlated Multi-Slope Blocks

Future larger correlated ordinary random-effect blocks should support:

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

`drmTMB` uses labelled group-level covariance blocks:

```r
(1 + x1 | p | id)
```

The middle label `p` identifies a group-level covariance block. In the current
univariate Gaussian `mu` implementation, the label is retained in output names.
When later implementations allow the same label in multiple parameter formulas,
for example in `mu` and `sigma`, the model should estimate constant
correlations among those group-level effects. These are the correlations used
in double-hierarchical models of personality, plasticity, predictability, and
malleability.

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
