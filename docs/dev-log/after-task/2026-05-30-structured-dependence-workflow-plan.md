# After Task: Structured-Dependence Workflow Plan

## Goal

Use the structured workflow registry to build a concrete workflow plan for
`phylo()`, `spatial()`, `animal()`, and `relmat()` rows. The plan should keep
Gaussian wrapper targets, count formal-admission rows, held smoke rows, and
diagnostic-only rows visible but not interchangeable.

## Implemented

Added `phase18_structured_dependence_workflow_plan()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper filters
the registry to `workflow_lane == "structured_dependence"`, excludes blocked
and design-only rows, and labels each remaining row as a wrapper target,
formal-admission task, hold-smoke audit, diagnostic audit, or other supported
dispatch state.

The current plan has seven rows: four Gaussian wrapper targets for
`phylo()`, `spatial()`, `animal()`, and `relmat()`; one Poisson `phylo()` q=1
formal-admission task; one NB2 `phylo()` q=1 hold-smoke audit row; and one
count q=1 `spatial()`/`animal()`/`relmat()` diagnostic audit row.

## Mathematical Contract

No likelihood, covariance parameterization, formula grammar, DGP, profile
target, or simulation evidence changed. This slice consumes the registry and
keeps structured Gaussian rows separate from count q=1 formal, held, and
diagnostic rows. It does not open non-Gaussian structured slopes, labelled q=2
or q=4 covariance, simultaneous structured count types, or recovery claims.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-structured-dependence-workflow-plan.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-structured-dependence-workflow-plan.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); p<-e$phase18_structured_dependence_workflow_plan(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(p[, c("lane_id", "admission_status", "dispatch_status", "actions_task", "workflow_helper")], row.names=FALSE)'
rg -n "structured-dependence workflow plan|phase18_structured_dependence_workflow_plan|formal_admission_task|hold_smoke_audit|diagnostic_audit|Slice 1817" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md
git diff --check
```

The focused registry tests passed. The plan print shows seven structured
dependence rows with wrapper, formal-admission, hold-smoke, and diagnostic
states separated. The scan found the intended helper, test, roadmap, and design
references, and `git diff --check` was clean.

## Tests Of The Tests

The focused tests require the live plan to have seven rows, with exactly four
`ready_grid` Gaussian wrapper targets, one `smoke_formal_admission` Poisson
row, one `hold_smoke_only` NB2 row, and one `diagnostic_only` count row. They
also confirm that `include_held = FALSE` drops held and diagnostic rows and
that a mock blocked structured-dependence row is excluded.

## Consistency Audit

The helper does not infer that a held or diagnostic count row is ready because
it shares the structured-dependence lane. It uses explicit status labels:
`formal_admission_task`, `hold_smoke_audit`, and `diagnostic_audit`.

## What Did Not Go Smoothly

No model or test failure appeared in this slice. The main care point was to
make held and diagnostic count rows visible by default, because they are useful
for audit planning, while giving callers `include_held = FALSE` for stricter
dispatch plans.

## Team Learning

Grace gets a clear distinction between wrapper targets and existing Actions
tasks. Rose gets an explicit place to check that held and diagnostic rows do not
become recovery evidence. Ada can now move from random slopes to structured
dependence without re-reading the whole capability table.

## Known Limitations

This slice prints a plan; it does not yet implement the
`structured_dependence_wrapper`, dispatch Actions, download artifacts, or close
the count q=1 hold/diagnostic gates.

## Next Actions

1. Add a dry-run printer for structured-dependence workflow plans.
2. Add the structured-dependence wrapper target for the four Gaussian ready-grid
   rows.
3. Add the correlation-block workflow plan for residual `rho12`, q=2
   `corpairs()`, and q=4 diagnostic rows.
