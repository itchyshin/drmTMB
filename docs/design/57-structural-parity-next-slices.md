# Structural-Parity Next Slices

> **Historical slice map, superseded 2026-07-14.** Status rows below preserve
> the planning state when this map was written. Use the live capability ledger
> and `docs/design/79-supported-nongaussian-evidence-goal.md` for current
> claims. Narrow fitted non-Gaussian gates now include ordinary `mu` random
> effects for every fitted univariate family, Poisson/NB2 q1 structured `mu`,
> NB2 q1 structured `sigma`, and exact Student-t, Gamma, beta, Poisson-`zi`,
> hurdle-`hu`, and cumulative-logit diagnostic-only routes. Their neighbours and
> interval/coverage promotion remain blocked.

Date: 2026-05-21

Status: closeout note for post-0.1.3 structural-dependence parity slices 1-8.

This note records the next eight structural-dependence slices after the 0.1.3
release. It keeps fitted, admitted, and planned routes separate so applied
users can see which structural-dependence paths are runnable today.

## Slice Table

| Slice | Target | Decision |
| --- | --- | --- |
| 1 | Spatial direct-SD design gate | Keep direct spatial SD surfaces planned. Do not add `sd_spatial()` syntax until coordinate-spatial q4, mesh/SPDE scale interpretation, and prediction-grid behaviour have a clear contract. The coordinate-spatial q4 precondition is now met, but the naming and prediction-grid questions remain. |
| 2 | Spatial q4 admission audit | Superseded by the later fitted slice: constant spatial q4 now has intercept-only matching terms across `mu1`, `mu2`, `sigma1`, and `sigma2`, plus diagnostics for weak site replication and near-boundary correlations. |
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

## Continuation To Slice 38

The continuation slices keep the same rule: implement only the small surfaces
that already have likelihood support, and close the rest as explicit
fitted-versus-planned status guards. This table is a working ledger for the
post-0.1.3 structural-parity lane, not a claim that every planned feature is
now fitted.

| Slice | Target | Status |
| --- | --- | --- |
| 9 | Rebase and publish the slice-1-to-8 branch after the pkgdown root-site hotfix | Done: branch merged `origin/main`, reran focused animal/relmat and pkgdown checks, and pushed the branch |
| 10 | Animal/relmat q4 ADEMP addendum | Done: `docs/design/58-phase-18-animal-relmat-q4-ademp.md` names the DGP, estimands, and derived-correlation interval boundary |
| 11 | Animal/relmat q4 DGP | Done: `phase18_dgp_animal_relmat_q4()` stores endpoint SDs, six endpoint correlations, matrix inputs, and residual `rho12` as separate truth layers |
| 12 | Animal/relmat q4 summariser and runner | Done: q4 replicate summaries report fixed `mu`/`sigma` coefficients, four structured SDs, six structured correlations, and residual `rho12` |
| 13 | Animal/relmat q4 interval-status guard | Done: requested q4 structured-correlation profile rows are marked `derived_interval_unavailable` |
| 14 | Animal/relmat q4 grid writer | Done: q4 aggregate, replicate, manifest, failure, profile-status, interval-evidence, diagnostic, and interval-failure CSV artifacts can be written |
| 15 | Spatial q4 fitted-status audit | Superseded by the later fitted slice: constant q=4 spatial location-scale blocks are no longer rejected when all four labelled endpoints match |
| 16 | Spatial direct-SD audit | Closed as planned: no direct spatial SD grammar until coordinate q4, mesh/SPDE scale, and prediction-grid semantics are designed |
| 17 | Spatial `sigma` boundary | Closed as planned: coordinate-spatial effects remain `mu`-only except for ordinary fixed `sigma` predictors |
| 18 | Spatial `corpair()` regression boundary | Closed as planned: spatial q=2 constant covariance is fitted, predictor-dependent spatial `corpair()` remains future work |
| 19 | Spatial one-slope parity reminder | Done as status map: coordinate spatial has one fitted Gaussian `mu` slope; phylo/animal/relmat slopes do not |
| 20 | Mesh/SPDE guard | Closed as planned: coordinate `coords` support does not imply mesh/SPDE support |
| 21 | Bivariate spatial slope guard | Closed as planned: bivariate spatial slopes remain outside the fitted q=2 intercept path |
| 22 | Spatial simulation admission line | Superseded by the later q4 first slice: admit coordinate-spatial `mu` intercept, one-slope, q=2 bivariate location-covariance, and constant q4 location-scale artifacts |
| 23 | Spatial user route | Superseded by the later q4 first slice: fit the fitted coordinate-spatial subsets first, including constant q4 when the all-four endpoint question is appropriate, not mesh or non-Gaussian syntax |
| 24 | Direct-SD grammar across animal/relmat | Closed as planned: no `sd_animal()` or `sd_relmat()` syntax until matrix scale and biological interpretation are named |
| 25 | Direct-SD grammar across spatial | Closed as planned: no `sd_spatial()` syntax until site versus mesh semantics are clear |
| 26 | Combined phylo plus spatial | Closed as planned: simultaneous structured layers remain an identifiability lane, not a tutorial route |
| 27 | Combined structured source guard | Done: bivariate models still admit one structured location-covariance source at a time |
| 28 | Known sampling `V` versus latent relatedness | Done as wording guard: `meta_V(V = V)` remains known sampling covariance, not `animal()` or `relmat()` latent structure |
| 29 | Residual `rho12` versus latent correlations | Done as wording guard: residual coscale and structured endpoint correlations stay in separate rows |
| 30 | q4 broad-grid boundary | Done: focused q4 smoke artifacts exist; broad operating-characteristic q4 reports still need larger replicate and interpretation work |
| 31 | Random-slope parity map | Done: `docs/design/59-structural-slope-and-non-gaussian-map.md` maps fitted versus planned slope routes |
| 32 | Ordinary Gaussian slope status | Historical boundary, superseded by current 0.6.0: ordinary Gaussian `mu` and `sigma` slopes include unlabelled correlated blocks; labelled residual-scale and cross-formula `mu`-`sigma` slope covariance remain planned |
| 33 | Structured slope status | Done at the time as a fitted-versus-planned map; superseded by Slice 39, which fits the phylo, animal, and relmat one-slope Gaussian `mu` sibling paths |
| 34 | Bivariate slope status | Done at the time as a boundary; superseded by Slice 83, which fits the matching slope-only `mu1`/`mu2` route while leaving broader bivariate slope blocks planned |
| 35 | Non-Gaussian ordinary random-effect status | Done: Poisson and NB2 `mu` random intercepts and independent numeric slopes are fitted first slices |
| 36 | Non-Gaussian structural-dependence status | Historical boundary, superseded by exact later gates: structured non-Gaussian routes remain blocked outside the row-specific gates recorded in the live ledger |
| 37 | Non-Gaussian distributional-parameter boundary | Historical boundary, superseded in part: ordinary cumulative-logit and zero-one-beta `mu` random effects plus exact row-specific `sigma`, shape, inflation, and hurdle gates are fitted where recorded; neighbours remain planned or blocked |
| 38 | User-facing usefulness pass | Done: the status map tells applied users what to fit now and what to leave out of simulation or tutorials |
