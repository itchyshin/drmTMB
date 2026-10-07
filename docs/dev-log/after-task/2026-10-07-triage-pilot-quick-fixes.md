# After Task: Triage pilot close verdicts and three quick fixes

## Goal

Give applied users and package contributors a measured close-candidate pass
on six open issues, and land two small user-facing fixes that do not need a
new design decision: `update()` for ordinary `drmTMB` fits, and `level`
validation on variance-ratio extractors. An attempted
`miss_control(predictor = "fail")` evaluated-control change for #1484 was
reverted and is waiting on a maintainer decision; merging this branch must
not auto-close #1484.

## Implemented

Wrote `triage/pilot_close_verdicts.md` against `origin/main` at
`75845a3d0`. Two issues can honestly close now: #1323 is already fixed by
PR #1368 / `0d07d18d7`, and #1015 is an explicitly parked planning item.
#1250, #1469, #1470, and #1462 stay open.

On the same branch, `update.drmTMB()` refits from the stored call with a new
`bf()` / `drm_formula()` or named arguments such as `data`.
`drm_variance_ratio()` now calls `validate_profile_level()` before any
interval arithmetic, so `heritability()`, `icc()`, and `repeatability()`
error on `level = 95`, `0`, or `-1`. A first-pass change that honoured the
evaluated `miss_control()` `predictor` field (#1484) was reverted: that
semantics change is waiting on a maintainer decision, so #1484 stays open.

## Mathematical Contract

No likelihood or parameterization changed. The variance-ratio Wald interval
still uses `qnorm(1 - (1 - level) / 2)` after `level` is confirmed to lie
strictly in `(0, 1)`.

## Files Changed

- `R/methods.R`: `update.drmTMB()`.
- `R/heritability.R`: `validate_profile_level(level)` in `drm_variance_ratio()`.
- `R/missing-data.R`, `R/drmTMB.R`: #1484 evaluated-control edit reverted;
  A-2 / #1332 call-syntax helper restored.
- `tests/testthat/test-update-drmTMB.R`,
  `tests/testthat/test-heritability.R`.
  The #1484 regression file was removed with the revert.
- `NEWS.md`, `man/update.drmTMB.Rd`, `man/heritability.Rd`, `man/miss_control.Rd`,
  `_pkgdown.yml`, `docs/design/capability-status.md`,
  `docs/design/parity-matrix.md`, `tools/write-parity-matrix.R`,
  `docs/dev-log/check-log.md`, `triage/pilot_close_verdicts.md`.
- This report.

## Checks Run

The cloud image had no R. Ubuntu 24.04 `r-base` 4.3.3 was installed, then TMB,
cli, lifecycle, RcppEigen, and testthat. `R CMD INSTALL` of this branch
succeeded.

Focused testthat files, after one test fix (Gaussian `y + 1` does not change
logLik when an intercept is present):

- `test-update-drmTMB.R`: 1 test, 0 fail (later 9/9 including unnamed extras)
- `test-missing-data-control.R`: 3 tests, 0 fail
- `test-dinnage-audit-wave4b2.R`: 9 pass, 1 skip (`tweedie` not installed)
- heritability `#1480` level block: 9 `expect_error` successes

`R CMD build --no-build-vignettes` then
`R CMD check --no-vignettes --no-manual --no-tests` on `drmTMB_0.7.1.tar.gz`
finished with examples OK and Status 2 WARNINGs, 4 NOTEs. The WARNINGs are from
skipping vignette rebuild (`inst/doc` absent). The NOTEs are missing Suggests,
installed size 98.1 Mb, pre-existing `%||%` globals on R 4.3, and Rd xrefs to
uninstalled `fmesher`/`sf`. The full testthat suite was not run.

## Tests Of The Tests

The #1480 dummy-object test failed before `validate_profile_level()` was
added, because `drm_variance_ratio()` continued into family checks. The
#1241 test asks for a refit that current `main` cannot dispatch. An
evaluated-control check for stored `miss_control(predictor = "fail")` was
tried for #1484 and then reverted; that issue stays open pending a
maintainer decision.

## Consistency Audit

```sh
rg "no update\\.drmTMB|there is no update.drmTMB" docs NEWS.md tools R
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" NEWS.md docs/design/capability-status.md docs/dev-log/after-task/2026-10-07-triage-pilot-quick-fixes.md
```

The remaining "no `update.drmTMB()`" mentions are historical evidence notes,
not current capability claims.

## GitHub Issue Maintenance

Did not close or comment on any issue. The PR body uses `Fixes #1241` and
`Fixes #1480` only. It must not say `Fixes #1484` or `Closes #1484`: the
#1484 evaluated-control fix was reverted and is waiting on a maintainer
decision, so merging must leave #1484 open. Close verdicts for #1323 and
#1015 are recommendations only.

## What Did Not Go Smoothly

#1332 keyed the fail check off call syntax so
`miss_control(response = "include")` could drop incomplete predictors while
keeping default `predictor = "fail"`. A first-pass #1484 change honoured
the evaluated field and broke 13 missing-response tests. That change is
reverted; the call-syntax helper is restored until a maintainer decides
whether an explicit `response = "include"` / `"drop"` should drop those
rows or error.

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
