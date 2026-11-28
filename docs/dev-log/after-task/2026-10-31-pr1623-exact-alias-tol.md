# After task: exact-alias tolerance for the #1623 pre-fit rank abort

Reader: a reviewer of #1623 after the four Ubuntu shards failed on
`4ed1481eb`, and a user who writes `poly(x, 2) + I(x^2)` or nearly
collinear predictors.

## Goal

Keep the #1478 abort for exact aliases (`sigma ~ x + xdup`) without refusing
near-collinear designs that `check_drm()` is meant to grade, or supported
formulas that only become aliased through a test fixture.

## Implemented

`drm_validate_fixed_design_rank()` now uses `drm_exact_alias_rank_tol`
(1e-12). `check_drm()` still uses `drm_twin_rank_tol` (1e-8). Tests that
were exact aliases now expect the abort; `prediction_grid()` and the
extreme-cutpoint cumulative-logit fixture were given full-rank data.

## Files Changed

- `R/check.R`: new `drm_exact_alias_rank_tol`.
- `R/drmTMB.R`: abort uses that tolerance.
- `tests/testthat/test-fixed-design-rank.R`: 1e-9 neighbour still fits.
- `tests/testthat/test-gaussian-location-scale.R`: `poly + I(x^2)` aborts;
  the transformation test keeps `poly(x, 2)` without `I(x^2)`.
- `tests/testthat/test-predict-character-predictors.R`: `chr + nchar(chr)`
  aborts; predict still runs on `y ~ chr`.
- `tests/testthat/test-prediction-grid.R`: uncoupled habitat, season, site.
- `tests/testthat/test-cumulative-logit.R`: `x = c(-1, 0, 1)`.
- `tests/testthat/test-mspl-estimator.R`: accept `rank-deficient`.
- this after-task note and a `check-log.md` header.

## Checks Run

`pkgload::load_all()` then the seven files that failed or pin the abort:
`test-fixed-design-rank.R` PASS 7 (one sdreport NaN warning on 1e-9);
`test-gaussian-location-scale.R` FAIL 0; `test-predict-character-predictors.R`
PASS 14; `test-prediction-grid.R` PASS 44; `test-cumulative-logit.R` PASS 85;
`test-check-conditioning.R` FAIL 0 (1e-9 row now reaches its existing
`pdHess` skip); `test-mspl-estimator.R` PASS 146.

## Tests Of The Tests

`sigma ~ x + xdup` still fails on unfixed `main`. The 1e-9 neighbour failed
on `4ed1481eb` before the tolerance split.

## Consistency Audit

`rg "drm_twin_rank_tol|drm_exact_alias_rank_tol|rank-deficient|x \\+ xdup" R tests NEWS.md docs/dev-log/known-limitations.md`
hits the new constant, the abort, the focused tests, and the existing NEWS
#1478 bullet. Known limitations does not still claim the old `vcov()`-only
path.

## GitHub Issue Maintenance

#1478 stays the close target of #1623. #1470 remains post-fit honesty. No
new issues opened.

## Known Limitations

Sparse-fixed `mu` is still skipped. A design that is aliased only at a
tolerance between 1e-12 and 1e-8 still fits and is a `check_drm()` note.

## Next Actions

Recertify C17 after this `R/drmTMB.R` edit, push, and wait for CI. Do not
merge from this note.
