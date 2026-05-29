# Phase 18 Count Structured q1 Next Pilot Spec

Date: 2026-05-29

## Purpose

This slice specifies the next diagnostic pilot for ordinary Poisson/NB2 q=1
`spatial()`, `animal()`, and `relmat()` count `mu` intercepts after the
boundary-gate helper returned `propose_next_pilot` for the post-diagnostic
smoke artifact.

## Implemented

- Added `docs/design/135-phase-18-count-structured-q1-next-pilot-slices-1743-1750.md`.
- Specified the 24-cell condition table, 10 replicates per cell, and 240 fitted
  replicate target.
- Recorded the exact manual Actions dispatch inputs.
- Kept `profile_parameters` empty so the pilot measures fit stability and
  boundary behavior without claiming structured-SD coverage.
- Required the boundary-gate helper audit and condition-level reporting before
  any larger formal pilot is proposed.

## Boundary

This does not dispatch a grid, widen model support, add formula syntax, include
`count_structured_q1` in `task = "all"`, or claim recovery or coverage. It is a
pre-run design note.

## Validation

```sh
air format docs/design/135-phase-18-count-structured-q1-next-pilot-slices-1743-1750.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-next-pilot-spec.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.

## Member-Group Review

- Ada kept the slice to a pre-run design.
- Curie checked replicate counts and gate-audit requirements.
- Fisher checked interval and recovery-claim boundaries.
- Grace checked documentation hygiene.
- Rose checked durable handoff wording.

No spawned subagents were running.
