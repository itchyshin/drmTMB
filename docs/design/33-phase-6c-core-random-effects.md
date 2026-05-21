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
| Are group baselines and several numeric slopes correlated? | `y ~ x1 + x2 + (1 + x1 + x2 | id)` | `sdpars$mu`, `corpars$re_cov`, `corpairs()`, and `summary(fit)$covariance` | Implemented for ordinary Gaussian `mu`; q=3 recovery is tested |
| Do group residual scales vary? | `sigma ~ z + (1 | id)` | `sdpars$sigma["(1 | id)"]` | Implemented |
| Do group residual-scale slopes vary? | `sigma ~ z + (0 + w | id)` | `sdpars$sigma["(0 + w | id)"]` | Implemented |
| Are baseline `mu` and baseline `sigma` deviations correlated? | `(1 | p | id)` in both `mu` and `sigma` | `corpars$mu_sigma` and `corpairs(class = "mean-scale")` | Implemented for one or more independent matched blocks |
| Does a group-level predictor change among-group `mu` SD? | `sd(id) ~ x_group` | `coef(fit, "sd(id)")`, `predict(fit, dpar = "sd(id)")` | Implemented for unlabelled Gaussian `mu` random intercepts |

The implemented ordinary Gaussian `mu` core now covers the random-intercept
foundation, the first intercept-slope correlation, and unstructured numeric
multi-slope blocks through the registry-backed q > 2 covariance path. It does
not claim bivariate random slopes, phylogenetic slopes, slope-SD regression, or
random effects in `rho12`.

## Expansion Boundaries

Random-slope support is not one feature. The project should track six separate
layers, because each layer has a different likelihood, output, and validation
cost.

The minimum programme before comprehensive random-slope claims is a one-slope
baseline: every random-effect layer that `drmTMB` supports should be able to
take at least one numeric slope, or should have an explicit unsupported status
and fallback. Ordinary grouped `mu` has an additional compatibility target:
arbitrary `lme4`/`glmmTMB`-style numeric multi-slope covariance such as
`(1 + x1 + x2 | id)`, limited in practice by data, diagnostics, and
computation rather than by a conceptual one- or two-slope cap.

| Layer | Current boundary | Next target | Claim only after |
|---|---|---|---|
| Ordinary Gaussian `mu` | Independent slope terms, one-slope correlated blocks, and q > 2 unstructured numeric grouped blocks are implemented | Expand diagnostics around larger q and weak slope SDs before teaching them as routine | q > 2 covariance blocks fit, `sdpars`, `corpars$re_cov`, `corpairs()`, `summary()`, and `profile_targets()` expose every SD/correlation; recovery tests cover the q=3 path, and a q=4 smoke check confirms arbitrary multi-slope naming and derived-correlation status |
| Gaussian `sigma` | Residual-scale random intercepts and multiple independent numeric slopes on `log(sigma)` are implemented, including separate grouping factors | Correlated scale intercept-slope blocks, then multi-slope scale covariance blocks | simulations recover scale-slope SDs on the modelled `log(sigma)` scale, boundary diagnostics are useful, and examples do not confuse `sigma` slopes with `sd(group)` models |
| Location-scale covariance | One or more independent matching labelled `mu`/`sigma` random-intercept blocks are implemented | Mean-scale covariance involving slope terms only after the separate `mu` and `sigma` slope blocks are stable | output names identify both distributional parameter and coefficient, and direct correlations have profile or explicit unavailable interval status |
| Bivariate Gaussian | Random-intercept covariance blocks are implemented; bivariate random slopes are not. Slice 273 tests keep slope-only `mu1`/`mu2`, q=4 location-slope, residual-scale slope, same-response location-scale slope, and q=8-style all-four slope requests blocked | One ordinary `mu1`/`mu2` slope per response, then same-covariate slope1-slope2 correlations for plasticity-syndrome questions | `corpairs()` carries response and coefficient columns, residual `rho12` stays separate, and simulations vary residual correlation and random-slope SDs |
| Structured phylogenetic/spatial | Slice 186 audit: coordinate spatial has one univariate Gaussian `mu` slope; phylogeny has intercept-level effects but no fitted slope | Bring phylogeny to the one-slope Gaussian `mu` baseline, then evaluate whether spatial and phylo need a second structured slope | each structured layer has SD summaries, direct profile targets, diagnostics, and simulation recovery for at least one fitted slope |
| Non-Gaussian families | Fixed-effect non-Gaussian families are implemented; ordinary Poisson `mu` random intercepts and independent numeric slopes are implemented for non-zero-inflated Poisson models; non-Gaussian `sigma` random effects are explicitly blocked in Slice 193 | Add NB2-style `mu` random intercepts after Poisson, then revisit correlated Poisson slopes and family-specific scale random effects; shape, zero-inflation, one-inflation, hurdle, ordinal, structured, and cross-parameter covariance blocks come later | family-specific simulations show convergence, boundary behaviour, recovery, and useful failure messages on both model and response scales |

The ordinary location-model benchmark is glmmTMB/lme4-style syntax such as
`(1 + x1 + x2 + ... | id)`: one grouped random-effect vector with an
unstructured covariance matrix. If the block has `q` coefficients, the model
estimates `q` SDs and `q * (q - 1) / 2` constant correlations. Slices 178-181
open this path for univariate Gaussian `mu`. The tested recovery path is q=3,
so larger blocks should be treated as advanced and sample-size hungry until
the comprehensive simulation phase quantifies convergence, boundary, bias, and
interval failure rates. Scale-side random slopes are a separate advantage and a
separate burden: they can answer harder distributional questions, but they
need larger validation grids because `sigma` variation is often less directly
identified than `mu` variation.

Before Phase 18 comprehensive simulation, every random-slope layer should have
an explicit status row: implemented, one-slope foundation, planned, or rejected
with a suggested fallback. Comprehensive simulation should then estimate the
sample-size and replication cost of these layers rather than assume they are
already equally powered.

Slice 188 publishes that gate as a pre-simulation status table:

| Layer | Fitted one-slope or covariance surface | Still outside the fitted surface |
|---|---|---|
| Ordinary Gaussian `mu` | Independent slopes, one-slope correlated blocks, and q > 2 numeric location blocks | q > 2 direct correlation profile intervals and routine guidance for very large q |
| Gaussian `sigma` | Multiple independent numeric slopes on `log(sigma)` | Correlated residual-scale slope blocks and labelled residual-scale slope covariance |
| Univariate `mu`/`sigma` covariance | One or more matched labelled random-intercept blocks | Slope-level mean-scale covariance |
| Bivariate ordinary covariance | Matching labelled random-intercept blocks and q=4 all-four intercept blocks | Matching slope-only `mu1`/`mu2`, q=4 location-slope, and q=8 all-four slope endpoints |
| Phylogenetic structured effects | Intercept-level univariate, bivariate, direct-SD, q=2 correlation-regression, and q=4 location-scale paths | `phylo(1 + x | species, tree = tree)` and richer structured-slope covariance |
| Coordinate spatial structured effects | Univariate Gaussian `mu` intercept, one numeric slope with independent coordinate fields, and constant bivariate `mu1`/`mu2` q=2 covariance | Mesh/SPDE, multiple slopes, slope correlations, spatial `sigma`, bivariate spatial q=4 covariance, spatial direct-SD surfaces, and spatial `corpair()` |
| Non-Gaussian families | Fixed-effect likelihoods plus ordinary Poisson `mu` random intercepts and independent numeric slopes in the pre-simulation random-effect gate; non-Gaussian `sigma` random effects have a fixed-effect-only boundary | NB2 `mu` random intercepts, correlated non-Gaussian `mu` slopes, scale/shape/ZI/one-inflation/hurdle/ordinal random effects, cross-parameter covariance blocks, and structured non-Gaussian paths |

Slice 236 re-audits the same promise before broader Phase 18 work starts. The
current boundary is:

- ordinary Gaussian `mu` is the only layer with arbitrary numeric multi-slope
  grouped covariance syntax, with q=3 recovery evidence and larger q treated as
  advanced;
- Gaussian `sigma` supports random intercepts and multiple independent numeric
  slopes on `log(sigma)`, not correlated scale-slope blocks;
- coordinate spatial Gaussian `mu` has one independent numeric slope field,
  while phylogenetic one-slope support remains planned;
- bivariate random slopes, slope-level `mu`/`sigma` covariance, and q=6/q=8
  bivariate location-scale slope endpoints remain outside the fitted surface;
- non-Gaussian random-slope support is currently ordinary Poisson `mu`
  intercepts and independent numeric slopes only; NB2, scale, shape,
  zero-inflation, one-inflation, hurdle, ordinal, and structured non-Gaussian
  random effects need their own recovery gates before entering comprehensive
  simulation.

This means Phase 18 Wave A can simulate fitted Gaussian location-scale,
ordinary Gaussian random-slope, coordinate-spatial one-slope, Poisson `mu`
pilot, and `meta_V(V = V)` surfaces. It should not silently include unfitted
bivariate slope, phylogenetic slope, non-Gaussian scale/shape, or random-effect
correlation surfaces.

## Correlation Policy

For the first random-slope expansion, slope-related correlations are
block-level constants, not modelled distributional parameters. A term such as
`(1 + x | id)` may estimate one constant `cor((Intercept), x | id)`
hyperparameter, and a labelled location-scale slope block may estimate constant
correlations involving `mu` or `sigma` slope coefficients. The first expansion
should not support formulae such as `cor((Intercept), x | id) ~ z` or
`cor(x1, x2 | id) ~ z`.

This policy keeps random-effect correlations separate from residual coscale
`rho12`. The residual bivariate correlation may already be fixed or modelled
with predictors in bivariate Gaussian models. Intercept-level group,
phylogenetic, and future spatial `corpair()` regressions are a different lane:
they may be predictor-dependent when the implemented likelihood and recovery
tests support that specific intercept-level target. The constant-correlation
cap here applies to correlations introduced by random slopes.

Cross-parameter non-Gaussian covariance is a separate gate. It is one thing to
fit independent random intercepts in `mu`, `sigma`, `zi`, `hu`, `zoi`, `coi`,
`nu`, or a future skewness parameter. It is another thing to estimate
correlations among those latent effects. Those correlations require labelled
covariance blocks, stable output names, `corpairs()` rows, profile-target
status, and simulation evidence that the data can distinguish the parameters.
The Slice 191-192 Poisson path therefore fits only independent `mu` random
intercepts and independent numeric slopes. For percentage or proportion data,
zero-one inflation is a bounded response likelihood problem first; `zoi` and
`coi` random effects should wait until the fixed-effect zero-one-inflated
beta-style likelihood is tested.

The practical cap for the first public slope phase outside ordinary grouped
`mu` is therefore: at most one numeric random slope per distributional-parameter
block, constant correlations inside that block, and clear errors for multiple
slopes, interactions, or duplicated slope columns on layers that have not
passed recovery tests. Ordinary grouped `mu` is the exception because its
benchmark is arbitrary numeric multi-slope covariance with constant
correlations.

## External Benchmarks

This project should benchmark against existing packages without pretending that
their syntax, inference, and computational cost are interchangeable.

| Package | Benchmark for `drmTMB` | Boundary for `drmTMB` planning |
|---|---|---|
| `lme4` | Ordinary location random slopes such as `(1 + x1 + x2 + ... | id)` | Match the familiar grouped `mu` syntax before claiming full ordinary random-slope support |
| `glmmTMB` | Fast frequentist GLMM location random slopes, zero-inflation random effects, and dispersion-side random effects | Treat conditional and dispersion random slopes as speed benchmarks; `glmmTMB` does not provide a shared covariance block that correlates conditional/location and dispersion random effects |
| `ordinal::clmm` | Cumulative ordinal mixed models with lme4-like random-effect syntax | Use it as the ordinal random-slope benchmark, while keeping ordinal work separate from Gaussian location-scale covariance |
| `brms` | Broad Bayesian distributional, ordinal, multivariate, and phylogenetic random-effect syntax | Use it as the breadth benchmark, not as a speed or profile-likelihood benchmark |
| `MCMCglmm` | Ecology/evolution multivariate, random-regression, ordinal, pedigree, and phylogenetic models | Use it as a conceptual benchmark for random regression and phylogenetic covariance, but keep `drmTMB` syntax and diagnostics simpler |
| `spaMM` and `INLA` | Spatial GLMMs, latent Gaussian fields, and spatially varying coefficients | Use them as structured-dependence benchmarks, not as direct bivariate distributional-regression templates |

The target niche for `drmTMB` is therefore a focused, fast TMB implementation:
one-response and two-response distributional regression with ordinary,
scale-side, bivariate, phylogenetic, and spatial random-effect covariance
made explicit through `summary()`, `sdpars`, `corpars`, `corpairs()`,
`profile_targets()`, `check_drm()`, simulation recovery, and reader-facing
examples.

## Random-Slope Implementation Ladder

The next random-slope work should proceed in small covariance expansions. The
first strategic goal is one numeric slope everywhere random effects are meant
to exist; the second goal is richer multi-slope covariance where the ordinary
location benchmark already expects it. Each step adds one likelihood surface
and one validation surface; if simulation recovery fails, the next step waits.

1. **Ordinary Gaussian location baseline and benchmark.** Keep the one-slope
   `mu` block stable while expanding diagnostics for unstructured grouped
   `mu` blocks such as `(1 + x1 + x2 + ... | id)`. This is the
   `lme4`/`glmmTMB` compatibility boundary for ordinary location models; the
   practical limit should come from identifiability diagnostics and
   computation, not from the formula grammar.
2. **Gaussian scale one-slope block.** Extend residual-scale `sigma` from
   independent slopes to a correlated intercept-slope block on `log(sigma)`.
   The reader-facing interpretation is group variation in residual variability,
   not mean plasticity and not `sd(group) ~ x`. `glmmTMB` can fit
   dispersion-side random effects, so the `drmTMB` target is not merely their
   existence; it is stable `sigma` terminology, direct profile targets,
   diagnostics, and later covariance with `mu` random effects.
3. **Univariate Gaussian location-scale slope block.** Fit one shared labelled
   block across `mu` and `sigma`, such as `(1 + x | p | id)` in both formulas.
   This q=4 block is the first true double-hierarchical random-slope target:
   mean intercept, mean slope, scale intercept, and scale slope.
4. **Bivariate Gaussian location slopes.** Add one ordinary grouped slope in
   `mu1` and `mu2`, then expose same-covariate slope1-slope2 correlations as
   group-level `corpairs()` rows. Residual `rho12` stays a separate row-level
   coscale parameter.
5. **Bivariate Gaussian scale and location-scale slopes.** Add `sigma1` and
   `sigma2` slope blocks only after bivariate location slopes are stable. Full
   one-slope bivariate location-scale covariance is q=8, with 8 SDs and 28
   correlations, so it belongs late in the ladder.
6. **Structured one-slope parity.** Bring phylogeny to the fitted one-slope
   Gaussian `mu` baseline already reached by coordinate spatial models; then
   decide whether spatial and phylogeny each need a second structured slope.
7. **Non-Gaussian random effects.** Add ordinary `mu` random intercepts and
   one-slope blocks for stable non-Gaussian likelihoods before scale, shape,
   zero-inflation, hurdle, or ordinal threshold-side random slopes. Once a
   non-Gaussian distributional parameter supports random effects, its one-slope
   baseline should follow the same constant-correlation rule. Every family
   needs its own recovery and boundary tests.
8. **Comprehensive simulation.** Use ADEMP-style simulation grids to estimate
   power, bias, RMSE, coverage, convergence rate, boundary rate, and profile
   failure rate across group counts, observations per group, within-group
   covariate spread, slope SD, residual scale, residual `rho12`, structured
   signal, family, and seed. Keep CRAN tests small and shard the large grid into
   optional scripts or CI artifacts.

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

For an ordinary q=3 location block:

```text
mu_ij = X_mu[ij, ] beta_mu + b_0j + x1_ij b_1j + x2_ij b_2j

[b_0j, b_1j, b_2j]' = diag(sd0, sd1, sd2) L_corr [u_0j, u_1j, u_2j]'
[u_0j, u_1j, u_2j]' ~ Normal([0, 0, 0]', I)
```

Matching syntax:

```r
bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ z)
bf(y ~ x1 + x2 + (1 + x1 + x2 | p | id), sigma ~ z)
```

The fitted SDs use `sdpars$mu`. The fitted correlations use `corpars$re_cov`
because the q > 2 block is backed by the registry unstructured-correlation
path, not by the older one-correlation `eta_cor_mu` path.

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
Multiple independent residual-scale terms, such as
`sigma ~ z + (1 | id) + (0 + w1 | id) + (0 + w2 | id)`, are fitted as separate
log-`sigma` SDs with correlations fixed at zero. Correlated residual-scale
blocks such as `sigma ~ z + (1 + w | id)` and labelled residual-scale slope
covariance blocks remain planned.

## Output and Inference Ledger

| Surface | Stable extractor | Profile target status | Notes |
|---|---|---|---|
| Fixed `mu` and `sigma` coefficients | `coef()` and `summary()` | Ready for fixed-effect targets | Wald and profile paths are separate |
| `mu` random-intercept SD | `sdpars$mu`, `summary()`, `profile_targets()` | Ready for direct SD targets | Boundary diagnostics use `check_drm()` |
| `mu` random-slope SD | `sdpars$mu`, `summary()`, `profile_targets()` | Ready for direct SD targets | One numeric slope per ordinary correlated block |
| Ordinary intercept-slope correlation | `corpars$mu`, `corpairs(level = "group")`, `profile_targets()` | Ready for direct correlation targets | Class is `mean-slope`; `location-slope` is a filter alias |
| q > 2 ordinary `mu` block SDs | `sdpars$mu`, `summary()`, `profile_targets()` | Ready for direct SD targets | TMB parameter is `log_sd_re_cov` |
| q > 2 ordinary `mu` block correlations | `corpars$re_cov`, `corpairs(level = "group")`, `summary()`, `profile_targets()` | Explicitly unavailable for direct profiling | Correlations are derived from an unstructured correlation parameterization |
| Residual-scale random-effect SD | `sdpars$sigma`, `summary()`, `profile_targets()` | Ready for direct SD targets | Enters `log(sigma)` |
| `mu`/`sigma` random-intercept correlation | `corpars$mu_sigma`, `corpairs(class = "mean-scale")` | Ready for direct correlation targets | Group-level covariance, not residual coupling; multiple independent matched blocks report multiple rows |
| `sd(id) ~ x_group` coefficients | `coef(fit, "sd(id)")`, `predict(fit, dpar = "sd(id)")` | Fixed-effect rows ready; derived group SD intervals remain limited | Target must be an unlabelled Gaussian `mu` random intercept |

## Deferred Surfaces

The following remained planned or unsupported when the Phase 6c core closed:

- `phylo(1 + x | species, tree = tree)` fitting;
- `spatial(1 + x | site, coords = coords)` fitting, later completed in
  Phase 10 for one numeric univariate Gaussian `mu` slope;
- bivariate random slopes in `mu1`, `mu2`, `sigma1`, or `sigma2`;
- slope-specific `sd(id, dpar = "mu", coef = "x") ~ x_group`;
- random effects in `rho12`;
- intercept-slope `corpair()` formulae;
- slope1-slope2 bivariate plasticity-syndrome correlations.

The surfaces that remain planned still need storage-order documentation,
simulation recovery, extractor names, `profile_targets()` rows, and
reader-facing examples before they can be taught as fitted behaviour.

## Structured-Slope Handoff

The structured one-slope rows were design-complete enough to hand forward, but
not fitted in the Phase 6c core closure. Phase 10 later completed the
coordinate-spatial row for one numeric univariate Gaussian `mu` slope. Slice
186 re-audited the sibling lanes and confirmed that phylogenetic slope syntax
is still rejected while spatial one-slope syntax is fitted. That is an
intentional parity gap, not hidden support.
Slice 187 re-audited the fitted spatial path itself and added direct
profile-interval coverage for the `spatial(0 + x | site)` slope-field SD plus
boundary tests for multiple slopes, spatial scale terms, and bivariate spatial
syntax.

| Surface | Minimum next implementation contract | Destination |
|---|---|---|
| `phylo(1 + x | species, tree = tree)` | one structured `mu` slope, explicit intercept/slope storage order, simulation recovery for slope SD, `sdpars$mu` and `profile_targets()` names, and `check_drm()` replication diagnostics | Phase 12 |
| `spatial(1 + x | site, coords = coords)` | one coordinate-spatial `mu` slope, separation from future mesh/SPDE path, simulation recovery for slope SD, `ranef()`/`sdpars` names, and coordinate diagnostics | Phase 10, completed for one numeric coordinate slope |
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
