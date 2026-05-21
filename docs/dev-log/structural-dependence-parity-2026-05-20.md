# Structural-Dependence Parity Snapshot

Date: 2026-05-20

Updated: 2026-05-21 after the post-0.1.3 animal-pedigree and spatial q=2
artifact slices.

Purpose: keep the "same as phylo" request balanced across `animal()`,
`spatial()`, and `relmat()` without claiming planned routes are fitted.

## Current Status

| Layer | Current status | Parity target |
| --- | --- | --- |
| Phylogenetic `mu` intercept | Fitted for univariate and selected bivariate Gaussian routes | Continue hardening profile/bootstrap diagnostics and q2/q4 examples. |
| Phylogenetic `mu` slope | Planned | Add only after intercept covariance, diagnostics, and simulation recovery are stable. |
| Spatial coordinate `mu` intercept and one numeric slope | Fitted for univariate Gaussian coordinate-spatial route | Keep mesh/SPDE, multiple slopes, scale, and slope correlations behind separate gates. |
| Spatial bivariate `mu` covariance | First q2 coordinate slice fitted for matching labelled `mu1`/`mu2` terms, with smoke runner, CSV grid artifacts, fixed-effect Wald rows, and profile-status ledgers | Add q4, scale, predictor-dependent `corpair()`, and richer interval evidence only after the q2 route is stable. |
| Animal `mu` intercept | First dense-pedigree and known-matrix slices fitted for `pedigree`, `A`, or `Ainv` | Add sparse large-pedigree precision construction, slopes, and scale models after the small dense-pedigree and known-matrix routes are stable. |
| Animal bivariate `mu` covariance | First q2 dense-pedigree and known-matrix slices fitted for matching labelled `mu1`/`mu2` terms with `pedigree`, `A`, or `Ainv`, with smoke-grid and interval-status artifacts | Add q4 location-scale blocks, predictor-dependent `corpair()`, and direct-SD grammar only after focused recovery evidence. |
| `relmat()` `mu` intercept | First known-matrix slice fitted for precomputed `K` or `Q` | Keep the low-level known matrix contract separate from `meta_V(V = V)` known sampling covariance. |
| `relmat()` bivariate `mu` covariance | First q2 known-matrix slice fitted for matching labelled `mu1`/`mu2` terms with `K` or `Q`, with smoke-grid and interval-status artifacts | Add q4 location-scale blocks, predictor-dependent `corpair()`, and direct-SD grammar only after focused recovery evidence. |
| Scale or mean-scale structured covariance | Mostly planned outside selected phylo q4 work | Do not advertise spatial, animal, or relmat scale parity until the corresponding likelihood, extractors, diagnostics, and simulations exist. |

## Order

The reader route should stay: animal, phylo, spatial, phylo + spatial, then
`relmat()`. The implementation order can differ when evidence demands it, but
status tables should always keep fitted, partial, planned, and blocked
separate.

## Evidence Ledger After 0.1.3

The post-release parity lane has now moved three evidence groups from planned
or design-only into fitted-but-bounded evidence:

| Surface | Evidence now present | Still not claimed |
| --- | --- | --- |
| Animal dense-pedigree Gaussian `mu` intercept and q=2 bivariate location covariance | fitted syntax, additive-matrix validation, smoke cell, grid-row inclusion, examples, diagnostics, and after-task notes | sparse large-pedigree precision construction, slopes, `sigma`, q=4, predictor-dependent `corpair()`, and direct-SD grammar |
| Animal/`relmat()` known-matrix q=2 bivariate location covariance | DGP, summariser, smoke runner, CSV grid writer, fixed-effect Wald artifacts, opt-in profile-status artifacts, examples, and dense-comparator tests | structured slopes, `sigma`, q=4, predictor-dependent `corpair()`, non-Gaussian structured effects, and default profile coverage for structured rows |
| Coordinate-spatial q=2 bivariate location covariance | ADEMP sheet, DGP, summariser, smoke runner, CSV grid writer, fixed-effect Wald artifacts, profile-status artifacts, dense-comparator tests, and diagnostics | mesh/SPDE, spatial `sigma`, spatial q=4, direct spatial SD surfaces, predictor-dependent spatial `corpair()`, and formal large-replicate coverage reports |
