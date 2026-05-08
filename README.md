# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

A fast TMB-based distributional regression package for broadly useful
univariate and bivariate location-scale-shape models. The package lets users
model not only mu and sigma but also shape, zero inflation, random-effect
variance, and residual correlation `rho12`; the first examples are motivated by
ecology, evolution, and environmental science.

The current implementation supports Gaussian location-scale models, including
fixed effects, random intercepts, independent numeric random slopes, and
ordinary labelled or unlabelled correlated random intercept-slope blocks in
the location formula, plus residual-scale random intercepts in the `sigma`
formula:

```r
drmTMB(
  bf(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

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
not the same as a future `sd(id) ~ x1` model, which will model the standard
deviation of a group-level `mu` random effect.

It also supports the fixed-effect seed of the bivariate location-coscale model,
including predictor-dependent residual correlation:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ x1 + x2,
    sigma2 = ~ x1,
    rho12 = ~ x1 + x2
  ),
  family = biv_gaussian(),
  data = dat
)
```

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

Future bivariate public syntax should also allow composed response families such
as `family = c(gaussian(), gaussian())` and `family = c(gaussian(), poisson())`
where a coherent joint likelihood is defined.

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

Current project status: Gaussian location-scale MVP with `mu` random
intercepts, independent numeric random slopes, ordinary correlated
intercept-slope blocks, labelled one-slope `mu` covariance-block labels,
residual-scale random intercepts in `sigma`,
`meta_known_V(V = V)` support for diagonal and dense known sampling covariance,
and fixed-effect bivariate Gaussian `rho12 ~ predictors`. The next targets are
random-effect scale models such as `sd(id) ~ x`, cross-formula labelled
covariance blocks, sparse precision paths, phylogenetic A-inverse, and spatial
SPDE paths.

Phylogenetic and spatial dependence will be treated as one structured-effect
module: `z ~ MVN(0, sigma_z^2 K)`, with `K = A` for tree-derived phylogenetic
correlation and `K = M` for distance-derived spatial correlation. The speed
routes differ, A-inverse for phylogeny and SPDE/GMRF for space, but the user
model should feel like the same idea attached to `mu`, later `sigma`, and only
experimentally to harder parameters such as `rho12`.

The long-term correlation roadmap is broader than residual `rho12`: bivariate
structured models should also expose phylogenetic, non-phylogenetic species,
spatial, study, site, and other group-level correlations as separate covariance
summaries.
