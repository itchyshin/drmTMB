# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

A fast TMB-based distributional regression package with brms-like syntax,
focused on univariate and bivariate location-scale-shape models, where not only
mu and sigma but also shape, zero inflation, random-effect variance, and
residual correlation `rho12` can be modelled by predictors.

The current implementation supports fixed-effect Gaussian location-scale
models:

```r
drmTMB(
  bf(y ~ x, sigma ~ z),
  family = gaussian(),
  data = dat
)
```

It also supports the first flagship bivariate location-coscale model, including
predictor-dependent residual correlation:

```r
drmTMB(
  bf(
    mu1 = y1 ~ x1 + x2,
    mu2 = y2 ~ x1,
    sigma1 = ~ z1,
    sigma2 = ~ z2,
    rho12 = ~ w
  ),
  family = biv_gaussian(),
  data = dat
)
```

Diagonal meta-analysis is handled as Gaussian regression with known sampling
variance, not as a separate family:

```r
drmTMB(
  bf(
    yi ~ moderator + meta_known_V(V = V),
    sigma ~ moderator
  ),
  family = gaussian(),
  data = dat
)
```

Current project status: Gaussian location-scale MVP, diagonal
`meta_known_V(V = vi)` meta-analysis support, and fixed-effect bivariate
Gaussian `rho12 ~ predictors`. The next target is to harden these likelihoods
and then add random effects, sparse known covariance, phylogenetic A-inverse,
and spatial SPDE paths.
