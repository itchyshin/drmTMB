# Codex Recovery Checkpoint

Generated: 2026-05-13 04:04:34 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: Recover crashed bivariate cross-parameter intercept slice
Suggested next step: Inspect current R/drmTMB.R and src/drmTMB.cpp diff, then add targeted bivariate same-response mu/sigma covariance tests and docs before running focused checks

## Purpose

This file is a durable handoff for a long or interrupted Codex thread. The
working tree is still authoritative: rerun `git status` and `git diff` before
editing, testing, committing, or summarizing the package state.

## Git State

### Branch And Status

`git status --short --branch`

```text
## codex/biv-cross-parameter-intercepts
 M R/drmTMB.R
 M src/drmTMB.cpp
```

### Changed Files

`git diff --name-status`

```text
M	R/drmTMB.R
M	src/drmTMB.cpp
```

`git ls-files --others --exclude-standard`

```text
(no output)
```

### Diff Stat

`git diff --stat`

```text
 R/drmTMB.R     | 435 +++++++++++++++++++++++++++++++++++++--------------------
 src/drmTMB.cpp |  49 +++++--
 2 files changed, 319 insertions(+), 165 deletions(-)
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

## 2026-05-12 -- Joint bivariate mean-scale covariance regression

Scope:

- added a deterministic bivariate Gaussian simulation test that fits matching
  labelled `mu1`/`mu2` and `sigma1`/`sigma2` random-intercept covariance
  blocks in the same model;
- used separate block labels, `(1 | pm | id)` and `(1 | ps | id)`, so the test
  proves that `corpairs()`, `summary()`, `profile_targets()`, and
  `check_drm()` keep mean-mean, scale-scale, and residual `rho12 ~ x` rows
  distinct;
- updated the roadmap and double-hierarchical endpoint note to record that this
  combined labelled-intercept slice is now covered, while bivariate random
  slopes and cross-parameter bivariate covariance remain planned.

Checks:

- live pre-edit fit with both labelled bivariate blocks and constant residual
  `rho12`: convergence 0, positive-definite Hessian, three `corpairs()` rows,
  and `check_drm()` status `ok` for both bivariate covariance diagnostics.
- strengthened the test to use predictor-dependent residual `rho12 ~ x` after
  auditing `docs/design/28-double-hierarchical-endpoint.md`; the live probe
  converged with a positive-definite Hessian and recovered the `rho12`
  coefficients within 0.12 on the link scale.
- `air format tests/testthat/test-biv-gaussian.R`: passed.
- `Rscript -e "devtools::test(filter = 'biv-gaussian')"`: passed with
  227 expectations, 0 failures, 0 warnings, and 0 skips.
- `Rscript -e "devtools::test()"`: passed with 2006 expectations,
  0 failures, 0 warnings, and 0 skips.
- `Rscript -e "pkgdown::check_pkgdown()"`: passed with no problems found.
- `git diff --check`: passed.
- `rg -n "joint.*mu.*sigma|coexist|same model|mean-mean|scale-scale|biv_mu_random_effect_covariance|biv_sigma_random_effect_covariance|corpars\\$mu|corpars\\$sigma" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  checked the current naming surface for the combined block claim.
- `rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  checked scope guardrails; hits were existing meta-analysis and design-rule
  references, not new grammar.
- `rg -n "rho12|sigma1|sigma2|sd\\(" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R tests/testthat/test-biv-gaussian.R`:
  reviewed high-density scale and correlation terminology touched by this
  slice.
- `rg -n "Targeted simulation coverage|Combine bivariate group-level covariance blocks|keeps mu and sigma covariance blocks distinct|rho12 ~ x" ROADMAP.md docs/design/28-double-hierarchical-endpoint.md tests/testthat/test-biv-gaussian.R docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-12-bivariate-joint-mu-sigma-covariance.md`:
  confirmed that the new roadmap/design status wording points to the new
  regression test and after-task evidence.


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-12-bivariate-random-structure-metadata.md` (2026-05-12 19:16): # After Task: Bivariate Random-Structure Metadata Parity
- `docs/dev-log/after-task/2026-05-12-bivariate-covariance-label-guard.md` (2026-05-12 19:03): # After Task: Bivariate Covariance Block Label Guard
- `docs/dev-log/after-task/2026-05-12-bivariate-joint-mu-sigma-covariance.md` (2026-05-12 18:47): # After Task: Bivariate Joint Mean-Scale Covariance Regression
- `docs/dev-log/after-task/2026-05-12-sigma-random-slope-slice.md` (2026-05-12 18:19): # After Task: Independent Sigma Random Slopes
- `docs/dev-log/after-task/2026-05-12-bivariate-sigma-scale-covariance.md` (2026-05-12 18:19): # After Task: Bivariate Sigma Scale Covariance
- `docs/dev-log/after-task/2026-05-12-univariate-mu-sigma-covariance-bridge.md` (2026-05-12 16:41): # After Task: Univariate Mu/Sigma Covariance Bridge
- `docs/dev-log/after-task/2026-05-12-profile-covariance-status-docs.md` (2026-05-12 16:41): # After Task: Profile Covariance Status Docs
- `docs/dev-log/after-task/2026-05-12-mu-sigma-transform-regression-test.md` (2026-05-12 16:41): # After Task: Mu/Sigma Transform Regression Test

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
