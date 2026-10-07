# After Task: Triage pilot close verdicts and three quick fixes

## Goal

Give applied users and package contributors a measured close-candidate pass
on six open issues, and land three small user-facing fixes that do not need a
new design decision: `update()` for ordinary `drmTMB` fits, `level` validation
on variance-ratio extractors, and `miss_control(predictor = "fail")` that
follows the evaluated control object.

## Implemented

Wrote `triage/pilot_close_verdicts.md` against `origin/main` at
`75845a3d0`. Two issues can honestly close now: #1323 is already fixed by
PR #1368 / `0d07d18d7`, and #1015 is an explicitly parked planning item.
#1250, #1469, #1470, and #1462 stay open.

On the same branch, `update.drmTMB()` refits from the stored call with a new
`bf()` / `drm_formula()` or named arguments such as `data`.
`drm_variance_ratio()` now calls `validate_profile_level()` before any
interval arithmetic, so `heritability()`, `icc()`, and `repeatability()`
error on `level = 95`, `0`, or `-1`. The missing-predictor fail check uses
the parsed control's `predictor` field whenever the caller supplied
`missing =`, including a stored control or a variable holding `"fail"`.
Omitting `missing` still drops incomplete predictor rows.

## Mathematical Contract

No likelihood or parameterization changed. The variance-ratio Wald interval
still uses `qnorm(1 - (1 - level) / 2)` after `level` is confirmed to lie
strictly in `(0, 1)`.

## Files Changed

- `R/methods.R`: `update.drmTMB()`.
- `R/heritability.R`: `validate_profile_level(level)` in `drm_variance_ratio()`.
- `R/missing-data.R`, `R/drmTMB.R`: evaluated `predictor = "fail"` check.
- `tests/testthat/test-update-drmTMB.R`,
  `tests/testthat/test-miss-control-predictor-fail.R`,
  `tests/testthat/test-heritability.R`.
- `NEWS.md`, `man/update.drmTMB.Rd`, `man/heritability.Rd`, `man/miss_control.Rd`,
  `_pkgdown.yml`, `docs/design/capability-status.md`,
  `docs/design/parity-matrix.md`, `tools/write-parity-matrix.R`,
  `docs/dev-log/check-log.md`, `triage/pilot_close_verdicts.md`.
- This report.

## Checks Run

Recorded after the focused test and `devtools::check()` run on this branch.

## Tests Of The Tests

The #1480 dummy-object test failed before `validate_profile_level()` was
added, because `drm_variance_ratio()` continued into family checks. The
#1484 stored-control and `predictor = pf` calls failed on current `main`
and pass after the evaluated-control check. The #1241 test asks for a
refit that current `main` cannot dispatch.

## Consistency Audit

```sh
rg "no update\\.drmTMB|there is no update.drmTMB" docs NEWS.md tools R
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" NEWS.md docs/design/capability-status.md docs/dev-log/after-task/2026-10-07-triage-pilot-quick-fixes.md
```

The remaining "no `update.drmTMB()`" mentions are historical evidence notes,
not current capability claims.

## GitHub Issue Maintenance

Did not close or comment on any issue. The PR body uses `Fixes #1241`,
`Fixes #1480`, and `Fixes #1484`. Close verdicts for #1323 and #1015 are
recommendations only.

## What Did Not Go Smoothly

#1332 keyed the fail check off call syntax so
`miss_control(response = "include")` could drop incomplete predictors while
keeping default `predictor = "fail"`. Honoring the evaluated field means an
explicit `missing = miss_control(response = "include")` now errors when
predictors are missing, which matches `?miss_control`. Users who want
missing-response include plus complete-case predictors still omit `missing`
or need a later `predictor = "drop"` design.

## Team Learning

A stored control and a literal call must take the same path. When a formal
default makes `missing(missing)` unusable, test the evaluated object, not
the unevaluated language.

## Known Limitations

`update.drmTMB_julia()` is not added. `anova.drmTMB()` still aborts, so the
model-comparison suite stays `scope-limited`. Single-fit OpenMP (#1250 /
#1232) and the Student large-`nu` kernel (#1462) were left untouched.

## Next Actions

A human can close #1323 and #1015 from the verdict file. Run the focused
tests and `devtools::check()` on this branch before merge.
