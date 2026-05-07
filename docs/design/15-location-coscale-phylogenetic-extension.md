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
models also relax constant residual covariance.

For two responses:

```text
[y1_i, y2_i]' ~ MVN([mu1_i, mu2_i]', Omega_i)

Omega_i[1,1] = sigma1_i^2
Omega_i[2,2] = sigma2_i^2
Omega_i[1,2] = rho12_i * sigma1_i * sigma2_i

log(sigma1_i) = W1[i, ] gamma1
log(sigma2_i) = W2[i, ] gamma2
atanh(rho12_i) = R[i, ] delta
```

The third equation is the distinctive `drmTMB` idea. It asks whether the
residual coupling between two traits changes with predictors after the means
and residual scales have been modelled.

## Biological Questions

The mammalian body mass-litter size protocol is an ideal flagship example.
It asks:

- Is the body mass-litter size association mostly phylogenetic?
- Does a non-phylogenetic association remain after shared ancestry?
- Do lifestyles such as terrestrial, aquatic, and aerial change the strength
  of the association?
- Do lineages with different mean trait values also differ in dispersion?
- Does dispersion covary across traits?

In `drmTMB`, the bivariate location-coscale part targets questions like:

```r
drmTMB(
  formula = drm_formula(
    mu1 = log_body_mass ~ lifestyle + x1 + phylo(species),
    mu2 = log_litter_size ~ lifestyle + x1 + phylo(species),
    sigma1 = ~ lifestyle,
    sigma2 = ~ lifestyle,
    rho12 = ~ lifestyle
  ),
  family = c(gaussian(), gaussian()),
  data = mammals
)
```

This syntax is aspirational. The implemented seed is fixed-effect
`biv_gaussian()` with `rho12 ~ predictors`.

## Implementation Stages

1. Fixed-effect Gaussian `rho12 ~ predictors`.
2. Univariate Gaussian simple random intercepts and random slopes in `mu`.
3. Sparse phylogenetic `phylo(species)` in univariate `mu` using A-inverse.
4. Bivariate Gaussian with phylogenetic and non-phylogenetic mean covariance.
5. Bivariate location-scale with phylogenetic scale effects.
6. Bivariate location-coscale with fixed-effect `rho12 ~ predictors` plus
   phylogenetic mean and scale structure.
7. Later only: phylogenetic effects in `atanh(rho12)` itself.

The ordering matters. The coscale idea is powerful, but the models become
weakly identified quickly. Each stage needs symbolic equations, simulation
recovery, comparator checks where possible, and an after-task report.

## Naming Rule

- Use `rho12` for residual response-response correlation.
- Use covariance-block summaries for phylogenetic or random-effect
  correlations such as `rho_a(l1,l2)` or `rho_a(s1,s2)`.
- Do not call every correlation `rho12`; that would erase the biological
  distinction between residual coupling and evolutionary covariance.
