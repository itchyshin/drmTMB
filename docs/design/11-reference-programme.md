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
- Brms-style `(1 | p | id)` labels are useful for correlated group-level effects.
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

## Location-Scale-Shape and GAMLSS Roots

Local sources:

```text
Royal Stata Society Series C - 2005 - Rigby - Generalized additive models for location scale and shape.pdf
Statistical Analysis - 2021 - Corrales - Bayesian modeling of location scale and shape parameters in skew-normal.pdf
Phylogenetic_location_scale_shape_models.pdf
```

Package implications:

- Shape parameters such as `skew`, `nu`, and positive-family shape parameters
  should get formulae like any other estimated parameter.
- `skew_normal()` and `skew_t()` should come after Gaussian and Student-t
  location-scale are reliable.

## Spatial Dependence

Local source:

```text
main_phylo_spatial.pdf
```

Package implications:

- Spatial fields should use SPDE/GMRF speed tricks rather than dense covariance
  matrices.
- Spatial syntax should be modular enough to attach initially to `mu`, and
  later to `sigma` when simulation tests show the model is identifiable.

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
3. O'Dea-style double-hierarchical model.
4. Bivariate `rho12 ~ predictors`.
5. Phylogenetic location-scale.
