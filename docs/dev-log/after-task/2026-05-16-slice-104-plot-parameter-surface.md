# After Task: Slice 104 Plot Parameter Surface

## Goal

Add the first narrow, optional `ggplot2` plotting helper for Phase 17 without
turning prediction helpers into plotters or claiming interval, EMM, contrast,
or slope support.

## Implemented

- Added exported `plot_parameter_surface()`.
- Added `ggplot2` to `Suggests`, not `Imports`.
- The helper consumes a `predict_parameters()`-style long table, validates
  `dpar`, `type`, `estimate`, `conf.status`, and `interval_source`, and plots
  existing point estimates against one explicit x-axis column.
- The helper returns a composable `ggplot` object and draws lines, points, or
  both.
- The helper supports optional `colour`, `group`, `facet`, `dpar`, and `type`
  arguments using character column names.
- The helper fails with an informative message if `ggplot2` is unavailable.
- The helper uses temporary internal plotting columns so unusual user column
  names do not need tidy-eval imports or brittle formula construction.
- Added the function to pkgdown under a new Reference section,
  `Visualization`.
- Updated NEWS, ROADMAP, the visualization grammar design note, and the
  model-workflow article.
- Wrote recovery checkpoint
  `docs/dev-log/recovery-checkpoints/2026-05-16-141704-codex-checkpoint.md`.

## Mathematical Contract

No likelihood, formula grammar, TMB code, parameter transformation, optimizer,
prediction calculation, or uncertainty calculation changed. The new helper is a
plotting consumer for existing prediction-table rows. It does not compute
`std.error`, `conf.low`, `conf.high`, EMMs, contrasts, slopes, posterior draws,
or confidence distributions.

## Files Changed

- `DESCRIPTION`
- `NAMESPACE`
- `NEWS.md`
- `ROADMAP.md`
- `_pkgdown.yml`
- `R/plot-parameter-surface.R`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-104-plot-parameter-surface.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-141704-codex-checkpoint.md`
- `man/plot_parameter_surface.Rd`
- `tests/testthat/test-plot-parameter-surface.R`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format R/plot-parameter-surface.R tests/testthat/test-plot-parameter-surface.R NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd _pkgdown.yml DESCRIPTION`:
  passed.
- `Rscript -e "devtools::document()"`: passed and wrote `NAMESPACE` plus
  `man/plot_parameter_surface.Rd`.
- `Rscript -e "devtools::test(filter = 'plot-parameter-surface|predict-parameters|prediction-grid', reporter = 'summary')"`:
  initially passed with two `ggplot2::aes_string()` lifecycle warnings; the
  helper was then changed to use temporary internal columns and `ggplot2::aes()`.
- `Rscript -e "devtools::test(filter = 'plot-parameter-surface|predict-parameters|prediction-grid', reporter = 'summary')"`:
  passed after the lifecycle-warning fix.
- `Rscript -e "devtools::test()"`: passed with
  `FAIL 0 | WARN 0 | SKIP 0 | PASS 3593` before the final facet-column polish.
- `Rscript -e "devtools::test(filter = 'plot-parameter-surface', reporter = 'summary')"`:
  passed after the final facet-column polish.
- `Rscript -e "devtools::test(reporter = 'summary')"`: passed after the final
  facet-column polish.
- `Rscript -e "out <- tempfile(fileext = '.html'); env <- new.env(parent = globalenv()); devtools::load_all(export_all = FALSE, quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = out, quiet = TRUE, envir = env); cat(out, '\n')"`:
  passed.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and wrote
  `reference/plot_parameter_surface.html`.
- `Rscript -e "pkgdown::clean_site(); pkgdown::build_site(preview = FALSE)"`:
  passed after a stale rendered NEWS/ROADMAP scan, forcing a full rendered-site
  refresh.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'not current plotters|future visualization helpers|future plotting|future plot|does not add `ggplot2`|does not add ggplot2|should not be exported|design placeholders only|Add one narrow ggplot|plot_parameter_surface|Visualization' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd _pkgdown.yml DESCRIPTION pkgdown-site/reference/index.html pkgdown-site/reference/plot_parameter_surface.html pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  found only current implementation, reference-page, and planned-neighbour
  wording after cleanup.
- `rg -n 'conf\\.low|conf\\.high|std\\.error|credible interval|posterior draws|Bayesian|EM means|autoplot\\.drmTMB|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|plotting dependency' R/plot-parameter-surface.R tests/testthat/test-plot-parameter-surface.R DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site/reference/plot_parameter_surface.html pkgdown-site/articles/model-workflow.html pkgdown-site/reference/index.html --glob '!pkgdown-site/search.json'`:
  returned intended model-workflow/profile-output and design-note references
  only; the new helper does not add interval columns, Bayesian claims,
  `autoplot.drmTMB()`, or hard plotting imports.
- `git diff -U0 -- DESCRIPTION NAMESPACE NEWS.md ROADMAP.md _pkgdown.yml R/plot-parameter-surface.R tests/testthat/test-plot-parameter-surface.R man/plot_parameter_surface.Rd docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd | LC_ALL=C rg -n '[^\\x00-\\x7F]'`:
  returned no matches.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 104 plot parameter surface helper" --next "append check-log and after-task report, then stage, commit, push, open PR, and monitor CI"`:
  passed and wrote the recovery checkpoint.

## Tests Of The Tests

The new tests exercise the ordinary plotting path, optional filtering, argument
validation, and the missing-`ggplot2` error. The first test builds a
`prediction_grid()`, converts it to a `predict_parameters()` table, calls
`plot_parameter_surface(pred, x = "x", colour = "habitat")`, checks for a
`ggplot` object, and runs `ggplot2::ggplot_build()` so the mapping is actually
renderable. The second test filters to `dpar = "sigma"` and turns lines off,
checking that the point-only layer keeps the expected number of rows. The
missing-dependency test mocks the internal `ggplot2` availability check, so the
error path is covered without uninstalling packages.

## Consistency Audit

Source and rendered docs now agree that `plot_parameter_surface()` is the only
implemented plotting helper. `predict_parameters()` and `marginal_parameters()`
remain data-table helpers. The new Reference section is `Visualization`, and
the rendered Reference index includes `plot_parameter_surface()`. The ROADMAP
and design note keep `corpairs()` plotting, EMM compatibility, contrasts,
slopes, intervals, diagnostics, and simulation plots as planned work.

## What Did Not Go Smoothly

The first implementation used `ggplot2::aes_string()`, which passed tests but
emitted lifecycle warnings. The helper now creates temporary internal columns
and uses `ggplot2::aes()`. A stale rendered NEWS/ROADMAP scan also showed that
the incremental pkgdown build did not refresh every page after a wording
cleanup, so Grace forced a clean site rebuild with `pkgdown::clean_site()`.

## Team Learning

- Ada: keep one plotting helper per slice and merge only after the reference
  page, tests, pkgdown, and closure notes agree.
- Boole: `plot_parameter_surface()` is a better first API than a broad
  `autoplot.drmTMB()` because it names the consumed table and leaves the
  estimand explicit.
- Fisher: the helper must not create fake intervals, credible intervals,
  posterior language, contrasts, slopes, or EMM claims.
- Curie: plotting tests should run `ggplot2::ggplot_build()`, not only check
  that a class was returned.
- Pat: the model-workflow article should teach that a plot is a convenience
  layer over a visible prediction grid and interval provenance table.
- Darwin: the first example stays on temperature and habitat because that is
  interpretable for ecology and evolution users.
- Jason: `ggplot2` belongs in `Suggests`; `tidybayes`, `ggdist`, `patchwork`,
  and `viridis` remain design inspirations or later optional examples.
- Grace: reference pages should include exported plotting functions under a
  dedicated pkgdown section, and clean rebuilds are useful after navigation
  changes.
- Rose: rendered-site scans are necessary because incremental pkgdown builds
  can leave stale page text after quick prose fixes.
- Gauss and Noether stayed watch-only because no likelihood, TMB, or symbolic
  model contract changed.

## Known Limitations

- The helper plots point estimates only.
- It does not draw intervals, ribbons, profile samples, bootstrap samples, or
  posterior-style distributions.
- It does not compute predictions; users must supply a prediction table.
- It does not implement EMMs, contrasts, slopes, diagnostics, simulation plots,
  or `corpairs()` plots.
- Facet strips use an internal plotting column, so they show facet values
  cleanly but do not rename the strip variable to the original column label.

## Next Actions

1. Add `corpairs()` plotting only after all displayed correlation rows carry
   interval status consistently.
2. Decide whether a later helper should add interval layers to
   `plot_parameter_surface()` or whether interval-aware tables should get a
   separate plotting function.
3. Keep EMM compatibility separate until the reference-grid and link-scale
   contract is tested across implemented families.
