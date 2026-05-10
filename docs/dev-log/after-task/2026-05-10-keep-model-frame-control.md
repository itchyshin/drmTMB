# After Task: keep_model_frame Storage Control

## Goal

Expose `drm_control(keep_model_frame = FALSE)` as a post-fit storage control
after adding response-name metadata and method smoke tests for no-model-frame
fits.

## Implemented

- Removed the temporary validation block that forced `keep_model_frame = TRUE`.
- Added `drm_drop_model_frames()` and call it from `drm_apply_storage_control()`
  when `keep_model_frame = FALSE`.
- Dropped top-level `fit$model$model_frame` and nested random-effect scale
  model-frame caches after fitting.
- Updated the control tests to use a real `keep_model_frame = FALSE` fit.
- Updated `R/control.R`, `vignettes/large-data.Rmd`, `NEWS.md`, `ROADMAP.md`,
  `docs/design/23-large-data-memory.md`, and
  `docs/dev-log/known-limitations.md`.

## Mathematical Contract

No likelihood, formula grammar, optimizer path, parameter transform, or public
statistical parameter changed. The control changes only fitted-object storage
after TMB data, optimization results, standard errors, response vectors,
offsets, model matrices, terms, and metadata have been built.

## Files Changed

- `R/control.R`
- `tests/testthat/test-control.R`
- `vignettes/large-data.Rmd`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-keep-model-frame-control.md`

## Checks Run

- `air format R/control.R tests/testthat/test-control.R`
- `Rscript -e "devtools::test(filter = 'control')"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `rg -n "0\\.0\\.0\\.9000|drmTMB 0\\.0\\.0\\.9000|version ['\\\"]?0\\.0\\.0\\.9000|not implemented|later keep_model_frame|planned.*keep_model_frame|must be TRUE" ...`
- `git diff --check`

The targeted control tests completed with 52 passes. The full package test
suite completed with 1,456 passes, 0 failures, 0 warnings, and 0 skips.
pkgdown checks and the local site build completed cleanly. Local R CMD check
completed with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The control test now fits with
`drm_control(keep_data = FALSE, keep_model_frame = FALSE, keep_tmb_object = FALSE)`,
then checks that `fit$model$model_frame` is `NULL` while prediction, fitted
values, residuals, simulation, and `check_drm()` still work.

## Consistency Audit

The large-data design note now says `keep_model_frame = FALSE` is implemented
as a post-fit storage control. The large-data vignette explains that this does
not avoid constructing model frames before optimization. A stale-wording scan
found no old package-version banner or `keep_model_frame` implementation drift;
the remaining "not implemented" match is the expected spatial-roadmap wording.

## What Did Not Go Smoothly

Earlier prose correctly treated `keep_model_frame = FALSE` as planned, so this
patch required a stale-wording pass across NEWS, roadmap, the vignette, known
limitations, and the design note.

## Team Learning

Emmy should keep storage controls explicit and post-fit unless the construction
path changes. Boole should keep the user-facing wording precise: this drops
stored model frames, not model-frame construction. Rose should keep checking
that "implemented" and "planned" labels move together across docs.

## Known Limitations

The control does not reduce peak memory during model construction. Sparse
fixed-effect matrices and aggregation remain future work for reducing memory
before optimization.

## Next Actions

1. Commit and push this storage-control slice, then monitor R-CMD-check and
   pkgdown.
2. Add broader no-model-frame coverage for any remaining method surfaces.
3. Continue benchmark runs for factor-heavy and `sigma ~ x` scenarios.
