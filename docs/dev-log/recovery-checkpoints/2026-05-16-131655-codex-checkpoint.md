# Codex Recovery Checkpoint

Generated: 2026-05-16 13:16:55 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Slice 102 empirical prediction-grid example
Suggested next step: append check-log and after-task report, then stage, commit, push, and open PR

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/slice-102-empirical-grid-example
 M NEWS.md
 M ROADMAP.md
 M docs/design/39-visualization-grammar.md
 M vignettes/model-workflow.Rmd
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	ROADMAP.md
M	docs/design/39-visualization-grammar.md
M	vignettes/model-workflow.Rmd
```

`git ls-files --others --exclude-standard`

```text
(no output)
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                 |  4 ++++
 ROADMAP.md                              |  5 +++++
 docs/design/39-visualization-grammar.md | 15 +++++++++------
 vignettes/model-workflow.Rmd            | 25 ++++++++++++++++++++++---
 4 files changed, 40 insertions(+), 9 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
d323155 Add prediction grid helper (#65)
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

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

After-task report:

- `docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md`.

## 2026-05-16 - Slice 98 bivariate group-level covariance polish

Goal: deepen the bivariate location-coscale tutorial with a compact
repeated-individual example that fits the implemented ordinary `mu1`/`mu2`
random-intercept covariance block, while keeping residual `rho12` and
group-level covariance as separate correlation layers.

Files changed:

- `ROADMAP.md`
- `docs/design/21-tutorial-style.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md`
- `docs/dev-log/recovery-checkpoints/2026-05-16-114952-codex-checkpoint.md`
- `vignettes/bivariate-coscale.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/source-map.Rmd`

What changed:

- Replaced the template-like group-level ending of
  `vignettes/bivariate-coscale.Rmd` with a runnable repeated-individual
  activity-boldness example.
- Fitted matching labelled `(1 | p | ID)` random intercepts in `mu1` and
  `mu2`, with constant residual `rho12`, `sigma1`, and `sigma2`.
- Added `check_drm(fit_group)` diagnostics focused on convergence,
  random-effect SD boundaries, residual-correlation boundaries, and the
  bivariate `mu` covariance replication row.
- Added `corpairs(fit_group)` output that keeps the residual `rho12` row and
  the group-level `mu1`/`mu2` row separate.
- Added a `summary(fit_group)$covariance` report-scale table with component
  SDs, correlation, covariance, and scale labels.
- Updated the worked-example inventory, tutorial-style candidate table,
  getting-started learning path, source map, and roadmap to record Slice 98.
- Cleaned up stale roadmap wording so ordinary bivariate q=4
  random-intercept support is described as fitted, while bivariate random
  slopes and the full double-hierarchical endpoint remain planned.
- Wrote a recovery checkpoint for the crash-recovery slice before staging.

Checks run:

- `air format ROADMAP.md docs/design/21-tutorial-style.md docs/design/37-worked-example-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md vignettes/bivariate-coscale.Rmd vignettes/drmTMB.Rmd vignettes/source-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript tools/codex-checkpoint.R --goal "Slice 98 bivariate group-level covariance polish" --next "git add the Slice 98 docs, commit, push, and open the PR"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-16-114952-codex-checkpoint.md`.
- `Rscript -e 'pkgload::load_all(".", quiet = TRUE); rmarkdown::render("vignettes/bivariate-coscale.Rmd", output_dir = tempfile("biv-coscale-render-"), quiet = FALSE)'`:
  passed and rendered all bivariate-coscale chunks with the source package
  loaded.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|corpairs", reporter = "summary")'`:
  passed; ran the bivariate Gaussian and `corpairs` test files with no
  failures.
- `Rscript -e 'pkgdown::build_site()'`: passed and rendered
  `articles/bivariate-coscale.html`, `articles/drmTMB.html`, and
  `articles/source-map.html` with the Slice 98 wording.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `rg -n 'individual-difference|individual differences|fit_group|corpairs\\(fit_group|summary\\(fit_group\\)\\$covariance|biv_mu_random_effect_covariance|mu1.*sigma2|slope1-slope2|random effects in rho12|Slice 98|Bivariate group-level covariance' vignettes/bivariate-coscale.Rmd pkgdown-site/articles/bivariate-coscale.html docs/design/37-worked-example-inventory.md ROADMAP.md docs/design/21-tutorial-style.md vignettes/drmTMB.Rmd vignettes/source-map.Rmd --glob '!pkgdown-site/search.json'`:
  confirmed the source and rendered individual-difference example, covariance
  extractor route, q=4 pair wording, Slice 98 inventory, and planned-neighbour
  boundaries.
- `rg -n 'bivariate random slopes|plasticity-syndrome|rho12.*random|bivariate meta_known_V\\(\\)|ordinary spatial group-level|all-four|mu1.*sigma1|mu1.*sigma2|mu2.*sigma1|mu2.*sigma2' vignettes/bivariate-coscale.Rmd pkgdown-site/articles/bivariate-coscale.html docs/design/37-worked-example-inventory.md ROADMAP.md vignettes/source-map.Rmd --glob '!pkgdown-site/search.json'`:
... 16703 check-log lines omitted

### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-16-slice-101-prediction-grid.md` (2026-05-16 13:12): # After Task: Slice 101 Prediction Grid Helper
- `docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md` (2026-05-16 12:28): # After Task: Slice 100 Visualization Research
- `docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md` (2026-05-16 12:03): # After Task: Slice 98 Bivariate Group-Level Covariance Polish
- `docs/dev-log/after-task/2026-05-16-slice-97-proportion-source-map.md` (2026-05-16 11:31): # After Task: Slice 97 Proportion Source-Map Tutorial
- `docs/dev-log/after-task/2026-05-16-reference-index-random-effect-scale-syntax.md` (2026-05-16 10:32): # After Task: Reference Index Random-Effect Scale Syntax
- `docs/dev-log/after-task/2026-05-16-slice-96-count-nbinom2-source-map.md` (2026-05-16 10:32): # After Task: Slice 96 Count NB2 Source-Map Tutorial
- `docs/dev-log/after-task/2026-05-16-slice-95-meta-analysis-source-map.md` (2026-05-16 09:24): # After Task: Slice 95 Meta-Analysis Source-Map Polish
- `docs/dev-log/after-task/2026-05-16-slice-94-0-1-2-release-evidence.md` (2026-05-16 09:06): # After Task: Slice 94 0.1.2 Release Evidence

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
