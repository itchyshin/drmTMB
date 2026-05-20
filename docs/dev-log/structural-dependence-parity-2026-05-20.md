# Structural-Dependence Parity Snapshot

Date: 2026-05-20

Purpose: keep the "same as phylo" request balanced across `animal()`,
`spatial()`, and `relmat()` without claiming planned routes are fitted.

## Current Status

| Layer | Current status | Parity target |
| --- | --- | --- |
| Phylogenetic `mu` intercept | Fitted for univariate and selected bivariate Gaussian routes | Continue hardening profile/bootstrap diagnostics and q2/q4 examples. |
| Phylogenetic `mu` slope | Planned | Add only after intercept covariance, diagnostics, and simulation recovery are stable. |
| Spatial coordinate `mu` intercept and one numeric slope | Fitted for univariate Gaussian coordinate-spatial route | Add `corpairs()`/interval parity only when the fitted spatial covariance exposes the same target inventory as phylo. |
| Spatial bivariate `mu` covariance | Planned | Mirror the phylogenetic q2 location-location route before considering scale or cross-parameter blocks. |
| Animal `mu` intercept | Planned marker only | Start with additive genetic intercept and one small example only after pedigree or `A`/`Ainv` validation, sparse precision setup, diagnostics, and recovery tests. |
| Animal bivariate `mu` covariance | Planned | Same q2 location-location target as phylo, but only after the univariate animal route works. |
| `relmat()` `mu` intercept | Planned marker only | Define the low-level known matrix contract and keep it separate from `meta_V(V = V)` known sampling covariance. |
| Scale or mean-scale structured covariance | Mostly planned outside selected phylo q4 work | Do not advertise spatial, animal, or relmat scale parity until the corresponding likelihood, extractors, diagnostics, and simulations exist. |

## Order

The reader route should stay: animal, phylo, spatial, phylo + spatial, then
`relmat()`. The implementation order can differ when evidence demands it, but
status tables should always keep fitted, partial, planned, and blocked
separate.
