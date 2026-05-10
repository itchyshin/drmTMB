# After Task: Optimizer Budget Diagnostic

## Goal

Help users diagnose difficult fits by showing optimizer iteration and evaluation
counts in `check_drm()`, alongside the existing convergence and gradient rows.

## Implemented

- Added an `optimizer_budget` row to `check_drm()`.
- Reports optimizer iterations, function evaluations, and gradient evaluations.
- Flags fits that reach a supplied `eval.max` or `iter.max` control as a
  `note` when the optimizer converged and a `warning` when it did not.
- Updated the check documentation, getting-started article, model-workflow
  article, and NEWS entry.
- Added tests for the new diagnostic row and budget-limit status behaviour.

## Mathematical Contract

No likelihood equations or parameter transforms changed.

## Files Changed

- `R/check.R`
- `tests/testthat/test-check-drm.R`
- `man/check_drm.Rd`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-workflow.Rmd`
- `NEWS.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-10-optimizer-budget-diagnostic.md`

## Checks Run

- `air format R/check.R tests/testthat/test-check-drm.R vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-10-optimizer-budget-diagnostic.md`:
  passed.
- `Rscript -e "devtools::test(filter = 'check-drm')"`: passed with 61 tests,
  0 failures, 0 warnings, 0 skips.
- `Rscript -e "devtools::document()"`: passed and refreshed
  `man/check_drm.Rd`.
- `Rscript -e "devtools::test()"`: passed with 1464 tests, 0 failures,
  0 warnings, 0 skips.
- `git diff --check`: passed.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems.
- `Rscript -e "pkgdown::build_site()"`: passed.
- `Rscript tools/fix-pkgdown-favicon-mime.R pkgdown-site`: passed.
- `rg -n "optimizer_budget|optimizer evaluation counts|eval\\.max|iter\\.max" R/check.R man/check_drm.Rd tests/testthat/test-check-drm.R vignettes/drmTMB.Rmd vignettes/model-workflow.Rmd NEWS.md pkgdown-site/reference/check_drm.html pkgdown-site/articles/drmTMB.html pkgdown-site/articles/model-workflow.html docs/dev-log/after-task/2026-05-10-optimizer-budget-diagnostic.md docs/dev-log/check-log.md`:
  passed and found the expected source, test, documentation, and rendered-site
  entries.
- `Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, 0 notes.

## Known Limitations

The diagnostic reports optimizer budget use; it does not decide whether a larger
optimizer budget is scientifically justified.
