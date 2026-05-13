# Codex Recovery Checkpoint

Generated: 2026-05-13 15:27:00 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 7 phylogenetic summary covariance closeout
Suggested next step: start slice 8 profile/confint smoke check for fitted bivariate phylogenetic correlation target

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
?? docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-151946-codex-checkpoint.md
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
docs/dev-log/recovery-checkpoints/2026-05-13-135745-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-144557-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-151946-codex-checkpoint.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                            |   7 +-
 R/check.R                                          | 148 ++++++++++++-
 R/drmTMB.R                                         | 185 +++++++++++-----
 R/formula-markers.R                                |  11 +-
 R/methods.R                                        | 196 ++++++++++++++++-
 R/profile.R                                        |   2 +-
 README.md                                          |  11 +-
 ROADMAP.md                                         |  44 ++--
 docs/design/01-formula-grammar.md                  |  22 ++
 docs/design/03-likelihoods.md                      |  32 ++-
 docs/design/09-phylogenetic-and-spatial-speed.md   |  14 +-
 docs/design/12-profile-likelihood-cis.md           |  15 +-
 .../15-location-coscale-phylogenetic-extension.md  |  17 +-
 docs/design/16-phylo-spatial-common-math.md        |  33 ++-
 docs/design/20-coscale-correlation-pairs.md        |  12 +-
 docs/design/28-double-hierarchical-endpoint.md     |  40 ++--
 docs/design/29-mammal-location-coscale-route.md    |   7 +-
 docs/dev-log/check-log.md                          | 183 ++++++++++++++++
 docs/dev-log/known-limitations.md                  |  40 ++--
 man/check_drm.Rd                                   |  12 +-
 man/corpairs.Rd                                    |   5 +-
 man/drmTMB.Rd                                      |   9 +-
 man/phylo.Rd                                       |  11 +-
 man/summary.drmTMB.Rd                              |   2 +
 src/drmTMB.cpp                                     |  66 +++++-
 tests/testthat/test-biv-gaussian.R                 |   4 +-
 tests/testthat/test-check-drm.R                    |  91 ++++++++
 tests/testthat/test-corpairs.R                     | 126 +++++++++++
 tests/testthat/test-gaussian-location-scale.R      |   2 +-
 tests/testthat/test-phylo-gaussian.R               | 240 ++++++++++++++++++---
 tests/testthat/test-phylo-utils.R                  |   3 +-
 tests/testthat/test-profile-targets.R              |  85 ++++++++
 tests/testthat/test-summary.R                      | 148 +++++++++++++
 vignettes/formula-grammar.Rmd                      |  18 +-
 vignettes/model-map.Rmd                            |  48 ++++-
 vignettes/phylogenetic-spatial.Rmd                 |  48 +++--
 vignettes/which-scale.Rmd                          |  10 +-
 37 files changed, 1710 insertions(+), 237 deletions(-)
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

## 2026-05-13 -- Slice 6 phylogenetic `profile_targets()` labels

Scope:

- added focused coverage that `profile_targets()` lists fitted bivariate
  phylogenetic `mu1`/`mu2` location SDs and the phylogenetic mean-mean
  correlation;
- checked the exact public target names:
  `sd:mu:mu1:phylo(1 | species)`,
  `sd:mu:mu2:phylo(1 | species)`, and
  `cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | phylo | species)`;
- checked TMB mapping to `log_sd_phylo` indices 1 and 2 and
  `eta_cor_phylo` index 1, with `exp`/`tanh` transformations and direct
  profile readiness;
- confirmed residual `rho12` remains a separate residual-correlation target;
- synchronized NEWS, roadmap, and profile/double-hierarchical design notes
  without changing spatial implementation status.

Checks:

- `air format tests/testthat/test-profile-targets.R NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md`:
  passed.
- `Rscript -e 'devtools::test(filter = "profile-targets|phylo-gaussian")'`:
  passed with 283 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,716 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'bivariate phylogenetic|cor:phylo|rho12|spatial' NEWS.md ROADMAP.md docs/design/12-profile-likelihood-cis.md docs/design/28-double-hierarchical-endpoint.md docs/dev-log/known-limitations.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  confirmed fitted phylogenetic target wording, residual-`rho12` separation, and
  spatial planned wording.
- `rg -n 'profile intervals already work|profile-likelihood intervals.*phylogenetic|derived.*phylo|spatial.*implemented|bivariate phylo\(\) syntax remains planned|bivariate phylogenetic.*planned' NEWS.md ROADMAP.md docs vignettes`:
  found only expected planned-boundary and historical-note wording; no current
  claim that spatial is implemented.
- `git diff --check`: passed.

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
- `Rscript tools/codex-checkpoint.R --goal "slice 5 phylogenetic check_drm diagnostics closeout" --next "review diff, then preserve branch state or plan the spatial sibling lane"`:
  passed and wrote
  `docs/dev-log/recovery-checkpoints/2026-05-13-150118-codex-checkpoint.md`.
- `git diff --check`: passed.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md` (2026-05-13 15:26): # After Task: Slice 7 Phylogenetic Summary Covariance
- `docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md` (2026-05-13 15:19): # After Task: Slice 6 Phylogenetic Profile Targets
- `docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md` (2026-05-13 15:01): # After Task: Slice 5 Phylogenetic `check_drm()` Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md` (2026-05-13 14:46): # After Task: Slice 4 Phylogenetic `corpairs()` Row
- `docs/dev-log/after-task/2026-05-13-fitted-bivariate-phylogenetic-location.md` (2026-05-13 13:58): # After Task: Fitted Bivariate Phylogenetic Location
- `docs/dev-log/after-task/2026-05-13-bivariate-phylogenetic-location-syntax-guard.md` (2026-05-13 12:44): # After Task: Bivariate Phylogenetic Location Syntax Guard
- `docs/dev-log/after-task/2026-05-13-slice-9d-derived-covariance-interval-status-guard.md` (2026-05-13 12:39): # After Task: Slice 9D Derived Covariance Interval Status Guard
- `docs/dev-log/after-task/2026-05-13-slice-9c-summary-covariance-reporting-surface.md` (2026-05-13 12:39): # After Task: Slice 9C Summary Covariance Reporting Surface

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
