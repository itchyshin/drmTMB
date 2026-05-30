# After Task: Family-Surface Admission Plan

## Goal

Use the structured workflow registry to build the distribution-level admission
plan. This is the executable version of the broad “which families are ready,
smoke-only, blocked, or design-only?” table.

## Implemented

Added `phase18_family_surface_workflow_plan()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper filters
the registry to `workflow_lane == "family_surface"` and returns an admission
category, dispatch status, Actions task, workflow helper, audit focus, next
autonomous action, and supervision boundary for each row.

The current plan has eleven rows: six admitted grid rows, one smoke-only NB2
`sigma` row, three blocked rows, and one design-only mixed-response row.
Blocked and design-only rows are visible by default but have no Actions task.

## Mathematical Contract

No likelihood, family registry entry, formula grammar, DGP, simulation result,
or documentation claim changed. This slice only consumes the registry and keeps
family-surface status explicit.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-family-surface-workflow-plan.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-family-surface-workflow-plan.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); p<-e$phase18_family_surface_workflow_plan(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(p[, c("lane_id", "admission_status", "admission_category", "dispatch_status", "actions_task")], row.names=FALSE)'
rg -n "family-surface admission plan|phase18_family_surface_workflow_plan|blocked_design_required|admission_category|Slice 1819" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md
git diff --check
```

The focused registry tests passed. The plan print shows eleven family-surface
rows with admitted, smoke-only, blocked, and design-only states separated. The
scan found the intended helper, test, roadmap, and design references, and `git
diff --check` was clean.

## Tests Of The Tests

The focused tests require the live plan to have eleven rows, with six
`ready_grid`, one `ready_smoke`, three `blocked`, and one `design_only` row.
They also confirm that admitted rows have existing Actions tasks, blocked rows
do not, the NB2 `sigma` row is smoke-only, and `include_blocked = FALSE` drops
blocked and design-only rows.

## Consistency Audit

The helper does not infer family support from neighbouring rows. It keeps
zero-inflated and hurdle count random effects, Student-t `nu` random effects,
ordinal random effects, and mixed-response bivariate families out of dispatch.

## What Did Not Go Smoothly

No model or test failure appeared in this slice. The main care point was to
keep blocked rows visible by default because they answer the user’s “what is
lacking?” question, while still making them non-dispatchable.

## Team Learning

Ada gets a compact distribution-level routing table. Pat and Darwin get clearer
reader-facing evidence boundaries. Grace gets a dispatch-oriented option via
`include_blocked = FALSE`.

## Known Limitations

This slice prints a plan; it does not add new family support, dispatch Actions,
or audit artifacts.

## Next Actions

1. Add dry-run printers for the four workflow plans.
2. Add wrapper targets for random slopes, structured dependence, and
   correlation blocks.
3. Use the family-surface plan to generate a human-facing status table for
   reports.
