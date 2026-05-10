# After Task: Large-Data Storage Controls

## Goal

Prepare `drmTMB` for large data by adding a conservative first storage-control
path for fitted objects, without changing formula grammar or likelihood
parameterization.

## Implemented

- Added exported `drm_control()` with `optimizer`, `keep_data`,
  `keep_model_frame`, and `keep_tmb_object` arguments.
- Preserved the old optimizer-only path: plain `control = list(...)` is still
  passed to `stats::nlminb()`.
- Added `keep_data = FALSE` to drop `fit$data` and `fit$model$data` after
  fitting.
- Added `keep_tmb_object = FALSE` to drop `fit$obj` after optimization.
- Kept `keep_model_frame = FALSE` unavailable for now, with a clear error,
  because safe prediction, offset, residual, and diagnostic fallbacks are still
  needed.
- Updated `check_drm()` so the fixed-gradient row becomes a note when the TMB
  automatic-differentiation object was intentionally not retained.

## Mathematical Contract

No likelihood changed. The fitted model, optimized parameters, standard errors,
predictions, fitted values, residuals, simulation, and scale extraction use the
same stored model matrices, response vectors, parameters, and `sdreport`
objects as before. The new controls only prune post-fit R-side storage.

## Files Changed

- `R/control.R`
- `R/drmTMB.R`
- `R/check.R`
- `tests/testthat/test-control.R`
- `man/drm_control.Rd`
- `man/drmTMB.Rd`
- `man/check_drm.Rd`
- `NAMESPACE`
- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/23-large-data-memory.md`
- `docs/dev-log/known-limitations.md`

## Checks Run

- `air format R/control.R R/drmTMB.R R/check.R tests/testthat/test-control.R`
- `Rscript -e "devtools::test(filter = '^control|^check-drm')"`
- `Rscript -e "devtools::document()"` twice; the first run created the new
  topic and the second run had no warnings.
- `Rscript -e "devtools::test()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `rg -n "Large-data memory controls are not implemented yet|drm_control|keep_tmb_object|keep_model_frame = FALSE|sparse_fixed" ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/23-large-data-memory.md pkgdown-site/ROADMAP.html pkgdown-site/reference/drm_control.html pkgdown-site/news/index.html`

Results: focused tests passed with 77 successes; the full test suite passed
with 1424 successes; pkgdown found no problems; R CMD check completed with 0
errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The new tests cover three behaviours: validation of malformed control inputs,
backward compatibility for plain optimizer lists, and a memory-light Gaussian
fit where core post-fit methods still work after `fit$data`, `fit$model$data`,
and `fit$obj` are removed. The failure path for `keep_model_frame = FALSE` is
also tested so users do not accidentally get an unsafe half-supported option.

## Consistency Audit

The design note now describes the implemented `drm_control()` slice and keeps
`keep_model_frame = FALSE` and sparse fixed-effect matrices explicitly planned.
The roadmap and known limitations no longer say large-data memory controls are
entirely unimplemented. NEWS announces the user-facing function. `_pkgdown.yml`
includes the new reference topic, and the local pkgdown site contains
`reference/drm_control.html`.

## What Did Not Go Smoothly

The first documentation run warned because `drm_control()` had just been added
and its topic did not exist yet. A second `devtools::document()` run was clean.
The formatter also rewrote unrelated wrapping in `R/check.R`; Ada trimmed that
back so the diff stayed focused.

## Team Learning

Rose should keep checking for stale status wording whenever implementation
moves a planned feature into partial support. Grace's full-check path remains
worth the time for exported API changes. Pat's future test should try the new
control in an install-and-play workflow with a bigger simulated phylogenetic
dataset.

## Known Limitations

This is not full large-data readiness. `drmTMB` still builds ordinary model
frames and dense fixed-effect model matrices before optimization. It also still
stores model matrices and response vectors, because current post-fit methods
depend on them. Million-row readiness needs safe model-frame pruning, sparse
fixed-effect matrices, sufficient-statistic aggregation where mathematically
valid, and explicit large benchmark scripts.

## Next Actions

1. Add a non-CRAN large-data benchmark script for Gaussian phylogenetic
   location models at 100k rows first.
2. Prototype safe `keep_model_frame = FALSE` with explicit method fallbacks.
3. Add a sparse fixed-effect design experiment with dense-versus-sparse parity
   tests on small datasets.
4. Explore Gaussian sufficient-statistic aggregation for repeated rows.
