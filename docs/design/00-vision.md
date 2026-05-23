# Vision

`drmTMB` provides fast distributional regression models using TMB, focused on
univariate and bivariate responses. The package should remain broadly useful,
like `glmmTMB`, while the first tutorials and examples are motivated by
ecology, evolution, and environmental science.

The package identity is:

> memorable distributional formulae, glmmTMB-like speed, GAMLSS-style
> parameter modelling, and explicit bivariate coscale models.

`brms` is an important conceptual reference, but `drmTMB` should not copy its
grammar wholesale. The public grammar should be easy to remember for applied
biologists and strict enough to keep the TMB implementation identifiable.

Every implemented model class should have two parallel representations:

1. symbolic equations that define the likelihood and parameter meanings;
2. matching R syntax that maps each equation term to a formula component.

This is both a development discipline and a teaching principle. Equations
should prevent API drift; syntax should make those equations usable.

## Core Idea

A model is defined by:

1. one or two response formulas;
2. one formula for every estimated distributional parameter;
3. optional known-covariance formula markers such as `meta_V(V = V)`;
4. optional structural dependence terms such as `animal()`, `phylo()`,
   `spatial()`, and `relmat()`;
5. a family object that defines parameters, links, likelihood, simulation, and
   starting values.

Parameters often share predictors, but coefficients are parameter specific.
For example, `x` in `mu ~ x` and `sigma ~ x` creates separate location and
scale effects.

## Signature Feature

The signature syntax should read like two biological response models plus
formulae for scale and residual coupling:

```r
drm_formula(
  mu1 = y1 ~ x1 + x2 + (1 + x2 | p | id),
  mu2 = y2 ~ x1      + (1 + x2 | p | id),
  sigma1 = ~ x1 + x2,
  sigma2 = ~ x1,
  rho12 = ~ x1 + x2
)
```

The `rho12` formula models residual correlation as a scientific response
rather than treating covariance homogeneity as a default assumption. The
`|p|` label controls group-level random-effect correlation blocks and is not
the same thing as residual `rho12`.

This is the package's strongest distinct contribution. Location-scale models
ask whether predictors change means and residual SDs. Location-coscale models
also ask whether predictors change the residual coupling between two traits.
That opens biological questions about trade-offs, integration, constraint,
release from selection, and environment-dependent trait coupling.

The primary constructor is `drm_formula()`. The short alias `bf()` remains
available for familiar interactive use. Avoid a helper named `formula()`, which
would be too easily confused with base R's formula tooling.

## Audience And Examples

Examples, vignettes, and pkgdown pages should often use ecological and
evolutionary questions, while package-level headings should stay general:

- treatment effects on mean and among-individual variability;
- environmental stress changing residual trait coupling;
- personality, plasticity, predictability, and malleability;
- phylogenetic comparative location-scale models;
- spatial and spatiotemporal environmental gradients;
- ecological and evolutionary meta-analysis.

## Sibling Boundary

`gllvmTMB` is the high-dimensional stacked-trait/GLLVM package. `drmTMB` is
the one- or two-response distributional-regression package. `drmTMB` may
selectively port GPL-compatible A-inverse phylogenetic and SPDE spatial speed
modules from `gllvmTMB`, with provenance comments and `inst/COPYRIGHTS`
updates, but it should not become a fork of `gllvmTMB`.
