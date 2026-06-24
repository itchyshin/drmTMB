# Structured Slope Status

## Purpose

This note records the SR041-SR050 structured-slope boundary. It separates the
implemented independent one-slope univariate Gaussian `mu` paths from future
correlated, labelled, bivariate, scale-side, count, and multi-slope structured
covariance designs.

## Current One-Slope Rows

The implemented native TMB ML slope rows are univariate Gaussian `mu` paths:

- `phylo(1 + x | species, tree = tree)`;
- `spatial(1 + x | site, coords = coords)`;
- `animal(1 + x | id, pedigree = pedigree)`;
- `relmat(1 + x | id, K = K)` or `relmat(1 + x | id, Q = Q)`.

Each fitted path estimates independent intercept and slope fields, with
separate SDs such as `phylo(1 | species)` and `phylo(0 + x | species)`. The
current fitted object has no structured intercept-slope `corpair()` row and no
structured slope correlation parameter.

## Rejection Boundary

Labels such as `phylo(1 + x | p | species, tree = tree)`,
`spatial(1 + x | p | site, coords = coords)`,
`animal(1 + x | p | id, pedigree = pedigree)`, and
`relmat(1 + x | p | id, Q = Q)` remain rejected because labelled structured
covariance blocks are intercept-only in this phase.

Structured slope routes also remain limited away from:

- multiple structured slopes in the same structured term;
- bivariate structured slope covariance;
- residual-scale structured slopes;
- non-Gaussian structured slopes;
- predictor-dependent slope `corpair()` regressions;
- structured `rho12` effects.

## Inference Boundary

The one-slope tests check direct SD profile-target rows for the independent
intercept and slope fields. That is target availability, not calibrated
coverage. Coverage remains unclaimed unless a target-specific simulation row is
attached.

This note does not promote native REML, AI-REML, R-to-Julia bridge parity,
public optimizer controls, or any correlated structured-slope design.
