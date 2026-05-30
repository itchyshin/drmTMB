# After Task: Correlation-Block Workflow Plan

## Goal

Use the structured workflow registry to build a concrete correlation-block
workflow plan. The plan should keep residual `rho12`, q=2 direct or
layer-specific `corpairs()` rows, q=4 diagnostic rows, and blocked count
labelled covariance apart.

## Implemented

Added `phase18_correlation_block_workflow_plan()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper filters
the registry to `workflow_lane == "correlation_blocks"`, excludes blocked and
design-only rows, and returns dispatch status, interval policy, Actions task,
wrapper helper, and audit focus for each remaining row.

The current plan has six rows. Three direct rows map to
`interval_heavy_summary`: Gaussian `mu`/`sigma` q=2 mean-scale covariance,
residual `rho12`, and selected bivariate Gaussian q=2 `corpairs()` rows.
Structured Gaussian q=2 is a wrapper target. The two q=4 rows are diagnostic
wrapper targets with `interval_policy = "q4_derived_interval_unavailable"`.

## Mathematical Contract

No likelihood, extractor, profile target, covariance parameterization, DGP, or
simulation evidence changed. This slice is workflow plumbing. It explicitly
prevents q=4 derived correlations from being treated as interval-ready and
keeps residual `rho12` separate from group and structured `corpairs()` rows.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-correlation-block-workflow-plan.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-correlation-block-workflow-plan.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); p<-e$phase18_correlation_block_workflow_plan(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(p[, c("lane_id", "admission_status", "dispatch_status", "interval_policy", "actions_task", "workflow_helper")], row.names=FALSE)'
rg -n "correlation-block workflow plan|phase18_correlation_block_workflow_plan|q4_derived_interval_unavailable|diagnostic_wrapper_target|interval_policy|Slice 1818" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md
git diff --check
```

The focused registry tests passed. The plan print shows six non-blocked rows,
including three direct interval-heavy rows, one structured q=2 wrapper target,
and two q=4 diagnostic wrapper targets. The scan found the intended helper,
test, roadmap, and design references, and `git diff --check` was clean.

## Tests Of The Tests

The focused tests require the live plan to have six rows, no blocked/design
rows, direct residual `rho12` policy for the residual row, q=4 derived-interval
unavailable policy for both q=4 rows, a wrapper target for structured q=2, and
no q=4 rows when `include_diagnostic = FALSE`.

## Consistency Audit

The helper reads registry status rather than inferring support from nearby
Gaussian rows. It excludes the blocked count labelled q=2/q=4 covariance row
and keeps q=4 rows visible as diagnostics rather than interval targets.

## What Did Not Go Smoothly

No model or test failure appeared in this slice. The main design point was to
add `interval_policy` rather than relying only on `dispatch_status`, because
q=4 rows can be useful diagnostic wrapper targets while still being
interval-unavailable.

## Team Learning

Grace gets an executable interval-policy guard. Rose gets a check against q=4
status drift. Fisher and Noether get a clearer boundary between residual
`rho12`, q=2 direct rows, and derived q=4 quantities.

## Known Limitations

This slice prints a plan; it does not implement the `correlation_block_wrapper`,
derive q=4 intervals, dispatch Actions, or audit downloaded artifacts.

## Next Actions

1. Add a dry-run printer for correlation-block workflow plans.
2. Add the `correlation_block_wrapper` target for structured q=2 and diagnostic
   q=4 reporting.
3. Add the family-surface admission workflow plan.
