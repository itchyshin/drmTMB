# Codex Recovery Checkpoint

Generated: 2026-05-16 22:48:15 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Slice 140 emmeans interaction grid
Suggested next step: commit Slice 140, then rebase Slice 135 through Slice 140 onto origin/main now that Slice 134 PR #99 merged

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/slice-140-emmeans-interaction-grid
 M NEWS.md
 M ROADMAP.md
 M docs/design/39-visualization-grammar.md
 M docs/design/40-emmeans-interface-contract.md
 M docs/dev-log/check-log.md
 M tests/testthat/test-emmeans-methods.R
?? docs/dev-log/after-task/2026-05-16-slice-140-emmeans-interaction-grid.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	ROADMAP.md
M	docs/design/39-visualization-grammar.md
M	docs/design/40-emmeans-interface-contract.md
M	docs/dev-log/check-log.md
M	tests/testthat/test-emmeans-methods.R
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-16-slice-140-emmeans-interaction-grid.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                      |  1 +
 ROADMAP.md                                   |  4 ++
 docs/design/39-visualization-grammar.md      |  5 ++
 docs/design/40-emmeans-interface-contract.md |  6 +++
 docs/dev-log/check-log.md                    | 75 ++++++++++++++++++++++++++++
 tests/testthat/test-emmeans-methods.R        | 38 ++++++++++++++
 6 files changed, 129 insertions(+)
```

### Current Head

`git log -1 --oneline`

```text
f2d03d8 cover emmeans zero-inflated NB2 boundary
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-16 - Slice 102 empirical prediction-grid example

Goal: add the first reader-facing empirical-grid workflow so the model-workflow
article shows how to average `prediction_grid(..., margin = "empirical")`
output with `marginal_parameters(..., by = "temperature")` instead of treating
conditioned prediction rows and empirical marginal summaries as the same
estimand.

Files changed:

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-102-empirical-grid-example.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-131655-codex-checkpoint.md`
- `vignettes/model-workflow.Rmd`

What changed:

- Updated the model-workflow article to keep the conditioned reef grid for
  direct `predict_parameters()` rows.
- Added a separate `temperature_empirical` grid with
  `prediction_grid(fit, focal = "temperature", at = ..., margin = "empirical")`.
- Added `marginal_parameters(..., by = "temperature")` to reduce the empirical
  grid over the fitted-row covariate distribution.
- Updated the Phase 17 roadmap and visualization-grammar design note to record
  Slice 102 and move the near-term order toward interval provenance.
- Updated NEWS with the new reader-facing empirical-grid workflow.

Checks run:

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd`:
  passed.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/model-workflow.Rmd", output_dir = tempfile("model-workflow-render-"), quiet = FALSE)'`:
  passed and rendered the model-workflow article with the new empirical-grid
  chunks.
- `Rscript -e "devtools::test(filter = 'prediction-grid|marginal-parameters', reporter = 'summary')"`:
  passed across the focused grid-builder and marginal-table helpers.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `articles/model-workflow.html`, `ROADMAP.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'temperature_empirical|margin = "empirical"|fitted-row covariate distribution|by = "temperature"|Slice 102|empirical-grid' NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd pkgdown-site/articles/model-workflow.html pkgdown-site/ROADMAP.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed the source and rendered site carry the empirical-grid workflow and
  Slice 102 roadmap/design-note wording.
- `rg -n 'plotting support|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|EM means|prediction_grid.*plot' DESCRIPTION NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  returned only intended design-boundary matches, not a new plotting claim or
  dependency.
- `git diff -U0 -- NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  returned no matches in the Slice 102 patch.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 102 empirical prediction-grid example" --next "append check-log and after-task report, then stage, commit, push, and open PR"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-131655-codex-checkpoint.md`.

Known limitations:

- This is a documentation and example slice; it does not change
  `prediction_grid()`, `predict_parameters()`, or `marginal_parameters()`.
- `weights` remains metadata only.
- No plotting helper, EMM contrast, slope helper, interval columns, or external
  visualization dependency was added.

After-task report:

- `docs/dev-log/after-task/2026-05-16-slice-102-empirical-grid-example.md`.

## 2026-05-16 - Slice 101 prediction grid helper

Goal: add the first data-only `prediction_grid()` contract for Phase 17 so
users can build explicit `newdata` grids for `predict_parameters()` and
`marginal_parameters()` before any plotting helper, EMM contrast, slope, or
uncertainty-interval surface is advertised.

Files changed:

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

What changed:

- Added exported generic and `drmTMB` method `prediction_grid()`.
- Added `margin = "mean_reference"` for focal-grid rows with nuisance
  predictors set to numeric means, first fitted factor levels, first fitted
  character values represented as factors, first fitted logical values, or
  supplied `condition` values.
- Added `margin = "empirical"` for counterfactual grids that cross focal values
  with fitted model rows while allowing non-focal predictors to be conditioned.
- Added `drm_prediction_grid` metadata recording focal terms, conditioned
  terms, margin, weights label, grid source, reference terms, predictor terms,
  source-row count, and grid-row count.
- Added tests for focal values, automatic numeric and factor grids, empirical
  grids, integration with `predict_parameters()` and `marginal_parameters()`,
  argument validation, retained-data requirements, and missing condition
  values.
- Added the reference topic to pkgdown navigation and introduced
  `prediction_grid()` in the model-workflow article.
- Updated the Phase 17 design note, roadmap, and NEWS to record Slice 101 while
  keeping plotting, EMM contrasts, slopes, and interval columns planned.

Checks run:

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format R/prediction-grid.R tests/testthat/test-prediction-grid.R`:
  passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/prediction_grid.Rd` plus the `prediction_grid` namespace exports.
- `Rscript -e "devtools::test(filter = 'prediction-grid|predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed across the focused prediction-grid, prediction-table, and
  marginal-table helpers.
- `Rscript -e "devtools::test(reporter = 'summary')"`: passed for the full
  test suite.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `reference/prediction_grid.html`, `articles/model-workflow.html`,
  `ROADMAP.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'prediction_grid|drm_prediction_grid|mean_reference|empirical|tables, not plotting functions|plotting helper|EMM|interval_source' R tests/testthat man NEWS.md ROADMAP.md docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd _pkgdown.yml pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  confirmed the source and rendered site carry the new helper, metadata class,
  grid-rule wording, table-not-plotter boundary, EMM boundary, and
  interval-source design note.
- `rg -n 'autoplot\\.drmTMB|ggplot2.*Imports|tidybayes.*dependency|ggdist.*dependency|prediction_grid.*plot|plotting support' DESCRIPTION NEWS.md ROADMAP.md R tests docs/design vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  returned only intended design-boundary matches, not a plotting dependency or
  implemented-plotting claim.
- `git diff -U0 -- NAMESPACE NEWS.md ROADMAP.md _pkgdown.yml docs/design/39-visualization-grammar.md vignettes/model-workflow.Rmd R/prediction-grid.R man/prediction_grid.Rd tests/testthat/test-prediction-grid.R | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  returned no matches in the Slice 101 patch.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 101 prediction_grid helper" --next "append check-log and after-task report, then stage, commit, push, and open PR"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-125304-codex-checkpoint.md`.

Known limitations:

- `prediction_grid()` requires fitted model data, so it errors for fits created
  with `drm_control(keep_data = FALSE)`.
- The helper records the requested `weights` label but does not compute
  weighted summaries.
- The helper does not add plotting, EMM contrasts, slopes, interval columns, or
  direct `emmeans`, `ggeffects`, or `marginaleffects` methods.
- The first contract is tested for ordinary fixed-effect prediction grids; more
  specialized transformed, bounded, count, ordinal, bivariate, structured, and
  random-scale cases still need targeted reference-grid checks before broad
  compatibility claims.

After-task report:

- `docs/dev-log/after-task/2026-05-16-slice-101-prediction-grid.md`.

## 2026-05-16 - Slice 100 visualization research

Goal: research the `ggplot2`, tidy Bayesian, marginal-effects, EMM,
diagnostics, and publication-figure ecosystem and record what `drmTMB` should
learn for Phase 17 without adding plotting dependencies or Bayesian claims.

Files changed:

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/39-visualization-grammar.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md`
- `vignettes/model-workflow.Rmd`

What changed:

- Added `docs/design/39-visualization-grammar.md` as the Slice 100 design
  note.
- Recorded lessons from official `ggplot2`, `tidybayes`, `ggdist`,
  `emmeans`, `ggeffects`, `marginaleffects`, `performance`, `DHARMa`,
  `patchwork`, and `viridis` documentation.
- Updated Phase 17 to keep visualization data-first and to treat predictions,
  adjusted predictions, estimated marginal means, contrasts, slopes, and
  diagnostics as separate estimands.
- Clarified in the model-workflow article that `predict_parameters()` and
  `marginal_parameters()` are tables for future visualization helpers, not
  current plotters.
- Updated NEWS for the design-note change.

Checks run:

- `PATH=/usr/local/bin:/opt/homebrew/bin:$PATH air format NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md`:
  passed.
- `git diff --check`: passed.
- `LC_ALL=C rg -n '[^\x00-\x7F]' NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md`:
  returned no matches.
- `git diff -U0 -- NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md | LC_ALL=C rg -n '[^\x00-\x7F]'`:
  returned no matches in the Slice 100 patch.
- `Rscript -e "devtools::test(filter = 'predict-parameters|marginal-parameters', reporter = 'summary')"`:
  passed with 40 expectations across the focused prediction and marginal-table
  helpers.
- `Rscript -e "pkgdown::build_site(preview = FALSE)"`: passed and rendered
  `ROADMAP.html`, `articles/model-workflow.html`, and `news/index.html`.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with "No problems found."
- `rg -n 'visualization-grammar|tables, not plotting functions|dependency-light|estimated marginal means|EM means|posterior draws|interval_source' NEWS.md ROADMAP.md vignettes/model-workflow.Rmd docs/design/39-visualization-grammar.md pkgdown-site/ROADMAP.html pkgdown-site/articles/model-workflow.html pkgdown-site/news/index.html --glob '!pkgdown-site/search.json'`:
  confirmed source and rendered pages carry the Slice 100 wording, EMM
  terminology guard, and interval-source contract.
- `rg -n 'plotting support|autoplot\\.drmTMB\\(\\).*export|tidybayes.*dependency|ggdist.*dependency|ggplot2.*Imports|EM means' NEWS.md ROADMAP.md DESCRIPTION docs/design vignettes pkgdown-site --glob '!pkgdown-site/search.json' --glob '!pkgdown-site/deps/**'`:
  returned only intended design-boundary and terminology-guard matches, not a
  dependency or implemented-plotting claim.

Known limitations:

- no plotting helper, `emmeans` method, `ggeffects` method, or
  `marginaleffects` method was implemented;
- no uncertainty columns were added to `predict_parameters()` or
  `marginal_parameters()`;
- no ggplot-oriented dependency was added to `DESCRIPTION`.

... 19902 check-log lines omitted

### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-16-slice-140-emmeans-interaction-grid.md` (2026-05-16 22:48): # After Task: Slice 140 emmeans interaction grid
- `docs/dev-log/after-task/2026-05-16-slice-139-emmeans-zi-nbinom-boundary.md` (2026-05-16 22:41): # After Task: Slice 139 emmeans zero-inflated NB2 boundary
- `docs/dev-log/after-task/2026-05-16-slice-138-emmeans-transformed-response-boundary.md` (2026-05-16 22:37): # After Task: Slice 138 emmeans transformed-response boundary
- `docs/dev-log/after-task/2026-05-16-slice-134-emmeans-zi-public-error.md` (2026-05-16 22:37): # After Task: Slice 134 emmeans zero-inflated public boundary
- `docs/dev-log/after-task/2026-05-16-slice-137-emmeans-bivariate-boundary.md` (2026-05-16 22:37): # After Task: Slice 137 emmeans bivariate public boundary
- `docs/dev-log/after-task/2026-05-16-slice-136-emmeans-ordinal-public-error.md` (2026-05-16 22:37): # After Task: Slice 136 emmeans ordinal public boundary
- `docs/dev-log/after-task/2026-05-16-slice-135-emmeans-hurdle-public-error.md` (2026-05-16 22:37): # After Task: Slice 135 emmeans hurdle public boundary
- `docs/dev-log/after-task/2026-05-16-slice-133-emmeans-multiple-at-grid.md` (2026-05-16 22:27): # After Task: Slice 133 emmeans multiple explicit at values

## Recovery Commands

Run these at the start of the next task before assuming this checkpoint is
still current:

```sh
git status --short --branch
git diff --stat
git diff
sed -n '1,240p' docs/dev-log/check-log.md
ls -lt docs/dev-log/after-task | head
```

## Notes For The Next Agent

- Do not treat this checkpoint as approval for broad changes.
- Preserve unrelated user, Codex, or Claude Code edits.
- If the diff is large, identify the smallest safe next step before editing.
- If validation is stale or incomplete, report that explicitly.
