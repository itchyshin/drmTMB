# After Task: Coscale And Corpairs Boundary Ledger

## Goal

Advance #443 and support #444 by making the reader-facing boundary between
residual coscale, latent correlation formulas, and extracted correlation rows
explicit.

## Implemented

- `docs/design/20-coscale-correlation-pairs.md` now defines coscale as the
  residual bivariate Gaussian `rho12` parameter and separates it from
  group-level, phylogenetic, spatial, animal-model, and `relmat()` covariance.
- `vignettes/bivariate-coscale.Rmd` now explains that `corpairs()` can report
  fitted ordinary and structured rows, while predictor-dependent spatial,
  animal, `relmat()`, q4, residual-scale, and slope-specific `corpair()`
  regressions remain planned.
- `R/formula-markers.R` and `man/corpair.Rd` now say spatial `corpair()`
  regressions remain planned, avoiding the false impression that all spatial
  `corpairs()` rows are planned.
- `docs/course/README.md` now points a learner through the current pkgdown
  teaching path and labels the bivariate slope-only route as fitted but still
  needing a worked tutorial.
- `ROADMAP.md`, `NEWS.md`, and the four-week sprint contract now carry the
  #443 boundary wording.

## Boundary

No likelihood, parser, formula grammar, TMB code, extractor behavior, or model
support changed. This is a documentation and release-ledger slice. It does not
promote random effects in `rho12`, spatial `corpair()` regression, q4
correlation regression, residual-scale correlation regression, or
slope-specific `corpair()` regression.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
completed checks covered formatting, roxygen regeneration for `corpair()`, a
focused formula-marker test, pkgdown release and development rebuilds,
rendered-page scans, stale wording scans, and diff hygiene.
