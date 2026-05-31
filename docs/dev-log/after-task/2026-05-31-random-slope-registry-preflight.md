# After Task: Random-Slope Registry Preflight

## Goal

Add the first #59 follow-through helper from the #446 Phase 6c simulation plan:
a dry preflight that prints the random-slope registry rows and fails before any
pilot dispatch if required gate fields are missing.

## Implemented

Added `phase18_random_slope_registry_preflight()`,
`phase18_format_random_slope_registry_preflight()`, and
`phase18_print_random_slope_registry_preflight()` to
`inst/sim/run/sim_phase18_structured_workflow_registry.R`.

The helper filters `workflow_lane == "random_slopes"`, verifies non-empty
`admission_status`, `existing_actions_task`, and `supervision_boundary` values,
then returns dry-run checks and a row table with dispatch status, Actions task,
workflow helper, audit focus, next action, and supervision boundary.

## Mathematical Contract

No likelihood, formula grammar, TMB parameterization, or simulation DGP changed.
The helper only inspects the registry and plan metadata before diagnostic
pilots run.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/148-phase6c-random-slope-simulation-plan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-31-random-slope-registry-preflight.md`
- `inst/sim/README.md`
- `ROADMAP.md`

No parser, likelihood, TMB, formula-grammar, NEWS, pkgdown-navigation, or
missing-data files changed.

## Checks Run

```sh
air format inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/148-phase6c-random-slope-simulation-plan.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-31-random-slope-registry-preflight.md inst/sim/README.md ROADMAP.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-structured-workflow-registry', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
rg -n 'phase18_random_slope_registry_preflight|phase18_print_random_slope_registry_preflight|Random-slope registry preflight|workflow_lane == "random_slopes"|No simulations, GitHub Actions jobs|supervision_boundary' inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat/test-phase18-structured-workflow-registry.R docs/design/143-phase-18-structured-workflow-registry.md docs/design/148-phase6c-random-slope-simulation-plan.md docs/dev-log/after-task/2026-05-31-random-slope-registry-preflight.md docs/dev-log/check-log.md inst/sim/README.md ROADMAP.md
rg -n 'random-slope registry preflight.*(dispatches|runs simulations|promotes|recovery claim|coverage claim|power claim)|phase18_random_slope_registry_preflight.*(dispatches|runs simulations|promotes)' inst/sim/run/sim_phase18_structured_workflow_registry.R tests/testthat docs/design inst/sim/README.md ROADMAP.md
git diff --check
```

Results:

- `air format` completed with no changes needed after the final edit.
- Focused `devtools::test()` passed for
  `phase18-structured-workflow-registry`.
- `pkgdown::check_pkgdown()` reported no problems.
- The positive scan found the helper, printer, dry-run wording, random-slope
  lane filter, and `supervision_boundary` gate in the source and status files.
- The stale-claim scan returned no matches in the helper, tests, design notes,
  simulation README, or roadmap for preflight wording that would claim
  simulation dispatch, GitHub Actions dispatch, status promotion, recovery,
  coverage, or power support.
- `git diff --check` passed.

## Tests Of The Tests

The focused registry tests now cover the passing preflight, the formatted
dry-run output, and a fail-closed path where a random-slope row has an empty
`supervision_boundary`.

## Consistency Audit

The helper keeps random-slope preflight separate from simulation dispatch. It
prints rows and statuses, but it does not run local simulations, dispatch
GitHub Actions, write artifacts, alter admission status, or make recovery,
coverage, or power claims.

## GitHub Issue Maintenance

#59 remains the broad Phase 18 simulation issue for this helper. #446 is
already closed by the simulation plan and is referenced only as the source of
the registry-preflight run-order requirement. No new issue was opened.

## What Did Not Go Smoothly

The registry already had most of the lower-level validation and random-slope
planning pieces, so the first implementation pass needed to stay small and not
duplicate the full structured-workflow dry run.

## Team Learning

Grace: dry-run helpers should state plainly that they do not dispatch Actions.
Curie: preflight tests need both a passing table and a failing required-field
path. Rose: capability gates should update the roadmap without claiming a pilot
has run.

## Known Limitations

This slice does not implement a diagnostic pilot, a new Actions task, a DGP, a
summariser, or a report. It also does not promote any random-slope surface
beyond its existing registry status.

## Next Actions

1. Use the preflight output to choose the first diagnostic pilot row.
2. Keep large final power or coverage grids blocked until a diagnostic pilot
   passes stop rules and artifact checks.
