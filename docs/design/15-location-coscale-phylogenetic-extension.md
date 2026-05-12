# Location-Coscale Phylogenetic Extension

This note records why `rho12 ~ predictors` is the central scientific
contribution of `drmTMB`, and how it extends phylogenetic location-scale models
from Nakagawa et al. (2025).

## Foundation: Phylogenetic Location-Scale Models

The MEE phylogenetic location-scale model treats trait means and residual
variation as linked evolutionary quantities. In a univariate PLSM:

```text
y_i = mu_i + e_i
mu_i = X[i, ] beta + a_i
a ~ Normal(0, sigma_a^2 A)
log(sigma_ei) = W[i, ] gamma
```

In richer PLSMs, the scale part can also have phylogenetic effects, so the
mean and log residual SD have their own phylogenetic covariance structure. In
bivariate PLSMs this yields interpretable group-level correlations:

```text
rho_a(l1,l2)  mean-mean phylogenetic correlation
rho_a(s1,s2)  scale-scale phylogenetic correlation
rho_a(l1,s1)  within-trait mean-scale correlation
rho_a(l1,s2)  cross-trait mean-scale correlation
```

These are not residual `rho12`. They are correlations among phylogenetic or
group-level effects.

## Extension: Location-Coscale Models

Location-scale models relax constant residual variance. Location-coscale
models also relax constant residual covariance or correlation between two
responses.

For two responses:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)

Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i

log(sigma1_i) = W1[i, ] gamma1
log(sigma2_i) = W2[i, ] gamma2
eta_rho12_i = R[i, ] delta
rho12_i = 0.99999999 * tanh(eta_rho12_i)
```

The third equation is the distinctive `drmTMB` idea. It asks whether the
residual coupling between two traits changes with predictors after the means
and residual scales have been modelled.

## Biological Questions

The mammalian body mass-litter size protocol by Ortega et al. is an ideal
central example. It explicitly motivates partitioning a bivariate association
into phylogenetic and non-phylogenetic components, then asking whether
lifestyle changes means, dispersion, and residual coupling.
`docs/design/29-mammal-location-coscale-route.md` maps that protocol to the
current `drmTMB` boundary and to the staged covariance work needed before the
full model is runnable.
It asks:

- Is the body mass-litter size association mostly phylogenetic?
- Does a non-phylogenetic association remain after shared ancestry?
- Do lifestyles such as terrestrial, aquatic, and aerial change the strength
  of the association?
- Do lineages with different mean trait values also differ in dispersion?
- Does dispersion covary across traits?

In `drmTMB`, the bivariate location-coscale part should eventually target
questions like the following. The implemented seed now covers fixed-effect
`rho12 ~ predictors`, optional matching ordinary random-intercept covariance
blocks, and matching intercept-only phylogenetic `mu1`/`mu2` covariance.

```r
drmTMB(
  formula = drm_formula(
    mu1 = log_body_mass ~ lifestyle + x1 + phylo(1 | species, tree = tree),
    mu2 = log_litter_size ~ lifestyle + x1 + phylo(1 | species, tree = tree),
    sigma1 = ~ lifestyle,
    sigma2 = ~ lifestyle,
    rho12 = ~ lifestyle
  ),
  family = c(gaussian(), gaussian()),
  data = mammals
)
```

## Correlation Levels

`drmTMB` should eventually model more than residual correlation. The public
grammar and extractors need a correlation namespace that keeps each level
visible:

| Level | Symbolic target | Scientific question | Status |
|---|---|---|---|
| Residual | `rho12_i` in `Omega_i` | Are the two responses coupled within an observation after means and scales are modelled? | implemented for fixed-effect bivariate Gaussian |
| Phylogenetic mean | `cor(a_mu1, a_mu2)` where `[a_mu1, a_mu2] ~ MVN(0, Sigma_phylo)` | Do species with high phylogenetic deviation in trait 1 also have high phylogenetic deviation in trait 2? | implemented for matching intercept-only `phylo()` terms in `mu1` and `mu2` |
| Non-phylogenetic mean | `cor(c_mu1, c_mu2)` where `[c_mu1, c_mu2] ~ MVN(0, Sigma_species)` | Is there a residual among-species association beyond shared ancestry? | implemented for matching labelled ordinary random intercepts |
| Phylogenetic scale | `cor(a_sigma1, a_sigma2)` | Do lineages that are more dispersed for one trait tend to be more dispersed for the other? | planned |
| Mean-scale | `cor(a_mu1, a_sigma2)` or analogous terms | Do high trait means covary with dispersion in the same or another trait? | planned |
| Spatial or site-level | `cor(z_mu1, z_mu2)` or covariance-block correlations | Do places, sites, studies, or other groups show coupled deviations across responses? | planned |

The implemented bivariate model now covers the residual row and the first
mean-mean phylogenetic and ordinary group-level rows of this table. The
long-term location-coscale programme should also estimate scale, mean-scale,
and spatial correlations when the data and simulations support them.

Extractor names should therefore be level-specific, for example
`corpars$phylo`, `corpars$species`, `corpars$spatial`, or labelled
group-level covariance blocks. Do not use bare `rho12` for these quantities.
The general long-format pair plan is in
`docs/design/20-coscale-correlation-pairs.md`.

## Implementation Stages

1. Fixed-effect Gaussian `rho12 ~ predictors`.
2. Univariate Gaussian simple random intercepts and random slopes in `mu`.
3. Sparse phylogenetic `phylo(1 | species, tree = tree)` in univariate `mu`
   using the Hadfield and Nakagawa A-inverse path.
4. Bivariate Gaussian with phylogenetic and non-phylogenetic mean covariance.
   Done for matching intercept-only `phylo()` terms and matching labelled
   ordinary random intercepts.
5. Bivariate location-scale with phylogenetic scale effects.
6. Bivariate location-coscale with fixed-effect `rho12 ~ predictors` plus
   phylogenetic mean and scale structure.
7. Later only: phylogenetic effects in the `rho12` linear predictor itself.

The ordering matters. The coscale idea is powerful, but the models become
weakly identified quickly. Each stage needs symbolic equations, simulation
recovery, comparator checks where possible, and an after-task report.

## Naming Rule

- Use `rho12` for residual response-response correlation.
- Use level-specific covariance-block summaries for phylogenetic,
  non-phylogenetic species, spatial, study, site, or other random-effect
  correlations, such as `cor_phylo(mu1,mu2)`, `cor_species(mu1,mu2)`, or
  `rho_a(l1,l2)` in paper notation.
- Do not call every correlation `rho12`; that would erase the biological
  distinction between residual coupling and evolutionary covariance.
