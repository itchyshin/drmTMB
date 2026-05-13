# Codex Recovery Checkpoint

Generated: 2026-05-13 15:37:50 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 9 bivariate phylogenetic reader path closeout
Suggested next step: run slice 10 final phylo-only audit and stop before spatial lane

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
 M docs/design/12-profile-likelihood-cis.md
 M docs/design/15-location-coscale-phylogenetic-extension.md
 M docs/design/16-phylo-spatial-common-math.md
 M docs/design/20-coscale-correlation-pairs.md
 M docs/design/28-double-hierarchical-endpoint.md
 M docs/design/29-mammal-location-coscale-route.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M man/check_drm.Rd
 M man/confint.drmTMB.Rd
 M man/corpairs.Rd
 M man/drmTMB.Rd
 M man/phylo.Rd
 M man/summary.drmTMB.Rd
 M src/drmTMB.cpp
 M tests/testthat/test-biv-gaussian.R
 M tests/testthat/test-check-drm.R
 M tests/testthat/test-corpairs.R
 M tests/testthat/test-gaussian-location-scale.R
 M tests/testthat/test-phylo-gaussian.R
 M tests/testthat/test-phylo-utils.R
 M tests/testthat/test-profile-targets.R
 M tests/testthat/test-summary.R
 M vignettes/formula-grammar.Rmd
 M vignettes/model-map.Rmd
 M vignettes/phylogenetic-spatial.Rmd
 M vignettes/which-scale.Rmd
?? docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md
?? docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md
?? docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md
?? docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md
?? docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md
?? docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md
?? docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-151946-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-152700-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-153448-codex-checkpoint.md
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
M	docs/design/12-profile-likelihood-cis.md
M	docs/design/15-location-coscale-phylogenetic-extension.md
M	docs/design/16-phylo-spatial-common-math.md
M	docs/design/20-coscale-correlation-pairs.md
M	docs/design/28-double-hierarchical-endpoint.md
M	docs/design/29-mammal-location-coscale-route.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	man/check_drm.Rd
M	man/confint.drmTMB.Rd
M	man/corpairs.Rd
M	man/drmTMB.Rd
M	man/phylo.Rd
M	man/summary.drmTMB.Rd
M	src/drmTMB.cpp
M	tests/testthat/test-biv-gaussian.R
M	tests/testthat/test-check-drm.R
M	tests/testthat/test-corpairs.R
M	tests/testthat/test-gaussian-location-scale.R
M	tests/testthat/test-phylo-gaussian.R
M	tests/testthat/test-phylo-utils.R
M	tests/testthat/test-profile-targets.R
M	tests/testthat/test-summary.R
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
docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md
docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md
docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md
docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md
docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-151946-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-152700-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-153448-codex-checkpoint.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                            |  11 +-
 R/check.R                                          | 148 ++++++++++++-
 R/drmTMB.R                                         | 185 +++++++++++-----
 R/formula-markers.R                                |  11 +-
 R/methods.R                                        | 196 ++++++++++++++++-
 R/profile.R                                        |   5 +-
 README.md                                          |  11 +-
 ROADMAP.md                                         |  54 +++--
 docs/design/01-formula-grammar.md                  |  22 ++
 docs/design/03-likelihoods.md                      |  32 ++-
 docs/design/09-phylogenetic-and-spatial-speed.md   |  14 +-
 docs/design/12-profile-likelihood-cis.md           |  18 +-
 .../15-location-coscale-phylogenetic-extension.md  |  17 +-
 docs/design/16-phylo-spatial-common-math.md        |  33 ++-
 docs/design/20-coscale-correlation-pairs.md        |  12 +-
 docs/design/28-double-hierarchical-endpoint.md     |  40 ++--
 docs/design/29-mammal-location-coscale-route.md    |   7 +-
 docs/dev-log/check-log.md                          | 243 +++++++++++++++++++++
 docs/dev-log/known-limitations.md                  |  40 ++--
 man/check_drm.Rd                                   |  12 +-
 man/confint.drmTMB.Rd                              |   3 +-
 man/corpairs.Rd                                    |   5 +-
 man/drmTMB.Rd                                      |   9 +-
 man/phylo.Rd                                       |  11 +-
 man/summary.drmTMB.Rd                              |   2 +
 src/drmTMB.cpp                                     |  66 +++++-
 tests/testthat/test-biv-gaussian.R                 |   4 +-
 tests/testthat/test-check-drm.R                    |  91 ++++++++
 tests/testthat/test-corpairs.R                     | 126 +++++++++++
 tests/testthat/test-gaussian-location-scale.R      |   2 +-
 tests/testthat/test-phylo-gaussian.R               | 240 ++++++++++++++++++--
 tests/testthat/test-phylo-utils.R                  |   3 +-
 tests/testthat/test-profile-targets.R              | 155 +++++++++++++
 tests/testthat/test-summary.R                      | 148 +++++++++++++
 vignettes/formula-grammar.Rmd                      |  18 +-
 vignettes/model-map.Rmd                            |  52 ++++-
 vignettes/phylogenetic-spatial.Rmd                 |  60 +++--
 vignettes/which-scale.Rmd                          |  10 +-
 38 files changed, 1870 insertions(+), 246 deletions(-)
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

## 2026-05-13 -- Slice 9 bivariate phylogenetic reader path

Scope:

- updated `vignettes/phylogenetic-spatial.Rmd` so the bivariate phylogenetic
  section shows the fitted `fit_biv_phylo` syntax, `corpairs()` reading path,
  `summary(fit)$covariance`, `check_drm()`, and the explicit `cor:phylo:`
  profile target;
- updated `vignettes/model-map.Rmd` so the practical trait protocol includes
  matching bivariate `phylo()` terms as the first fitted phylogenetic
  mean-mean slice;
- kept phylogenetic slopes, phylogenetic `sigma`, q=4 location-scale
  covariance, structured effects in `rho12`, and spatial terms planned;
- updated NEWS to describe the tutorial reading guidance.

Checks:

- `air format NEWS.md vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd`:
  passed.
- `Rscript -e 'for (f in c("vignettes/model-map.Rmd", "vignettes/phylogenetic-spatial.Rmd")) rmarkdown::render(f, output_file = tempfile(fileext = ".html"), quiet = TRUE)'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'fit_biv_phylo|cor:phylo|summary\(fit_biv_phylo\)\$covariance|corpairs\(fit_biv_phylo|confint\(fit_biv_phylo|spatial.*implemented|spatial.*planned|rho12.*phylogenetic' vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd NEWS.md`:
  confirmed the new reader path and spatial planned boundary.
- `rg -n 'bivariate phylogenetic.*planned|corpairs\(\).*remain planned|q=4 endpoint|spatial likelihood is not implemented' vignettes/phylogenetic-spatial.Rmd vignettes/model-map.Rmd NEWS.md`:
  confirmed q=4 and spatial limitations remain explicit without hiding the
  fitted `mu1`/`mu2` phylogenetic slice.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 8 bivariate phylogenetic profile smoke

Scope:

- added a focused `confint(..., method = "profile")` smoke test for the direct
  bivariate phylogenetic `mu1`/`mu2` mean-mean correlation target;
- used a stronger deterministic fixture than the small target-inventory fixture
  so the profile has finite lower and upper endpoints without warnings;
- compared the public `confint()` output to an independent
  `TMB::tmbprofile()` call on `eta_cor_phylo`;
- updated NEWS, roadmap, profile design notes, and generated `confint()`
  reference docs to include the phylogenetic correlation target.

Checks:

- `air format tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md R/profile.R`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/confint.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian")'`:
  passed with 292 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,758 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'eta_cor_phylo|bivariate phylogenetic.*profile|confint\(\).*phylogenetic|phylogenetic.*confint|rho12.*phylogenetic|spatial.*implemented' NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/dev-log/known-limitations.md R/profile.R tests/testthat/test-profile-targets.R man/confint.drmTMB.Rd`:
  confirmed the profile target, residual-`rho12` separation, and spatial
  planned boundary.
- `rg -n 'profile.*bivariate phylogenetic|bivariate phylogenetic.*planned|spatial.*implemented' NEWS.md ROADMAP.md docs vignettes man`:
  found expected current and historical planned-boundary wording only.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 7 phylogenetic `summary()` covariance row

Scope:

- added a `summary(fit)$covariance` row for fitted bivariate phylogenetic
  `mu1`/`mu2` mean-mean covariance;
- kept the row on the same covariance-summary surface used by fitted
  registry-backed covariance blocks, with `level = "phylogenetic"`,
  `block = "phylo"`, `class = "mean-mean"`, identity scales, component SD
  targets, and the `cor:phylo:` target name;
- kept residual `rho12` in `summary(fit)$parameters`, not in the random-effect
  covariance table;
- updated NEWS, roadmap, known limitations, the double-hierarchical endpoint
  note, and the `summary()` reference documentation.

Checks:

- `air format R/methods.R tests/testthat/test-summary.R NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/summary.drmTMB.Rd`.
- `Rscript -e 'devtools::test(filter = "summary|phylo-gaussian|corpairs|profile-targets")'`:
  passed with 484 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,749 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'summary\(fit\)\$covariance|summary\(\).*phylogenetic|bivariate phylogenetic.*covariance|rho12.*summary|spatial.*implemented' NEWS.md ROADMAP.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd R/methods.R tests/testthat/test-summary.R man/summary.drmTMB.Rd`:
  confirmed the new summary surface and residual/spatial boundaries.
- `rg -n 'summary\(fit\)\$covariance.*registry-backed|registry-backed.*summary\(fit\)\$covariance|covariance component.*registry-backed|spatial.*implemented' NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md vignettes man/summary.drmTMB.Rd`:
  confirmed the registry-backed wording now has the phylogenetic exception where
  needed and no current spatial-implemented claim.
- `git diff --check`: passed.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md` (2026-05-13 15:37): # After Task: Slice 9 Phylogenetic Reader Path
- `docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md` (2026-05-13 15:34): # After Task: Slice 8 Phylogenetic Profile Smoke
- `docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md` (2026-05-13 15:26): # After Task: Slice 7 Phylogenetic Summary Covariance
- `docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md` (2026-05-13 15:19): # After Task: Slice 6 Phylogenetic Profile Targets
- `docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md` (2026-05-13 15:01): # After Task: Slice 5 Phylogenetic `check_drm()` Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md` (2026-05-13 14:46): # After Task: Slice 4 Phylogenetic `corpairs()` Row
- `docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md` (2026-05-13 13:58): # After Task: Fitted Bivariate Phylogenetic Location
- `docs/dev-log/after-task/2026-05-13-bivariate-phylogenetic-location-syntax-guard.md` (2026-05-13 12:44): # After Task: Bivariate Phylogenetic Location Syntax Guard

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
