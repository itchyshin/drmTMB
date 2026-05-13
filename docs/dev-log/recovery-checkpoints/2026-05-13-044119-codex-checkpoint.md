# Codex Recovery Checkpoint

Generated: 2026-05-13 04:41:19 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Finish bivariate same-response mu/sigma covariance slice
Suggested next step: Review diff, then either commit slice 3 or start a plan for Cholesky labelled block slice 4

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/biv-cross-parameter-intercepts
 M NEWS.md
 M R/check.R
 M R/drmTMB.R
 M R/methods.R
 M README.md
 M ROADMAP.md
 M docs/design/01-formula-grammar.md
 M docs/design/03-likelihoods.md
 M docs/design/12-profile-likelihood-cis.md
 M docs/design/17-correlated-random-effect-blocks.md
 M docs/design/20-coscale-correlation-pairs.md
 M docs/design/28-double-hierarchical-endpoint.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M man/corpairs.Rd
 M man/drmTMB.Rd
 M src/drmTMB.cpp
 M tests/testthat/test-biv-gaussian.R
 M tests/testthat/test-gaussian-random-intercepts.R
 M tests/testthat/test-phylo-utils.R
 M vignettes/distribution-families.Rmd
 M vignettes/formula-grammar.Rmd
 M vignettes/model-map.Rmd
 M vignettes/source-map.Rmd
 M vignettes/which-scale.Rmd
?? docs/dev-log/after-task/2026-05-13-bivariate-same-response-mu-sigma-covariance.md
?? docs/dev-log/recovery-checkpoints/2026-05-13-040434-codex-checkpoint.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/check.R
M	R/drmTMB.R
M	R/methods.R
M	README.md
M	ROADMAP.md
M	docs/design/01-formula-grammar.md
M	docs/design/03-likelihoods.md
M	docs/design/12-profile-likelihood-cis.md
M	docs/design/17-correlated-random-effect-blocks.md
M	docs/design/20-coscale-correlation-pairs.md
M	docs/design/28-double-hierarchical-endpoint.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	man/corpairs.Rd
M	man/drmTMB.Rd
M	src/drmTMB.cpp
M	tests/testthat/test-biv-gaussian.R
M	tests/testthat/test-gaussian-random-intercepts.R
M	tests/testthat/test-phylo-utils.R
M	vignettes/distribution-families.Rmd
M	vignettes/formula-grammar.Rmd
M	vignettes/model-map.Rmd
M	vignettes/source-map.Rmd
M	vignettes/which-scale.Rmd
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-13-bivariate-same-response-mu-sigma-covariance.md
docs/dev-log/recovery-checkpoints/2026-05-13-040434-codex-checkpoint.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                           |   7 +-
 R/check.R                                         | 104 +++++
 R/drmTMB.R                                        | 506 +++++++++++++++-------
 R/methods.R                                       |   7 +-
 README.md                                         |   8 +-
 ROADMAP.md                                        |  24 +-
 docs/design/01-formula-grammar.md                 |  43 +-
 docs/design/03-likelihoods.md                     |   8 +-
 docs/design/12-profile-likelihood-cis.md          |   7 +-
 docs/design/17-correlated-random-effect-blocks.md |   3 +-
 docs/design/20-coscale-correlation-pairs.md       |   8 +-
 docs/design/28-double-hierarchical-endpoint.md    |  18 +-
 docs/dev-log/check-log.md                         |  57 +++
 docs/dev-log/known-limitations.md                 |  29 +-
 man/corpairs.Rd                                   |   7 +-
 man/drmTMB.Rd                                     |   4 +-
 src/drmTMB.cpp                                    |  49 ++-
 tests/testthat/test-biv-gaussian.R                | 192 +++++++-
 tests/testthat/test-gaussian-random-intercepts.R  |   2 +-
 tests/testthat/test-phylo-utils.R                 |   5 +
 vignettes/distribution-families.Rmd               |   2 +-
 vignettes/formula-grammar.Rmd                     |  19 +-
 vignettes/model-map.Rmd                           |   4 +-
 vignettes/source-map.Rmd                          |   2 +-
 vignettes/which-scale.Rmd                         |  11 +-
 25 files changed, 867 insertions(+), 259 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
7cd540a Align bivariate random structure metadata (#23)
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Bivariate same-response mu/sigma covariance

Scope:

- finished the same-response bivariate `mu`/`sigma` random-intercept covariance
  slice, allowing one matching labelled pair such as `mu1` with `sigma1` or
  `mu2` with `sigma2`;
- wired the bivariate TMB data list, C++ likelihood branch, fitted random-effect
  extraction, `corpars$mu_sigma`, `corpairs()`, `profile_targets()`, and
  `check_drm()` to keep this mean-scale pair separate from `mu1`/`mu2`,
  `sigma1`/`sigma2`, and residual `rho12`;
- updated formula grammar, likelihood, profile, roadmap, known-limitations,
  README, NEWS, and vignette status surfaces so the implemented pairwise bridge
  is not confused with the still-planned full labelled covariance block across
  `mu1`, `mu2`, `sigma1`, and `sigma2`.

Checks:

- recovery rehydration: inspected `git status --short --branch`, `git diff
  --stat`, `git diff -- R/drmTMB.R`, `git diff -- src/drmTMB.cpp`, and
  `docs/dev-log/recovery-checkpoints/2026-05-13-040434-codex-checkpoint.md`
  before editing.
- `air format R/drmTMB.R R/check.R R/methods.R
  tests/testthat/test-biv-gaussian.R`: passed.
- `air format tests/testthat/test-gaussian-random-intercepts.R
  tests/testthat/test-phylo-utils.R`: passed.
- `Rscript -e "devtools::document()"`: passed and regenerated
  `man/drmTMB.Rd` and `man/corpairs.Rd`.
- `Rscript -e "devtools::test(filter = 'biv-gaussian|check-drm')"`: passed
  with 369 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test(filter =
  'gaussian-random-intercepts|phylo-utils|biv-gaussian|check-drm')"`: passed
  with 639 expectations, 0 failures, 0 warnings, and 0 skips after updating
  stale unsupported-message expectations and the hand-built phylo TMB data
  fixture for the new random-effect metadata fields.
- `Rscript -e "devtools::test()"`: passed with 2052 expectations, 0 failures,
  0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n 'bivariate random slopes, cross-parameter|cross-parameter covariance
  blocks, and `rho12`|cross-parameter bivariate covariance blocks remain
  planned|double-hierarchical cross-parameter covariance|bivariate
  `sigma1`/`sigma2` and cross-parameter' README.md ROADMAP.md NEWS.md docs
  vignettes --glob '!docs/dev-log/after-task/**' --glob
  '!docs/dev-log/recovery-checkpoints/**'`: no active stale broad-planned
  wording found.
- `rg -n 'same-response|full cross-parameter|biv_mu_sigma_random_effect_covariance|corpars\\$mu_sigma|eta_cor_mu_sigma'
  README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md
  vignettes R tests/testthat/test-biv-gaussian.R
  tests/testthat/test-check-drm.R`: checked that code, tests, and docs name the
  implemented pairwise bridge and the still-planned full block separately.
- `rg -n 'meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]' README.md ROADMAP.md
  NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R
  tests/testthat/test-biv-gaussian.R`: remaining hits are intentional
  meta-analysis and residual-correlation guardrails; no new syntax was
  introduced.

## 2026-05-12 -- Bivariate random-structure metadata parity

Scope:

- added `coef_names`, `group_names`, and `covariance_labels` fields to the
  bivariate `mu1`/`mu2` random-effect structure so it matches the existing
  bivariate `sigma1`/`sigma2` structure shape;
- added assertions to the combined bivariate covariance regression so future
  covariance code can rely on those metadata fields being present for both
  same-parameter blocks.

Checks:

- inspected `build_biv_mu_random_structure()` and
  `build_biv_sigma_random_structure()`; the `sigma` path already returned the
  metadata fields, while the `mu` path did not.
- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  235 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2014 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.

## 2026-05-12 -- Bivariate covariance block label guard

Scope:

- rejected the ambiguous same-label bivariate pattern where `(1 | p | id)`
  appears in all four `mu1`, `mu2`, `sigma1`, and `sigma2` formulas;
- kept the implemented bivariate covariance surface limited to two separate
  same-parameter blocks: a mean-mean `mu1`/`mu2` block and a scale-scale
  `sigma1`/`sigma2` block;
- added negative tests for the same-label cross-parameter pattern and for
  random-effect syntax in residual `rho12`.

Checks:

- live pre-edit probe confirmed that the same-label all-four-formula pattern
  was previously accepted and reported two separate group-level `corpairs()`
  rows with the same `block` label.
- `air format R/drmTMB.R tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  229 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2008 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n "Reusing one bivariate|same-label pattern|same label and grouping variable|cross-parameter bivariate covariance|rho12.*within-observation" R/drmTMB.R tests/testthat/test-biv-gaussian.R NEWS.md docs/design/01-formula-grammar.md docs/design/28-double-hierarchical-endpoint.md ROADMAP.md docs/dev-log/known-limitations.md vignettes`:
  checked the new guard, NEWS note, and formula-grammar wording.
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  checked scope guardrails; hits were existing meta-analysis and design-rule
  references, not new grammar.
- `rg -n "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  reviewed the high-density scale and residual-correlation wording touched by
  this guard.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-bivariate-same-response-mu-sigma-covariance.md` (2026-05-13 04:41): # After Task: Bivariate Same-Response Mu/Sigma Covariance
- `docs/dev-log/after-task/2026-05-12-bivariate-random-structure-metadata.md` (2026-05-12 19:16): # After Task: Bivariate Random-Structure Metadata Parity
- `docs/dev-log/after-task/2026-05-12-bivariate-covariance-label-guard.md` (2026-05-12 19:03): # After Task: Bivariate Covariance Block Label Guard
- `docs/dev-log/after-task/2026-05-12-bivariate-joint-mu-sigma-covariance.md` (2026-05-12 18:47): # After Task: Bivariate Joint Mean-Scale Covariance Regression
- `docs/dev-log/after-task/2026-05-12-sigma-random-slope-slice.md` (2026-05-12 18:19): # After Task: Independent Sigma Random Slopes
- `docs/dev-log/after-task/2026-05-12-bivariate-sigma-scale-covariance.md` (2026-05-12 18:19): # After Task: Bivariate Sigma Scale Covariance
- `docs/dev-log/after-task/2026-05-12-univariate-mu-sigma-covariance-bridge.md` (2026-05-12 16:41): # After Task: Univariate Mu/Sigma Covariance Bridge
- `docs/dev-log/after-task/2026-05-12-profile-covariance-status-docs.md` (2026-05-12 16:41): # After Task: Profile Covariance Status Docs

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
