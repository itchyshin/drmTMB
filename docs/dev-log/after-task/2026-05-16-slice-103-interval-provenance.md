# After Task: Slice 103 Interval Provenance Columns

## Goal

Add interval provenance columns to the Phase 17 prediction and marginal-summary
tables without computing confidence intervals or adding a plotting dependency.

## Implemented

- `predict_parameters()` now returns `conf.status = "not_requested"` and
  `interval_source = "not_available"` for every point-estimate row.
- `marginal_parameters()` carries the same provenance contract after averaging
  prediction rows.
- User-supplied `newdata` columns named `conf.status` or `interval_source` are
  renamed to `newdata_conf.status` and `newdata_interval_source`, matching the
  existing reserved-column behaviour.
- `marginal_parameters(..., by = "conf.status")` groups by the renamed
  `newdata_conf.status` column rather than colliding with the core provenance
  column.
- Roxygen, generated Rd files, the model-workflow article, NEWS, ROADMAP, and
  the visualization-grammar design note now describe the point-estimate-only
  interval provenance contract.
- Wrote recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-05-16-134305-codex-checkpoint.md`.

## Mathematical Contract

No likelihood, formula grammar, TMB code, parameter transformation, optimizer,
or fitted-object structure changed. The slice only changes post-fit table
shape. The statistical claim is deliberately narrow: these helpers return
point estimates and explicitly state that no interval was requested and no
interval source is available.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `R/marginal-parameters.R`
- `R/predict-parameters.R`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-103-interval-provenance.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-134305-codex-checkpoint.md`
- `man/marginal_parameters.Rd`
- `man/predict_parameters.Rd`
- `tests/testthat/test-marginal-parameters.R`
- `tests/testthat/test-predict-parameters.R`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format R/predict-parameters.R R/marginal-parameters.R tests/testthat/test-predict-parameters.R tests/testthat/test-marginal-parameters.R`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated the prediction
  and marginal-parameter Rd files.
- `Rscript -e "devtools::test()"`: passed with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 3578`.
- `Rscript -e "out <- tempfile(fileext = '.html'); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = out, quiet = TRUE); cat(out, '\n')"`:
  failed because the package was not loaded in the ad hoc render environment
  and `prediction_grid()` was unavailable.
- `Rscript -e "out <- tempfile(fileext = '.html'); env <- new.env(parent = globalenv()); devtools::load_all(export_all = FALSE, quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = out, quiet = TRUE, envir = env); cat(out, '\n')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered the
  updated reference, model-workflow article, ROADMAP, and NEWS pages.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n "conf\\.low|conf\\.high|std\\.error" R/predict-parameters.R R/marginal-parameters.R tests/testthat/test-predict-parameters.R tests/testthat/test-marginal-parameters.R vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md NEWS.md ROADMAP.md`:
  returned only the intended design-note schema references, not new prediction
  or marginal-table interval columns.
- `rg -n "plot_predictions|plot\\(|ggplot|geom_|half-eye|posterior draws|credible interval|Bayesian" R/predict-parameters.R R/marginal-parameters.R tests/testthat/test-predict-parameters.R tests/testthat/test-marginal-parameters.R vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md NEWS.md ROADMAP.md`:
  returned only intended design-boundary references; no plotting helper or
  Bayesian interval claim was added.
- `LC_ALL=C rg -n "[^\\x00-\\x7F]" R/predict-parameters.R R/marginal-parameters.R tests/testthat/test-predict-parameters.R tests/testthat/test-marginal-parameters.R vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md NEWS.md ROADMAP.md`:
  returned no matches.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 103 interval provenance columns" --next "append check-log and after-task report, then stage, commit, push, and open PR"`:
  passed and wrote the recovery checkpoint.

## Tests Of The Tests

The new tests check both the main table contract and one neighbouring collision
path. `test-predict-parameters.R` verifies that core provenance columns are
present for response-scale and link-scale rows, that their values are
`not_requested` and `not_available`, and that user `newdata` columns with the
same names are preserved under `newdata_*` names. `test-marginal-parameters.R`
checks grouped, fitted-row, and bivariate `rho12` summaries, then exercises
`by = "conf.status"` so the reserved-column path is covered by a real grouped
summary.

## Consistency Audit

The source files, generated Rd files, NEWS, ROADMAP, design note, vignette, and
rendered pkgdown pages now tell the same story: prediction and marginal tables
carry interval provenance, but they are still point-estimate tables. The scans
confirmed that no `conf.low`, `conf.high`, plotting helper, posterior-draw
wording, credible-interval wording, or new visualization dependency was added
outside the design discussion.

## What Did Not Go Smoothly

The first standalone vignette render failed because `rmarkdown::render()` was
called without first attaching the package; the document then could not find
`prediction_grid()`. Rerunning the render with `devtools::load_all()` in the
render session passed. This is a local validation setup issue rather than a
package-code change.

## Team Learning

- Ada: keep the slice scoped to one table-contract change and close it with
  code, tests, docs, check log, checkpoint, and PR evidence.
- Boole: reserve interval provenance names in both direct prediction rows and
  marginal grouping columns so the API remains parseable when users bring the
  same names in `newdata`.
- Fisher: do not add empty confidence-limit columns or decorative interval
  language before there is a validated interval source.
- Curie: pair positive provenance checks with a collision-path test so the
  tests cover ordinary use and a likely edge case.
- Pat: teach the reader that `not_requested` and `not_available` are action
  signals, not missing statistical results.
- Grace: render both the vignette and pkgdown site after changing exported docs
  and a reader-facing article.
- Rose: stale scans should include both source and rendered-site wording when a
  slice changes a table contract that future plots will consume.
- Gauss and Noether stayed watch-only because no likelihood, TMB, or symbolic
  model contract changed in this slice.

## Known Limitations

- `predict_parameters()` and `marginal_parameters()` still do not compute
  confidence intervals.
- `std.error`, `conf.low`, and `conf.high` remain future columns for a real
  interval-aware helper, not placeholders in this slice.
- No plotting helper, EMM method, slope helper, or external visualization
  dependency was added.
- `marginal_parameters()` is still an unweighted plug-in average of prediction
  rows.

## Next Actions

1. Add one narrow ggplot-oriented helper for `predict_parameters()` output only
   after the data contract remains stable through review.
2. Decide how future interval-aware helpers will populate `std.error`,
   `conf.low`, `conf.high`, `conf.status`, and `interval_source` without
   mixing profile, Wald, bootstrap, simulation, or Bayesian semantics.
3. Keep EMM-style contrasts and slope helpers as separate estimands rather than
   hidden plotting options.
