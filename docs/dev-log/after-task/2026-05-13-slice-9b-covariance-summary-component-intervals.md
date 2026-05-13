# After Task: Slice 9B Covariance-Summary Component Intervals

## Goal

Attach direct profile-interval metadata to the internal covariance summary table
without pretending those direct component intervals are a covariance interval.

## Implemented

`random_effect_covariance_summaries()` now records three profile-target names
for each covariance row: the correlation target, the from-side SD target, and
the to-side SD target. When supplied an interval table, it attaches direct
profile interval bounds and methods for those component targets.

The helper also includes explicit derived covariance interval columns, but they
remain `NA`. This is deliberate. The covariance is a nonlinear function of two
SDs and a correlation, so a future interval needs a fix-and-refit, profiling, or
other derived-quantity method rather than a quick Wald or component-interval
shortcut.

`tests/testthat/test-covariance-block-registry.R` now checks the hidden q=4
endpoint scaffold with synthetic profile rows for all six correlation targets
and four SD targets. The test verifies target names, component interval joins,
and the empty derived covariance interval columns.

## Team Roles

Ada integrated the slice. Gauss kept the covariance interval boundary strict.
Emmy checked the target names against the existing `profile_targets()` namespace.
Curie kept the test deterministic. Rose's boundary is that this is still
internal infrastructure, not a user-facing interval claim.

## Scope Boundary

This does not implement covariance intervals. It attaches direct profile
intervals for the component SD and correlation targets only. It also remains
internal: no public extractor, no residual `rho12` covariance summary, and no
ordinary fitted q4 support claim.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-covariance-block-registry.R`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-9b-covariance-summary-component-intervals.md`

## Checks Run

- `Rscript -e 'devtools::test(filter = "covariance-block-registry")'`: passed
  with 180 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e 'devtools::test(filter =
  "covariance-block-registry|corpairs")'`: passed with 228 expectations, 0
  failures, 0 warnings, and 0 skips.
- `air format R/methods.R tests/testthat/test-covariance-block-registry.R
  ROADMAP.md docs/design/28-double-hierarchical-endpoint.md
  docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9b-covariance-summary-component-intervals.md`:
  passed.
- `git diff --check`: passed.

## Next Actions

1. Add Slice 9C: decide the public summary surface and keep derived covariance
   intervals labelled as unavailable until a proper derived-interval method is
   implemented.
