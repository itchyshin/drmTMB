# Mammal Location-Coscale Route

This note maps the mammal body mass and litter-size protocol supplied by the
project owner onto the current and planned `drmTMB` surface. The reader is a
package contributor deciding which model slice to implement next, plus an
applied evolutionary ecologist who needs to know which analyses can be run now.

The source protocol is the local 6 May 2026 PDF titled "Phylogeny,
variability, and lifestyle dependence in the relationship between body mass and
litter size in mammals". It proposes bivariate phylogenetic models for log
adult body mass and log litter size, with terrestrial, aquatic, and aerial
lifestyle contrasts.

## Scientific Target

The protocol has three model targets.

Objective 1 partitions the body mass-litter size association into a
phylogenetic mean-mean correlation and a non-phylogenetic species mean-mean
correlation:

```text
[a_mass, a_litter]' ~ MVN(0, Sigma_a^(l) kron A)
[e_mass, e_litter]' ~ MVN(0, Sigma_e^(l) kron I)
```

The estimands are the phylogenetic correlation `rho_a(l1,l2)`, the
non-phylogenetic species correlation `rho_e(l1,l2)`, and trait-specific
phylogenetic heritability for the two means. These are structured covariance
parameters, not residual `rho12`.

Objective 2 extends that model to a bivariate phylogenetic location-scale
model. Location means and observation-level log residual SDs are jointly
modelled through a phylogenetic covariance matrix:

```text
u_species =
  [a_mass_location, a_litter_location,
   a_mass_log_sd, a_litter_log_sd]'

u_species ~ MVN(0, Sigma_a^(location_scale) kron A)
```

The main estimands are the phylogenetic mean-mean correlation, the
phylogenetic scale-scale correlation, and the non-phylogenetic mean-mean
correlation. Mean-scale and cross-trait mean-scale correlations are secondary
quantities that need careful naming in any extractor.

Objective 3 lets lifestyle change mean traits and the phylogenetic and
non-phylogenetic covariance matrices:

```text
Sigma_a,g^(l) and Sigma_e,g^(l), where g is terrestrial, aquatic, or aerial
```

In Objective 3, the SDs describe variation in species-level trait means within
lifestyle groups. They are not observation-level residual `sigma1` or
`sigma2`.

## Current `drmTMB` Boundary

Several useful scouting models can be run before the full protocol is
implemented:

| Protocol need | Current `drmTMB` status | Safe use now |
|---|---|---|
| One-trait phylogenetic mean structure | Implemented for univariate Gaussian `mu` with `phylo(1 | species, tree = tree)` | Fit separate log body mass and log litter size models. |
| One-trait residual scale predictors | Implemented for Gaussian `sigma ~ predictors` | Explore lifestyle or data-quality effects on observation-level residual SD. |
| Two-trait residual coupling | Implemented for fixed-effect bivariate Gaussian `rho12 ~ predictors` | Scout whether residual coupling changes with lifestyle after fixed-effect means and scales. |
| Bivariate phylogenetic mean covariance | Planned | Needed for Objective 1. |
| Bivariate non-phylogenetic species covariance | Planned | Needed for Objectives 1 and 3. |
| Phylogenetic scale effects and 4 by 4 location-scale covariance | Planned | Needed for Objective 2. |
| Lifestyle-specific structured covariance matrices | Planned | Needed for Objective 3. |
| Posterior pooling across many trees | Outside the current maximum-likelihood surface | Use tree-loop sensitivity summaries first; Bayesian posterior pooling needs a separate implementation path. |

The immediate runnable bivariate seed is:

```r
drmTMB(
  formula = bf(
    mu1 = log_body_mass ~ lifestyle,
    mu2 = log_litter_size ~ lifestyle,
    sigma1 = ~ lifestyle,
    sigma2 = ~ lifestyle,
    rho12 = ~ lifestyle
  ),
  family = c(gaussian(), gaussian()),
  data = mammals
)
```

This estimates residual `rho12`, not the protocol's phylogenetic or
non-phylogenetic mean-mean correlations.

The immediate runnable univariate phylogenetic scouts are:

```r
drmTMB(
  formula = bf(
    log_body_mass ~ lifestyle + phylo(1 | species, tree = tree),
    sigma ~ lifestyle
  ),
  family = gaussian(),
  data = mammals
)

drmTMB(
  formula = bf(
    log_litter_size ~ lifestyle + phylo(1 | species, tree = tree),
    sigma ~ lifestyle
  ),
  family = gaussian(),
  data = mammals
)
```

These can assess one-trait phylogenetic signal and residual SD structure, but
they do not estimate a bivariate phylogenetic correlation. The first fitted
bivariate phylogenetic location slice can now estimate the mean-mean
phylogenetic correlation with matching intercept-only `mu1`/`mu2` `phylo()`
terms; phylogenetic scale and mean-scale correlations remain planned.

## Correlation Names

The mammal route needs three correlation layers to stay visible.

| Layer | Protocol notation | `drmTMB` naming rule |
|---|---|---|
| Residual row-level coupling | Not the main Objective 1-3 target | Use `rho12` only for the bivariate residual correlation in `Omega_i`. |
| Phylogenetic trait covariance | `rho_a(l1,l2)`, `rho_a(s1,s2)`, mean-scale pairs | Use `corpairs(fit, level = "phylogenetic")` for the first fitted mean-mean slice; future rows should cover the complete phylogenetic set. |
| Non-phylogenetic species covariance | `rho_e(l1,l2)` | Use an ordinary labelled species block and read it with `corpairs(fit, level = "group")`; when combined with `phylo()`, `check_drm()` notes the same-group separation risk. |

This naming is not cosmetic. A residual `rho12 ~ lifestyle` model asks whether
two traits remain coupled within an observation after fixed-effect location and
scale predictors. The protocol's `rho_a` and `rho_e` ask whether species or
lineages have coupled trait deviations at structured levels.

## Implementation Route

The route should be pushed, but in small covariance slices.

1. Keep the fixed-effect bivariate Gaussian `rho12` path green while it becomes
   the scouting model for mammal residual coupling.
2. Use the implemented bivariate Gaussian `mu1` and `mu2` ordinary species
   covariance blocks as the non-phylogenetic species layer.
3. Use the implemented bivariate Gaussian phylogenetic `mu1` and `mu2`
   covariance block with the existing sparse A-inverse path. This unlocks a
   maximum-likelihood analogue of Objective 1 for one tree at a time.
4. Add a tree-loop workflow that refits the Objective 1 analogue across a small
   tree set and reports sensitivity of `rho_a(l1,l2)` and `rho_e(l1,l2)`.
5. Add phylogenetic scale effects only after the bivariate location covariance
   path has recovery evidence. This is the gate before Objective 2.
6. Add the four-effect phylogenetic location-scale covariance block:
   location for trait 1, location for trait 2, log residual SD for trait 1, and
   log residual SD for trait 2.
7. Add lifestyle-specific covariance structures only after the common
   bivariate phylogenetic and non-phylogenetic blocks are stable. This is the
   Objective 3 gate.

Each step should have symbolic equations, R syntax, simulation recovery,
extractor naming, `check_drm()` diagnostics where relevant, and an after-task
report before the next covariance layer starts.

## First Pull Request Slice

The next implementation PR should not try to fit Objective 2 or Objective 3.
The first useful slice is bivariate Gaussian species-level covariance for
`mu1` and `mu2`, because it exercises:

- two-response random-effect design matrices;
- a positive-definite 2 by 2 covariance block;
- `corpairs()` output for a non-residual mean-mean pair;
- clear separation between species-level correlation and residual `rho12`;
- simulation recovery for both SDs and the correlation.

That slice gives the package a rehearsal for both the non-phylogenetic species
layer and the later phylogenetic layer without combining all protocol
complexity at once.

## Not Yet In Scope

Do not introduce `rho ~` as a shortcut. Use `rho12` for residual bivariate
correlation and level-specific names for structured covariance pairs.

Do not add a special mammal family, a `meta_gaussian()` helper, or `tau ~`
syntax for this route. The mammal protocol is still Gaussian regression with
structured covariance and distributional formulas.

Do not present posterior pooling across 50 trees as implemented in `drmTMB`
until there is an explicit Bayesian or tree-loop uncertainty design. A
maximum-likelihood tree loop can be useful earlier, but it is a sensitivity
workflow rather than the same posterior-pooling procedure described in the
protocol.
