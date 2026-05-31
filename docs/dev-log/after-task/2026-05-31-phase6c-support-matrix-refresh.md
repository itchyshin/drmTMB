# After Task: Phase 6c Support Matrix Refresh

## Goal

Close #438 by making the random-slope and structured-dependence status matrix
agree across the roadmap, README, design notes, and known-limitations ledger
before larger Phase 18 power simulations use those rows.

## Implemented

- `README.md` now treats only multiple phylogenetic slopes and phylogenetic
  slope correlations as planned, rather than saying all phylogenetic slopes are
  planned.
- `ROADMAP.md` now records that the first coordinate-spatial, phylogenetic,
  animal-model, and `relmat()` one-slope Gaussian `mu` paths are fitted, while
  multiple structured slopes, structured slope correlations, bivariate
  structured slopes, and residual-scale structured slopes remain planned.
- `docs/design/59-structural-slope-and-non-gaussian-map.md` removes a duplicate
  non-Gaussian row, adds evidence handles for the support matrix, and separates
  source-tested/smoke structured count q=1 routes from broad count parity.
- `docs/design/33-phase-6c-core-random-effects.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/46-pre-simulation-readiness-matrix.md`, and
  `docs/dev-log/known-limitations.md` now describe ordinary Poisson/NB2 q=1
  structured `mu` intercepts as the fitted count-structured surface for
  `phylo()`, `spatial()`, `animal()`, and `relmat()`, not as a phylogeny-only
  route.
- `vignettes/model-map.Rmd` now uses the same fitted/planned wording as the
  README matrix, so the rendered model-map article does not preserve older
  phylogeny-only or all-phylogenetic-slope wording.
- `NEWS.md` records the support-matrix refresh for users tracking fitted versus
  planned random-slope surfaces.

## Boundary

No likelihood, parser, formula grammar, TMB, extractor, simulation-runner, or
missing-data files changed. This slice only repairs status and evidence
wording for already-fitted or already-planned surfaces.

## Mathematical Contract

No model equation changed. The contract update is status-only: the fitted
Gaussian structured one-slope `mu` paths and the narrow ordinary Poisson/NB2
q=1 structured `mu` intercept routes are documented as existing surfaces, while
multiple structured slopes, slope correlations, residual-scale structured
slopes, and broad non-Gaussian structured dependence remain planned or blocked.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/33-phase-6c-core-random-effects.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/59-structural-slope-and-non-gaussian-map.md`
- `docs/dev-log/after-task/2026-05-31-phase6c-support-matrix-refresh.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/known-limitations.md`
- `vignettes/model-map.Rmd`

## Checks Run

Recorded in `docs/dev-log/check-log.md` under the 2026-05-31 Phase 6c support
matrix refresh entry.

## Tests Of The Tests

This documentation slice reused the focused source tests that guard the status
claims: package skeleton checks, non-Gaussian structured-boundary checks, and
count-structured `mu` checks. The duplicate-row guard and source/rendered stale
wording scans were added because the failure mode here is contradictory support
language rather than a new likelihood calculation.

## Consistency Audit

The refreshed wording keeps fitted, source-test/smoke, planned, and blocked
rows separate. It does not promote multiple structured slopes, structured slope
correlations, residual-scale structured slopes, bivariate structured slopes,
structured count slopes, labelled count covariance, simultaneous structured
count types, zero-inflated structured effects, or structured NB2 `sigma`.

## GitHub Issue Maintenance

#438 is the owning issue. Related issues #33, #128, #436, #439, #440, #441,
#442, #444, and #446 remain open for later capability, tutorial, or simulation
work.

## What Did Not Go Smoothly

The first rendered-site pass still contained stale model-map wording because
the source vignette was updated after the first `pkgdown::build_site()` run. The
final validation rebuilt the site and reran the rendered stale-wording scan.

## Team Learning

Rose: when support-matrix work touches vignettes, a clean source scan is not
enough; rerun the rendered pkgdown scan before closing. Grace: keep
`pkgdown::check_pkgdown()` and rendered text checks separate, because the former
does not prove that stale status language disappeared.

## Known Limitations

This refresh does not promote any new model surface. The remaining support gaps
still need separate issues and evidence: #439 for ordinary Gaussian closeout,
#440 for the bivariate slope-only gate, #441 for non-Gaussian independent `mu`
slope admission, #442 for the structured Gaussian one-slope audit, #444 for the
tutorial/release ledger, and #446 for the simulation power/coverage plan.

## Next Actions

Use this refreshed matrix before deciding which random-slope rows enter the
planned larger power-simulation design.
