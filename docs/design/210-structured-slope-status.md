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
> ### ⚠️ SUPERSEDED IN PART (2026-07-08)
>
> **This is FALSE for the bivariate cells.** The q-series TSV records labelled structured *slope*
> covariance blocks as admitted under ML (e.g. `qseries_phylo_q2_mu1_mu2_one_slope`,
> `qseries_phylo_q4_mu1_mu2_one_slope`, and the spatial/animal/relmat counterparts). What remains
> genuinely rejected is the **univariate** labelled slope block (`phylo(1 + x | p | sp)` on `mu`), a hybrid
> gate + small-C++ job: `src/drmTMB.cpp:916` discriminates by dpar inequality, not by the `|p|` label, so a
> new DATA flag is required. Naively widening that guard would silently correlate every existing
> `phylo(1 + x | group)` fit.
>
> Authority: `docs/dev-log/dashboard/estimator-surface-conformance.tsv` (machine-checked by
> `tests/testthat/test-estimator-surface-conformance.R`) and
> `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`. Prose is derived; the TSVs are truth.


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
