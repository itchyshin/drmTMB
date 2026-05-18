# Slice 249 NB2 Weak-SD Boundary

## Goal

Add a focused weak-SD diagnostic for fitted NB2 `mu` random effects before
larger Phase 18 NB2 grids vary the true random-effect SD.

## Implemented

- Extended the NB2 random-effect test data helper so the true random-intercept
  and independent random-slope SDs can be set per test.
- Added a weak-SD NB2 random-intercept test with a near-zero true SD.
- Checked that the fitted model converges, keeps finite positive `sdpars$mu`,
  and triggers `check_drm()` lower-boundary reporting at a deliberately high
  smoke-test boundary.
- Updated the Phase 18 blueprint, validation-debt register, roadmap, NEWS, and
  check log.

## Files Changed

- `tests/testthat/test-nbinom2-location-scale.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/34-validation-debt-register.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format tests/testthat/test-nbinom2-location-scale.R docs/design/41-phase-18-simulation-programme.md docs/design/34-validation-debt-register.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-249-nbinom2-weak-sd-boundary.md`
- `Rscript -e "devtools::test(filter = 'nbinom2-location-scale|check-drm', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The new test uses 50 groups with 12 observations each, a true random-intercept
SD of 0.03, and no random-slope variation in the DGP. It fits an ordinary NB2
random-intercept model and verifies convergence, finite positive fitted SD,
rough fixed-effect recovery, and a `check_drm()` warning when `sd_boundary` is
set to 0.25.

## Consistency Audit

This is diagnostic evidence, not a full operating-characteristic grid. It
matches the Poisson weak-SD boundary pattern while preserving the NB2-specific
confounding risk between overdispersion and group-level heterogeneity.

## Team Learning

Curie kept the boundary test small and deterministic. Fisher kept it framed as
diagnostic evidence, not coverage evidence. Gauss and Noether kept the model on
the already fitted NB2 `mu` random-effect path. Rose updated the debt register
so NB2 no longer says the smoke runner and interval evidence are missing, while
larger grids remain open.

## Known Limitations

This slice does not vary weak random slopes, overdispersion, mean count, group
count, or repeated observations across a grid. It does not add zero-truncated
NB2 random effects, zero-inflated NB2 random effects, or NB2 `sigma` random
effects.

## Next Actions

Use the NB2 smoke surface and weak-SD diagnostic as inputs to a small optional
pilot grid, or move to the next non-Gaussian gate before comprehensive Phase 18
simulation.
