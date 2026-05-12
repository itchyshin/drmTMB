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
5. Random intercepts and slopes in residual scale. Implemented for univariate
   Gaussian `sigma`, with ordinary unlabelled intercept-slope covariance.
6. Random-effect scale formulae such as `sd(id) ~ x_group`. Implemented for
   one or more distinct unlabelled univariate Gaussian `mu` random intercepts.
7. Slope-specific random-effect scale models, labelled-block scales, and
   correlations among location and scale random effects when identifiable.

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

In the univariate Gaussian `mu` implementation, `p` is retained in output names
and can match a labelled residual-scale random intercept or one-slope block in
`sigma`. Matching `(1 | p | id)` terms in `mu` and `sigma` estimate one
group-level mean-scale correlation. Matching `(1 + x | p | id)` terms estimate
one positive-definite four-effect block spanning the `mu` intercept, `mu`
slope, `sigma` intercept, and `sigma` slope. The pairwise correlations from
that shared block are reported under `corpars$mu_sigma` and `corpairs()`.

Residual-scale random intercepts and slopes are implemented in `sigma`:

```r
bf(
  y ~ x1 + (1 | id),
  sigma ~ x1 + (1 | id)
)

bf(
  y ~ x1,
  sigma ~ x1 + (1 + x1 | id)
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

For `sigma ~ x1 + (1 + x1 | id)`, the residual-scale random intercept and
random slope share one ordinary group-level covariance block. The fitted SDs
are reported in `sdpars$sigma`, and the scale-slope correlation is reported in
`corpars$sigma` and `corpairs(class = "scale-slope")`.

The first cross-formula covariance path matches labelled random intercepts or
one-slope blocks in `mu` and `sigma`:

```r
bf(
  y ~ x1 + (1 + x1 | p | id),
  sigma ~ x1 + (1 + x1 | p | id)
)
```

This reports the group-level mean-slope, mean-scale, slope-scale, and
scale-slope correlations in `corpars$mu_sigma` and `corpairs()`. The block is
positive definite because the likelihood uses a Cholesky construction from
partial correlations rather than independent pairwise `tanh()` parameters.

Random-effect scale formulae are implemented for the first simple case:

```r
bf(
  y ~ x1 + (1 | id),
  sigma ~ x2,
  sd(id) ~ x_group
)
```

This means:

```text
mu_i = X_mu[i, ] beta_mu + b_{id[i]}
b_j = sd_mu_id,j u_j
u_j ~ Normal(0, 1)
log(sd_mu_id,j) = W_id[j, ] alpha_id
```

The `sd(id)` formula targets the standard deviation of the `mu` random
intercept. Its predictors must be group-level, constant within `id` after
missing-row filtering.

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
- ordinary correlated intercept-slope blocks are written as `(1 + x | id)` or,
  for `mu`, `(1 + x | p | id)`, and currently support one numeric slope;
- labelled blocks are implemented within univariate Gaussian `mu`; matching
  labelled `mu` and `sigma` random intercepts or one-slope blocks are
  implemented as shared cross-formula covariance blocks; the one-slope case
  reports derived pairwise correlations from a positive-definite Cholesky
  parameterization;
- residual `sigma` random effects support unlabelled random intercepts,
  independent numeric slopes, and ordinary unlabelled correlated
  intercept-slope blocks;
- random-effect scale formulae are implemented for one or more distinct
  unlabelled Gaussian `mu` random intercepts, such as `sd(id) ~ x_group` and
  `sd(site) ~ site_type`;
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

The first double-hierarchical scale syntax is explicit and implemented for one
unlabelled random-intercept target:

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

The middle label `p` identifies a group-level covariance block. In the
univariate cross-formula path, matching `(1 | p | id)` or
`(1 + x1 | p | id)` terms in `mu` and `sigma` estimate correlations among
individual averages, mean-model slopes, residual scale, and scale-model slopes.
In the first bivariate Gaussian covariance slices, matching `(1 | p | id)`
terms in `mu1` and `mu2` estimate one constant group-level random-intercept
correlation, and matching `(1 | q | id)` terms in `sigma1` and `sigma2`
estimate one constant scale-scale random-intercept correlation. Matching
`phylo(1 | species, tree = tree)` terms in `mu1` and `mu2` estimate a separate
phylogenetic mean-mean correlation. Later implementations should allow the same
label for bivariate random slopes and richer cross-parameter blocks.

Residual `rho12 ~` is separate and belongs to bivariate response likelihoods.
It models the residual coupling between two responses after their location and
scale predictors have been accounted for.

## Double-Hierarchical Correlation Taxonomy

Individual-difference location-scale models distinguish correlations among
persistent individual effects:

- individual averages: random intercepts in mean models;
- individual mean-model slopes: random slopes in mean models;
- individual residual scale: random intercepts in scale models;
- individual changes in residual scale: random slopes in scale models.

In bivariate models these can produce correlations within and between responses
for average response, mean-model slope, residual scale, and scale-model slope.
These are group-level covariance parameters and should be named/extracted as
group-level correlations, not as `rho12`.

Initial random-intercept/slope correlations should be constant covariance-block
parameters. Predictor-dependent correlation formulae should be reserved for
residual or response-level `rho12` until identifiability is demonstrated.

The detailed long-format correlation-pair namespace is recorded in
`docs/design/20-coscale-correlation-pairs.md`. Future implementations should
return enough labels to identify the level, grouping factor, covariance block,
distributional parameters, responses, and random-effect coefficients involved
in each pair.

The staged endpoint for the complete model is recorded in
`docs/design/28-double-hierarchical-endpoint.md`.

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
