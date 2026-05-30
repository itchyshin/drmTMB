# After Task: Workflow Plan Bundle

## Goal

Bundle the four structured workflow plans into one object and one compact count
table so status reports can answer “where are we now?” without manually
combining random-slope, structured-dependence, correlation-block, and
family-surface rows.

## Implemented

Added `phase18_structured_workflow_plan_bundle()` and
`phase18_structured_workflow_plan_counts()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The bundle returns a
registry summary, the four plan tables, and a counts table with row counts,
existing Actions task counts, wrapper targets, ready/source/diagnostic/smoke/
hold counts, blocked rows, and design-only rows.

## Mathematical Contract

No likelihood, parser, formula grammar, profile target, family support, or
simulation evidence changed. This is status plumbing only.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-workflow-plan-bundle.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-workflow-plan-bundle.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); b<-e$phase18_structured_workflow_plan_bundle(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(b$plan_counts, row.names=FALSE)'
rg -n "workflow plan bundle|phase18_structured_workflow_plan_bundle|phase18_structured_workflow_plan_counts|Slice 1820|plan_counts" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-workflow-plan-bundle.md
git diff --check
```

The focused tests passed, the live bundle print returned the expected count
table, the reference scan found the intended Slice 1820 entries, and
`git diff --check` passed.

## Tests Of The Tests

The focused tests assert that the bundle returns all four plan tables and that
counts match the current registry: random slopes 9 rows, structured dependence
7 rows, correlation blocks 6 rows, and family surfaces 11 rows. They also check
existing Actions tasks, wrapper targets, diagnostic rows, blocked rows, and
design-only rows.

## Consistency Audit

The bundle calls the same plan helpers used by the workflow-specific slices, so
it does not introduce a second interpretation of registry state.

## What Did Not Go Smoothly

No model or test failure appeared in this slice.

## Team Learning

Ada gets a single status table for choosing the next slice. Grace gets a quick
view of what can be dispatched through existing Actions tasks versus what needs
a wrapper target. Rose gets the blocked and design-only counts in the same
place as the active lanes.

## Known Limitations

The bundle reports plan state. It does not print a user-facing table, dispatch
Actions, download artifacts, or update support docs automatically.

## Next Actions

1. Add dry-run printers for workflow plans and bundles.
2. Add wrapper targets for random slopes, structured dependence, and
   correlation blocks.
3. Use the bundle count table in future status reports.
