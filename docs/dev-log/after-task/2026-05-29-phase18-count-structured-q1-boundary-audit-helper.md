# Phase 18 Count Structured q1 Boundary Audit Helper

Date: 2026-05-29

## Purpose

This slice turns the count structured q=1 boundary gate into a repeatable
artifact audit. The immediate reader is the next contributor deciding whether a
larger ordinary Poisson/NB2 `spatial()`, `animal()`, or `relmat()` q=1 `mu`
pilot can be proposed after a smoke or diagnostic run.

## Implemented

- Added `sd_structured` to count structured q=1 replicate rows.
- Added `phase18_audit_count_structured_q1_boundary_gate()` for reading a
  count structured q=1 grid directory and applying the gate.
- Added `phase18_count_structured_q1_boundary_gate_summary()` and helpers for
  fitted-replicate collapse, overall rates, condition-level rates, gate checks,
  warning-ledger review, and the final decision row.
- Added tests for read-back audit behavior, failed gate triggers, clean gate
  behavior, and older replicate tables that do not yet contain
  `sd_structured`.
- Updated ROADMAP, the count structured q=1 design note, the Phase 18
  simulation programme, the simulation README, and the check log.

## Boundary

This does not run a larger grid, widen the model surface, change likelihood
parameterization, add formula syntax, include `count_structured_q1` in
`task = "all"`, or make recovery or coverage claims. A clean helper decision
means `propose_next_pilot`; formal recovery still needs a separate design note,
replicate count, MCSE target, interval policy, and runtime budget.

## Validation

```sh
air format inst/sim/fit/sim_summarise_count_structured_q1.R inst/sim/run/sim_write_count_structured_q1_grid.R tests/testthat/test-phase18-count-structured-q1.R ROADMAP.md docs/design/134-phase-18-count-structured-q1-artifacts-slices-1721-1728.md docs/design/41-phase-18-simulation-programme.md inst/sim/README.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-count-structured-q1-boundary-audit-helper.md
Rscript --vanilla -e 'devtools::test(filter = "phase18-count-structured-q1")'
Rscript --vanilla -e 'devtools::test(filter = "phase18-actions-runner|phase18-count-structured-q1")'
Rscript --vanilla -e "pkgdown::check_pkgdown()"
gh issue list --repo itchyshin/drmTMB --state open --search 'count_structured_q1 boundary audit OR count structured q1 audit helper OR count structured q1 gate helper' --limit 20 --json number,title,state,url,labels
rg -n 'count structured q1.*formal recovery|formal recovery.*count structured q1|count structured q1.*coverage claims|count structured q1.*coverage claim|count structured q1.*all clean|zero-inflated.*count structured q1.*(implemented|supported|admitted)|structured count slopes.*(implemented|supported|admitted)|count structured q1.*task = "all"|task = "all".*count_structured_q1' README.md NEWS.md ROADMAP.md docs/design inst/sim tests/testthat .github/workflows --glob '!docs/dev-log/**'
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.

## Member-Group Review

- Ada kept the change on the existing artifact lane.
- Curie checked fitted-replicate counting and condition-level rates.
- Fisher checked that the helper does not promote formal recovery or coverage.
- Grace checked tests and documentation hygiene.
- Rose checked roadmap and design-note visibility for future handoff.

No spawned subagents were running.
