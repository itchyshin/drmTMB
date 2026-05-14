# Codex Recovery Checkpoint

Generated: 2026-05-13 18:07:27 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: ordinary q4 check_drm diagnostic
Suggested next step: commit slice 16, then choose q4 profile-target hardening or next safe Family B structured-SD slice

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
 M R/check.R
 M docs/design/16-phylo-spatial-common-math.md
 M docs/dev-log/check-log.md
 M docs/dev-log/known-limitations.md
 M man/check_drm.Rd
 M tests/testthat/test-check-drm.R
?? docs/dev-log/after-task/2026-05-13-slice-16-ordinary-q4-check-drm-diagnostic.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/check.R
M	docs/design/16-phylo-spatial-common-math.md
M	docs/dev-log/check-log.md
M	docs/dev-log/known-limitations.md
M	man/check_drm.Rd
M	tests/testthat/test-check-drm.R
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-13-slice-16-ordinary-q4-check-drm-diagnostic.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                     |   2 +-
 R/check.R                                   | 242 +++++++++++++++++++++++++++-
 docs/design/16-phylo-spatial-common-math.md |  10 +-
 docs/dev-log/check-log.md                   |  22 +++
 docs/dev-log/known-limitations.md           |   9 +-
 man/check_drm.Rd                            |  16 +-
 tests/testthat/test-check-drm.R             | 102 ++++++++++++
 7 files changed, 382 insertions(+), 21 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
3c0e24f Reserve corpair formula syntax
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Slice 16 ordinary q4 check_drm diagnostic

Scope:

- added a `biv_q4_random_effect_covariance` row to `check_drm()` for ordinary
  all-four bivariate q4 covariance blocks;
- reports q4 block count, group count, minimum group replication, singleton
  groups, location SD ratio, log-`sigma` SD, maximum absolute latent
  correlation, and the active correlation boundary;
- added tests for the normal diagnostic row, near-boundary latent correlations,
  and tiny log-`sigma` component SDs.

Checks:

- `Rscript -e 'devtools::test(filter = "check-drm", reporter = "summary")'`:
  passed.
- `Rscript -e 'devtools::document()'`: passed and regenerated
  `man/check_drm.Rd`.
- `Rscript -e 'devtools::test(filter = "check-drm|biv-gaussian|summary|corpairs", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.

## 2026-05-13 -- Slice 15 corpair formula reservation

Scope:

- added exported `corpair()` formula marker documentation and pkgdown reference
  indexing;
- taught `drm_formula()` to parse
  `corpair(group, block = "...", class = "...") ~ x` as planned latent
  random-effect correlation syntax;
- made `drmTMB()` reject parsed `corpair()` formulas clearly, separating future
  predictor-dependent latent correlations from residual `rho12` and the
  `corpairs()` extractor.

Checks:

- `Rscript -e 'devtools::document()'`: passed and wrote `man/corpair.Rd` plus
  the `NAMESPACE` export.
- `Rscript -e 'devtools::test(filter = "package-skeleton|biv-gaussian", reporter = "summary")'`:
  passed.
- `Rscript -e 'pkgdown::check_pkgdown()'`: passed with no problems found.
- `git diff --check`: passed.

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


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-16-ordinary-q4-check-drm-diagnostic.md` (2026-05-13 18:07): # After Task: Slice 16 Ordinary q4 check_drm Diagnostic
- `docs/dev-log/after-task/2026-05-13-slice-15-corpair-formula-reservation.md` (2026-05-13 18:00): # After Task: Slice 15 corpair Formula Reservation
- `docs/dev-log/after-task/2026-05-13-slice-14-ordinary-q4-location-scale-covariance.md` (2026-05-13 17:53): # After Task: Slice 14 Ordinary q4 Location-Scale Covariance
- `docs/dev-log/after-task/2026-05-13-bivariate-direct-location-sd-formulas.md` (2026-05-13 17:26): # After Task: Bivariate Direct Location SD Formulas
- `docs/dev-log/after-task/2026-05-13-slice-9-phylogenetic-reader-path.md` (2026-05-13 16:40): # After Task: Slice 9 Phylogenetic Reader Path
- `docs/dev-log/after-task/2026-05-13-slice-8-phylogenetic-profile-smoke.md` (2026-05-13 16:40): # After Task: Slice 8 Phylogenetic Profile Smoke
- `docs/dev-log/after-task/2026-05-13-slice-7-phylogenetic-summary-covariance.md` (2026-05-13 16:40): # After Task: Slice 7 Phylogenetic Summary Covariance
- `docs/dev-log/after-task/2026-05-13-slice-6-phylogenetic-profile-targets.md` (2026-05-13 16:40): # After Task: Slice 6 Phylogenetic Profile Targets

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
