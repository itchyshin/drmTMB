# Codex Recovery Checkpoint

Generated: 2026-05-13 17:53:28 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: ordinary q4 bivariate location-scale covariance block
Suggested next step: commit slice 14, then add corpair() parser deferred errors

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
 M docs/design/01-formula-grammar.md
 M docs/design/03-likelihoods.md
 M docs/design/28-double-hierarchical-endpoint.md
 M docs/design/30-labelled-covariance-block-assembler.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M src/drmTMB.cpp
 M tests/testthat/test-biv-gaussian.R
?? docs/dev-log/after-task/2026-05-13-slice-14-ordinary-q4-location-scale-covariance.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/drmTMB.R
M	R/methods.R
M	docs/design/01-formula-grammar.md
M	docs/design/03-likelihoods.md
M	docs/design/28-double-hierarchical-endpoint.md
M	docs/design/30-labelled-covariance-block-assembler.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	src/drmTMB.cpp
M	tests/testthat/test-biv-gaussian.R
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-13-slice-14-ordinary-q4-location-scale-covariance.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                            |   4 +-
 R/drmTMB.R                                         | 483 ++++++++++++++++++++-
 R/methods.R                                        |  39 ++
 docs/design/01-formula-grammar.md                  |  25 +-
 docs/design/03-likelihoods.md                      |  18 +-
 docs/design/28-double-hierarchical-endpoint.md     |  27 +-
 .../30-labelled-covariance-block-assembler.md      |  12 +-
 docs/dev-log/check-log.md                          |  23 +
 docs/dev-log/known-limitations.md                  |  31 +-
 src/drmTMB.cpp                                     | 106 +++++
 tests/testthat/test-biv-gaussian.R                 | 148 ++++++-
 11 files changed, 845 insertions(+), 71 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
5b31422 Add bivariate direct location SD formulas
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Slice 14 ordinary q4 location-scale covariance block

Scope:

- enabled the all-four ordinary labelled random-intercept pattern
  `(1 | p | id)` across bivariate `mu1`, `mu2`, `sigma1`, and `sigma2`;
- added TMB q > 2 covariance-block plumbing for the bivariate Gaussian path,
  with one non-centred latent vector, four SDs, six correlations, fitted
  random-effect contributions, and `corpairs()` / `summary()` reporting;
- updated formula grammar, likelihood, endpoint, assembler, known-limitations,
  and NEWS wording so ordinary q4 is fitted while phylogenetic q4, spatial q4,
  random-slope endpoint blocks, and `rho12` random effects remain planned.

Checks:

- `Rscript -e 'devtools::load_all(quiet = TRUE)'`: passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|covariance-block-registry|summary|corpairs", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::test(filter = "biv-gaussian|covariance-block-registry|summary|corpairs|profile-targets|check-drm", reporter = "summary")'`:
  passed.
- `rg -n 'full.*remain planned|full.*rejected|all four.*rejected|Reusing one bivariate covariance-block label|q=4.*remains planned|q4.*remain planned|ambiguous same-label|larger block remains planned' NEWS.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md docs/design/28-double-hierarchical-endpoint.md docs/design/30-labelled-covariance-block-assembler.md docs/dev-log/known-limitations.md`:
  no stale q4-rejection matches in the synchronized status docs.

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


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-14-ordinary-q4-location-scale-covariance.md` (2026-05-13 17:53): # After Task: Slice 14 Ordinary q4 Location-Scale Covariance
- `docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md` (2026-05-13 17:26): # After Task: Bivariate Direct Location SD Formulas
- `docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md` (2026-05-13 16:40): # After Task: Slice 9 Phylogenetic Reader Path
- `docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md` (2026-05-13 16:40): # After Task: Slice 8 Phylogenetic Profile Smoke
- `docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md` (2026-05-13 16:40): # After Task: Slice 7 Phylogenetic Summary Covariance
- `docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md` (2026-05-13 16:40): # After Task: Slice 6 Phylogenetic Profile Targets
- `docs/dev-log/after-task/2026-05-13-slice-5-phylogenetic-check-drm-diagnostics.md` (2026-05-13 16:40): # After Task: Slice 5 Phylogenetic `check_drm()` Diagnostics
- `docs/dev-log/after-task/2026-05-13-slice-4-phylogenetic-corpairs-row.md` (2026-05-13 16:40): # After Task: Slice 4 Phylogenetic `corpairs()` Row

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
