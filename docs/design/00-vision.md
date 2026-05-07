# Vision

`drmTMB` provides fast distributional regression models using TMB, focused on
univariate and bivariate responses.

The package identity is:

> brms-like distributional formulae, glmmTMB-like speed, GAMLSS-style
> parameter modelling, and explicit bivariate coscale models.

## Core Idea

A model is defined by:

1. one or two response formulas;
2. one formula for every estimated distributional parameter;
3. optional known-covariance formula markers such as `meta_known_V(V = V)`;
4. optional structured dependence terms such as `gr()`, `phylo()`, and
   `spatial()`;
5. a family object that defines parameters, links, likelihood, simulation, and
   starting values.

Parameters often share predictors, but coefficients are parameter specific.
For example, `x` in `mu ~ x` and `sigma ~ x` creates separate location and
scale effects.

## Signature Feature

The flagship syntax is:

```r
bf(
  mu1 = y1 ~ x1 + (1 | p | id),
  mu2 = y2 ~ x2 + (1 | p | id),
  sigma1 = ~ z1,
  sigma2 = ~ z2,
  rho12 = ~ w
)
```

The `rho12` formula models residual correlation as a scientific response
rather than treating covariance homogeneity as a default assumption. The
`|p|` label controls group-level random-effect correlation blocks and is not
the same thing as residual `rho12`.

## Sibling Boundary

`gllvmTMB` is the high-dimensional stacked-trait/GLLVM package. `drmTMB` is
the one- or two-response distributional-regression package. `drmTMB` may
selectively port GPL-compatible A-inverse phylogenetic and SPDE spatial speed
modules from `gllvmTMB`, with provenance comments and `inst/COPYRIGHTS`
updates, but it should not become a fork of `gllvmTMB`.
