# Random Effects

Random effects are implemented after fixed-effect likelihoods are tested, but
the grammar must support them from the start.

The Phase 6c core source map is
`docs/design/33-phase-6c-core-random-effects.md`. It records the ordinary
random-intercept and one-slope foundation that later bivariate, phylogenetic,
spatial, and derived-inference phases should build on.

## Order of Implementation

1. No random effects.
2. Random intercepts in location. Implemented for univariate Gaussian `mu`.
3. Simple numeric random slopes in location. Implemented for univariate
   Gaussian `mu` as separate uncorrelated terms.
4. Ordinary correlated random intercept-slope and multi-slope blocks in
   location. Implemented for univariate Gaussian `mu`, with optional
   covariance-block labels.
5. Random intercepts and independent numeric random slopes in residual scale.
   Implemented for univariate Gaussian `sigma`.
6. Random-effect scale formulae such as `sd(id) ~ x_group`. Implemented for
   one or more distinct unlabelled univariate Gaussian `mu` random intercepts.
7. Labelled location-scale random-intercept covariance blocks. Implemented for
   matching univariate Gaussian `mu` and `sigma` intercept terms.
8. Slope-specific random-effect scale models, labelled-block scale models, and
   larger correlations among location and scale random effects when
   identifiable.

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

Slice 177 adds explicit recovery coverage for the multiple-independent-slope
case, using two numeric slopes in `mu` with no fitted group-level correlation.
Slices 178-181 add the ordinary unstructured location block:

```r
bf(
  y ~ x1 + x2 + (1 + x1 + x2 | id),
  sigma ~ x1
)
```

This syntax fits one grouped Gaussian `mu` random-effect vector with an
intercept, an `x1` slope, and an `x2` slope. The covariance matrix has three
SDs and three constant correlations. The parser accepts additional simple
numeric slope columns, but q grows quickly: a block with q coefficients has
q SDs and q * (q - 1) / 2 correlations. Treat blocks larger than the tested q=3
path as advanced fits that need enough groups, within-group predictor spread,
and diagnostics.

Ordinary correlated random intercept-slope blocks are implemented for one
numeric slope:

```r
bf(
  y ~ x1 + (1 + x1 | id),
  sigma ~ x1
)
```

The fitted group-level intercept-slope correlation is reported under
`corpars$mu` and as a `mean-slope` row from `corpairs(level = "group")`.
It is not residual `rho12`.

The same block can carry a covariance-block label:

```r
bf(
  y ~ x1 + (1 + x1 | p | id),
  sigma ~ x1
)
```

In the current univariate Gaussian `mu` implementation, `p` is retained in
output names and covariance metadata. A multi-slope label such as
`(1 + x1 + x2 | p | id)` labels the ordinary `mu` block; it does not yet create
covariance sharing across `sigma`, `mu1`, or `mu2` formulas.

For q > 2 ordinary `mu` blocks, fitted SDs are reported in `sdpars$mu` and
`summary(fit)$parameters`. The fitted correlations are reported in
`corpars$re_cov`, `corpairs(level = "group")`, and
`summary(fit)$covariance`. The SD profile targets are direct; the unstructured
correlations are derived from the TMB correlation parameterization and are
therefore marked as unavailable for direct profiling in this phase.

Residual-scale random intercepts and independent numeric random slopes are
implemented in `sigma`:

```r
bf(
  y ~ x1 + (1 | id),
  sigma ~ x1 + (1 | id) + (0 + w | id)
)
```

This means:

```text
log(sigma_i) = X_sigma[i, ] beta_sigma + a_{id[i]} + w_i c_{id[i]}
a_id = sd_sigma_id * v_id
c_id = sd_sigma_w * q_id
v_id, q_id ~ Normal(0, 1)
```

It models residual-scale heterogeneity. Multiple independent residual-scale
terms can be added, for example `(1 | id) + (0 + w1 | id) + (0 + w2 | id)`.
Each term gets its own log-`sigma` random-effect SD in `sdpars$sigma`; the
correlations among those residual-scale terms are fixed at zero in this phase,
so no `corpars$sigma` rows are reported. This is not a model for the standard
deviation of the `mu` random intercept.

The first cross-formula covariance block is also implemented for matching
labelled random intercepts:

```r
bf(
  y ~ x1 + (1 | p | id),
  sigma ~ x1 + (1 | p | id)
)
```

This means:

```text
mu_i = X_mu[i, ] beta_mu + b_{id[i]}
log(sigma_i) = X_sigma[i, ] beta_sigma + a_{id[i]}

[b_j, a_j]' =
  diag(sd_mu_id, sd_sigma_id) L_p [u_j, v_j]'
[u_j, v_j]' ~ Normal([0, 0]', I)
cor(b_j, a_j) = rho_mu_sigma
```

The fitted correlation is reported under `corpars$mu_sigma` and `corpairs()`
as `mean-scale`. It is a group-level association between individual average
response and individual residual scale, not residual `rho12`.

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
- ordinary correlated intercept-slope blocks are written as `(1 + x | id)` or
  `(1 + x | p | id)` and currently support one numeric slope;
- labelled blocks are implemented within univariate Gaussian `mu`, and the
  first matching labelled `mu`/`sigma` random-intercept covariance block is
  implemented for syntax such as `(1 | p | id)` in both formulas;
- residual `sigma` random effects support random intercepts and independent
  numeric random slopes; labelled `sigma` intercepts require a matching
  labelled `mu` intercept in this phase;
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
univariate Gaussian `mu` implementation, the label is retained in output names.
In the bivariate Gaussian covariance foundation, matching `(1 | p | id)` terms
can estimate constant group-level random-intercept correlations for
`mu1`/`mu2`, `sigma1`/`sigma2`, one same-response `mu`/`sigma` pair, or the
intercept-only all-four block across `mu1`, `mu2`, `sigma1`, and `sigma2`.
These are the correlations used in double-hierarchical models of individual
averages and residual scale. Mean-model slopes, scale-model slopes, and
coefficient-aware slope-pair `corpair()` regressions remain planned.

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
