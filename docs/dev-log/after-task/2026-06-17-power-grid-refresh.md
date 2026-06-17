# After Task: Power Grid Refresh

## Goal

Refresh the stale #473 power-grid execution draft against current `main` while
preserving the newer Phase 18 Actions task registry and workflow-dispatch
invariants.

## Implemented

- Replayed the generic power-grid engine and CSV artifact writer.
- Replayed the Gaussian location-scale, meta-analysis known-variance, and
  Poisson random-effect power runner wrappers.
- Replayed the Actions task choices and workflow matrix entries for
  `gaussian_ls_power`, `meta_v_power`, and `poisson_mu_re_power`, keeping them
  outside the `all` batch.
- Preserved the current-main test that workflow dispatch options and runner task
  choices must match, then added the power dry-run and dependency-path tests.

## Mathematical Contract

No model likelihood, formula grammar, estimator, or inference method changed.
This slice adds simulation orchestration around already admitted surfaces and
keeps the power results as artifacts, not public support or release-readiness
claims.

## Files Changed

- `.github/workflows/phase18-simulation-grid.yaml`
- `docs/design/154-phase-18-power-simulation-plan.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-02-power-grid-execution.md`
- `docs/dev-log/after-task/2026-06-17-power-grid-refresh.md`
- `inst/sim/R/sim_power.R`
- `inst/sim/README.md`
- `inst/sim/run/sim_run_actions_cell.R`
- `inst/sim/run/sim_run_gaussian_ls_power_smoke.R`
- `inst/sim/run/sim_run_meta_v_power_smoke.R`
- `inst/sim/run/sim_run_poisson_mu_re_power_smoke.R`
- `inst/sim/run/sim_run_power_grid.R`
- `inst/sim/run/sim_write_power_grid.R`
- `tests/testthat/test-phase18-actions-runner.R`
- `tests/testthat/test-phase18-gaussian-ls-power-runner.R`
- `tests/testthat/test-phase18-power-grid-engine.R`
- `tests/testthat/test-phase18-power.R`

## Checks Run

- `git cherry-pick 069cd53e 8d453d94 444f82a5`
- Resolved the only conflict in `tests/testthat/test-phase18-actions-runner.R`
  by keeping current-main's dispatch-option invariant and adding the power task
  tests.
- `air format inst/sim/R/sim_power.R inst/sim/run/sim_run_actions_cell.R inst/sim/run/sim_run_gaussian_ls_power_smoke.R inst/sim/run/sim_run_meta_v_power_smoke.R inst/sim/run/sim_run_poisson_mu_re_power_smoke.R inst/sim/run/sim_run_power_grid.R inst/sim/run/sim_write_power_grid.R tests/testthat/test-phase18-actions-runner.R tests/testthat/test-phase18-gaussian-ls-power-runner.R tests/testthat/test-phase18-power-grid-engine.R tests/testthat/test-phase18-power.R`
- `Rscript --vanilla -e 'devtools::test(filter = "phase18-(actions-runner|power-grid-engine|gaussian-ls-power-runner|power)", reporter = "summary")'`
- `git diff --check`

## Tests Of The Tests

The refreshed tests cover the workflow/runner registry invariant, dry-run
dispatch for each new power task, writer clobber protection, artifact-manifest
generation, non-`n` sample-size column handling, and a stubbed end-to-end
run-and-write composition.

## Consistency Audit

The refresh preserves all newer Phase 18 task choices that landed after the old
#473 base. The workflow entries remain excluded from the aggregate `all` dispatch
so the default simulation grid is unchanged.

## GitHub Issue Maintenance

This refresh supersedes draft PR #473 once fresh current-main CI passes.

## What Did Not Go Smoothly

The old branch conflicted with newer Actions-runner tests. The conflict exposed
a useful invariant that should remain: every dispatchable runner task must be
selectable from the workflow.

## Team Learning

Simulation dispatch PRs should include registry-invariant tests so new tasks are
not added to one side of the runner/workflow pair only.

## Known Limitations

This is an execution-layer slice. It does not run a large power grid, promote a
power claim, add a public tutorial figure, or make a release-readiness claim.

## Next Actions

- Wait for fresh Ubuntu, macOS, and Windows R-CMD-check on the refreshed branch.
- Merge only after CI passes, then update mission-control dashboard state.
