# After Task: Model-Frame Dependency Map

## Goal

Prepare the next large-data memory reduction step by identifying which post-fit
methods depend on stored model frames and by removing the first small blocker:
response labels for fitted correlation summaries.

## Implemented

- Added a method-dependency table to `docs/design/23-large-data-memory.md`.
- Stored fitted response names in `model$response_names` before TMB fitting.
- Updated response-name extraction to prefer `model$response_names` and fall
  back to `model$model_frame` for older fitted objects.
- Added `corpairs()` tests that manually remove `model$model_frame` and still
  recover response names for residual `rho12` and univariate group-level
  correlation summaries.

## Mathematical Contract

No likelihood, formula grammar, optimizer behaviour, link function, or public
parameterization changed. The patch adds fitted-object metadata and extractor
fallbacks only.

## Files Changed

- `R/drmTMB.R`
- `R/methods.R`
- `tests/testthat/test-control.R`
- `tests/testthat/test-corpairs.R`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-model-frame-dependency-map.md`

## Checks Run

- `air format R/drmTMB.R R/methods.R tests/testthat/test-corpairs.R`
- `Rscript -e "devtools::test(filter = 'corpairs|control')"`
- `git diff --check`
- `rg -n "model-frame dependency|Model-Frame Dependency Map|response_names|keep_model_frame = FALSE|manually removed|corpairs\\(\\) regression" R tests docs/design/23-large-data-memory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-model-frame-dependency-map.md`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `air format tests/testthat/test-control.R`
- `Rscript -e "devtools::test(filter = 'control')"`
- `Rscript -e "devtools::test()"`

The targeted tests completed with 65 passes. The full test suite completed with
1428 passes. `pkgdown::check_pkgdown()` found no problems. R CMD check
completed with 0 errors, 0 warnings, and 0 notes. The follow-up control test
run completed with 35 passes after adding the first method-matrix smoke tests,
and the follow-up full suite completed with 1439 passes.

## Tests Of The Tests

The new tests mutate fitted objects by setting `fit$model$model_frame <- NULL`.
That forces `corpairs()` to use the new response-name metadata instead of the
old model-frame path. The follow-up control tests use the same mutation to
check core Gaussian post-fit methods and Poisson offset prediction without a
stored model frame.

## Consistency Audit

The design note still says `keep_model_frame = FALSE` is planned rather than
implemented. The new dependency map records which public surfaces should be
tested before that control becomes user-facing.

## What Did Not Go Smoothly

The initial large-data storage control correctly blocked
`keep_model_frame = FALSE`, but it did not yet name the exact method
dependencies. The dependency map makes that work less hand-wavy.

## Team Learning

Emmy should prefer small fitted-object metadata over relying on bulky
construction-time frames. Boole should keep the public storage control blocked
until each method surface has a regression test. Rose should continue checking
that the design doc says "planned" until the control is truly enabled.

## Known Limitations

`drm_control(keep_model_frame = FALSE)` remains unavailable. The next patch
must test prediction, fitted values, residuals, simulation, diagnostics, and
extractors across the implemented family set before exposing it.

## Next Actions

1. Add a broader method matrix across the remaining family set.
2. Test bivariate known-covariance and beta-binomial trial paths without stored
   model frames.
3. Only then allow the control to drop `model$model_frame`.
