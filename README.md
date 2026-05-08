# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

A fast TMB-based distributional regression package for broadly useful
univariate and bivariate distributional regression. The package is designed to
model not only mu and sigma but also shape, zero inflation, random-effect
variance, and residual correlation `rho12`; the current implementation starts
with Gaussian location-scale, known-covariance meta-analysis, phylogenetic
location effects, and bivariate Gaussian residual-correlation models. The first
examples are motivated by ecology, evolution, and environmental science. Here
`mu` is the expected response, `sigma` is the residual standard deviation, and
`rho12` is the residual correlation between two responses.

The current implementation supports Gaussian location-scale models, including
fixed effects, random intercepts, independent numeric random slopes, and
ordinary labelled or unlabelled correlated random intercept-slope blocks in
the location formula, residual-scale random intercepts in the `sigma`
formula, and random-effect scale formulae for one or several distinct `mu`
random intercepts:

## Implemented now

```r
drmTMB(
  drm_formula(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

`bf()` remains available as a short alias for `drm_formula()`.

Use separate terms for independent group-level intercept and slope variation,
and a single block when the intercept-slope correlation is part of the model:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | id), sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

The group-level correlation from `(1 + x1 | id)` is reported separately from
residual bivariate `rho12`.

The same one-slope block can carry a covariance-block label:

```r
drmTMB(
  bf(y ~ x1 + (1 + x1 | p | id), sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

For now, `p` is retained as a group-level covariance-block label in output
names such as `cor((Intercept),x1 | p | id)`. Cross-parameter or bivariate
sharing of labelled blocks is still future work.

Residual-scale random intercepts are also implemented:

```r
drmTMB(
  bf(y ~ x1 + (1 | id), sigma ~ x1 + (1 | id)),
  family = gaussian(),
  data = dat
)
```

Here `sigma` is the residual or within-observation standard deviation. This is
not the same as `sd(id) ~ x_group`, which models the standard deviation of a
group-level `mu` random effect. The implemented `sd()` grammar supports one or
more distinct unlabelled Gaussian `mu` random-intercept targets:

```r
drmTMB(
  bf(
    y ~ x1 + (1 | id) + (1 | site),
    sigma ~ x1,
    sd(id) ~ x_group,
    sd(site) ~ site_type
  ),
  family = gaussian(),
  data = dat
)
```

The right-hand side of each `sd(group) ~ ...` formula is group-level:
predictors must be constant within the named group after missing-row filtering.
In the example above, `sigma ~ x1`, `sd(id) ~ x_group`, and
`sd(site) ~ site_type` are three different scale models: residual variation,
among-`id` variation in the mean, and among-`site` variation in the mean.

It also supports the fixed-effect seed of the bivariate location-coscale model,
including predictor-dependent residual correlation. Here "coscale" means the
residual covariance structure, represented in this bivariate Gaussian case by
the residual correlation parameter `rho12`:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

The fitted covariance matrix for observation `i` is:

```text
Omega_i =
  [sigma1_i^2,                  rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,   sigma2_i^2]
rho12_i = tanh(X_rho12[i, ] beta_rho12)
```

That equation is the package's first location-coscale contract: predictors may
change means, residual standard deviations, and the residual coupling between
two responses. Use `rho12(fit)` to extract the fitted response-scale residual
correlations.

The legacy helper `biv_gaussian()` remains available, but the public direction
is composed response families. Both `family = c(gaussian(), gaussian())` and
`family = list(gaussian(), gaussian())` route to the current bivariate Gaussian
engine. Mixed bivariate families such as `family = c(gaussian(), poisson())`
are planned for later, where a coherent joint likelihood is defined.

Meta-analysis is handled as Gaussian regression with known sampling covariance,
not as a separate family:

```r
drmTMB(
  bf(
    yi ~ x1 + x2 + meta_known_V(V = V),
    sigma ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

Use `meta_known_V(V = V)` when observations have known sampling variances or a
known sampling covariance matrix, such as effect sizes from studies. The known
`V` is sampling uncertainty; fitted `sigma` is the extra residual heterogeneity
SD after that known uncertainty has been included.

Phylogenetic location effects are fitted as structured Gaussian random effects
in the `mu` formula:

```r
drmTMB(
  bf(
    y ~ x1 + phylo(1 | species, tree = tree),
    sigma ~ x1
  ),
  family = gaussian(),
  data = dat
)
```

Symbolically, this adds `a_species ~ MVN(0, sigma_phylo^2 A)` to the mean
model, where `A` is derived from an ultrametric branch-length tree. The current
implemented path is intercept-only and univariate Gaussian.

## Planned next

The planned double-hierarchical bivariate location-scale model is richer: the
mean part can carry group-level random intercepts and random slopes, while
`sigma1` and `sigma2` remain residual/within-unit scale parameters. This
supports general grouped-response workflows and is especially useful for
individual-differences applications such as personality, plasticity,
predictability, and malleability (O'Dea et al. 2022):

```r
drmTMB(
  formula = drm_formula(
    mu1 = y1 ~ x1 + x2 + (1 + x2 | p | ID),
    mu2 = y2 ~ x1      + (1 + x2 | p | ID),
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

In this syntax, `(1 + x2 | p | ID)` describes the group-level covariance block
for personality and plasticity. Residual `rho12` is a different parameter: it is
the within-observation coupling between response 1 and response 2.
If the correlation is among random intercepts or random slopes, it is a
group-level covariance parameter; if it is between the two residual responses
in one row, it is `rho12`.

## Current project status

Gaussian location-scale MVP with `mu` random
intercepts, independent numeric random slopes, ordinary correlated
intercept-slope blocks, labelled one-slope `mu` covariance-block labels,
residual-scale random intercepts in `sigma`,
one or more univariate Gaussian random-effect scale models such as
`sd(id) ~ x_group` and `sd(site) ~ site_type`,
`meta_known_V(V = V)` support for diagonal and dense known sampling covariance,
intercept-only univariate Gaussian phylogenetic location effects such as
`phylo(1 | species, tree = tree)`,
and fixed-effect bivariate Gaussian `rho12 ~ predictors` using either
`biv_gaussian()`, `family = c(gaussian(), gaussian())`, or
`family = list(gaussian(), gaussian())`. The next targets are cross-formula
labelled covariance blocks, phylogenetic slopes and scale effects, larger
sparse covariance routes, and spatial SPDE paths.

Roadmap note:

Phylogenetic and spatial dependence are treated as one structured-effect
module: `z ~ MVN(0, sigma_z^2 K)`, with `K = A` for tree-derived phylogenetic
correlation and `K = M` for distance-derived spatial correlation. The speed
routes differ, sparse A-inverse for phylogeny and SPDE/GMRF for space, but the
user model should feel like the same idea attached to `mu`, later `sigma`, and
only experimentally to harder parameters such as `rho12`.

The long-term correlation roadmap is broader than residual `rho12`: bivariate
structured models should also expose phylogenetic, non-phylogenetic species,
spatial, study, site, and other group-level correlations as separate covariance
summaries.
