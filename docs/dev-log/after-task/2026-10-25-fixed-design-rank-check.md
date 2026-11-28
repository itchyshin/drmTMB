# After task: pre-fit rank check for every fixed-effect design (#1478)

Reader: a drmTMB user who writes `sigma ~ x + xdup` (or any other aliased
non-`mu` or ML design) and currently gets `converged = TRUE` with no usable
standard errors.

## Goal

Abort at spec-build time when any dense fixed-effect design in `spec$X` is
rank-deficient, not only REML `mu`.

## Implemented

`drm_validate_fixed_design_rank()` walks every named block in `spec$X`, skips
NULL, empty, and sparse-fixed blocks, and uses the same `qr()` tolerance as
`drm_fixed_effect_rank_deficient()` (`drm_twin_rank_tol`). It is called from
`drm_apply_estimator_spec()` so ML, REML, and MSPL share the check. The old
REML-only `mu` messages remain as a second line of defence for those two
validators.

## Files Changed

- `R/drmTMB.R`: new validator and call site.
- `tests/testthat/test-fixed-design-rank.R`: red-on-main regressions for
  collinear `sigma` and `mu` under ML, plus a full-rank neighbour.
- `tests/testthat/test-comparators.R`: REML collinear-`mu` neighbour now
  matches the shared message.
- `NEWS.md` bug-fix bullet.

## Checks Run

`pkgload::load_all()` then
`testthat::test_file("tests/testthat/test-fixed-design-rank.R")`: 6
expectations, 0 failures. A one-off REML `y ~ x + x_dup` call printed
`rank-deficient` for `mu` and did not reach the optimiser. Full package
tests and `R CMD check` were not run.

## Tests Of The Tests

The new file fails on unfixed `main` because `sigma ~ x + xdup` currently
fits. The neighbour `sigma ~ x` still fits after the change.

## Consistency Audit

`rg "full-rank dense" tests R docs/dev-log/known-limitations.md NEWS.md`
only hits the remaining REML-only `cli_abort()` strings and historical notes.
No lineage, C17, or capability-ledger files were edited.

## GitHub Issue Maintenance

Closes #1478 if the focused tests pass. #1470 remains the post-fit honesty
track (open PR #1505) and is not closed here.

## Known Limitations

Sparse-fixed `mu` is skipped here because REML already refuses that route.
Near-collinear (not exact duplicate) columns still reach the optimiser; that
is a `check_drm()` note, not this abort.

## Next Actions

Independent reviewer pass on the PR. Do not merge.
