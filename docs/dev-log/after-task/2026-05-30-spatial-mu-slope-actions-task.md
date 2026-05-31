# After-Task Report: Spatial Mu-Slope Actions Task

## Task

Make the existing coordinate-spatial Gaussian `mu` one-slope Phase 18 artifact
lane dispatchable as a manual Actions task without changing model syntax,
likelihood code, or simulation claims.

## Changes

- Added `spatial_mu_slope` to the Phase 18 Actions task vocabulary and manual
  workflow choices.
- Routed the task to `phase18_write_spatial_mu_slope_grid_outputs()`.
- Updated the structured workflow registry so `gaussian_spatial_mu_one_slope`
  uses the manual task instead of `needed:structured_dependence_wrapper`.
- Updated workflow-plan and wrapper-readiness tests so `phylo()`, `animal()`,
  and `relmat()` remain wrapper targets while spatial is dispatchable.
- Synchronized the simulation README, Phase 18 programme, structured-workflow
  registry note, roadmap, and NEWS.

## Boundary

This task does not add mesh/SPDE support, multiple spatial slopes, spatial
slope correlations, structured residual-scale slopes, or broader structured
covariance. It does not promote the spatial one-slope lane to recovery or
coverage evidence.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. Focused
checks included formatting, parsing the changed runner/registry helpers,
workflow/registry tests, spatial mu-slope grid-writer tests, the manual
`spatial_mu_slope` dry run, pkgdown release and development rebuilds,
`pkgdown::check_pkgdown()`, rendered stale-wording scans, and
`git diff --check`.
