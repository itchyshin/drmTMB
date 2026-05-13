# Codex Recovery Checkpoint

Generated: 2026-05-13 16:14:51 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 11B-13B phylo-only recovery, diagnostic, and reader path
Suggested next step: review local pkgdown article pages or decide whether to stage/commit/push this phylo-only batch

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
?? docs/dev-log/after-task/2026-05-13-slice-10-phylo-only-batch-audit.md
?? docs/dev-log/after-task/2026-05-13-slice-11b-bivariate-phylo-simulation-recovery.md
?? docs/dev-log/after-task/2026-05-13-slice-12b-phylo-species-layer-diagnostic.md
?? docs/dev-log/after-task/2026-05-13-slice-13b-phylo-species-reader-path.md
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
?? docs/dev-log/recovery-checkpoints/2026-05-13-153750-codex-checkpoint.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-153943-codex-checkpoint.md
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
docs/dev-log/after-task/2026-05-13-slice-10-phylo-only-batch-audit.md
docs/dev-log/after-task/2026-05-13-slice-11b-bivariate-phylo-simulation-recovery.md
docs/dev-log/after-task/2026-05-13-slice-12b-phylo-species-layer-diagnostic.md
docs/dev-log/after-task/2026-05-13-slice-13b-phylo-species-reader-path.md
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
docs/dev-log/recovery-checkpoints/2026-05-13-153750-codex-checkpoint.md
docs/dev-log/recovery-checkpoints/2026-05-13-153943-codex-checkpoint.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                            |  11 +-
 R/check.R                                          | 207 ++++++++++++-
 R/drmTMB.R                                         | 185 ++++++++---
 R/formula-markers.R                                |  11 +-
 R/methods.R                                        | 196 +++++++++++-
 R/profile.R                                        |   5 +-
 README.md                                          |  11 +-
 ROADMAP.md                                         |  61 ++--
 docs/design/01-formula-grammar.md                  |  22 ++
 docs/design/03-likelihoods.md                      |  32 +-
 docs/design/09-phylogenetic-and-spatial-speed.md   |  14 +-
 docs/design/12-profile-likelihood-cis.md           |  18 +-
 .../15-location-coscale-phylogenetic-extension.md  |  25 +-
 docs/design/16-phylo-spatial-common-math.md        |  40 ++-
 docs/design/20-coscale-correlation-pairs.md        |  12 +-
 docs/design/28-double-hierarchical-endpoint.md     |  40 +--
 docs/design/29-mammal-location-coscale-route.md    |  20 +-
 docs/dev-log/check-log.md                          | 344 +++++++++++++++++++++
 docs/dev-log/known-limitations.md                  |  40 ++-
 man/check_drm.Rd                                   |  11 +-
 man/confint.drmTMB.Rd                              |   3 +-
 man/corpairs.Rd                                    |   5 +-
 man/drmTMB.Rd                                      |   9 +-
 man/phylo.Rd                                       |  11 +-
 man/summary.drmTMB.Rd                              |   2 +
 src/drmTMB.cpp                                     |  66 +++-
 tests/testthat/test-biv-gaussian.R                 |   4 +-
 tests/testthat/test-check-drm.R                    | 127 ++++++++
 tests/testthat/test-corpairs.R                     | 126 ++++++++
 tests/testthat/test-gaussian-location-scale.R      |   2 +-
 tests/testthat/test-phylo-gaussian.R               | 287 +++++++++++++++--
 tests/testthat/test-phylo-utils.R                  |   3 +-
 tests/testthat/test-profile-targets.R              | 155 ++++++++++
 tests/testthat/test-summary.R                      | 148 +++++++++
 vignettes/formula-grammar.Rmd                      |  18 +-
 vignettes/model-map.Rmd                            |  82 ++++-
 vignettes/phylogenetic-spatial.Rmd                 |  87 ++++--
 vignettes/which-scale.Rmd                          |  10 +-
 38 files changed, 2196 insertions(+), 254 deletions(-)
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

## 2026-05-13 -- Slice 13B phylo and species reader path

Scope:

- updated `vignettes/model-map.Rmd` and `vignettes/phylogenetic-spatial.Rmd`
  with syntax for fitting an ordinary labelled species covariance block beside
  matching bivariate `phylo()` terms;
- kept the three correlation layers separate in prose: residual `rho12`,
  ordinary group-level species covariance, and phylogenetic mean-mean
  covariance;
- rebuilt the two local pkgdown article pages for user review.

Checks:

- `Rscript -e 'pkgdown::build_article("model-map"); pkgdown::build_article("phylogenetic-spatial")'`:
  passed and wrote `pkgdown-site/articles/model-map.html` and
  `pkgdown-site/articles/phylogenetic-spatial.html`.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `rg -n 'spatial.*implemented|spatial.*now fits|spatial likelihood is implemented|full q=4.*implemented|q=4.*now fits' NEWS.md README.md ROADMAP.md docs vignettes man R tests`:
  found only planned-boundary wording, historical notes, and explicit
  not-implemented text.
- `rg -n 'future .*non-phylogenetic species|Non-phylogenetic species covariance.*future|Add bivariate Gaussian \`mu1\` and \`mu2\` ordinary species|Add bivariate Gaussian phylogenetic \`mu1\`' docs/design/29-mammal-location-coscale-route.md ROADMAP.md docs/design vignettes`:
  no matches.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## 2026-05-13 -- Slice 12B phylo and ordinary species layer diagnostic

Scope:

- extended `check_drm()` so the `biv_phylo_mu_covariance` diagnostic reports
  `same_group_covariance=true` when an ordinary labelled `mu1`/`mu2`
  group-level covariance block uses the same grouping factor as the fitted
  bivariate phylogenetic layer;
- changed that row to `note` when the same-group overlap is present, unless a
  stronger boundary warning applies;
- updated the roadmap and design notes to say this is an identifiability guard,
  not evidence that same-species phylogenetic and non-phylogenetic layers are
  always cleanly separated.

Checks:

- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm")'`: passed with 119
  expectations.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|corpairs|summary|profile-targets")'`:
  passed with 620 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.

## 2026-05-13 -- Slice 11B bivariate phylogenetic simulation recovery

Scope:

- added a CRAN-safe deterministic recovery test for the first fitted
  bivariate phylogenetic `mu1`/`mu2` mean-mean correlation;
- checked optimizer convergence, positive correlation recovery, phylogenetic
  SD recovery, residual scale recovery, residual `rho12`, and `corpairs()`
  reporting;
- updated roadmap and common-math design wording so the fitted bivariate
  phylogenetic mean-mean layer now has direct simulation evidence.

Checks:

- `air format R/check.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-check-drm.R ROADMAP.md docs/design/15-location-coscale-phylogenetic-extension.md docs/design/16-phylo-spatial-common-math.md docs/design/29-mammal-location-coscale-route.md vignettes/model-map.Rmd vignettes/phylogenetic-spatial.Rmd`:
  passed.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm")'`: passed
  with 165 expectations.
- `Rscript -e 'devtools::test(filter = "phylo-gaussian|check-drm|corpairs|summary|profile-targets")'`:
  passed with 620 expectations.
- `Rscript -e 'devtools::test()'`: passed with 2,772 expectations.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-13b-phylo-species-reader-path.md` (2026-05-13 16:14): # After Task: Slice 13B Phylo And Species Reader Path
- `docs/dev-log/after-task/2026-05-13-slice-12b-phylo-species-layer-diagnostic.md` (2026-05-13 16:14): # After Task: Slice 12B Phylo And Species Layer Diagnostic
- `docs/dev-log/after-task/2026-05-13-slice-11b-bivariate-phylo-simulation-recovery.md` (2026-05-13 16:14): # After Task: Slice 11B Bivariate Phylogenetic Simulation Recovery
- `docs/dev-log/after-task/2026-05-13-slice-10-phylo-only-batch-audit.md` (2026-05-13 15:39): # After Task: Slice 10 Phylo-Only Batch Audit
- `docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md` (2026-05-13 15:37): # After Task: Slice 9 Phylogenetic Reader Path
- `docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md` (2026-05-13 15:34): # After Task: Slice 8 Phylogenetic Profile Smoke
- `docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md` (2026-05-13 15:26): # After Task: Slice 7 Phylogenetic Summary Covariance
- `docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md` (2026-05-13 15:19): # After Task: Slice 6 Phylogenetic Profile Targets

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
