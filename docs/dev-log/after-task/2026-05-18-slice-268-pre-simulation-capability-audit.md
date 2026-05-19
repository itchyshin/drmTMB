# After Task: Slice 268 Pre-Simulation Capability Audit

## Task

Add one pre-simulation capability table that says which major model classes are
implemented, tested, planned, or unsupported before Phase 18 grids admit them.

## What Changed

- Added a Slice 268 capability audit to
  `docs/design/46-pre-simulation-readiness-matrix.md`.
- Covered Gaussian, non-Gaussian, shape, inflation, bivariate, random-slope,
  meta-analysis, phylogenetic, spatial, animal, and `relmat()` model classes in
  one table.
- Separated "implemented" parser or likelihood status from "tested" evidence
  status, so planned markers such as `animal()` and `relmat()` are not mistaken
  for fitted models.
- Updated the Phase 18 simulation programme, roadmap, NEWS, check log, and
  after-task trail, with the recovery checkpoint recorded for handoff.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/after-task/2026-05-18-slice-268-pre-simulation-capability-audit.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/recovery-checkpoints/2026-05-18-183851-codex-checkpoint.md`

## Checks

- `air format NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-268-pre-simulation-capability-audit.md docs/dev-log/recovery-checkpoints/2026-05-18-183851-codex-checkpoint.md`
- `rg -n "Slice 268|Capability Audit|implemented, tested, planned, and unsupported|animal\\(\\)|relmat\\(\\)|Phase 18 admission" NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md`
- `rg -n "animal.*fitted|relmat.*fitted|animal.*implemented|relmat.*implemented|phylogenetic slopes.*implemented|spatial.*sigma.*implemented|non-Gaussian.*sigma random effects.*implemented" docs/design/46-pre-simulation-readiness-matrix.md ROADMAP.md NEWS.md`
  returned only negative, planned, or support-boundary rows, not fitted
  `animal()` or `relmat()` claims.
- `Rscript -e "pkgdown::check_pkgdown()"`
- `git diff --check`

## Role Review

- Ada kept the slice to a status audit rather than starting new simulation
  grids.
- Pat checked that a Phase 18 report writer can see which model class to use
  next.
- Fisher kept "tested" tied to focused evidence and did not let parser markers
  count as simulation evidence.
- Grace checked pkgdown and diff hygiene before closure.
- Rose checked stale capability claims, especially for animal, `relmat()`,
  phylogenetic slopes, spatial scale, and non-Gaussian scale random effects.

## Known Limits

- This slice does not add new tests, likelihood code, simulation helpers, or
  fitted model classes.
- The table summarizes existing evidence. When any planned class becomes
  fitted, the table should be updated in the same PR as the implementation,
  tests, examples, and after-task report.
