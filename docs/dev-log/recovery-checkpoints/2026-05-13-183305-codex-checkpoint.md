# Codex Recovery Checkpoint

Generated: 2026-05-13 18:33:05 MDT
Repository: `/Users/z3437171/Dropbox/Github Local/drmTMB`
Goal: slice 21 corpairs location-class aliases
Suggested next step: commit slice 21, then continue with next safe q4 or phylo hardening slice

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
 M R/methods.R
 M docs/design/01-formula-grammar.md
 M docs/design/20-coscale-correlation-pairs.md
 M docs/dev-log/check-log.md
 M man/corpairs.Rd
 M tests/testthat/test-biv-gaussian.R
?? docs/dev-log/after-task/2026-05-13-slice-21-corpairs-location-class-aliases.md
```

### Changed Files

`git diff --name-status`

```text
M	NEWS.md
M	R/methods.R
M	docs/design/01-formula-grammar.md
M	docs/design/20-coscale-correlation-pairs.md
M	docs/dev-log/check-log.md
M	man/corpairs.Rd
M	tests/testthat/test-biv-gaussian.R
```

`git ls-files --others --exclude-standard`

```text
docs/dev-log/after-task/2026-05-13-slice-21-corpairs-location-class-aliases.md
```

### Diff Stat

`git diff --stat`

```text
 NEWS.md                                     |  2 +-
 R/methods.R                                 | 17 +++++++++++++-
 docs/design/01-formula-grammar.md           |  3 +++
 docs/design/20-coscale-correlation-pairs.md | 10 ++++++++
 docs/dev-log/check-log.md                   | 36 +++++++++++++++++++++++++++++
 man/corpairs.Rd                             |  4 +++-
 tests/testthat/test-biv-gaussian.R          |  2 ++
 7 files changed, 71 insertions(+), 3 deletions(-)
```

### Current Head

`git log -1 --oneline`

```text
42735aa Add q4 and phylo simulation smoke tests
```

## Recent Project Evidence

### Newest `docs/dev-log/check-log.md` Entries (3 sections)

# Check Log

Record meaningful development checks here.

## 2026-05-13 -- Slice 17 q4 profile-target status guard

Scope:

- changed ordinary q4 `theta_re_cov` correlation rows in `profile_targets()` to
  `target_type = "derived"` and `profile_ready = FALSE`;
- kept q4 rows visible for inventory and summaries, but stopped them from being
  treated as simple direct atanh-correlation targets;
- updated the endpoint, assembler, known-limitations, and NEWS wording to say
  ordinary q4 direct profile intervals remain planned.

Checks:

- `Rscript -e 'devtools::test(filter = "profile-targets|biv-gaussian|summary", reporter = "summary")'`:
  passed.
- `git diff --check`: passed.

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


### Newest After-Task Reports

- `docs/dev-log/after-task/2026-05-13-slice-21-corpairs-location-class-aliases.md` (2026-05-13 18:32): # After Task: Slice 21 Corpairs Location-Class Aliases
- `docs/dev-log/after-task/2026-05-13-slice-20-bivariate-q4-phylo-simulate-smoke.md` (2026-05-13 18:28): # After Task: Slice 20 Bivariate Q4 And Phylo Simulate Smoke Tests
- `docs/dev-log/after-task/2026-05-13-slice-19-explicit-random-slope-sd-targets.md` (2026-05-13 18:25): # After Task: Slice 19 Explicit Random-Slope SD Target Reservation
- `docs/dev-log/after-task/2026-05-13-slice-18-direct-sd-family-boundary-guard.md` (2026-05-13 18:19): # After Task: Slice 18 Direct-SD Family Boundary Guard
- `docs/dev-log/after-task/2026-05-13-slice-17-q4-profile-target-status-guard.md` (2026-05-13 18:11): # After Task: Slice 17 q4 Profile-Target Status Guard
- `docs/dev-log/after-task/2026-05-13-slice-16-ordinary-q4-check-drm-diagnostic.md` (2026-05-13 18:07): # After Task: Slice 16 Ordinary q4 check_drm Diagnostic
- `docs/dev-log/after-task/2026-05-13-slice-15-corpair-formula-reservation.md` (2026-05-13 18:00): # After Task: Slice 15 corpair Formula Reservation
- `docs/dev-log/after-task/2026-05-13-slice-14-ordinary-q4-location-scale-covariance.md` (2026-05-13 17:53): # After Task: Slice 14 Ordinary q4 Location-Scale Covariance

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
