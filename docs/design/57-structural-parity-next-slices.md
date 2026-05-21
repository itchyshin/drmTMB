# Structural-Parity Next Slices

Date: 2026-05-21

Status: closeout note for post-0.1.3 structural-dependence parity slices 1-8.

This note records the next eight structural-dependence slices after the 0.1.3
release. It keeps fitted, admitted, and planned routes separate so applied
users can see which structural-dependence paths are runnable today.

## Slice Table

| Slice | Target | Decision |
| --- | --- | --- |
| 1 | Spatial direct-SD design gate | Keep direct spatial SD surfaces planned. Do not add `sd_spatial()` syntax until coordinate-spatial q4, mesh/SPDE scale interpretation, and prediction-grid behaviour have a clear contract. |
| 2 | Spatial q4 admission audit | Admit as a design target only. A fitted spatial q4 block needs intercept-only matching terms across `mu1`, `mu2`, `sigma1`, and `sigma2`, plus diagnostics for weak site replication and near-boundary correlations. |
| 3 | Animal/relmat q4 design parity | Fitted for constant q4 location-scale blocks for `animal()` and `relmat()`. The matrix, group, and covariance-block label must match across all four endpoints. |
| 4 | Animal/relmat direct-SD grammar decision | Keep generic direct-SD syntax planned. Do not add `sd_animal()` or `sd_relmat()` until the public naming, matrix scale, and biological interpretation are clearer. |
| 5 | Combined phylo + spatial identifiability note | Keep simultaneous `phylo()` plus `spatial()` planned. Separate sensitivity fits are the current user route until multiple structured `mu` layers have identifiability diagnostics. |
| 6 | First implementation slice | Completed for constant q4 `animal()` and `relmat()` blocks, reusing the existing structured-precision q4 TMB path. |
| 7 | Focused simulation smoke | Completed as a deterministic small q4 known-matrix smoke test with broad fixed-effect recovery and finite objective checks. |
| 8 | Extractor/profile/corpairs hardening | Completed for `corpairs()`, `summary()$covariance`, `profile_targets()`, and `check_drm()` exposure with explicit derived interval status. |

## Slice 1: Spatial Direct-SD Gate

Spatial direct-SD surfaces are useful but not admitted yet. A formula such as
future `sd_spatial(site) ~ reef_cover` would model predictors of the latent
coordinate-spatial location SD, not residual `sigma`, and not a q4
location-scale block. Before adding syntax, the team needs to decide whether
the SD surface is tied to observed coordinate sites, future mesh vertices, or
both. That decision affects `prediction_grid()`, `predict()`, profile targets,
and reader interpretation.

For now, the fitted spatial routes remain:

- `spatial(1 | site, coords = coords)` in univariate Gaussian `mu`;
- `spatial(1 + x | site, coords = coords)` in univariate Gaussian `mu`;
- matching `spatial(1 | p | site, coords = coords)` terms in bivariate
  `mu1` and `mu2`.

## Slice 2: Spatial Q4 Admission Audit

Spatial q4 should follow the same reader contract as phylogenetic q4, but not
the same implementation shortcut by default. The admitted future shape is a
constant, intercept-only block across `mu1`, `mu2`, `sigma1`, and `sigma2`:

```r
drmTMB(
  mu1 = y1 ~ x + spatial(1 | p | site, coords = coords),
  mu2 = y2 ~ x + spatial(1 | p | site, coords = coords),
  sigma1 = ~ z + spatial(1 | p | site, coords = coords),
  sigma2 = ~ z + spatial(1 | p | site, coords = coords),
  family = biv_gaussian(),
  data = dat
)
```

This route stays planned until diagnostics distinguish weak site replication,
tiny spatial log-sigma SDs, near-boundary latent correlations, and possible
confounding between fixed spatial trends and latent fields.

## Slice 3: Animal/relmat Q4 Design Parity

Constant q4 location-scale blocks were the safest next fitted parity gap because
`animal()` and `relmat()` already use the same structured-precision backend as
the q=2 route. The fitted contract mirrors phylogenetic q4:

- all four endpoints must contain one intercept-only structured term;
- the marker must be one of `animal()` or `relmat()`;
- the grouping variable, matrix object, matrix input type, and covariance-block
  label must match across the endpoints;
- full q4 uses one shared label for all endpoints;
- block-diagonal fallback may use one label for `mu1`/`mu2` and another label
  for `sigma1`/`sigma2`;
- all six full-q4 correlations must include the four mean-scale pairs:
  `mu1`-`sigma1`, `mu1`-`sigma2`, `mu2`-`sigma1`, and `mu2`-`sigma2`.

The public claim is limited to constant Gaussian bivariate location-scale
blocks. Slopes, sparse large-pedigree construction, predictor-dependent
`corpair()` regressions, and direct-SD grammar remain planned.

## Slice 4: Animal/relmat Direct-SD Gate

Direct SD syntax for known-matrix layers remains planned. The team should not
add `sd_animal()` or `sd_relmat()` as a reflexive copy of `sd_phylo()`. Animal
and relmat users may supply covariance or precision matrices at different
biological scales, so a direct-SD surface needs explicit interpretation:

- Does the predictor scale the additive genetic SD, a lower-level latent SD, or
  a normalized matrix-specific SD?
- Are predictors required to be constant within individual, line, or matrix
  level?
- Should `animal()` direct-SD syntax be separate from generic `relmat()` syntax
  so pedigree users are not asked to reason in low-level matrix terms?

Until those answers are recorded, keep direct-SD grammar planned.

## Slice 5: Combined Phylo + Spatial Identifiability Note

Simultaneous `phylo()` plus `spatial()` layers remain planned. The useful user
route today is to fit separate sensitivity models:

```r
fit_phylo <- drmTMB(y ~ x + phylo(1 | species, tree = tree), data = dat)
fit_spatial <- drmTMB(y ~ x + spatial(1 | site, coords = coords), data = dat)
```

A simultaneous route needs its own identifiability checks before it becomes a
tutorial example. The minimum diagnostics should report replication by species
and site, overlap between species and site grouping, weak component SDs, and
whether the two structured layers compete for the same residual pattern.

## Slice 6-8 Implementation Contract

The first implementation target is now complete for constant q4 `animal()` and
`relmat()` location-scale blocks. The implementation reuses the existing
structured-precision q4 likelihood path rather than adding a separate TMB
template. The extractor layer labels rows as `level = "animal"` or
`level = "relmat"` rather than `level = "phylogenetic"`, and q4 correlations
from the unstructured parameterization remain derived interval targets.

This is useful to applied users because it lets the same known relatedness
matrix explain coupled variation in both response means and residual
log-scales, while still keeping residual `rho12` and latent structured
correlations separate.
