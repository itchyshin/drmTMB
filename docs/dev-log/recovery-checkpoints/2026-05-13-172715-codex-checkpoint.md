# Codex Recovery Checkpoint

Generated: 2026-05-13 17:27:15 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: bivariate direct location random-effect SD formulas
Suggested next step: review diff, then choose ordinary q4 Family A covariance or sd_phylo design as the next slice

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/sd-cor-model-family-split
 M NEWS.md
 M R/drmTMB.R
 M R/methods.R
 M R/parse-formula.R
 M docs/design/01-formula-grammar.md
 M docs/design/03-likelihoods.md
 M docs/design/18-random-effect-scale-models.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M tests/testthat/test-biv-gaussian.R
?? docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/drmTMB.R
M	R/methods.R
M	R/parse-formula.R
M	docs/design/01-formula-grammar.md
M	docs/design/03-likelihoods.md
M	docs/design/18-random-effect-scale-models.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	tests/testthat/test-biv-gaussian.R
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                      |   1 +
 R/drmTMB.R                                   | 190 ++++++++++++++++++++++-----
 R/methods.R                                  |   3 +-
 R/parse-formula.R                            | 127 ++++++++++++++----
 docs/design/01-formula-grammar.md            |  33 ++++-
 docs/design/03-likelihoods.md                |  39 +++++-
 docs/design/18-random-effect-scale-models.md |  72 ++++++++--
 docs/dev-log/check-log.md                    |  52 ++++++++
 docs/dev-log/known-limitations.md            |   9 +-
 tests/testthat/test-biv-gaussian.R           | 158 ++++++++++++++++++++++
 10 files changed, 612 insertions(+), 72 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
dba9f30 Merge pull request #25 from itchyshin/codex/bivariate-phylo-location-guard
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

- `docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md` (2026-05-13 17:26): # After Task: Bivariate Direct Location SD Formulas
- `docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md` (2026-05-13 16:40): # After Task: Slice 9 Phylogenetic Reader Path
- `docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md` (2026-05-13 16:40): # After Task: Slice 8 Phylogenetic Profile Smoke
- `docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md` (2026-05-13 16:40): # After Task: Slice 7 Phylogenetic Summary Covariance
- `docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md` (2026-05-13 16:40): # After Task: Slice 6 Phylogenetic Profile Targets
- `docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md` (2026-05-13 16:40): # After Task: Slice 5 Phylogenetic `check_drm()` Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md` (2026-05-13 16:40): # After Task: Slice 4 Phylogenetic `corpairs()` Row
- `docs/dev-log/after-task/2026-05-13-slice-13b-phylo-species-reader-path.md` (2026-05-13 16:40): # After Task: Slice 13B Phylo And Species Reader Path

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
