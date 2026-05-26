# Ayumi and Santi Protocol Formula Gallery

Reader: Ayumi, Santi, and `drmTMB` contributors preparing the first applied
phylogenetic validation runs. This gallery turns the protocol model ladders
into concrete formula sketches and marks each route as runnable, diagnostic, or
planned.

This is a no-fit contract. It is meant to prevent two mistakes before long
model runs begin: treating residual `rho12` as a phylogenetic correlation, and
treating a nearby fitted covariance block as evidence that the full
pre-registered model is routine.

## Status Labels

| Label | Meaning |
| --- | --- |
| Runnable validation | The formula matches a fitted package surface, but the applied protocol still needs convergence and sensitivity evidence. |
| Diagnostic only | The formula can be useful for stress tests or positive controls, but should not yet be the applied showcase. |
| Workflow only | The route is an analysis workflow around fitted models, not new formula syntax. |
| Planned feature | The route needs likelihood, extractor, diagnostics, tests, documentation, and after-task evidence before use. |

Location means the expected trait value. Scale means residual standard
deviation `sigma`. Coscale means the residual bivariate correlation `rho12`.
Phylogenetic correlations, ordinary species correlations, and residual `rho12`
must be reported as separate layers.

## Common Preflight

Every applied run should save the following before fitting:

- response names and transformations;
- species identifier and tree tip matching table;
- the pruned tree name or tree index;
- complete-case counts for each model target;
- centered and scaled predictor definitions;
- class counts for lifestyle or nest habitat;
- the exact formula object;
- the intended estimands and extraction calls.

The minimum post-fit table should include `convergence`, `pdHess`,
maximum absolute gradient, boundary notes from `check_drm()`, `sdpars`,
`rho12()`, `corpairs()`, `profile_targets()`, and any interval status columns.
Point estimates, Wald intervals, profiles, bootstrap intervals, and failed
intervals should not be merged into one uncertainty column.

Helper names such as `prune_tree_to_species()` and `match_data_to_tree()` below
are placeholders for the applied analysis scripts, not exported `drmTMB`
functions.

The shared Objective 1 q2 validation harness is
`tools/ayumi-santi-q2-objective1-runner.R`. It is not a package API. It is a
developer script for prepared CSV or RDS data plus a `phylo` tree, designed to
write preflight and extraction artifacts before anyone interprets the fitted
correlations biologically.

The matching simulated positive control is
`tools/ayumi-santi-q2-positive-control.R`; its design note is
`docs/design/78-ayumi-santi-q2-objective1-positive-control.md`.

The broader simulated-only finish for the first five Ayumi/Santi slices is
`tools/ayumi-santi-finish-sim-slices.R`, with the design note in
`docs/design/79-ayumi-santi-no-real-data-sim-slices.md` and artifacts under
`docs/dev-log/ayumi-santi/sim-slices/`.

## Santi Mammal Protocol

The mammal protocol models adult body mass and litter size, then asks whether
the association differs among terrestrial, aquatic, and aerial mammals.

### M1: Objective 1 q2 Phylogenetic Location Model

Status: Runnable validation.

Purpose: estimate the phylogenetic location-location correlation between adult
body mass and litter size, while keeping residual `rho12` separate.

```r
fit_m1 <- drmTMB(
  formula = bf(
    mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
    mu2 = log_litter_size ~ 1 + phylo(1 | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  ),
  family = c(gaussian(), gaussian()),
  data = dat_mammal
)
```

Primary extraction:

```r
corpairs(fit_m1, level = "phylogenetic")
rho12(fit_m1)
fit_m1$sdpars$mu
check_drm(fit_m1)
```

Interpretation: the phylogenetic `corpairs()` row is the shared-ancestry
trait-correlation target. `rho12` is the remaining row-level residual
correlation after the fixed effects and phylogenetic effects.

### M2: Objective 2 q4 Phylogenetic Location-Scale Model

Status: Diagnostic only.

Purpose: estimate constant phylogenetic correlations among `mu1`, `mu2`,
`sigma1`, and `sigma2`.

```r
fit_m2 <- drmTMB(
  formula = bf(
    mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
    mu2 = log_litter_size ~ 1 + phylo(1 | p | species, tree = tree),
    sigma1 = ~1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  ),
  family = c(gaussian(), gaussian()),
  data = dat_mammal
)
```

Primary extraction:

```r
corpairs(fit_m2, level = "phylogenetic")
profile_targets(fit_m2)
check_drm(fit_m2)
```

Interpretation: `corpairs()` can report the six q4 phylogenetic endpoint
correlations. Full q4 correlations are currently derived-only for intervals,
so this model needs positive-control and real-data hardening before it becomes
the applied route.

### M3: Objective 3 Lifestyle Split-Fit Sensitivity

Status: Workflow only.

Purpose: compare the body mass-litter size correlation across terrestrial,
aquatic, and aerial mammals without introducing class-specific covariance
syntax yet.

```r
fits_m3 <- lapply(split(dat_mammal, dat_mammal$lifestyle), function(dat_g) {
  tree_g <- prune_tree_to_species(tree, dat_g$species)

  drmTMB(
    formula = bf(
      mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree_g),
      mu2 = log_litter_size ~ 1 + phylo(1 | p | species, tree = tree_g),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat_g
  )
})
```

Interpretation: this compares class-pruned estimates. It is not the same model
as a single likelihood with lifestyle-specific covariance matrices, but it is
the right first stress test for class sizes, tree information, and boundary
behaviour.

### M4: Single-Model Lifestyle-Specific Covariance

Status: Planned feature.

Purpose: estimate `Sigma_a,g` and `Sigma_e,g` inside one model, where `g` is
terrestrial, aquatic, or aerial.

Needed before syntax opens: log-SD and Fisher-z parameterization by class,
positive-definite covariance construction, class-size diagnostics, extractor
rows for class-specific correlations, simulation recovery, and user-facing
fallback rules.

## Santi Avian Clutch-Size Protocol

The avian clutch-size protocol mirrors the mammal protocol but uses adult body
mass and clutch size, with nest habitat as the class variable.

### A1: Objective 1 q2 Phylogenetic Location Model

Status: Runnable validation.

```r
fit_a1 <- drmTMB(
  formula = bf(
    mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
    mu2 = log_clutch_size ~ 1 + phylo(1 | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1
  ),
  family = c(gaussian(), gaussian()),
  data = dat_bird_clutch
)
```

Primary extraction:

```r
corpairs(fit_a1, level = "phylogenetic")
rho12(fit_a1)
check_drm(fit_a1)
```

Interpretation: the phylogenetic row asks whether lineages with larger body
mass also tend to have larger or smaller clutch size. `rho12` is the
independent-species residual coupling for complete response rows.

### A2: Objective 2 q4 Phylogenetic Location-Scale Model

Status: Diagnostic only.

```r
fit_a2 <- drmTMB(
  formula = bf(
    mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
    mu2 = log_clutch_size ~ 1 + phylo(1 | p | species, tree = tree),
    sigma1 = ~1 + phylo(1 | p | species, tree = tree),
    sigma2 = ~1 + phylo(1 | p | species, tree = tree),
    rho12 = ~1
  ),
  family = c(gaussian(), gaussian()),
  data = dat_bird_clutch
)
```

Interpretation: the q4 rows name the phylogenetic location-location,
scale-scale, and four location-scale correlations. They are useful for
checking whether the protocol's Objective 2 model is numerically plausible,
but not yet for routine applied inference.

### A3: Objective 3 Nest-Habitat Split-Fit Sensitivity

Status: Workflow only.

```r
fits_a3 <- lapply(split(dat_bird_clutch, dat_bird_clutch$nest_habitat), function(dat_h) {
  tree_h <- prune_tree_to_species(tree, dat_h$species)

  drmTMB(
    formula = bf(
      mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree_h),
      mu2 = log_clutch_size ~ 1 + phylo(1 | p | species, tree = tree_h),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = c(gaussian(), gaussian()),
    data = dat_h
  )
})
```

Interpretation: this is a class-pruned sensitivity analysis. It should report
nest-habitat sample sizes, tree sizes, convergence status, and correlation
estimates before any single-model habitat-specific covariance feature is
designed.

## Ayumi Ecogeographic Protocol

The ecogeographic preregistration treats univariate phylogenetic
location-scale models as the primary species-level route. Selected bivariate
PLSMs are exploratory.

### E1: Univariate PLSM For Body Mass Or Plumage Lightness

Status: Runnable validation.

```r
fit_e1 <- drmTMB(
  formula = bf(
    trait ~ temp + precip + I(temp^2) + I(precip^2) +
      phylo(1 | p | species, tree = tree),
    sigma ~ temp + precip + I(temp^2) + I(precip^2) +
      phylo(1 | p | species, tree = tree)
  ),
  family = gaussian(),
  data = dat_ecogeo
)
```

Primary extraction:

```r
fixef(fit_e1)
fit_e1$sdpars
corpairs(fit_e1, level = "phylogenetic")
check_drm(fit_e1)
```

Interpretation: fixed effects in `mu` estimate average climate-trait
relationships. Fixed effects in `sigma` estimate changes in residual
species-level heterogeneity around the climate model. The phylogenetic
`mu`-`sigma` correlation asks whether lineages with higher fitted trait values
also tend to show larger or smaller residual heterogeneity.

### E2: Univariate Appendage PLSM With Allometry

Status: Runnable validation.

```r
fit_e2 <- drmTMB(
  formula = bf(
    appendage ~ temp + precip + I(temp^2) + I(precip^2) + log_body_mass +
      phylo(1 | p | species, tree = tree),
    sigma ~ temp + precip + I(temp^2) + I(precip^2) + log_body_mass +
      phylo(1 | p | species, tree = tree)
  ),
  family = gaussian(),
  data = dat_ecogeo
)
```

Interpretation: the appendage fixed effects are body-size-adjusted climate
effects. The scale model asks whether residual appendage heterogeneity changes
with climate and body mass after the location model is fitted.

### E3: Exploratory Bivariate PLSM For A Trait Pair

Status: Diagnostic only.

```r
fit_e3 <- drmTMB(
  formula = bf(
    mu1 = trait1 ~ temp + precip + I(temp^2) + I(precip^2) +
      phylo(1 | p | species, tree = tree),
    mu2 = trait2 ~ temp + precip + I(temp^2) + I(precip^2) +
      phylo(1 | p | species, tree = tree),
    sigma1 = ~ temp + precip + I(temp^2) + I(precip^2) +
      phylo(1 | p | species, tree = tree),
    sigma2 = ~ temp + precip + I(temp^2) + I(precip^2) +
      phylo(1 | p | species, tree = tree),
    rho12 = ~1
  ),
  family = c(gaussian(), gaussian()),
  data = dat_ecogeo_pair
)
```

Appendage responses should include `log_body_mass` in the matching `mu` and
`sigma` formulas. This is a q4 diagnostic route until the Ayumi real-data
boundary behaviour is resolved.

### E4: Family-Level Slope Synthesis

Status: Workflow only.

Purpose: summarize family-specific climate slopes and then meta-analyse those
slopes. This is a separate analysis lane from the species-level q4
phylogenetic covariance model.

If each family contributes a slope estimate and known sampling variance, the
nearest package surface is known-sampling-covariance Gaussian regression. Use
that only after the slope table and uncertainty table are explicit. Do not add
`meta_gaussian()` or `tau ~` syntax for this protocol.

## Optional Direct-SD Scaffold

Status: Runnable validation when the biological question is species-specific
phylogenetic SD or q2 predictor-dependent phylogenetic correlation.

```r
fit_direct_sd <- drmTMB(
  formula = bf(
    mu1 = trait1 ~ x + phylo(1 | p | species, tree = tree),
    mu2 = trait2 ~ x + phylo(1 | p | species, tree = tree),
    sigma1 = ~1,
    sigma2 = ~1,
    rho12 = ~1,
    sd1(species, level = "phylogenetic") ~ z1_species,
    sd2(species, level = "phylogenetic") ~ z2_species,
    corpair(
      species,
      level = "phylogenetic",
      block = "p",
      from = "mu1",
      to = "mu2"
    ) ~ z_cor_species
  ),
  family = c(gaussian(), gaussian()),
  data = dat_pair
)
```

Interpretation: `sd1()` and `sd2()` model the species-level phylogenetic SD
surfaces for the two location endpoints. The `corpair()` formula models the
q2 phylogenetic location-location correlation. None of these terms model
residual `sigma1`, residual `sigma2`, q4 location-scale correlations, or
residual `rho12`.

## Tree Uncertainty

Status: Workflow only.

Near-term `drmTMB` analysis should use a maximum-likelihood tree loop:

```r
fits_by_tree <- lapply(seq_along(trees), function(k) {
  tree_k <- trees[[k]]
  dat_k <- match_data_to_tree(dat, tree_k)

  drmTMB(
    formula = formula_target,
    family = family_target,
    data = dat_k
  )
})
```

The report should summarize movement in `corpairs()`, `rho12()`, SDs, fixed
effects, convergence, and boundary diagnostics across trees. This is a
sensitivity analysis, not Bayesian posterior pooling.

## Planned Or Deferred

| Target | Why Deferred |
| --- | --- |
| Partially missing bivariate responses through marginal likelihood | Current bivariate fitting uses complete cases across response and predictor formulas; partial-response marginalization is a separate likelihood feature. |
| Single-model lifestyle or nest-habitat covariance surfaces | Needs class-specific positive-definite covariance construction, class-size diagnostics, extractor rows, simulation recovery, and fallback rules. |
| Predictor-dependent q4 phylogenetic `corpair()` | Needs a positive-definite q4 correlation-regression contract; six independent `tanh()` regressions would not be enough. |
| q4 derived intervals | Current q4 correlations are point-estimate rows with explicit derived-unavailable interval status. |
| Bayesian posterior pooling across trees | Outside the current maximum-likelihood package surface; use tree-loop sensitivity first. |

## First Run Order

1. Mammal M1 and avian A1 on representative trees.
2. Ecogeographic E1 for body mass and plumage lightness.
3. Ecogeographic E2 for one appendage trait.
4. Positive-control q4 fit before any full Ayumi/Santi q4 applied run.
5. Split-fit lifestyle and nest-habitat sensitivity after q2 behaves.
