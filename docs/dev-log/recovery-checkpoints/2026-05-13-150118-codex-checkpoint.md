# Codex Recovery Checkpoint

Generated: 2026-05-13 15:01:18 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 5 phylogenetic check_drm diagnostics closeout
Suggested next step: review diff, then preserve branch state or plan the spatial sibling lane

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
 M R/check.R
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
 M man/check_drm.Rd
 M man/corpairs.Rd
 M man/drmTMB.Rd
 M man/phylo.Rd
 M src/drmTMB.cpp
 M tests/testthat/test-biv-gaussian.R
 M tests/testthat/test-check-drm.R
 M tests/testthat/test-corpairs.R
 M tests/testthat/test-gaussian-location-scale.R
 M tests/testthat/test-phylo-gaussian.R
 M tests/testthat/test-phylo-utils.R
 M vignettes/formula-grammar.Rmd
 M vignettes/model-map.Rmd
 M vignettes/phylogenetic-spatial.Rmd
 M vignettes/which-scale.Rmd
?? docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md
?? docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md
?? docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/check.R
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
M	man/check_drm.Rd
M	man/corpairs.Rd
M	man/drmTMB.Rd
M	man/phylo.Rd
M	src/drmTMB.cpp
M	tests/testthat/test-biv-gaussian.R
M	tests/testthat/test-check-drm.R
M	tests/testthat/test-corpairs.R
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
docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md
docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md
docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                            |   3 +-
 R/check.R                                          | 148 ++++++++++++-
 R/drmTMB.R                                         | 185 +++++++++++-----
 R/formula-markers.R                                |  11 +-
 R/methods.R                                        |  85 +++++++-
 R/profile.R                                        |   2 +-
 README.md                                          |  11 +-
 ROADMAP.md                                         |  31 ++-
 docs/design/01-formula-grammar.md                  |  22 ++
 docs/design/03-likelihoods.md                      |  32 ++-
 docs/design/09-phylogenetic-and-spatial-speed.md   |  14 +-
 .../15-location-coscale-phylogenetic-extension.md  |  17 +-
 docs/design/16-phylo-spatial-common-math.md        |  33 ++-
 docs/design/20-coscale-correlation-pairs.md        |  12 +-
 docs/design/28-double-hierarchical-endpoint.md     |  14 +-
 docs/design/29-mammal-location-coscale-route.md    |   7 +-
 docs/dev-log/check-log.md                          | 112 ++++++++++
 docs/dev-log/known-limitations.md                  |  31 ++-
 man/check_drm.Rd                                   |  12 +-
 man/corpairs.Rd                                    |   5 +-
 man/drmTMB.Rd                                      |   9 +-
 man/phylo.Rd                                       |  11 +-
 src/drmTMB.cpp                                     |  66 +++++-
 tests/testthat/test-biv-gaussian.R                 |   4 +-
 tests/testthat/test-check-drm.R                    |  91 ++++++++
 tests/testthat/test-corpairs.R                     | 126 +++++++++++
 tests/testthat/test-gaussian-location-scale.R      |   2 +-
 tests/testthat/test-phylo-gaussian.R               | 240 ++++++++++++++++++---
 tests/testthat/test-phylo-utils.R                  |   3 +-
 vignettes/formula-grammar.Rmd                      |  18 +-
 vignettes/model-map.Rmd                            |  48 ++++-
 vignettes/phylogenetic-spatial.Rmd                 |  48 +++--
 vignettes/which-scale.Rmd                          |  10 +-
 33 files changed, 1248 insertions(+), 215 deletions(-)
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

## 2026-05-13 -- Slice 5 phylogenetic `check_drm()` diagnostics

Scope:

- added a `biv_phylo_mu_covariance` row to `check_drm()` for fitted bivariate
  Gaussian models with matching `mu1`/`mu2` phylogenetic location effects;
- reused the existing `rho_boundary` threshold to warn when fitted
  `corpars$phylo` is near the correlation boundary;
- added a weak-identification note when species replication is thin or either
  fitted phylogenetic location SD is tiny relative to the matching residual
  scale;
- kept residual `rho12`, phylogenetic mean-mean correlation, ordinary
  group-level covariance, and planned spatial covariance as separate diagnostic
  stories;
- updated `check_drm()` reference docs, NEWS, roadmap/status notes, known
  limitations, and phylogenetic/model-map tutorial wording.

Checks:

- `air format R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/dev-log/known-limitations.md docs/design/16-phylo-spatial-common-math.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm|phylo-gaussian|corpairs")'`:
  passed with 228 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,703 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'biv_phylo_mu_covariance|corpars\$phylo|phylogenetic.*diagnostic|near-boundary.*phylo|tiny phylogenetic|spatial.*implemented|spatial.*planned|rho12.*phylogenetic|rho12.*spatial' R/check.R tests/testthat/test-check-drm.R NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd man/check_drm.Rd`:
  confirmed the new diagnostic row, fitted phylogenetic wording, spatial
  planned boundary, and residual-`rho12` separation.
- `rg -n 'check_drm\(\).*phylo|phylo.*check_drm|bivariate phylogenetic.*check_drm|corpars\$phylo.*check_drm' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes man/check_drm.Rd`:
  confirmed the user-facing diagnostic references.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 4 phylogenetic `corpairs()` row

Scope:

- added a `corpairs()` row for fitted bivariate phylogenetic mean-mean
  correlations exposed in `corpars$phylo`;
- used `level = "phylogenetic"`, `block = "phylo"`, `class = "mean-mean"`,
  and the matched `mu1`/`mu2` response labels so residual `rho12`, ordinary
  group-level covariance, and phylogenetic covariance stay separate;
- kept full q=4 phylogenetic location-scale rows planned: this slice reports
  only the fitted `mu1`/`mu2` phylogenetic location correlation;
- updated `corpairs()` docs, NEWS, correlation-pair design notes, known
  limitations, and the phylogenetic/model-map tutorial references.

Checks:

- `air format R/methods.R tests/testthat/test-corpairs.R NEWS.md docs/dev-log/known-limitations.md docs/design/20-coscale-correlation-pairs.md docs/design/29-mammal-location-coscale-route.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::test(filter = "corpairs|phylo-gaussian|biv-gaussian")'`:
  passed with 616 expectations after normalizing the expected filtered-row name
  in the new `corpairs()` regression test.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/corpairs.Rd`.
- `Rscript -e 'devtools::test()'`: passed with 2,686 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `Rscript tools/codex-checkpoint.R --goal "slice 4 phylogenetic corpairs row closeout" --next "review diff, then start slice 5 check_drm diagnostics for fitted bivariate phylogenetic correlations"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md`.
- `git diff --check`: passed.

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
- `air format tests/testthat/test-gaussian-location-scale.R`: passed.
- `air format docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md`:
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
- `Rscript tools/codex-checkpoint.R --goal "fitted bivariate phylogenetic location closeout" --next "review diff, then add corpairs rows for fitted phylogenetic mean-mean correlations or commit this slice"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md`.
- `git diff --check`: passed.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md` (2026-05-13 15:01): # After Task: Slice 5 Phylogenetic `check_drm()` Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md` (2026-05-13 14:46): # After Task: Slice 4 Phylogenetic `corpairs()` Row
- `docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md` (2026-05-13 13:58): # After Task: Fitted Bivariate Phylogenetic Location
- `docs/dev-log/after-task/2026-05-13-bivariate-phylogenetic-location-syntax-guard.md` (2026-05-13 12:44): # After Task: Bivariate Phylogenetic Location Syntax Guard
- `docs/dev-log/after-task/2026-05-13-slice-9d-derived-covariance-interval-status-guard.md` (2026-05-13 12:39): # After Task: Slice 9D Derived Covariance Interval Status Guard
- `docs/dev-log/after-task/2026-05-13-slice-9c-summary-covariance-reporting-surface.md` (2026-05-13 12:39): # After Task: Slice 9C Summary Covariance Reporting Surface
- `docs/dev-log/after-task/2026-05-13-slice-9b-covariance-summary-component-intervals.md` (2026-05-13 12:39): # After Task: Slice 9B Covariance-Summary Component Intervals
- `docs/dev-log/after-task/2026-05-13-slice-9a-internal-covariance-summary-scaffold.md` (2026-05-13 12:39): # After Task: Slice 9A Internal Covariance-Summary Scaffold

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
