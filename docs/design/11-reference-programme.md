# Reference and Paper Programme

The local paper folder is:

```text
/Users/z3437171/Desktop/dis_reg_models
```

This document maps the papers into package design decisions. It is not a full
literature review yet; future phases should add deeper notes, equations, data
links, and vignette examples.

## Location-Scale Core

Local source:

```text
Methods Ecol Evol - 2025 - Nakagawa - Location scale models in ecology and evolution Heteroscedasticity in continuous .pdf
```

Package implications:

- `drmTMB` should make location-scale models routine rather than special.
- The first worked path is Gaussian `bf(y ~ x1, sigma ~ x1)`.
- Counts and proportions are not afterthoughts; negative binomial,
  COM-Poisson, beta, beta-binomial, and zero/one-inflated families belong on
  the roadmap.
- Tutorials should use ecological and evolutionary examples where variance is
  biological signal, not just nuisance.

## Location-Scale Meta-Analysis

Local source:

```text
Global Change Biology - 2025 - Nakagawa - Location-Scale Meta-Analysis and Meta-Regression as a Tool to Capture Large-Scale.pdf
```

Package implications:

- Meta-analysis is Gaussian regression with known sampling covariance.
- Use `meta_known_V(V = V)` in the formula and `family = gaussian()`.
- Keep public `sigma` terminology; explain that meta-analysis papers often call
  the same extra heterogeneity SD `tau`.
- Make heterogeneous heterogeneity a first-class example:

```r
bf(
  yi ~ x1 + x2 + meta_known_V(V = V),
  sigma ~ x1
)
```

## Heterogeneous Heterogeneity

Local source:

```text
Brit J Math Statis - 2023 - Rodriguez - Heterogeneous heterogeneity by default Testing categorical moderators in.pdf
```

Package implications:

- Categorical moderators in scale models should be common and well documented.
- Examples should distinguish mean moderation from heterogeneity moderation.

## Double-Hierarchical Predictability and Plasticity

Local source:

```text
Methods Ecol Evol - 2021 - O'Dea - Unifying individual differences in personality predictability and plasticity A.pdf
```

Package implications:

- The formula grammar must support mean and scale models with shared grouping
  structures.
- Labelled `(1 | p | id)` covariance blocks are useful for correlated
  group-level effects.
- `sd(group) ~ predictors` is reserved for random-effect scale models.

## Correlations Between Variance Components

Local source:

```text
Methods Ecol Evol - 2025 - King - Quantifying the correlation between variance components An extension to the.pdf
```

Package implications:

- Later DHGLM work should allow correlations among residual-scale and
  random-effect-scale components where identifiable.
- This is distinct from residual bivariate `rho12`.

## Phylogenetic Location-Scale Models

Local source:

```text
Methods Ecol Evol - 2025 - Nakagawa - Quantifying macro-evolutionary patterns of trait mean and variance with phylogenetic.pdf
```

Package implications:

- Phylogenetic dependence should be planned from Phase 1.
- The computational path should use sparse A-inverse or precision-matrix tricks.
- Multivariate phylogenetic examples should stay bivariate in `drmTMB`; larger
  response sets belong to `gllvmTMB`.
- The key scientific move is to treat variance as an evolvable trait-like
  response, not only as nuisance.
- The bivariate MEE extension gives several interpretable phylogenetic
  correlations: mean-mean, scale-scale, within-trait mean-scale, and
  across-trait mean-scale. `drmTMB` should expose these as group-level
  covariance summaries, not confuse them with residual `rho12`.

## Location-Coscale Extension

Local sources:

```text
/Users/z3437171/Downloads/Bivariate_location_coscale.pdf
/Users/z3437171/Downloads/Mammalian_location_co_scale_trade_offs_protocol.pdf
```

Package implications:

- Location-coscale models are the package's clearest unique contribution:
  means, residual SDs, and residual correlations can all have predictors.
- The core residual equations are:

```text
log(sigma1_i) = W1[i, ] gamma1
log(sigma2_i) = W2[i, ] gamma2
atanh(rho12_i) = R[i, ] delta
```

- For mammals, the natural teaching example is the body mass-litter size
  trade-off, asking whether trait association is phylogenetic, non-phylogenetic,
  lifestyle-dependent, or expressed through dispersion around mean patterns.
- The location-coscale paper extends the MEE PLSM paper by releasing residual
  covariance/correlation from homogeneity, just as location-scale models
  release residual variance from homogeneity.
- Phylogenetic effects in `sigma` or `rho12` predictors are important but later
  implementation phases because they need strong replication, careful
  regularisation, and simulation evidence.

## Location-Scale-Shape and GAMLSS Roots

Local sources:

```text
Royal Stata Society Series C - 2005 - Rigby - Generalized additive models for location scale and shape.pdf
Statistical Analysis - 2021 - Corrales - Bayesian modeling of location scale and shape parameters in skew-normal.pdf
Phylogenetic_location_scale_shape_models.pdf
```

Package implications:

- Treat Rigby and Stasinopoulos (2005) as the foundational distributional
  regression paper for the package grammar.
- Use the GAMLSS-style parameter vocabulary as the default:
  - `mu` for location;
  - `sigma` for scale;
  - `nu` for the first shape parameter;
  - `tau` for the second shape parameter.
- Shape parameters should get formulae like any other estimated parameter.
- For skew-normal-like families, prefer canonical `nu` over `skew` unless a
  later usability study shows that an alias is needed.
- `skew_normal()` and `skew_t()` should come after Gaussian and Student-t
  location-scale are reliable.

## Spatial Dependence

Local source:

```text
main_phylo_spatial.pdf
/Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf
```

Package implications:

- Spatial fields should use SPDE/GMRF speed tricks rather than dense covariance
  matrices.
- Spatial syntax should be modular enough to attach initially to `mu`, and
  later to `sigma` when simulation tests show the model is identifiable.
- Phylogenetic and spatial dependence share the same structured random-effect
  template: `z ~ MVN(0, sigma_z^2 K)`, with `K = A` for phylogeny and `K = M`
  for space.
- Meta-analysis is an ideal teaching bridge because known sampling covariance
  `V`, phylogenetic correlation `A`, and spatial correlation `M` are all known
  matrix structures that enter the likelihood in different places.
- Identifiability should be treated as a first-class package diagnostic:
  species, locations, studies, and effect sizes must have enough replication to
  separate structured and unstructured variance components.

## Phylogenetic And Spatial Meta-Analysis Tutorial

Local source:

```text
/Users/z3437171/Downloads/Tutorial___Phylo_spatial_meta_analysis_2.pdf
```

Package implications:

- Teach phylogenetic and spatial models as distance-to-correlation models:
  evolutionary distance for phylogeny, geographic distance for space.
- Use Brownian motion versus linear spatial decay and OU versus exponential
  spatial decay as paired examples.
- Document that OU and exponential spatial kernels share the same form when
  `alpha = 1 / range`.
- When implementing meta-analysis extensions, support both structured and
  unstructured components where identifiable:
  `p_species ~ MVN(0, sigma_phylo^2 A)` plus
  `q_species ~ MVN(0, sigma_species^2 I)`, or
  `l_location ~ MVN(0, sigma_space^2 M)` plus
  `m_location ~ MVN(0, sigma_location^2 I)`.

## Tutorial and Data Reuse

Many papers have online tutorials or GitHub repositories. For each future
article, add:

- source paper;
- online tutorial or data repository;
- exact data license;
- minimal reproducible example;
- package feature it tests.

The first target tutorials should be:

1. Gaussian location-scale.
2. Location-scale meta-analysis.
3. Double-hierarchical individual-differences model.
4. Bivariate `rho12 ~ predictors`.
5. Phylogenetic location-scale.
