# Structural-Dependence Parity Snapshot

Date: 2026-05-20

Purpose: keep the "same as phylo" request balanced across `animal()`,
`spatial()`, and `relmat()` without claiming planned routes are fitted.

## Current Status

| Layer | Current status | Parity target |
| --- | --- | --- |
| Phylogenetic `mu` intercept | Fitted for univariate and selected bivariate Gaussian routes | Continue hardening profile/bootstrap diagnostics and q2/q4 examples. |
| Phylogenetic `mu` slope | Planned | Add only after intercept covariance, diagnostics, and simulation recovery are stable. |
| Spatial coordinate `mu` intercept and one numeric slope | Fitted for univariate Gaussian coordinate-spatial route | Keep mesh/SPDE, multiple slopes, scale, and slope correlations behind separate gates. |
| Spatial bivariate `mu` covariance | First q2 coordinate slice fitted for matching labelled `mu1`/`mu2` terms | Add q4, scale, predictor-dependent `corpair()`, and richer interval evidence only after the q2 route is stable. |
| Animal `mu` intercept | First known-matrix slice fitted for precomputed `A` or `Ainv` | Add pedigree construction, slopes, and scale models after the known-matrix route is stable. |
| Animal bivariate `mu` covariance | First q2 known-matrix slice fitted for matching labelled `mu1`/`mu2` terms with `A` or `Ainv` | Add pedigree construction, q4 location-scale blocks, predictor-dependent `corpair()`, and direct-SD grammar only after focused recovery evidence. |
| `relmat()` `mu` intercept | First known-matrix slice fitted for precomputed `K` or `Q` | Keep the low-level known matrix contract separate from `meta_V(V = V)` known sampling covariance. |
| `relmat()` bivariate `mu` covariance | First q2 known-matrix slice fitted for matching labelled `mu1`/`mu2` terms with `K` or `Q` | Add q4 location-scale blocks, predictor-dependent `corpair()`, and direct-SD grammar only after focused recovery evidence. |
| Scale or mean-scale structured covariance | Mostly planned outside selected phylo q4 work | Do not advertise spatial, animal, or relmat scale parity until the corresponding likelihood, extractors, diagnostics, and simulations exist. |

## Order

The reader route should stay: animal, phylo, spatial, phylo + spatial, then
`relmat()`. The implementation order can differ when evidence demands it, but
status tables should always keep fitted, partial, planned, and blocked
separate.
