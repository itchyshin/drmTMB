# Codex Recovery Checkpoint

Generated: 2026-05-16 12:53:04 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Slice 101 prediction_grid helper
Suggested next step: append check-log and after-task report, then stage, commit, push, and open PR

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/slice-101-prediction-grid
 M NAMESPACE
 M NEWS.md
 M ROADMAP.md
 M _pkgdown.yml
 M docs/design/39-visualization-grammar.md
 M vignettes/model-workflow.Rmd
?? R/prediction-grid.R
?? man/prediction_grid.Rd
?? tests/testthat/test-prediction-grid.R
```

### Changed Files

`git diff --name-status`

```text
M	NAMESPACE
M	NEWS.md
M	ROADMAP.md
M	_pkgdown.yml
M	docs/design/39-visualization-grammar.md
M	vignettes/model-workflow.Rmd
```

`git ls-files --others --exclude-standard`

```text
R/prediction-grid.R
man/prediction_grid.Rd
tests/testthat/test-prediction-grid.R
```

### Diff Stat

`git diff --stat`

```text
 NAMESPACE                               |  2 ++
 NEWS.md                                 |  5 +++++
 ROADMAP.md                              |  6 +++++-
 _pkgdown.yml                            |  1 +
 docs/design/39-visualization-grammar.md | 19 ++++++++++---------
 vignettes/model-workflow.Rmd            | 20 +++++++++++++++++---
 6 files changed, 40 insertions(+), 13 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
e0ed82a Add visualization grammar research note (#64)
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

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
  confirmed bivariate random slopes, plasticity-syndrome correlations,
  `rho12` random effects, bivariate known-`V` plus random effects, and ordinary
  spatial covariance stay planned, and all four q=4 mean-scale pairs are named.
- Added-line non-ASCII scan with
  `git diff --unified=0 -- ROADMAP.md docs/design/21-tutorial-style.md docs/design/37-worked-example-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md docs/dev-log/recovery-checkpoints/2026-05-16-114952-codex-checkpoint.md vignettes/bivariate-coscale.Rmd vignettes/drmTMB.Rmd vignettes/source-map.Rmd | perl -ne 'print if /^\\+/ && !/^\\+\\+\\+/ && /[^\\x00-\\x7F]/'`:
  returned no matches.

Known limitations:

- no formula grammar, likelihood, TMB, extractor, or test implementation
  changed in this slice;
- the new fitted example teaches ordinary bivariate Gaussian random intercepts
  only;
- bivariate random slopes, slope1-slope2 plasticity-syndrome correlations,
  random effects in `rho12`, bivariate `meta_known_V()` plus random effects,
  mixed-response models, and ordinary spatial group-level covariance remain
  planned until they have implementation, recovery evidence, diagnostics, and
  tutorial support.

After-task report:

- `docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md`.

## 2026-05-16 - Slice 97 proportion source-map tutorial

Goal: add the next non-Gaussian bounded-response worked example after Slice 96,
keeping the example inside the implemented fixed-effect univariate
`beta_binomial()` and `beta()` surfaces.

Files changed:

- `ROADMAP.md`
- `_pkgdown.yml`
- `docs/design/21-tutorial-style.md`
- `docs/design/37-worked-example-inventory.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-16-slice-97-proportion-source-map.md`
- `vignettes/distribution-families.Rmd`
- `vignettes/drmTMB.Rmd`
- `vignettes/model-map.Rmd`
- `vignettes/proportion-beta-binomial.Rmd`
- `vignettes/source-map.Rmd`

What changed:

- Added `vignettes/proportion-beta-binomial.Rmd`, a bounded-response tutorial
  with beta-binomial and strict beta equations, exact `drmTMB()` syntax,
  parameter definitions, fitted diagnostics, and biological interpretation.
- Explained the public `sigma` scale for beta and beta-binomial responses:
  `phi_i = 1 / sigma_i^2`, so larger `sigma` means lower beta precision and
  more modelled variation.
- Added denominator-aware response-scale interpretation for seed germination:
  expected probability, expected successes, `sigma`, `phi`, and
  proportion-level SD.
- Added a strict beta vegetation-cover example and kept exact 0/1 values as
  future zero-one-inflated beta or ordered-beta territory.
- Linked the tutorial from the pkgdown Tutorials menu, Getting Started,
  model map, family guide, source map, worked-example inventory, tutorial
  style contract, and roadmap.

Checks run:

- `air format _pkgdown.yml ROADMAP.md docs/design/21-tutorial-style.md docs/design/37-worked-example-inventory.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-16-slice-97-proportion-source-map.md vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd vignettes/model-map.Rmd vignettes/proportion-beta-binomial.Rmd vignettes/source-map.Rmd`:
  passed.
- `git diff --check`: passed.
- `Rscript -e 'devtools::test(filter = "beta|family-link-contract", reporter = "summary")'`:
  passed; ran the beta-binomial, beta-location-scale, and family-link-contract
  test files with no failures.
- `Rscript -e 'pkgdown::build_site()'`: passed and rendered
  `articles/proportion-beta-binomial.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with "No problems found."
- `rg -n 'Proportions and success rates|proportion-beta-binomial|sigma_sheltered|phi_sheltered|zero-one-inflated beta|ordered beta|cbind\\(successes, failures\\)|strict continuous|successes out of trials|beta-binomial|beta\\(\\)' vignettes/proportion-beta-binomial.Rmd pkgdown-site/articles/proportion-beta-binomial.html _pkgdown.yml pkgdown-site/articles/index.html pkgdown-site/articles/distribution-families.html vignettes/distribution-families.Rmd vignettes/drmTMB.Rmd pkgdown-site/articles/drmTMB.html vignettes/model-map.Rmd pkgdown-site/articles/model-map.html vignettes/source-map.Rmd docs/design/37-worked-example-inventory.md ROADMAP.md --glob '!pkgdown-site/search.json'`:
  confirmed the tutorial route, source and rendered links, scale conversion,
  strict beta wording, denominator syntax, and unsupported-boundary wording.
- `rg -n 'successes / trials|successes/trials|zero-one-inflated beta|ordered beta|beta-binomial zero inflation|meta_known_V\\(V = V\\).*beta|phylo\\(\\)|spatial\\(\\)|family = c\\(beta\\(\\), gaussian\\(\\)\\)' vignettes/proportion-beta-binomial.Rmd pkgdown-site/articles/proportion-beta-binomial.html docs/design/37-worked-example-inventory.md ROADMAP.md vignettes/source-map.Rmd --glob '!pkgdown-site/search.json'`:
  confirmed the planned-neighbour and denominator-shorthand boundaries.
- Tracked-diff and new-file non-ASCII scans with
  `LC_ALL=C rg -n '[^\\x00-\\x7F]'`: returned no matches.

Known limitations:

- no formula grammar, family, likelihood, TMB, extractor, or test
  implementation changed in this slice;
- the examples are fixed-effect and univariate only;
- non-Gaussian random effects, zero-one-inflated beta, ordered beta,
  beta-binomial zero inflation, structured bounded responses, mixed-response
  families, known covariance with bounded responses, and denominator shorthand
  remain planned until they have implementation and recovery evidence.

... 16614 check-log lines omitted

### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-16-slice-100-visualization-research.md` (2026-05-16 12:28): # After Task: Slice 100 Visualization Research
- `docs/dev-log/after-task/2026-05-16-slice-98-bivariate-group-covariance.md` (2026-05-16 12:03): # After Task: Slice 98 Bivariate Group-Level Covariance Polish
- `docs/dev-log/after-task/2026-05-16-slice-97-proportion-source-map.md` (2026-05-16 11:31): # After Task: Slice 97 Proportion Source-Map Tutorial
- `docs/dev-log/after-task/2026-05-16-reference-index-random-effect-scale-syntax.md` (2026-05-16 10:32): # After Task: Reference Index Random-Effect Scale Syntax
- `docs/dev-log/after-task/2026-05-16-slice-96-count-nbinom2-source-map.md` (2026-05-16 10:32): # After Task: Slice 96 Count NB2 Source-Map Tutorial
- `docs/dev-log/after-task/2026-05-16-slice-95-meta-analysis-source-map.md` (2026-05-16 09:24): # After Task: Slice 95 Meta-Analysis Source-Map Polish
- `docs/dev-log/after-task/2026-05-16-slice-94-0-1-2-release-evidence.md` (2026-05-16 09:06): # After Task: Slice 94 0.1.2 Release Evidence
- `docs/dev-log/after-task/2026-05-16-slice-93-0-1-2-release-gate.md` (2026-05-16 08:42): # After Task: Slice 93 0.1.2 Release Gate

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
