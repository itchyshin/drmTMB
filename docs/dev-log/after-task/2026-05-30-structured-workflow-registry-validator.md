# After Task: Structured Workflow Registry Validator

## Goal

Make the structured workflow registry executable before adding wrappers for
random slopes, structured dependence, q=2/q=4 correlation blocks, and
family-surface admission.

## Implemented

Added `inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper
finds the registry CSV, reads it, validates its columns and controlled
vocabularies, summarizes rows by lane and status, filters rows by lane/status/
dependence/family group, and returns admitted rows for wrapper dispatch.

The Actions runner now exposes `phase18_actions_task_choices()`, so the
registry validator can compare `existing_actions_task` values with the same
task names used by manual GitHub Actions dispatch.

## Mathematical Contract

No likelihood, formula grammar, DGP, parameterization, profile target, or
artifact status changed. The new checks are deliberately administrative:
blocked and design-only rows must not name an Actions task, q=4 diagnostic rows
remain diagnostic, and admitted filters include only rows whose status is
workflow-dispatchable.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `inst/sim/run/sim_run_actions_cell.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-structured-workflow-registry-validator.md`

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-structured-workflow-registry-validator.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e "devtools::test(filter = 'phase18-actions-runner', reporter = 'summary')"
rg -n "structured workflow registry validator|phase18_read_structured_workflow_registry|phase18_validate_structured_workflow_registry|phase18_structured_workflow_registry_summary|phase18_actions_task_choices|Slice 1815" inst/sim/run tests/testthat docs/design ROADMAP.md docs/dev-log/check-log.md
git diff --check
```

The registry helper and Actions runner focused suites passed. The scan found
the intended helper, test, roadmap, and design references, and `git diff
--check` was clean.

## Tests Of The Tests

The focused tests cover the happy path and the failure modes that would cause
bad autonomous work: duplicated lane IDs, unknown Actions tasks, and blocked
rows that try to name a dispatchable task. Another test sources the Actions
runner and verifies that the registry helper uses the same task choices.

## Consistency Audit

The validator keeps status vocabulary explicit rather than inferring status
from neighbouring rows. This preserves the current boundary between fitted,
diagnostic-only, blocked, and design-only surfaces. It also keeps residual
`rho12`, group/structured `corpairs()` rows, q=4 diagnostic rows, and known
sampling covariance `V` separate.

## What Did Not Go Smoothly

The first focused test run caught two small implementation details. The test
now treats `anyDuplicated()` as an integer check, and the summary helper drops
empty lane/status combinations instead of returning `NA` counts.

## Team Learning

Grace gets the failure-closed guard for future Actions wrappers. Rose gets a
single place to spot accidental status promotion. Ada can now order the next
slices from registry filters rather than another hand-maintained checklist.

## Known Limitations

This slice does not yet dispatch a workflow lane. The next safe slice is a
random-slope wrapper that reads admitted `workflow_lane == "random_slopes"`
rows and prints or dispatches only existing, named tasks.

## Next Actions

1. Add the random-slope workflow wrapper.
2. Add the structured-dependence wrapper for `phylo()`, `spatial()`,
   `animal()`, and `relmat()`.
3. Add the correlation-block wrapper that keeps residual `rho12`, q=2 direct
   rows, and q=4 diagnostic rows apart.
