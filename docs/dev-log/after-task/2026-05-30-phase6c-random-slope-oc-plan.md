# After Task: Phase 6c Random-Slope Operating-Characteristic Plan

## Goal

Advance #446 by making the random-slope accuracy, coverage, and power agenda
machine-readable without claiming operating-characteristic evidence that has
not yet been produced by `drmTMB` simulations.

## Implemented

- `phase18_random_slope_operating_characteristic_plan()` now derives a planning
  table from the Phase 18 structured workflow registry.
- The table records the admitted random-slope lane, family, route, `dpar`,
  dependence, existing Actions task, accuracy status, coverage status, power
  status, minimum estimands, and boundary note.
- Source-test-only rows can be omitted with `include_source_test = FALSE`.
- Coverage and power remain `planned_not_estimated` for every row.

## Mathematical Contract

This is ADEMP-facing planning only. It does not change likelihood code, formula
grammar, fitted support, simulation DGPs, Actions task dispatch, or registry
admission status.

## Files Changed

- `inst/sim/run/sim_phase18_structured_workflow_registry.R`
- `tests/testthat/test-phase18-structured-workflow-registry.R`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`. It included the
structured-workflow registry test file, printing the new plan table from the
current CSV registry, adjacent random-slope grid-writer smoke tests, source
scans, and `git diff --check`.

## Tests Of The Tests

The new tests check row count, required columns, exclusion of
blocked/design-only/diagnostic rows, planned-only coverage and power status,
non-empty estimands and boundary notes, and the five-row view that omits
source-test-only lanes.

## Consistency Audit

The design docs and helper agree that the plan is not a simulation result. It
names accuracy, coverage, and power as future operating-characteristic targets
and keeps broad claims below the evidence line until replicate grids,
intervals, MCSE targets, and artifact audits exist.

## GitHub Issue Maintenance

This slice advances #446 and should be linked from the Phase 6c sprint issue
and PR after the commit is pushed.

## What Did Not Go Smoothly

The registry already mixes grid-ready rows and source-test rows. The helper
therefore needed the `include_source_test` switch so reports can show the full
planning table or only the rows with existing artifact routes.

## Team Learning

Operating-characteristic planning needs three columns, not one: accuracy,
coverage, and power. Keeping all power cells planned-only prevents a smoke
artifact from being misread as a hypothesis-test or sample-size claim.

## Known Limitations

No grids were run, no MCSE target was chosen, and no null/alternative contrast
was defined for power. Those belong in follow-up simulation design issues.

## Next Actions

Use this table to choose the first ADEMP sheets and replicate grids for
random-slope recovery, coverage, and power.
