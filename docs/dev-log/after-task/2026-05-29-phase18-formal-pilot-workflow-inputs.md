# After-Task Report: Phase 18 Formal-Pilot Workflow Inputs

Date: 2026-05-29

## Task

Make the manual Phase 18 simulation workflow match the Slice 1763-1770 count
structured q1 formal-pilot dispatch contract before dispatching the run from
`main`.

## Changes

- `.github/workflows/phase18-simulation-grid.yaml` now exposes manual
  `profile_level` and `require_complete` inputs.
- The workflow passes both inputs to `inst/sim/run/sim_run_actions_cell.R`
  instead of hard-coding `--require-complete=false` and relying on the runner's
  default `profile_level`.
- The runner dry-run plan prints `require_complete`, which makes pre-dispatch
  evidence visible in focused tests.
- `tests/testthat/test-phase18-actions-runner.R` now checks the
  count-structured q1 dry-run and workflow file for the new input and
  pass-through contract.
- `ROADMAP.md` and `docs/design/41-phase-18-simulation-programme.md` record
  Slices 1771-1772 as operational workflow plumbing only.

## Validation

```sh
air format .github/workflows/phase18-simulation-grid.yaml inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-formal-pilot-workflow-inputs.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-actions-runner', reporter = 'summary')"
git diff --check
rg -n "profile_level|require_complete|--profile-level|--require-complete" .github/workflows/phase18-simulation-grid.yaml inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R docs/design/139-phase-18-count-structured-q1-formal-pilot-design-slices-1763-1770.md
```

Results:

- The focused `phase18-actions-runner` suite passed.
- `git diff --check` was clean.
- The contract grep showed the formal-pilot design command, workflow inputs,
  pass-through flags, and test assertions use the same `profile_level` and
  `require_complete` names.

## Boundaries

This slice does not dispatch the formal pilot, audit any artifact, or add
recovery, coverage, bootstrap, low-SD, zero-inflated, structured-slope,
labelled-covariance, or structured NB2 `sigma` evidence.

## Standing Review

- Ada kept the change to the workflow contract needed by the formal-pilot
  design.
- Grace required a focused workflow test before dispatching Actions work.
- Curie made the dry-run evidence show `require_complete`.
- Fisher kept the change separate from simulation-evidence claims.
- Rose recorded the preflight mismatch and its fix.
- No spawned subagents were running.
