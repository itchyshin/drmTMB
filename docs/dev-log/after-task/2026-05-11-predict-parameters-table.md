# After Task: `predict_parameters()` Table

## Goal

Add a small interpretation surface that can carry mean, scale, shape,
probability, and residual-correlation predictions on the same `newdata` grid.

## Implemented

- Added exported `predict_parameters()`.
- Added `predict_parameters.drmTMB()` for fitted `drmTMB` objects.
- Returned long-format predictions with `row`, `row_label`, `dpar`,
  `component`, `type`, and `estimate` columns.
- Appended supplied `newdata` columns by default, with reserved output-column
  names prefixed as `newdata_*`.
- Added component labels for location, distributional scale, shape,
  probability, residual correlation, random-effect scale models, and other
  distributional parameters.
- Updated `NEWS.md`, `_pkgdown.yml`, `vignettes/model-workflow.Rmd`,
  `NAMESPACE`, and `man/predict_parameters.Rd`.

## Mathematical Contract

No likelihood, formula grammar, or parameter transformation changed.
`predict_parameters()` delegates to `predict.drmTMB()` for each selected
distributional parameter. With `newdata = NULL`, it uses the same fitted-row
prediction contract as `predict()`. With supplied `newdata`, it returns
fixed-effect, population-level predictions, matching `predict()`.

## Files Changed

- `R/predict-parameters.R`
- `tests/testthat/test-predict-parameters.R`
- `NAMESPACE`
- `man/predict_parameters.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-predict-parameters-table.md`

## Checks Run

- `air format R/predict-parameters.R R/methods.R tests/testthat/test-predict-parameters.R NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::test(filter = 'predict-parameters')"`: passed with 23
  expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::document()"`: passed and regenerated `NAMESPACE` and
  `man/predict_parameters.Rd`.
- `Rscript -e "devtools::load_all(); dat <- data.frame(y=rnorm(12), x=seq(-1,1,length.out=12)); fit <- drmTMB(bf(y ~ x, sigma ~ x), data=dat); print(predict_parameters(fit, newdata=data.frame(x=c(0,1)), dpar=c('mu','sigma')))"`:
  passed and printed a four-row `mu`/`sigma` prediction table.
- `Rscript -e "devtools::test(filter = 'predict-parameters|summary')"`:
  passed with 55 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1712 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/predict_parameters.html`, `articles/model-workflow.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `LC_ALL=C rg -n "[^\x00-\x7F]" R/predict-parameters.R tests/testthat/test-predict-parameters.R NEWS.md vignettes/model-workflow.Rmd man/predict_parameters.Rd _pkgdown.yml`:
  passed with no matches.
- `rg -n "predict_parameters|long-format predictions|newdata_dpar|location.*distributional-scale|future plotting or marginalisation|same grid" R/predict-parameters.R tests/testthat/test-predict-parameters.R man/predict_parameters.Rd NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site/reference/predict_parameters.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html pkgdown-site/reference/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, tests, documentation, pkgdown navigation, generated
  reference, workflow article, and generated NEWS.
- `rg -n "predict\\(\\) returns one distributional parameter at a time|interpretation task needs several distributional parameters|plotting|marginalisation|marginalization|emmeans" README.md ROADMAP.md docs vignettes R man pkgdown-site --glob '!docs/dev-log/**' --glob '!pkgdown-site/search.json'`:
  confirmed that the new helper is described as a prediction-table surface, not
  as implemented emmeans-style marginalisation or plotting.

## Tests Of The Tests

- The Gaussian test compares `predict_parameters()` output directly with
  `predict(..., dpar = "mu")` and `predict(..., dpar = "sigma")`.
- The shape test checks Student-t `nu` uses the shape component and matches
  `predict(..., dpar = "nu")`.
- The bivariate test checks residual `rho12` uses the residual-correlation
  component and matches `rho12(fit, newdata = grid)`.
- The validation test covers malformed `dpar`, non-data-frame `newdata`,
  malformed `include_newdata`, and reserved `...`.

## Consistency Audit

The reference page, model-workflow article, NEWS entry, pkgdown reference index,
source code, and tests now describe the same contract: `predict()` remains the
single-parameter method, while `predict_parameters()` collects selected
distributional parameters into one long table for interpretation.

## What Did Not Go Smoothly

Before `devtools::document()`, the new S3 method was available in tests but not
exported through `NAMESPACE`, so a quick interactive smoke check failed. Running
roxygen regenerated the S3 method registration and export, and the smoke check
then passed.

## Team Learning

- Pat: the helper gives applied users one table for mean and variability
  without making them remember several extractor names.
- Boole: the API should stay close to `predict()`; `dpar`, `newdata`, and
  `type` are already learned names.
- Emmy: long-format output is the right dependency-free base for future plots
  and marginal summaries.

## Known Limitations

- The helper does not compute confidence intervals.
- The helper does not average over covariate distributions or produce emmeans
  contrasts.
- The helper does not draw plots; it only returns the data surface that later
  plotting helpers can consume.

## Next Actions

- Design a small marginalisation layer that averages a `predict_parameters()`
  grid within user-defined groups.
- Design plotting helpers that consume this long table for `mu`, `sigma`,
  `nu`, and `rho12` without adding a hard plotting dependency too early.
