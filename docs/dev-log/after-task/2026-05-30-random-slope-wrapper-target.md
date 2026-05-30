# After Task: Random-Slope Wrapper Target

## Goal

Turn the one remaining random-slope wrapper row into an explicit target plan
that names what evidence exists, what helper is missing, and why no dispatch
should happen yet.

## Implemented

Added `phase18_random_slope_wrapper_target_plan()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper extracts
rows from `phase18_random_slope_workflow_plan()` whose `workflow_helper` is
`random_slope_wrapper`, then labels the current
`bivariate_gaussian_slope_only` row as `needs_simulation_helper` with dispatch
mode `no_dispatch_until_helper_lands`.

The target plan records the source-test evidence in
`tests/testthat/test-biv-gaussian.R` and names
`phase18_run_bivariate_gaussian_mu_slope_smoke()` as the required next helper.

## Mathematical Contract

No likelihood, parser, formula grammar, family support, interval target, or
simulation result changed. This slice only prevents an admitted source-tested
row from being mistaken for an Actions-dispatchable artifact lane.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-random-slope-wrapper-target.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-random-slope-wrapper-target.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e 'e<-new.env(); source("inst/sim/run/sim_phase18_structured_workflow_registry.R", local=e); p<-e$phase18_random_slope_wrapper_target_plan(e$phase18_read_structured_workflow_registry("inst/sim/registry/phase18_structured_workflow_registry.csv")); print(p[, c("lane_id", "target_status", "required_helper", "dispatch_mode")], row.names=FALSE)'
rg -n "random-slope wrapper target|phase18_random_slope_wrapper_target_plan|phase18_run_bivariate_gaussian_mu_slope_smoke|no_dispatch_until_helper_lands|Slice 1822" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-random-slope-wrapper-target.md
git diff --check
```

The focused tests passed, the printed target table showed the single
bivariate Gaussian slope-only row, the reference scan found the intended Slice
1822 entries, and `git diff --check` passed.

## Tests Of The Tests

The new test asserts that the target plan has exactly one row, that the row is
`bivariate_gaussian_slope_only`, that it is marked
`needs_simulation_helper`, and that `actions_task` remains `NA`.

## Consistency Audit

The target helper consumes `phase18_random_slope_workflow_plan()`, so it does
not create a second source of truth for random-slope admission status.

## What Did Not Go Smoothly

The source route is implemented in ordinary package tests, but no Phase 18
simulation helper exists yet. This slice records that boundary rather than
dispatching the source-tested model through a neighbouring workflow.

## Team Learning

Ada gets a precise next implementation target. Grace gets an explicit
no-dispatch status until the simulation helper and artifact path land. Rose
gets source evidence and required-helper wording in the same row, which reduces
status drift.

## Known Limitations

This is not the bivariate Gaussian `mu1`/`mu2` slope-only smoke runner. It is
the target-plan preflight for that runner.

## Next Actions

1. Add `phase18_run_bivariate_gaussian_mu_slope_smoke()`.
2. Add a grid/artifact writer once the smoke helper has focused tests.
3. Only then convert the wrapper target to an Actions-dispatchable lane.
