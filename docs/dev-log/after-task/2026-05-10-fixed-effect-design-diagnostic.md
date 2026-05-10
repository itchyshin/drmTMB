# After Task: Fixed-Effect Design Diagnostic

## Goal

Add a user-visible diagnostic for dense fixed-effect design size so large-data
fits with high-cardinality factors or wide interactions are easier to inspect.

## Implemented

- Added a `fixed_effect_design_size` row to `check_drm()`.
- Reported total dense design-matrix storage, maximum column count, and the
  largest distributional-parameter block.
- Added a note when dense design storage reaches 25 MB or any fixed-effect
  design reaches 30 columns.
- Added a test with a 45-level factor to confirm the diagnostic note.
- Updated NEWS and `man/check_drm.Rd`.

## Mathematical Contract

No likelihood, formula grammar, optimizer, prediction, or inference method
changed. This task only adds a post-fit diagnostic row.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-fixed-effect-design-diagnostic.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R`
- `Rscript -e "devtools::test(filter = 'check-drm')"`
- `Rscript -e "devtools::document()"`
- `Rscript -e "pkgdown::check_pkgdown()"`
- `Rscript -e "devtools::test()"`
- `Rscript -e "devtools::check(error_on = 'never', env_vars = c('_R_CHECK_SYSTEM_CLOCK_' = 'FALSE'))"`
- `Rscript -e "pkgdown::build_site()"`
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`
- `git diff --check`

The targeted check-drm tests completed with 57 passes. The full package test
suite completed with 1,460 passes, 0 failures, 0 warnings, and 0 skips. Local
R CMD check completed with 0 errors, 0 warnings, and 0 notes.

## Tests Of The Tests

The new test fits a Gaussian model with a 45-level factor in the location
formula. `check_drm()` then reports `fixed_effect_design_size` as a note with
`max_cols=45`, while `attr(chk, "ok")` remains `TRUE` because notes are
inspectable diagnostics rather than failed checks.

## Consistency Audit

The large-data benchmark showed factor-heavy dense matrices as a pressure
point. This diagnostic gives users a direct post-fit clue that dense
fixed-effect design matrices, not only phylogenetic precision matrices, may be
driving memory or convergence friction.

## Known Limitations

This does not implement sparse fixed-effect matrices. It only names the memory
pressure clearly.

## Next Actions

1. Use this diagnostic in future large-data examples.
2. Design the sparse fixed-effect matrix path with dense-versus-sparse parity
   tests before changing TMB data contracts.
