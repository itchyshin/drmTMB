# After Task: Slice 9C Summary Covariance Reporting Surface

## Goal

Expose the derived variance and covariance point summaries through the existing
`summary()` surface without overclaiming q > 2 support or derived covariance
intervals.

## Implemented

`summary.drmTMB()` now includes a `covariance` component. The component is the
registry-backed table built by `random_effect_covariance_summaries()`, so it
contains only covariance rows that the fitted model already populated. Ordinary
fits without registry-backed covariance rows receive an empty table.

`print(summary(fit))` now prints a compact random-effect covariance table when
rows are present. The printed table includes the correlation, fitted SDs, and
covariance point estimate. The full `summary(fit)$covariance` component retains
the identifying columns, variance columns, target names, component interval
columns, and empty derived covariance interval columns.

`tests/testthat/test-summary.R` now checks that `summary(fit)$covariance`
reports the univariate `mu`/`sigma` and bivariate `mu1`/`mu2` covariance rows,
keeps residual `rho12` out of the covariance table, attaches direct correlation
profile intervals when supplied through `summary(..., conf.int = TRUE,
method = "profile")`, and leaves derived covariance intervals unavailable.

## Team Roles

Ada integrated the reporting surface. Emmy checked that the public surface is a
summary component rather than a new exported function. Gauss kept scale wording
explicit: sigma-side covariance rows are on the fitted `log(sigma)` random-effect
scale. Curie checked the focused summary tests. Rose guarded against claiming
q > 2 public support or covariance intervals.

## Scope Boundary

This is a public summary component for currently fitted registry-backed blocks.
It does not expose q > 2 syntax, does not add ordinary fitted q4 support, does
not include residual `rho12` covariance rows, and does not implement derived
covariance intervals. Component SD and correlation intervals can be present;
the covariance interval remains `NA` until a valid nonlinear interval method is
implemented.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-summary.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-9c-summary-covariance-reporting-surface.md`
- `man/summary.drmTMB.Rd`

## Checks Run

- `Rscript -e 'devtools::test(filter = "summary")'`: passed with 87
  expectations, 0 failures, 0 warnings, and 0 skips.
- `devtools::document()`: passed.
- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9c-summary-covariance-reporting-surface.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "summary|covariance-block-registry|corpairs")'`:
  passed with 315 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Add Slice 9D: decide whether to stop Slice 9 here as a point-summary release
   or add explicit user-facing unavailable-status wording for derived covariance
   intervals before pushing the slice stack.
