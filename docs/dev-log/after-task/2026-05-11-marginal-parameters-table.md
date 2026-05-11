# After Task: `marginal_parameters()` Table

## Goal

Add a small marginal summary layer that averages predicted distributional
parameters over fitted rows or supplied `newdata` groups.

## Implemented

- Added exported `marginal_parameters()`.
- Added `marginal_parameters.drmTMB()` for fitted `drmTMB` objects.
- Delegated prediction to `predict_parameters()` so the marginal table uses the
  same `dpar`, `newdata`, and `type` contract.
- Added optional `by` grouping over supplied `newdata` columns.
- Returned one row per distributional parameter and group combination, with
  `dpar`, `component`, `type`, optional grouping columns, `estimate`, and `n`.
- Updated `NEWS.md`, `_pkgdown.yml`, `vignettes/model-workflow.Rmd`,
  `NAMESPACE`, and `man/marginal_parameters.Rd`.

## Mathematical Contract

No likelihood, formula grammar, or parameter transformation changed.
`marginal_parameters()` computes unweighted arithmetic means of the
already-predicted parameter values returned by `predict_parameters()`. With
`newdata = NULL`, it averages fitted-row predictions. With supplied `newdata`,
it averages fixed-effect, population-level predictions for the supplied grid.

## Files Changed

- `R/marginal-parameters.R`
- `tests/testthat/test-marginal-parameters.R`
- `NAMESPACE`
- `man/marginal_parameters.Rd`
- `_pkgdown.yml`
- `NEWS.md`
- `vignettes/model-workflow.Rmd`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-11-marginal-parameters-table.md`

## Checks Run

- `air format R/marginal-parameters.R tests/testthat/test-marginal-parameters.R NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated `NAMESPACE` and
  `man/marginal_parameters.Rd`.
- `Rscript -e "devtools::load_all(); dat <- data.frame(y=rnorm(20), x=rep(c(0,1),10), g=factor(rep(c('a','b'), each=10))); fit <- drmTMB(bf(y ~ x + g, sigma ~ x), data=dat); grid <- expand.grid(x=c(0,1), g=levels(dat$g)); print(marginal_parameters(fit, newdata=grid, dpar=c('mu','sigma'), by='g'))"`:
  passed and printed a grouped `mu`/`sigma` marginal table.
- `Rscript -e "devtools::test(filter = 'marginal-parameters')"`: passed with
  17 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter = 'marginal-parameters|predict-parameters|summary')"`:
  passed with 72 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 1729 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/marginal_parameters.html`, `articles/model-workflow.html`, and
  `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `_R_CHECK_SYSTEM_CLOCK_=FALSE Rscript -e "devtools::check(document = FALSE, manual = FALSE, args = '--no-tests')"`:
  passed with 0 errors, 0 warnings, and 0 notes.
- `git diff --check`: passed.
- `git diff -U0 -- R/marginal-parameters.R tests/testthat/test-marginal-parameters.R NEWS.md vignettes/model-workflow.Rmd man/marginal_parameters.Rd _pkgdown.yml docs/dev-log/check-log.md | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  passed with no matches.
- `rg -n '[ \t]+$' R/marginal-parameters.R tests/testthat/test-marginal-parameters.R man/marginal_parameters.Rd`:
  passed with no matches.
- `rg -n 'marginal_parameters|simple marginalisation|group-level interpretation|future emmeans-style|supplied `newdata` groups|marginal-parameters' R/marginal-parameters.R tests/testthat/test-marginal-parameters.R man/marginal_parameters.Rd NEWS.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site/reference/marginal_parameters.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html pkgdown-site/reference/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source, tests, documentation, pkgdown navigation, generated
  reference, workflow article, and generated NEWS.
- `rg -n "emmeans|contrast|confidence intervals|profile intervals|plots|plotting|marginalisation|marginalization" R/marginal-parameters.R tests/testthat/test-marginal-parameters.R man/marginal_parameters.Rd NEWS.md vignettes/model-workflow.Rmd pkgdown-site/reference/marginal_parameters.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed that the helper is described as a simple plug-in marginal summary,
  not as implemented uncertainty, contrasts, or plotting.

## Tests Of The Tests

- The Gaussian test compares grouped `marginal_parameters()` output to an
  independent base `aggregate()` calculation over `predict_parameters()` rows.
- The Student-t test checks that fitted-row `nu` marginalisation uses the shape
  component and equals the mean of `predict(fit, dpar = "nu")`.
- The bivariate test checks that grouped `rho12` marginalisation uses the
  residual-correlation component and equals grouped means of `rho12(fit,
  newdata = grid)`.
- The validation test covers `by` without `newdata`, missing grouping columns,
  non-data-frame `newdata`, malformed `by`, and reserved `...`.

## Consistency Audit

The reference page, model-workflow article, NEWS entry, pkgdown reference index,
source code, and tests now describe the same contract:
`predict_parameters()` creates the long prediction table and
`marginal_parameters()` reduces that table to unweighted group summaries.

## What Did Not Go Smoothly

The first smoke-check command used double quotes around R code containing
`dat$g`, so the shell expanded `$g` and the grid lost its grouping column. The
package code and tests were fine; rerunning the smoke check with single-quoted
R code printed the expected grouped table.

## Team Learning

- Pat: a user can now make one compact table for mean, scale, shape, or
  residual correlation summaries without memorising several extractors.
- Boole: keeping `dpar`, `newdata`, `type`, and `by` explicit makes the helper
  predictable and close to existing R modelling habits.
- Fisher: the helper should stay honest about uncertainty; it reports plug-in
  averages only until interval and contrast machinery are designed.

## Known Limitations

- The helper computes unweighted means only.
- The helper does not compute confidence intervals, standard errors, contrasts,
  or profile intervals.
- The helper does not implement full `emmeans` integration.
- The helper does not draw plots; it returns the summary table that later
  plotting helpers can consume.

## Next Actions

- Design a plotting helper that consumes `predict_parameters()` and
  `marginal_parameters()` tables without adding a hard plotting dependency too
  early.
- Begin the issue #6 comparator harness so the next package-growth claims are
  backed by executable evidence.
