# After-Task Report: Phase 18 Require-Complete Print-Plan Fix

Date: 2026-05-29

## Task

Fix the post-run print-plan failure from Phase 18 formal pilot Actions run
`26667502560`.

## Context

The selected `count_structured_q1` job received the intended workflow inputs:
`profile_level=0.70`, `require_complete=true`, `condition_set=stable`, and
`profile_parameters=log_sd_phylo`. It failed after the task body when the
post-run call to `phase18_actions_print_plan()` omitted the new
`require_complete` argument.

## Changes

- `inst/sim/run/sim_run_actions_cell.R` now passes `require_complete` to the
  post-run `phase18_actions_print_plan()` call.
- `tests/testthat/test-phase18-actions-runner.R` now mocks a non-dry-run
  `count_structured_q1` execution and checks that `require_complete=TRUE`
  prints after `phase18-actions-result.rds` is saved.
- `ROADMAP.md`, `docs/design/41-phase-18-simulation-programme.md`, and
  `docs/dev-log/check-log.md` record Slice 1773.

## Validation

```sh
air format inst/sim/run/sim_run_actions_cell.R tests/testthat/test-phase18-actions-runner.R ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-29-phase18-require-complete-print-plan.md
Rscript --vanilla -e "devtools::test(filter = 'phase18-actions-runner', reporter = 'summary')"
git diff --check
```

Results:

- The focused `phase18-actions-runner` suite passed.
- `git diff --check` was clean.

## Boundaries

This fix does not audit the failed run artifact and does not add recovery,
coverage, bootstrap, low-SD, zero-inflated, structured-slope,
labelled-covariance, or structured NB2 `sigma` evidence.
