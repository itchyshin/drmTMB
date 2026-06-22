# Structured q2 Native ML Status

## Purpose

This note records the SR021-SR030 q2 boundary for structured random effects.
It separates implemented bivariate location q2 routes from scale-side q2
decisions and keeps q2 point evidence away from q4 or interval-coverage claims.

## Current q2 Rows

The implemented native TMB ML q2 location rows are:

- `phylo(1 | p | species, tree = tree)` in matching `mu1` and `mu2`;
- `spatial(1 | p | site, coords = coords)` in matching `mu1` and `mu2`;
- `animal(1 | p | id, pedigree = pedigree)`, `animal(1 | p | id, A = A)`,
  or `animal(1 | p | id, Ainv = Ainv)` in matching `mu1` and `mu2`;
- `relmat(1 | p | id, K = K)` or `relmat(1 | p | id, Q = Q)` in matching
  `mu1` and `mu2`.

The focused tests check fitted objects, named SDs, latent correlations,
`corpairs()`, `summary(fit)$covariance`, profile-target identities, diagnostics,
and prediction contributions.

## Scale-Side q2 Boundary

The phylogenetic route has a block-diagonal q2-plus-q2 fallback:

```r
bf(
  mu1 = y1 ~ x + phylo(1 | pl | species, tree = tree),
  mu2 = y2 ~ x + phylo(1 | pl | species, tree = tree),
  sigma1 = ~ z + phylo(1 | ps | species, tree = tree),
  sigma2 = ~ z + phylo(1 | ps | species, tree = tree),
  rho12 = ~ 1
)
```

That route reports one mean-mean `corpairs()` row for block `pl` and one
scale-scale row for block `ps`; it does not report mean-scale correlations.

For coordinate `spatial()`, `animal()`, and `relmat()`, pure
`sigma1`/`sigma2` structured q2 formulas are intentionally rejected as partial
location-scale blocks. A direct smoke on 2026-06-22 produced these route
decisions:

```text
spatial  error  Partial spatial location-scale blocks are not implemented.
animal   error  Partial animal-model location-scale blocks are not implemented.
relmat   error  Partial relmat location-scale blocks are not implemented.
```

For those structured types, scale endpoints currently enter the bivariate
structured covariance surface through the all-four q4 route, not a standalone
scale-only q2 route.

## Inference Boundary

The q2 rows are fit and extractor evidence. They are not interval-coverage
evidence. Direct q2 location correlation profile targets are row-specific, and
coverage remains unclaimed unless a coverage study is attached to the exact
target row.

This note does not promote native REML, AI-REML, bridge parity, public
optimizer controls, q4 interval support, or non-Gaussian structured q2/q4
support.
