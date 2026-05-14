# Codex Recovery Checkpoint

Generated: 2026-05-14 09:27:48 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Slice 11 endpoint-specific corpair grammar
Suggested next step: commit, push, and monitor PR #26 Actions

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/sd-cor-model-family-split...origin/codex/sd-cor-model-family-split
 M NEWS.md
 M R/formula-markers.R
 M R/parse-formula.R
 M docs/design/01-formula-grammar.md
 M docs/design/20-coscale-correlation-pairs.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M man/corpair.Rd
 M tests/testthat/test-package-skeleton.R
 M vignettes/formula-grammar.Rmd
 M vignettes/model-map.Rmd
 M vignettes/phylogenetic-spatial.Rmd
?? docs/dev-log/after-task/2026-05-14-slice-11-endpoint-specific-corpair-grammar.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/formula-markers.R
M	R/parse-formula.R
M	docs/design/01-formula-grammar.md
M	docs/design/20-coscale-correlation-pairs.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	man/corpair.Rd
M	tests/testthat/test-package-skeleton.R
M	vignettes/formula-grammar.Rmd
M	vignettes/model-map.Rmd
M	vignettes/phylogenetic-spatial.Rmd
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-14-slice-11-endpoint-specific-corpair-grammar.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                     |  2 +-
 R/formula-markers.R                         |  9 ++--
 R/parse-formula.R                           | 52 +++++++++++++++---
 docs/design/01-formula-grammar.md           | 21 ++++++--
 docs/design/20-coscale-correlation-pairs.md | 84 +++++++++++++++++------------
 docs/dev-log/check-log.md                   | 47 ++++++++++++++++
 docs/dev-log/known-limitations.md           | 11 ++--
 man/corpair.Rd                              | 10 ++--
 tests/testthat/test-package-skeleton.R      | 36 +++++++++++--
 vignettes/formula-grammar.Rmd               | 11 ++--
 vignettes/model-map.Rmd                     | 36 +++----------
 vignettes/phylogenetic-spatial.Rmd          | 29 ++++++----
 12 files changed, 246 insertions(+), 102 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
dd131a3 Clarify q4 cross-trait correlation docs
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-14 -- Map Slice 25 bivariate sd_phylo diagnostics and docs

Scope:

- extended `check_drm()` direct-SD diagnostics from univariate
  `sd_phylo(species)` to bivariate `sd_phylo1(species)` /
  `sd_phylo2(species)`;
- added per-endpoint diagnostic rows with target endpoint, species group,
  species replication, fitted SD range, and maximum fitted species-SD ratio;
- added tests for both-endpoint and one-sided bivariate direct-SD diagnostics;
- updated the structured-dependence article with the bivariate Box 1
  direct-SD syntax and interpretation;
- regenerated `man/check_drm.Rd` and rebuilt the local
  `phylogenetic-spatial` pkgdown article.

Checks:

- `air format NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/18-random-effect-scale-models.md vignettes/phylogenetic-spatial.Rmd R/check.R R/drmTMB.R tests/testthat/test-check-drm.R`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and updated
  `man/check_drm.Rd`.
- Initial focused
  `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian|profile-targets|summary", reporter = "summary")'`:
  failed because the old singleton test mutated the legacy flat
  `observation_sd_row0` field instead of the new per-dpar row-index list, and
  because the small bivariate fit could have unrelated diagnostics. The test
  now mutates the per-dpar list and asserts the direct-SD rows directly.
- Final focused
  `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian|profile-targets|summary", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE); pkgdown::build_article("phylogenetic-spatial", new_process = FALSE, quiet = TRUE)'`:
  passed and wrote `pkgdown-site/articles/phylogenetic-spatial.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'sd_phylo1\(species\).*planned|sd_phylo2\(species\).*planned|sd_phylo1\(species\).*not implemented|sd_phylo2\(species\).*not implemented|bivariate `sd_phylo1\(\)`.*planned|bivariate `sd_phylo2\(\)`.*planned|univariate `sd_phylo\(\)` direct-SD diagnostic row|univariate `sd_phylo\(\)` path' README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/articles/phylogenetic-spatial.html R tests`:
  only historical Slice 22 check-log wording remains.
- `git diff --check`: passed.

Known limitations:

- Bivariate `sd_phylo1()` / `sd_phylo2()` diagnostics are still compact
  first-pass checks; they do not replace broad simulation grids across tree
  size, predictor strength, weak SD surfaces, or alternative tree shapes.
- `summary(fit)$covariance` uses median fitted species SDs for direct-SD
  endpoints because the true covariance is species-pair specific.
- Spatial `sd_spatial*()` siblings begin in Slice 26 and remain planned in this
  slice.

## 2026-05-14 -- Map Slice 24 bivariate sd_phylo implementation

Scope:

- implemented bivariate Family B direct-SD formulas
  `sd_phylo1(species) ~ z1` and `sd_phylo2(species) ~ z2` for matching
  bivariate phylogenetic location random effects;
- generalized the direct phylogenetic SD parser, model-frame construction,
  TMB data, start/map plumbing, coefficient splitting, prediction, `sdpars`,
  random-effect transforms, `summary()$covariance`, and `profile_targets()`;
- kept the latent phylogenetic location-location correlation constant and
  separate from residual `rho12`;
- rejected mixtures with all-four q=4 phylogenetic location-scale blocks;
- documented that `summary(fit)$covariance` uses a median fitted species-SD
  summary for direct-SD endpoints because the true covariance is
  species-pair specific.

Checks:

- `air format R/drmTMB.R R/parse-formula.R R/methods.R R/profile.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-biv-gaussian.R tests/testthat/test-profile-targets.R src/drmTMB.cpp docs/design/01-formula-grammar.md docs/design/16-phylo-spatial-common-math.md docs/design/18-random-effect-scale-models.md`:
  passed.
- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- Initial focused
  `Rscript -e 'devtools::test(filter = "phylo-gaussian|biv-gaussian|profile-targets|summary", reporter = "summary")'`:
  failed after Franklin's sidecar review because `summary()$covariance` still
  assumed scalar phylogenetic SDs and `profile_targets()` routed
  `sd_phylo1()` / `sd_phylo2()` coefficients to non-existent internal
  parameters; both were fixed before closing the slice.
- Final focused
  `Rscript -e 'devtools::test(filter = "phylo-gaussian|profile-targets|summary|biv-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(reporter = "summary")'`: passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'beta_sd_phylo1|beta_sd_phylo2|sd_phylo1\(species\).*planned|sd_phylo2\(species\).*planned|sd_phylo1\(species\).*not implemented|sd_phylo2\(species\).*not implemented' R tests docs NEWS.md ROADMAP.md vignettes`:
  no hits.
- `git diff --check`: passed.

Known limitations:

- This slice implements the fitted bivariate direct-SD path and focused tests,
  but it does not add a `check_drm()` diagnostic row for bivariate
  `sd_phylo1()` / `sd_phylo2()` surfaces.
- Broad recovery grids across tree size, predictor strength, weak direct-SD
  surfaces, and one-sided direct-SD models remain Slice 25 work.
- Spatial `sd_spatial*()` siblings remain planned.

## 2026-05-14 -- Map Slice 23 bivariate sd_phylo direct-SD design

Scope:

- documented the planned bivariate `sd_phylo1(species) ~ z1` /
  `sd_phylo2(species) ~ z2` Family B contract;
- specified that the targets are response-specific phylogenetic location
  random-effect SD surfaces for `mu1` and `mu2`, not residual `sigma1`,
  residual `sigma2`, or q=4 location-scale endpoint SDs;
- recorded the intended covariance algebra
  `Cov(a1_l, a2_m) = rho_phylo tau1_l A_lm tau2_m`, with residual `rho12`
  remaining separate;
- updated the formula grammar, likelihood design, shared phylo/spatial math,
  random-effect scale design, roadmap, known limitations, and the parser hint
  for planned `sd_phylo1()` / `sd_phylo2()` errors.

Checks:

- `air format R/parse-formula.R ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/16-phylo-spatial-common-math.md docs/design/18-random-effect-scale-models.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|phylo-gaussian|package-skeleton", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'sd_phylo1\(species\).*Implemented|sd_phylo2\(species\).*Implemented|sd_phylo1\(species\).*fits|sd_phylo2\(species\).*fits|bivariate `sd_phylo1\(\)`.*implemented|bivariate `sd_phylo2\(\)`.*implemented' README.md ROADMAP.md NEWS.md docs vignettes man pkgdown-site/articles/phylogenetic-spatial.html R tests`:
  no hits.
- `git diff --check`: passed.

Known limitations:

- Slice 23 is design-only; `sd_phylo1()` / `sd_phylo2()` still error as planned
  syntax.
- The implementation, recovery tests, summary/predict methods, and diagnostics
  are Slice 24/25 work.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-14-slice-11-endpoint-specific-corpair-grammar.md` (2026-05-14 09:26): # After Task: Slice 11 Endpoint-Specific corpair Grammar
- `docs/dev-log/after-task/2026-05-14-correlation-pair-ci-status-output.md` (2026-05-14 08:54): # After-Task Report: Correlation-Pair CI Status Output
- `docs/dev-log/after-task/2026-05-14-map-slice-25-bivariate-sd-phylo-diagnostics-docs.md` (2026-05-14 08:15): # After Task: Map Slice 25 Bivariate sd_phylo Diagnostics And Docs
- `docs/dev-log/after-task/2026-05-14-map-slice-24-bivariate-sd-phylo-implementation.md` (2026-05-14 07:53): # After Task: Map Slice 24 Bivariate sd_phylo Implementation
- `docs/dev-log/after-task/2026-05-14-map-slice-23-bivariate-sd-phylo-design.md` (2026-05-14 07:13): # After Task: Map Slice 23 Bivariate sd_phylo Design
- `docs/dev-log/after-task/2026-05-14-map-slice-22-sd-phylo-recovery-diagnostics.md` (2026-05-14 07:07): # After Task: Map Slice 22 sd_phylo Recovery Diagnostics
- `docs/dev-log/after-task/2026-05-14-map-slice-21-sd-phylo-implementation.md` (2026-05-14 06:55): # After Task: Map Slice 21 sd_phylo Implementation
- `docs/dev-log/after-task/2026-05-14-map-slice-20-sd-phylo-design.md` (2026-05-14 06:29): # After Task: Map Slice 20 sd_phylo Direct-SD Design

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
