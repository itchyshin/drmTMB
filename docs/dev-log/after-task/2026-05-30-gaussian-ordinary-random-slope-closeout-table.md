# After Task: Gaussian Ordinary Random-Slope Closeout Table

## Goal

Advance #439 by recording the ordinary Gaussian random-slope closeout boundary
without changing likelihood code, formula grammar, tests, simulations, or
pkgdown navigation.

## Implemented

- `docs/design/80-four-week-random-slope-digital-twin-sprint.md` now has an
  #439 closeout table for ordinary Gaussian grouped random slopes.
- `ROADMAP.md` now marks the old q > 2 export block as superseded by later
  ordinary Gaussian `mu` slices and narrows the first-slope correlation
  prohibition to first structured one-slope paths.
- `vignettes/location-scale.Rmd` now gives readers a compact q > 2 ordinary
  Gaussian `mu` example and an explicit independent-versus-correlated
  residual-scale `sigma` slope boundary.
- `vignettes/model-map.Rmd` now maps residual-scale random slopes to
  `sdpars$sigma`, `profile_targets(fit)`, and `sigma(fit)`.
- The table records fitted support for q > 2 Gaussian `mu` grouped blocks,
  including `sdpars$mu`, `corpars$re_cov`, `corpairs()`,
  `summary(fit)$covariance`, and `profile_targets()` evidence.
- The table records fitted support for independent Gaussian residual-scale
  slopes on `log(sigma)`, including `sdpars$sigma`, prediction contribution,
  direct profile targets, and Phase 18 smoke-runner evidence.
- The table records Phase 18 routing through `first_wave_summary` while keeping
  broad power, accuracy, and coverage evidence for #446.

## Mathematical Contract

This is a documentation and status-ledger slice. It does not add random-slope
syntax, promote q > 2 correlations to direct profile targets, or add correlated
or labelled residual-scale slope covariance. Larger q Gaussian `mu` blocks
remain advanced and sample-size hungry.

## Files Changed

- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `ROADMAP.md`
- `vignettes/location-scale.Rmd`
- `vignettes/model-map.Rmd`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
source scans covered the new #439 table, local test and registry evidence
handles, public-prose wording, stale roadmap wording, and diff hygiene.
Targeted Gaussian and Phase 18 random-slope tests were then run for the
evidence files named in the table.
`pkgdown::check_pkgdown()` and `pkgdown::build_site(preview = FALSE)` were run
because this slice touched vignettes and roadmap prose; rendered HTML/search
scans then checked that the new wording appeared and stale roadmap wording did
not reappear. The site build repeated the existing glmmTMB/TMB
version-mismatch warning while reading the convergence article, but completed.

## Tests Of The Tests

No new tests were added in this slice. The closeout table points to existing
q > 2 Gaussian `mu` extractor checks, independent Gaussian `sigma` slope checks,
unsupported residual-scale covariance failure checks, and Phase 18 smoke-runner
tests.

## Consistency Audit

The public wording now separates ordinary Gaussian `mu` q > 2 grouped blocks
from structured one-slope blocks and residual-scale slope covariance. It also
states that independent `sigma` slopes live on `log(sigma)` and that q > 2
correlation rows are derived rather than direct profile-interval targets.

## GitHub Issue Maintenance

This slice advances #439 and should be linked back to the Phase 6c sprint issue
after the commit is pushed. It also points operating-characteristic work to
#446 rather than treating smoke-grid admission as power, accuracy, or coverage
evidence.

## What Did Not Go Smoothly

The ROADMAP still contained older q > 2 export language from an earlier
labelled-covariance slice. The fix was to preserve the historical statement but
make the later ordinary Gaussian `mu` support explicit.

## Team Learning

The #439 closeout needed three separate columns: fitted extractor behavior,
artifact dispatch, and inference readiness. Keeping those columns separate
prevents q > 2 `mu` blocks and independent `sigma` slopes from turning into a
claim about every residual-scale covariance model.

## Next Actions

- Use #446 for recovery, accuracy, power, and coverage grids.
- Keep correlated residual-scale slope covariance as a design issue until
  likelihood, extractor, interval, and failure-path evidence exist.
