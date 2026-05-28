# After-Task Report: Phase 18 Skew-Normal Implementation Gate

Date: 2026-05-28

## Goal

Turn the remaining skew-normal Slices 1689-1702 into a concrete
implementation gate while keeping `skew_normal()` absent and design-only.

## Implemented

`docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md`
now names the density, normal-limit, sign-orientation, malformed-neighbour,
method, documentation, provenance, no-fit, recovery, false-positive,
confounding, interval-status, diagnostic, runtime, DGP, and summary checks
required before the first implementation PR can expose skew-normal support.

`tests/testthat/test-skew-normal-boundary.R` now reads that gate as part of the
no-fit boundary test while still requiring `skew_normal()` to remain absent
from the package namespace.

`tests/testthat/test-check-drm.R` now disables standard-error reporting for a
diagnostic-only bivariate phylogenetic covariance fit after Windows CI exposed
a platform-specific `NaNs produced` warning from `sdreport()`. The test still
checks the fitted covariance diagnostics; it does not need standard errors.

## Files Changed

- `docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md`
- `tests/testthat/test-skew-normal-boundary.R`
- `tests/testthat/test-check-drm.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format docs/design/132-phase-18-skew-normal-implementation-gate-slices-1689-1702.md tests/testthat/test-skew-normal-boundary.R tests/testthat/test-check-drm.R docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-skew-normal-implementation-gate.md
Rscript --vanilla -e "devtools::test(filter = '^skew-normal-boundary$', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = '^check-drm$', reporter = 'summary')"
Rscript --vanilla -e "devtools::load_all(quiet = TRUE); stopifnot(!exists('skew_normal', envir = asNamespace('drmTMB'), inherits = FALSE)); cat('skew_normal constructor absent\n')"
rg -n "skew_normal\\(" R src NAMESPACE man
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.
Focused `test-skew-normal-boundary` and `test-check-drm` passed, the
constructor-absence check confirmed that `skew_normal` is absent, the
package-code support scan found no matches, `pkgdown::check_pkgdown()`
reported no problems, and
`git diff --check` was clean.

## Tests Of The Tests

The boundary test now verifies three local design artifacts: the source map,
the first-test contract, and the implementation gate. It checks that each
continues to describe planned support rather than fitted support, and that the
package namespace still has no `skew_normal()` constructor.

## Known Limitations

This is not an implementation PR. It adds no constructor, no density helper in
package code, no C++ or TMB branch, no exported documentation, no `NAMESPACE`
entry, no formula-grammar change, and no fitted skew-normal claim.
