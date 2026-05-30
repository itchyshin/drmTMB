# After Task: Random-Slope Workflow Plan

## Goal

Use the structured workflow registry to build the first concrete workflow plan:
the admitted random-slope lane. This should tell Ada and Grace which rows can
use existing Actions tasks, which rows need an explicit wrapper target, and
which rows remain outside dispatch.

## Implemented

Added `phase18_random_slope_workflow_plan()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper filters
the registry to admitted `workflow_lane == "random_slopes"` rows and returns a
dispatch plan with family, distributional parameter, dependence, q/block,
admission status, dispatch status, Actions task, wrapper helper, audit focus,
next autonomous action, and supervision boundary.

The current plan has nine rows. Eight rows map to existing Phase 18 Actions
tasks through `phase18_actions_main`; the bivariate Gaussian slope-only row is
marked `needs_wrapper_target` because it still names
`needed:random_slope_wrapper`.

## Mathematical Contract

No likelihood, DGP, formula grammar, profile target, simulation grid, or model
surface changed. This slice is a registry consumer. It keeps ordinary random
slopes separate from correlated non-Gaussian slopes, structured slopes,
residual-scale slope covariance, and other blocked or design-only neighbours.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-random-slope-workflow-plan.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-random-slope-workflow-plan.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); p<-e$phase18_random_slope_workflow_plan(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(p[, c("lane_id", "admission_status", "dispatch_status", "actions_task", "workflow_helper")], row.names=FALSE)'
rg -n "random-slope workflow plan|phase18_random_slope_workflow_plan|needs_wrapper_target|source_test_audit|Slice 1816" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md
git diff --check
```

The focused registry tests passed. The plan print shows nine admitted rows,
including eight existing Actions tasks and one needed wrapper target. The scan
found the intended helper, test, roadmap, and design references, and `git diff
--check` was clean.

## Tests Of The Tests

The focused tests require the live registry plan to have nine admitted
random-slope rows, no blocked/design/diagnostic rows, and the bivariate
Gaussian slope-only row marked as a needed wrapper target. They also inject a
mock blocked random-slope row and confirm that the helper excludes it.

## Consistency Audit

The wrapper reads registry status; it does not infer fitted status from family
similarity. `ready_source_test` rows are labelled as source-test audit rows
rather than grid evidence. The helper can omit needed-wrapper rows when a caller
wants only rows that already map to named Actions tasks.

## What Did Not Go Smoothly

No model or test failure appeared in this slice. The main judgment call was to
keep the bivariate Gaussian slope-only row in the default plan but mark it as
`needs_wrapper_target`, so it remains visible without pretending that an
Actions task exists.

## Team Learning

Ada now has a concrete ordering primitive for random-slope work. Grace can
distinguish existing-task rows from wrapper-target rows. Rose can audit that
blocked rows stay out of dispatch even if someone appends them to the registry.

## Known Limitations

This slice prints a plan; it does not yet dispatch the wrapper target, trigger
Actions, download artifacts, or promote source-tested rows to artifact lanes.

## Next Actions

1. Add a dry-run printer or wrapper command for the random-slope plan.
2. Add the bivariate Gaussian slope-only wrapper target if that row is the next
   chosen random-slope action.
3. Add the structured-dependence workflow plan for `phylo()`, `spatial()`,
   `animal()`, and `relmat()`.
