# After Task: Slice 108 Reference Plotting Inventory

## Goal

Answer the reference-page question by making the pkgdown organization explicit:
post-fit data and extractors belong with model fitting and post-fit tools,
while exported plotting helpers belong under Visualization. After reader review,
also tighten the nearby `summary()` confidence-interval example so the reference
and workflow pages describe mixed Wald/profile summaries accurately.

## Implemented

- Renamed the pkgdown reference group from "Model fitting" to
  "Model fitting and post-fit tools".
- Updated that group description to include diagnosing, summarizing,
  predicting, and simulating fitted models.
- Clarified that the Visualization reference group is for exported plotting
  helpers for post-fit tables.
- Added a compact Reference-index map to the model-map article.
- Recorded in the visualization design note that `plot_parameter_surface()` is
  currently the only exported plotting helper.
- Kept fixed-effect Wald confidence intervals in profile summaries unless
  fixed-effect profile targets are selected.
- Added tests that direct `sigma` profile summaries still include Wald
  fixed-effect intervals while selected direct targets get profile intervals.
- Stopped duplicated `minimum` and `maximum` columns from appearing for constant
  direct parameter rows with no fitted range.
- Updated NEWS, ROADMAP, the summary reference page, and model-workflow wording
  with the Slice 108 reference-index and summary-reading contracts.

## Files Changed

- `NEWS.md`
- `R/methods.R`
- `ROADMAP.md`
- `_pkgdown.yml`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-108-reference-plotting-inventory.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-154741-codex-checkpoint.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-162251-codex-checkpoint.md`
- `man/summary.drmTMB.Rd`
- `tests/testthat/test-summary.R`
- `vignettes/model-map.Rmd`
- `vignettes/model-workflow.Rmd`

## Checks Run

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md _pkgdown.yml docs/design/39-visualization-grammar.md vignettes/model-map.Rmd vignettes/model-workflow.Rmd docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-108-reference-plotting-inventory.md`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/summary.drmTMB.Rd`.
- `Rscript -e "devtools::test(filter = 'summary', reporter = 'summary')"`:
  passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-map.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e "devtools::load_all(quiet = TRUE); rmarkdown::render('vignettes/model-workflow.Rmd', output_file = tempfile(fileext = '.html'), quiet = TRUE)"`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE); cfg <- yaml::read_yaml("_pkgdown.yml"); ... stopifnot(identical(plot_exports, sort(viz)))'`:
  passed and confirmed `plot_parameter_surface` is the only exported `plot_*`
  helper and the only Visualization reference entry.
- `Rscript -e "pkgdown::clean_site(); pkgdown::build_site(preview = FALSE)"`:
  passed and rendered the updated reference index, summary reference page,
  model-map article, model-workflow article, NEWS, and ROADMAP.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `git diff --check`: passed.
- `rg -n "Model fitting and post-fit tools|Visualization|plot_parameter_surface\\(\\)|Exported plotting functions|Planned plotting helpers|Reference index" _pkgdown.yml vignettes/model-map.Rmd docs/design/39-visualization-grammar.md NEWS.md ROADMAP.md pkgdown-site/reference/index.html pkgdown-site/articles/model-map.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages carry the reference-index contract.
- `rg -n 'fixed-effect Wald|profile-likelihood 95% confidence intervals|method = "profile"|ci_parm = "sigma"|duplicated `minimum`|summary\\(fit, conf.int = TRUE\\)' R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd vignettes/model-workflow.Rmd NEWS.md ROADMAP.md pkgdown-site/reference/summary.drmTMB.html pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html`:
  confirmed source and rendered pages carry the fixed-effect Wald plus direct
  profile interval contract and the constant-parameter range cleanup.
- `rg -n "plot_corpairs\\(\\).*reference|plot_diagnostics\\(\\).*reference|plot_simulation_summary\\(\\).*reference|autoplot\\.drmTMB|planned plotting helpers stay out|only exported plotting helper" _pkgdown.yml vignettes docs/design NEWS.md ROADMAP.md pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  found only the intended warning against broad `autoplot.drmTMB()` and the
  intended "only exported plotting helper" wording.
- `Rscript tools/codex-checkpoint.R --goal "Slice 108 reference plotting inventory" --next "stage, commit, push, open PR, monitor CI, merge, then start Slice 109 visualization examples and landscape translation"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-154741-codex-checkpoint.md`.
- `Rscript tools/codex-checkpoint.R --goal "Slice 108 reference plotting inventory with summary CI cleanup" --next "stage all Slice 108 files, commit, push, open PR, monitor CI, then start Slice 109 visualization examples and landscape translation"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-162251-codex-checkpoint.md`.

## What Did Not Change

- No new plotting functions were exported.
- No planned plotting helper names were added to `_pkgdown.yml`.
- No likelihood code, formula grammar, or TMB code changed.

## Team Learning

- Ada: Slice 108 was an index and navigation contract, not a plotting feature.
- Grace: the reference index already included `plot_parameter_surface()`, but
  the group labels needed to make the post-fit path clearer.
- Boole: planned plotting helper names should stay out of the user-facing
  Reference index until they are exported and tested.
- Pat: applied readers benefit from a short model-map table that says where to
  find summaries, predictions, uncertainty, extractors, and plots.
- Jason: the visualization landscape supports data-first helpers, so the
  reference index should distinguish data/extraction functions from plotting
  functions.
- Fisher: profile summaries should make clear that fixed effects can keep Wald
  intervals while selected direct response-scale targets use profile intervals.
- Emmy: printed parameter tables should not display duplicated fitted-range
  columns when direct constant parameters do not have fitted ranges.
- Rose: stale scans should include rendered pkgdown pages whenever `_pkgdown.yml`
  changes.
- Gauss and Noether stayed watch-only because no likelihood or equation
  changed.

## Known Limitations

- The only exported plotting helper is still `plot_parameter_surface()`.
- The slice does not add `corpairs()` plots, diagnostic plots, interval plots,
  EMMs, contrasts, or slopes.
- The summary change is limited to fixed-effect Wald intervals in profile
  summaries and printed direct-parameter range columns; it does not add new
  profile targets.
- Future plotting helpers still need their own data contracts, documentation,
  tests, and optional-dependency policy before they appear in Reference pages.

## Next Actions

1. Use Slice 109 to turn visualization-landscape lessons into concrete
   example rules for raw-data-plus-model displays.
2. Keep the Reference index synchronized whenever a new exported plotting
   helper is added.
