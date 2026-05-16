# After Task: Slice 101 Prediction Grid Helper

## Goal

Add the first explicit prediction-grid helper for Phase 17. The target was a
data-only contract that creates `newdata` grids for `predict_parameters()` and
`marginal_parameters()` without adding plotting dependencies, Bayesian claims,
EMM contrasts, slopes, or interval columns.

## Implemented

- Added exported `prediction_grid()` generic and `prediction_grid.drmTMB()`.
- Added `margin = "mean_reference"` for focal grids with nuisance predictors
  held at reference values or supplied `condition` values, including first
  fitted logical values.
- Added `margin = "empirical"` for counterfactual grids that cross focal
  values with fitted model rows.
- Added `drm_prediction_grid` metadata for focal terms, conditioned terms,
  margin, weights label, grid source, reference terms, predictor terms, source
  rows, and grid rows.
- Added tests for ordinary use, automatic focal values, empirical grids,
  integration with `predict_parameters()` and `marginal_parameters()`, invalid
  terms, invalid levels, missing conditions, and `keep_data = FALSE` fits.
- Added the reference topic to `_pkgdown.yml`.
- Updated NEWS, ROADMAP, the Phase 17 design note, and the model-workflow
  article.
- Wrote recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-05-16-125304-codex-checkpoint.md`.

## Mathematical Contract

No likelihood, TMB template, formula grammar, fitted parameterization, or random
effect representation changed. `prediction_grid()` only builds model-compatible
data frames. The helper keeps `sigma` and `rho12` terminology untouched and
does not introduce `rho`, `tau`, Bayesian posterior terminology, or a
multivariate surface beyond the existing univariate and bivariate scope.

## Files Changed

- `R/prediction-grid.R`
- `NAMESPACE`
- `man/prediction_grid.Rd`
- `tests/testthat/test-prediction-grid.R`
- `_pkgdown.yml`
- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-101-prediction-grid.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-125304-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/prediction-grid.R tests/testthat/test-prediction-grid.R`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/prediction_grid.Rd` and namespace exports.
- `Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::test(reporter = 'summary')"`: passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/prediction_grid.html`, `articles/model-workflow.html`,
  `ROADMAP.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'prediction_grid|drm_prediction_grid|mean_reference|empirical|tables, not plotting functions|plotting helper|EMM|interval_source' R tests/testthat man NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  confirmed source and rendered wording for the new helper, metadata class,
  grid rules, and Phase 17 boundaries.
- `rg -n 'autoplot\\.drmTMB|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|prediction_grid.*plot|plotting support' DESCRIPTION NEWS.md ROADMAP.md R tests docs/design vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  returned only intended design-boundary matches.
- `git diff -U0 -- NAMESPACE NEWS.md ROADMAP.md _pkgdown.yml docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd R/prediction-grid.R man/prediction_grid.Rd tests/testthat/test-prediction-grid.R | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  returned no matches.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 101 prediction_grid helper" --next "append check-log and after-task report, then stage, commit, push, and open PR"`:
  passed and wrote the recovery checkpoint.

## Tests Of The Tests

The first focused test run failed because a factor `NA` condition was reported
as an invalid level before the helper reached the missing-condition contract.
The implementation now checks condition length and missingness before type
casting, and the focused test suite passes with that negative case in place.

The focused tests also call `predict_parameters()` and `marginal_parameters()`
on generated grids, so they do not only check object classes or metadata. The
full suite was rerun after the new helper and roxygen output were in place.

## Consistency Audit

The source files, manual page, pkgdown reference index, model-workflow article,
roadmap, NEWS entry, Phase 17 design note, and rendered site now describe the
same contract:

- `prediction_grid()` is an explicit data-frame builder.
- `mean_reference` and `empirical` are the two current grid rules.
- `weights` is metadata for later marginalization work, not a computed summary.
- The helper feeds `predict_parameters()` and `marginal_parameters()`.
- Plotting, EMM contrasts, slopes, and interval columns remain future work.
- No `ggplot2`, `tidybayes`, or `ggdist` dependency was added.

## What Did Not Go Smoothly

The initial missing-condition test exposed a misleading factor-level error for
`condition = list(habitat = NA)`. That was useful: it moved the missing-value
check ahead of type casting and made the user-facing validation more direct.

## Team Learning

- Ada: Phase 17 can now move from research notes to a narrow grid contract
  without committing to a plotting API.
- Boole: `at` should vary only focal terms, while `condition` should hold
  non-focal terms fixed; the error messages enforce that split.
- Pat: explicit metadata gives applied users something to inspect before they
  interpret a marginal table.
- Fisher: empirical grids should stay visibly counterfactual until weighting
  and interval provenance are implemented.
- Grace: adding the reference page to pkgdown at the same time as the export
  kept the site navigation in sync.
- Rose: negative tests for invalid levels, missing conditions, and dropped data
  prevent the first helper from quietly becoming broader than its contract.

## Known Limitations

- Fits created with `drm_control(keep_data = FALSE)` cannot use
  `prediction_grid()` because the helper needs fitted model data for predictor
  discovery, reference values, and empirical rows.
- `weights` is recorded as metadata only.
- No plotting helper, EMM contrast, slope helper, interval column, or external
  visualization dependency was added.
- More specialized reference-grid checks are still needed for transformed,
  bounded, count, ordinal, bivariate, structured, and random-scale workflows
  before broad compatibility claims.

## Next Actions

1. Add model-workflow examples that use `prediction_grid(..., margin = "empirical")`
   with `marginal_parameters(..., by = focal_terms)`.
2. Decide whether a later helper should consume `drm_prediction_grid` metadata
   for default grouping and labels.
3. Add interval provenance to prediction and marginal tables only after the
   interval source is computed and tested.
4. Keep any future plotting helper narrow and data-first, consuming these
   tables rather than hiding grid, scale, or marginalization choices.
