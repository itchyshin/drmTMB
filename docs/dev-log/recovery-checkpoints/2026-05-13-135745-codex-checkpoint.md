# Codex Recovery Checkpoint

Generated: 2026-05-13 13:57:45 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: fitted bivariate phylogenetic location closeout
Suggested next step: review diff, then add corpairs rows for fitted phylogenetic mean-mean correlations or commit this slice

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/bivariate-phylo-location-guard...origin/codex/bivariate-phylo-location-guard
 M NEWS.md
 M R/drmTMB.R
 M R/formula-markers.R
 M R/methods.R
 M R/profile.R
 M README.md
 M ROADMAP.md
 M docs/design/01-formula-grammar.md
 M docs/design/03-likelihoods.md
 M docs/design/09-phylogenetic-and-spatial-speed.md
 M docs/design/15-location-coscale-phylogenetic-extension.md
 M docs/design/16-phylo-spatial-common-math.md
 M docs/design/20-coscale-correlation-pairs.md
 M docs/design/28-double-hierarchical-endpoint.md
 M docs/design/29-mammal-location-coscale-route.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M man/drmTMB.Rd
 M man/phylo.Rd
 M src/drmTMB.cpp
 M tests/testthat/test-biv-gaussian.R
 M tests/testthat/test-gaussian-location-scale.R
 M tests/testthat/test-phylo-gaussian.R
 M tests/testthat/test-phylo-utils.R
 M vignettes/formula-grammar.Rmd
 M vignettes/model-map.Rmd
 M vignettes/phylogenetic-spatial.Rmd
 M vignettes/which-scale.Rmd
?? docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/drmTMB.R
M	R/formula-markers.R
M	R/methods.R
M	R/profile.R
M	README.md
M	ROADMAP.md
M	docs/design/01-formula-grammar.md
M	docs/design/03-likelihoods.md
M	docs/design/09-phylogenetic-and-spatial-speed.md
M	docs/design/15-location-coscale-phylogenetic-extension.md
M	docs/design/16-phylo-spatial-common-math.md
M	docs/design/20-coscale-correlation-pairs.md
M	docs/design/28-double-hierarchical-endpoint.md
M	docs/design/29-mammal-location-coscale-route.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	man/drmTMB.Rd
M	man/phylo.Rd
M	src/drmTMB.cpp
M	tests/testthat/test-biv-gaussian.R
M	tests/testthat/test-gaussian-location-scale.R
M	tests/testthat/test-phylo-gaussian.R
M	tests/testthat/test-phylo-utils.R
M	vignettes/formula-grammar.Rmd
M	vignettes/model-map.Rmd
M	vignettes/phylogenetic-spatial.Rmd
M	vignettes/which-scale.Rmd
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                            |   1 +
 R/drmTMB.R                                         | 185 +++++++++++-----
 R/formula-markers.R                                |  11 +-
 R/methods.R                                        |  25 ++-
 R/profile.R                                        |   2 +-
 README.md                                          |  11 +-
 ROADMAP.md                                         |  26 ++-
 docs/design/01-formula-grammar.md                  |  22 ++
 docs/design/03-likelihoods.md                      |  32 ++-
 docs/design/09-phylogenetic-and-spatial-speed.md   |  14 +-
 .../15-location-coscale-phylogenetic-extension.md  |  17 +-
 docs/design/16-phylo-spatial-common-math.md        |  30 ++-
 docs/design/20-coscale-correlation-pairs.md        |   3 +-
 docs/design/28-double-hierarchical-endpoint.md     |  14 +-
 docs/design/29-mammal-location-coscale-route.md    |   7 +-
 docs/dev-log/check-log.md                          |  36 ++++
 docs/dev-log/known-limitations.md                  |  26 ++-
 man/drmTMB.Rd                                      |   9 +-
 man/phylo.Rd                                       |  11 +-
 src/drmTMB.cpp                                     |  66 +++++-
 tests/testthat/test-biv-gaussian.R                 |   4 +-
 tests/testthat/test-gaussian-location-scale.R      |   2 +-
 tests/testthat/test-phylo-gaussian.R               | 240 ++++++++++++++++++---
 tests/testthat/test-phylo-utils.R                  |   3 +-
 vignettes/formula-grammar.Rmd                      |  18 +-
 vignettes/model-map.Rmd                            |  45 +++-
 vignettes/phylogenetic-spatial.Rmd                 |  43 ++--
 vignettes/which-scale.Rmd                          |  10 +-
 28 files changed, 717 insertions(+), 196 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
1431c1e Guard bivariate phylogenetic location syntax
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Fitted bivariate phylogenetic location slice

Scope:

- replaced the previous matched-term guard with a fitted bivariate Gaussian
  `mu1`/`mu2` phylogenetic location slice for matching intercept-only
  `phylo(1 | species, tree = tree)` terms;
- added the TMB parameterization for two phylogenetic location SDs and one
  phylogenetic mean-mean correlation while keeping `sigma1`, `sigma2`, and
  residual `rho12` as ordinary fixed-effect distributional parameters;
- exposed the fitted phylogenetic SDs through `sdpars$mu`, the mean-mean
  correlation through `corpars$phylo`, and fitted-row `predict(..., dpar =
  "mu1")` / `predict(..., dpar = "mu2")` contributions;
- updated README, NEWS, roadmap, design notes, known limitations, reference
  docs, and tutorials to mark only this first bivariate phylogenetic location
  slice as fitted while leaving the full q=4 location-scale endpoint and
  `corpairs()` rows planned.

Checks:

- `air format R/drmTMB.R R/formula-markers.R R/methods.R R/profile.R tests/testthat/test-biv-gaussian.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-phylo-utils.R README.md NEWS.md ROADMAP.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/09-phylogenetic-and-spatial-speed.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/16-phylo-spatial-common-math.md docs/design/20-coscale-correlation-pairs.md docs/design/28-double-hierarchical-endpoint.md docs/design/29-mammal-location-coscale-route.md docs/dev-log/known-limitations.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd vignettes/which-scale.Rmd`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated `man/drmTMB.Rd`
  and `man/phylo.Rd`.
- `Rscript -e 'devtools::test(filter = "phylo|biv-gaussian|profile-targets")'`:
  passed with 838 expectations.
- `Rscript -e 'devtools::test(filter = "gaussian-location-scale|phylo|biv-gaussian|profile-targets")'`:
  passed with 916 expectations after updating a stale one-sided bivariate
  `phylo()` error-message expectation.
- `Rscript -e 'devtools::test()'`: passed with 2,657 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/formula-grammar.Rmd", "vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd", "vignettes/which-scale.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `git diff --check`: passed.

## 2026-05-13 -- Bivariate phylogenetic location syntax guard

Scope:

- added a narrow bivariate Gaussian guard for the next fitted phylogenetic
  location path;
- made unmatched `phylo()` terms in `mu1` or `mu2` fail with a matched-term
  message;
- made mismatched bivariate `phylo()` group/tree combinations fail explicitly;
- made matched `mu1`/`mu2` phylogenetic location syntax report that it is
  recognized but not fitted yet, with `sigma1`, `sigma2`, and residual `rho12`
  still ordinary fixed-effect distributional parameters.

Checks:

- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian")'`: passed with 501
  expectations, 0 failures, 0 warnings, and 0 skips.

## 2026-05-13 -- pkgdown feature-branch build workflow guard

Scope:

- split the pkgdown workflow so manual feature-branch dispatches build and
  upload the site artifact without entering the protected GitHub Pages deploy
  environment;
- kept deploys restricted to main/master dispatches or successful main/master
  `R-CMD-check` workflow-run completions;
- responded to failed pkgdown run `25817629476`, which was rejected by
  GitHub Pages environment protection before build steps started.

Checks:

- `air format .github/workflows/pkgdown.yaml docs/dev-log/check-log.md
  docs/dev-log/after-task/2026-05-13-pkgdown-feature-branch-build-workflow-guard.md`:
  passed.
- `ruby -e 'require "yaml"; data = YAML.load_file(".github/workflows/pkgdown.yaml");
  abort("missing jobs") unless data["jobs"] || data[true] || data[:jobs]; puts
  "yaml parsed"'`: passed.
- `git diff --check`: passed.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md` (2026-05-13 13:56): # After Task: Fitted Bivariate Phylogenetic Location
- `docs/dev-log/after-task/2026-05-13-bivariate-phylogenetic-location-syntax-guard.md` (2026-05-13 12:44): # After Task: Bivariate Phylogenetic Location Syntax Guard
- `docs/dev-log/after-task/2026-05-13-slice-9d-derived-covariance-interval-status-guard.md` (2026-05-13 12:39): # After Task: Slice 9D Derived Covariance Interval Status Guard
- `docs/dev-log/after-task/2026-05-13-slice-9c-summary-covariance-reporting-surface.md` (2026-05-13 12:39): # After Task: Slice 9C Summary Covariance Reporting Surface
- `docs/dev-log/after-task/2026-05-13-slice-9b-covariance-summary-component-intervals.md` (2026-05-13 12:39): # After Task: Slice 9B Covariance-Summary Component Intervals
- `docs/dev-log/after-task/2026-05-13-slice-9a-internal-covariance-summary-scaffold.md` (2026-05-13 12:39): # After Task: Slice 9A Internal Covariance-Summary Scaffold
- `docs/dev-log/after-task/2026-05-13-slice-8f-hidden-q4-profile-target-scaffold.md` (2026-05-13 12:39): # After Task: Slice 8F Hidden q=4 Profile-Target Scaffold
- `docs/dev-log/after-task/2026-05-13-slice-8e-hidden-q4-corpairs-scaffold.md` (2026-05-13 12:39): # After Task: Slice 8E Hidden q=4 Corpairs Scaffold

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
