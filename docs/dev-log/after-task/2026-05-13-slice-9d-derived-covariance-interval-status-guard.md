# After Task: Slice 9D Derived Covariance Interval Status Guard

## Goal

Close Slice 9 by making the covariance-summary interval boundary explicit. The
package should report covariance point estimates and direct component profile
intervals, but it should not let users read blank covariance interval columns
as an implemented nonlinear derived interval.

## Implemented

`summary(fit)$covariance` and the internal
`random_effect_covariance_summaries()` table now include
`covariance_conf.status`. Ordinary summaries use `not_requested`. When profile
interval rows are supplied, the covariance rows use
`derived_interval_unavailable`, while `covariance_conf.low`,
`covariance_conf.high`, and `covariance_conf.method` remain `NA`.

`print(summary(fit))` keeps the compact covariance table for ordinary
summaries. When profile intervals are requested and covariance rows are
present, the printed table includes `covariance_conf.status` so the derived
interval boundary is visible at the public reporting surface.

## Team Roles

Ada integrated the guard. Noether checked that the table says why the
covariance interval is absent rather than changing the estimate. Curie added
focused regression checks for ordinary summaries, profiled summaries, and the
hidden q4 scaffold. Rose checked that this does not claim q > 2 fitted support
or a nonlinear interval method.

## Scope Boundary

This slice adds reporting status only. It does not add derived covariance
intervals, does not expose q > 2 syntax, does not make ordinary fitted q4
models populate covariance rows, and does not change the fitted likelihood.

## Files Changed

- `R/methods.R`
- `tests/testthat/test-summary.R`
- `tests/testthat/test-covariance-block-registry.R`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-13-slice-9d-derived-covariance-interval-status-guard.md`

## Checks Run

- `air format R/methods.R tests/testthat/test-summary.R
  tests/testthat/test-covariance-block-registry.R NEWS.md ROADMAP.md
  docs/design/28-double-hierarchical-endpoint.md docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-slice-9d-derived-covariance-interval-status-guard.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "summary|covariance-block-registry|corpairs")'`:
  passed with 322 expectations, 0 failures, 0 warnings, and 0 skips.
- `git diff --check`: passed.

## Next Actions

1. Commit and push the Slice 9 stack.
2. Trigger `R-CMD-check.yaml` manually for the branch, because the workflow is
   not configured to run on every feature-branch push.
3. Use the GitHub Actions result as the Slice 9 boundary check before starting
   Slice 10.
