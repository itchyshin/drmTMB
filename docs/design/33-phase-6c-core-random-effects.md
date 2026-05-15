# Phase 6c Core Random-Effect Foundation

This note records the bounded Phase 6c core before the larger Phase 10-13
structured-effect programme. The purpose is to make the ordinary grouped
random-effect layer stable enough that later phylogenetic, spatial, bivariate,
and derived-inference work has a plain mixed-model baseline.

## Reader Contract

For an applied ecology, evolution, or environmental-science reader:

- a random intercept means groups differ in baseline `mu`;
- a random slope means groups differ in the effect of a covariate on `mu`;
- a residual-scale random effect means groups differ in `log(sigma)`;
- an `sd(group)` formula models the standard deviation of a `mu` random
  intercept across groups;
- `rho12` is residual two-response coupling and is not a group-level
  random-effect correlation.

For an R package contributor, every advertised random-effect quantity needs a
traceable path:

```text
symbolic equation -> formula syntax -> internal parameter -> extractor row
```

If any link is missing, the surface is experimental, planned, or unsupported.

## Implemented Core

| Scientific question | Syntax | Main output | Status |
|---|---|---|---|
| Do groups differ in baseline mean response? | `y ~ x + (1 | id)` | `sdpars$mu["(1 | id)"]` | Implemented |
| Do groups differ in the slope of `x`? | `y ~ x + (0 + x | id)` | `sdpars$mu["(0 + x | id)"]` | Implemented |
| Are group baselines and slopes correlated? | `y ~ x + (1 + x | id)` | `corpars$mu["cor((Intercept),x | id)"]` and `corpairs()` | Implemented |
| Do group residual scales vary? | `sigma ~ z + (1 | id)` | `sdpars$sigma["(1 | id)"]` | Implemented |
| Do group residual-scale slopes vary? | `sigma ~ z + (0 + w | id)` | `sdpars$sigma["(0 + w | id)"]` | Implemented |
| Are baseline `mu` and baseline `sigma` deviations correlated? | `(1 | p | id)` in both `mu` and `sigma` | `corpars$mu_sigma` and `corpairs(class = "mean-scale")` | Implemented |
| Does a group-level predictor change among-group `mu` SD? | `sd(id) ~ x_group` | `coef(fit, "sd(id)")`, `predict(fit, dpar = "sd(id)")` | Implemented for unlabelled Gaussian `mu` random intercepts |

The implemented ordinary one-slope core therefore covers the random-intercept
foundation and the first intercept-slope correlation. It does not claim
bivariate random slopes, structured phylogenetic or spatial slopes, slope-SD
regression, or random effects in `rho12`.

## Equations

For a location random intercept:

```text
y_ij | mu_ij, sigma_ij ~ Normal(mu_ij, sigma_ij^2)
mu_ij = X_mu[ij, ] beta_mu + b_0j
log(sigma_ij) = X_sigma[ij, ] beta_sigma
b_0j = sd_mu_id u_0j
u_0j ~ Normal(0, 1)
```

Matching syntax:

```r
bf(y ~ x + (1 | id), sigma ~ z)
```

For an independent location random slope:

```text
mu_ij = X_mu[ij, ] beta_mu + x_ij b_1j
b_1j = sd_mu_x_id u_1j
u_1j ~ Normal(0, 1)
```

Matching syntax:

```r
bf(y ~ x + (0 + x | id), sigma ~ z)
```

For a correlated intercept-slope block:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x_ij b_1j

[b_0j, b_1j]' = diag(sd0, sd1) L_corr [u_0j, u_1j]'
[u_0j, u_1j]' ~ Normal([0, 0]', I)
cor(b_0j, b_1j) = rho_re
```

Matching syntax:

```r
bf(y ~ x + (1 + x | id), sigma ~ z)
bf(y ~ x + (1 + x | p | id), sigma ~ z)
```

The label `p` is a covariance-block label. It is not a grouping variable and
it is not `rho12`.

For residual-scale random effects:

```text
log(sigma_ij) = X_sigma[ij, ] beta_sigma + a_0j + w_ij a_1j
a_0j = sd_sigma_id v_0j
a_1j = sd_sigma_w_id v_1j
v_0j, v_1j ~ Normal(0, 1)
```

Matching syntax:

```r
bf(y ~ x, sigma ~ z + (1 | id) + (0 + w | id))
```

This is group-to-group variation in residual scale. It is not the same as
`sd(id) ~ x_group`, which models the SD of a location random intercept.

## Output and Inference Ledger

| Surface | Stable extractor | Profile target status | Notes |
|---|---|---|---|
| Fixed `mu` and `sigma` coefficients | `coef()` and `summary()` | Ready for fixed-effect targets | Wald and profile paths are separate |
| `mu` random-intercept SD | `sdpars$mu`, `summary()`, `profile_targets()` | Ready for direct SD targets | Boundary diagnostics use `check_drm()` |
| `mu` random-slope SD | `sdpars$mu`, `summary()`, `profile_targets()` | Ready for direct SD targets | One numeric slope per ordinary correlated block |
| Ordinary intercept-slope correlation | `corpars$mu`, `corpairs(level = "group")`, `profile_targets()` | Ready for direct correlation targets | Class is `mean-slope`; `location-slope` is a filter alias |
| Residual-scale random-effect SD | `sdpars$sigma`, `summary()`, `profile_targets()` | Ready for direct SD targets | Enters `log(sigma)` |
| `mu`/`sigma` random-intercept correlation | `corpars$mu_sigma`, `corpairs(class = "mean-scale")` | Ready for direct correlation targets | Group-level covariance, not residual coupling |
| `sd(id) ~ x_group` coefficients | `coef(fit, "sd(id)")`, `predict(fit, dpar = "sd(id)")` | Fixed-effect rows ready; derived group SD intervals remain limited | Target must be an unlabelled Gaussian `mu` random intercept |

## Deferred Surfaces

The following remain planned or unsupported in the Phase 6c core:

- `phylo(1 + x | species, tree = tree)` fitting;
- `spatial(1 + x | site, coords = coords)` fitting;
- bivariate random slopes in `mu1`, `mu2`, `sigma1`, or `sigma2`;
- slope-specific `sd(id, dpar = "mu", coef = "x") ~ x_group`;
- random effects in `rho12`;
- intercept-slope `corpair()` formulae;
- slope1-slope2 bivariate plasticity-syndrome correlations.

Those surfaces need storage-order documentation, simulation recovery, extractor
names, `profile_targets()` rows, and reader-facing examples before they can be
taught as fitted behaviour.

## Structured-Slope Handoff

The structured one-slope rows are design-complete enough to hand forward, but
not fitted in this Phase 6c core closure.

| Surface | Minimum next implementation contract | Destination |
|---|---|---|
| `phylo(1 + x | species, tree = tree)` | one structured `mu` slope, explicit intercept/slope storage order, simulation recovery for slope SD, `sdpars$mu` and `profile_targets()` names, and `check_drm()` replication diagnostics | Phase 12 |
| `spatial(1 + x | site, coords = coords)` | one coordinate-spatial `mu` slope, separation from future mesh/SPDE path, simulation recovery for slope SD, `ranef()`/`sdpars` names, and coordinate diagnostics | Phase 10 |
| bivariate slope1-slope2 correlation | coefficient-aware `corpair()` syntax, `corpairs()` rows with `from_coef` and `to_coef`, direct-target interval status, and recovery evidence | Phase 11 or later |
| structured slope tutorials | fitted output, interval/status columns, and biological interpretation after the model surface is stable | final tutorial pass after Phases 10-13 |

The first structured-slope implementation should not estimate
intercept-slope correlations. It should fit one slope SD first, expose that SD
through the same output path as ordinary random-effect SDs, and leave
slope-correlation rows unavailable until a direct and identifiable target
exists.

## Biological Reading

For a thermal reaction-norm example, let `x` be centred temperature and `id`
be individual, population, or species:

```text
mu_ij = beta_0 + beta_1 temperature_ij + b_0j + temperature_ij b_1j
```

Then:

- `beta_1` is the average temperature slope;
- `sd_mu_id` is among-group variation in baseline response;
- `sd_mu_temperature_id` is among-group variation in thermal plasticity;
- `cor(b_0, b_1)` asks whether groups with high baseline response tend to have
  steeper or shallower temperature slopes;
- `sigma` remains residual within-observation variation around the fitted
  reaction norm;
- `rho12` is not part of this one-response model.

For the fitted ordinary core, the matching syntax is:

```r
bf(y ~ temperature + (1 + temperature | p | id), sigma ~ habitat)
```

The matching output path is `sdpars$mu` for the two SDs, `corpars$mu` and
`corpairs(fit, class = "mean-slope")` for the intercept-slope correlation, and
`profile_targets(fit)` for the direct SD and correlation target names.

## Evidence Pointers

The current core is covered by:

- `tests/testthat/test-gaussian-random-intercepts.R` for ordinary `mu`,
  residual-scale `sigma`, labelled intercept-slope blocks, missingness,
  boundary, and `corpairs()` rows;
- `tests/testthat/test-profile-targets.R` for direct SD and correlation target
  names and profile readiness;
- `tests/testthat/test-check-drm.R` for replication, boundary, and weak
  random-slope design diagnostics;
- `docs/design/04-random-effects.md`,
  `docs/design/13-gaussian-location-scale-math.md`,
  `docs/design/17-correlated-random-effect-blocks.md`, and
  `docs/design/20-coscale-correlation-pairs.md` for the surrounding contracts.
