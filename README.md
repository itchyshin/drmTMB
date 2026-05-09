# drmTMB <a href="https://itchyshin.github.io/drmTMB/"><img src="man/figures/drmTMB-logo.png" align="right" height="138" alt="drmTMB hex logo" /></a>

A fast TMB-based distributional regression package for broadly useful
univariate and bivariate distributional regression. The current implementation
starts with Gaussian, Student-t, lognormal, Gamma, Poisson, and negative
binomial models,
known-covariance meta-analysis, phylogenetic location effects, random-effect
scale models, and bivariate Gaussian residual-correlation models. The long-term
design also includes skewness, further zero-inflation paths, and additional response
families. The first examples are motivated by ecology, evolution, and
environmental science, but the package is general-purpose. Here `mu` is the
location or mean-like parameter, `sigma` is the residual scale parameter, `nu`
is the first shape parameter, and `rho12` is the residual correlation between
two responses. For Gaussian models, `mu` is the expected response and `sigma`
is the residual standard deviation. For Student-t models, `sigma` is the
Student-t scale parameter; when `nu > 2`, the residual standard deviation is
`sigma * sqrt(nu / (nu - 2))`. For lognormal models, `mu` and `sigma` are the
mean and standard deviation of `log(y)`, and `fitted()` returns the arithmetic
mean `exp(mu + sigma^2 / 2)`. For Gamma models, `mu` is the response mean and
`sigma` is the coefficient of variation, so the residual standard deviation is
`mu * sigma`. For Poisson models, `mu` is the count mean and variance; there
is no fitted residual `sigma` parameter in the first Poisson path. For
negative-binomial 2 models, `mu` is the count mean and `sigma` is an
overdispersion scale in `Var(y) = mu + sigma^2 * mu^2`, not a residual
standard deviation.

The current implementation supports Gaussian location-scale models, including
fixed effects, random intercepts, independent numeric random slopes, and
ordinary labelled or unlabelled correlated random intercept-slope blocks in
the location formula, residual-scale random intercepts in the `sigma`
formula, and random-effect scale formulae for one or several distinct `mu`
random intercepts:

## Implemented now

The simplest fitted Gaussian location-scale model is:

```text
y_i | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 x1_i
log(sigma_i) = gamma_0 + gamma_1 x1_i
```

```r
drmTMB(
  drm_formula(y ~ x1, sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

Here `x1` can change both the expected response and the residual standard
deviation.

The first robust continuous family uses the same location-scale grammar and
adds a tail-shape formula:

```text
y_i | mu_i, sigma_i, nu_i ~ Student-t(mu_i, sigma_i, nu_i)
mu_i = beta_0 + beta_1 x1_i
log(sigma_i) = gamma_0 + gamma_1 x1_i
nu_i = 2 + exp(delta_0)
```

```r
drmTMB(
  drm_formula(y ~ x1, sigma ~ x1, nu ~ 1),
  family = student(),
  data = dat
)
```

This is useful when a continuous response has occasional large residuals but
the scientific question is still about predictors of the mean and residual
scale.

Positive continuous responses can use the fixed-effect lognormal path:

```text
log(y_i) | mu_i, sigma_i ~ Normal(mu_i, sigma_i^2)
mu_i = beta_0 + beta_1 habitat_i
log(sigma_i) = gamma_0 + gamma_1 treatment_i
E[y_i] = exp(mu_i + sigma_i^2 / 2)
```

```r
drmTMB(
  drm_formula(biomass ~ habitat, sigma ~ treatment),
  family = lognormal(),
  data = dat
)
```

This is useful for positive measurements such as biomass, body mass,
concentration, area, and time-to-event measurements when multiplicative
variation is scientifically natural. The response must be positive and finite.
Random effects, known sampling covariance, phylogenetic terms, and bivariate
lognormal models are later phases.

Gamma mean-CV models are also implemented for positive continuous responses:

```text
y_i | mu_i, sigma_i ~ Gamma(shape_i, scale_i)
log(mu_i) = beta_0 + beta_1 habitat_i
log(sigma_i) = gamma_0 + gamma_1 treatment_i
shape_i = 1 / sigma_i^2
scale_i = mu_i * sigma_i^2
E[y_i] = mu_i
```

```r
drmTMB(
  drm_formula(biomass ~ habitat, sigma ~ treatment),
  family = Gamma(link = "log"),
  data = dat
)
```

Here `sigma` is the coefficient of variation. Use this path when predictors
may change relative variability in positive responses such as biomass, body
mass, metabolic rate, or concentration. `drmTMB` requires the log-linked
`stats::Gamma()` family route; it does not export a lowercase `gamma()` helper
because `base::gamma()` is already the special gamma function.

The first count family is a fixed-effect Poisson mean model:

```text
y_i | mu_i ~ Poisson(mu_i)
log(mu_i) = beta_0 + beta_1 habitat_i
E[y_i] = Var[y_i] = mu_i
```

```r
drmTMB(
  drm_formula(count ~ habitat),
  family = poisson(link = "log"),
  data = dat
)
```

This is mainly a baseline count-regression path and a comparator for later
overdispersed count families. It intentionally does not accept `sigma`,
`sd(group)`, `meta_known_V()`, random effects, or bivariate count syntax yet.
Ecological counts with biological overdispersion will usually need
`nbinom2()` or the planned COM-Poisson family.

Zero-inflated Poisson models are fitted by adding a `zi` formula to the same
Poisson family route:

```text
y_i | mu_i, zi_i ~ ZIP(mu_i, zi_i)
log(mu_i) = beta_0 + beta_1 habitat_i
logit(zi_i) = gamma_0 + gamma_1 survey_method_i
E[y_i] = (1 - zi_i) mu_i
```

```r
drmTMB(
  drm_formula(count ~ habitat, zi ~ survey_method),
  family = poisson(link = "log"),
  data = dat
)
```

Here `mu` is the conditional count mean and `zi` is the structural-zero
probability. `fitted()` returns the unconditional response mean `(1 - zi) *
mu`.

Negative-binomial 2 mean-dispersion models are implemented for overdispersed
counts:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
log(mu_i) = beta_0 + beta_1 habitat_i
log(sigma_i) = gamma_0 + gamma_1 treatment_i
size_i = 1 / sigma_i^2
E[y_i] = mu_i
Var[y_i] = mu_i + sigma_i^2 * mu_i^2
```

```r
drmTMB(
  drm_formula(count ~ habitat, sigma ~ treatment),
  family = nbinom2(),
  data = dat
)
```

Here `sigma` is the extra-Poisson scale. Larger `sigma` means more
overdispersion. This is the opposite direction from parameterizations that use
a size or precision parameter; for example, `size = 1 / sigma^2`. Random
effects, zero inflation, hurdle components, known sampling covariance,
phylogenetic or spatial structured effects, and bivariate count models are
later phases.

```r
drmTMB(
  drm_formula(y ~ x1 + (1 | id) + (0 + x1 | id), sigma ~ x1),
  family = gaussian(),
  data = dat
)
```

This adds independent group-level intercept and slope variation in the mean:

```text
mu_ij = beta_0 + beta_1 x1_ij + b_{0j} + b_{1j} x1_ij
b_{0j} ~ Normal(0, sd_mu_id_intercept^2)
b_{1j} ~ Normal(0, sd_mu_id_x1^2)
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
group-level `mu` random effect:

```text
sigma formula:
  log(sigma_ij) = gamma_0 + gamma_1 x1_ij + a_j
  a_j ~ Normal(0, sd_sigma_id^2)

sd(id) formula:
  b_j = sd_mu_id,j u_j
  u_j ~ Normal(0, 1)
  log(sd_mu_id,j) = alpha_0 + alpha_1 x_group_j
```

The implemented `sd()` grammar supports one or more distinct unlabelled
Gaussian `mu` random-intercept targets:

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
eta_rho12_i = X_rho12[i, ] beta_rho12
rho12_i = 0.99999999 * tanh(eta_rho12_i)
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

If both responses share the same location predictors, `mvbind(y1, y2) ~ x`
is implemented as shorthand for identical `mu1` and `mu2` location formulas.
Use explicit `mu1 = y1 ~ ...` and `mu2 = y2 ~ ...` when the two responses need
different predictors.

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

Bivariate Gaussian meta-analysis uses the same marker with a dense row-paired
`2n` by `2n` covariance matrix. `meta_vcov_bivariate()` builds the common
within-study block-diagonal case, and fitted `rho12` remains the residual or
between-study correlation after known sampling covariance has been included.

```text
y_stack = (y1_1, y2_1, ..., y1_n, y2_n)'
y_stack ~ MVN(mu_stack, V + Omega_stack)
Omega_i =
  [sigma1_i^2,                  rho12_i sigma1_i sigma2_i;
   rho12_i sigma1_i sigma2_i,   sigma2_i^2]
```

```r
V <- meta_vcov_bivariate(v1 = v1, v2 = v2, cor12 = sampling_cor12)

drmTMB(
  bf(
    mu1 = y1 ~ x1 + meta_known_V(V = V),
    mu2 = y2 ~ x1,
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    rho12 = ~ x1
  ),
  family = c(gaussian(), gaussian()),
  data = dat
)
```

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

Implemented now: Gaussian location-scale models with `mu` random intercepts,
independent numeric random slopes, ordinary correlated intercept-slope blocks,
labelled one-slope `mu` covariance-block labels, residual-scale random
intercepts in `sigma`, one or more univariate Gaussian random-effect scale
models such as `sd(id) ~ x_group` and `sd(site) ~ site_type`, fixed-effect
Student-t `mu`, `sigma`, and `nu` models, fixed-effect lognormal `mu` and
`sigma` models for positive responses, fixed-effect Gamma mean-CV models with
`family = Gamma(link = "log")`, fixed-effect Poisson mean models with
`family = poisson(link = "log")`, fixed-effect zero-inflated Poisson models
using `family = poisson(link = "log")` plus `zi ~ predictors`, fixed-effect negative-binomial 2
mean-dispersion models with `family = nbinom2()`, `meta_known_V(V = V)` support for diagonal and
dense known sampling covariance, intercept-only univariate Gaussian
phylogenetic location effects such as
`phylo(1 | species, tree = tree)`, and fixed-effect bivariate Gaussian
`rho12 ~ predictors` using either `biv_gaussian()`,
`family = c(gaussian(), gaussian())`, or
`family = list(gaussian(), gaussian())`. `mvbind(y1, y2) ~ x` is implemented
as shorthand for identical bivariate location formulas.

`check_drm()` provides a first-pass diagnostic table for convergence, gradients,
Hessian status, dropped rows, finite objective values, scale positivity,
`rho12` boundaries, Student-t `nu` boundary behaviour, known sampling covariance
summaries, and random-effect replication/design checks. The next targets are
cross-formula labelled covariance blocks, phylogenetic slopes and scale effects,
larger sparse covariance routes, and spatial SPDE paths.

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
