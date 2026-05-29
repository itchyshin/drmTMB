# Phase 18 Count Structured q1 Boundary Gate

Date: 2026-05-29

## Purpose

This slice turns the post-diagnostic `count_structured_q1` smoke findings into
a pre-grid rule. The immediate reader is the next package contributor deciding
whether to dispatch a larger count structured q=1 pilot for ordinary Poisson
and NB2 `spatial()`, `animal()`, or `relmat()` `mu` intercepts.

## Implemented

- Added Slice 1737-1738 to the count structured q=1 design note and ROADMAP.
- Defined fitted replicates, not parameter rows, as the counting unit for
  fit-level diagnostics.
- Required larger pilots to report `fit_diagnostic_status`,
  `sd_boundary_status`, `hessian_status`, and warning-ledger rates overall and
  by condition.
- Added stop triggers for Hessian warnings, SD-boundary warnings, and
  unexplained optimizer or non-finite warning messages.
- Updated the Phase 18 simulation programme and `inst/sim/README.md` so the
  boundary gate is visible before new grid work starts.

## Boundary

This is design evidence only. It does not run a larger grid, change likelihood
code, add formula syntax, promote `count_structured_q1` to `task = "all"`, or
claim recovery or coverage evidence.

## Validation

```sh
air format ROADMAP.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-boundary-gate.md
Rscript --vanilla -e "pkgdown::check_pkgdown()"
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 boundary gate OR count structured q1 boundary gate OR count structured q1 recovery' --limit 20 --json number,title,state,url,labels
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.

## Member-Group Review

- Ada kept this as a small planning slice after the merged smoke audit.
- Curie checked that the gate counts fitted replicates, not repeated parameter
  rows.
- Fisher kept the rule from becoming a recovery or coverage claim.
- Grace checked documentation hygiene.
- Rose checked that the roadmap and simulation programme carry the same
  boundary before future agents dispatch larger grids.

No spawned subagents were running.
