# After Task: Bivariate Gaussian q2 Scale-Intercept Recovery Lane

## Goal

Promote the bivariate Gaussian q2 scale-intercept covariance lane from a
single-replicate smoke check to a multi-replicate recovery and coverage lane.
The smoke lane (`biv_gaussian_q2_scale`, merged in PR #481) only proves the
model fits and reports sensibly; the q8 endpoint gate and issue #59 ask for
recovery, coverage, and MCSE evidence. This lane provides the first such
evidence for the fittable scale-covariance prerequisite.

## What This Lane Adds

The smoke summary already produced bias, RMSE, empirical SE, and MCSE (via
`phase18_aggregate_parameters()` and `phase18_aggregate_error_mcse()`); at
`n_rep = 1` those are trivial. The recovery lane:

- runs the existing DGP/fit/runner at recovery-scale `n_rep` (so bias and MCSE
  are meaningful), and
- adds Wald intervals and an interval-coverage table, mirroring the established
  `biv_rho12` coverage lane.

The honest scoping is built into the data: Wald intervals are computed only for
endpoints with a standard error in `summary(fit)$coefficients` (the fixed
`mu1`/`mu2` coefficients). The random-effect scale SDs and the derived
scale-scale correlation have no Wald standard error, so their interval
endpoints stay `NA` and they remain `derived_interval_unavailable`, consistent
with the q8 gate. Bias and MCSE are still reported for those rows as point
estimates.

## Files Added

- `inst/sim/run/sim_summary_biv_gaussian_q2_scale_recovery.R`
- `inst/sim/run/sim_write_biv_gaussian_q2_scale_recovery_grid.R`
- `tests/testthat/test-phase18-biv-gaussian-q2-scale-recovery.R`
- `docs/design/156-phase-18-bivariate-scale-q2-recovery-ademp.md`
- `docs/dev-log/after-task/2026-06-04-bivariate-q2-scale-recovery-lane.md` (this file)

## Files Changed

- `inst/sim/run/sim_run_actions_cell.R` (task choices, dispatcher branch,
  `phase18_actions_task_paths`)
- `inst/sim/run/sim_phase18_structured_workflow_registry.R` (fallback task list)
- `inst/sim/registry/phase18_structured_workflow_registry.csv` (new row)
- `tests/testthat/test-phase18-structured-workflow-registry.R` (count assertions)
- `.github/workflows/phase18-simulation-grid.yaml` (opt-in matrix entry)
- `inst/sim/README.md`, `docs/design/143-phase-18-structured-workflow-registry.md`,
  `NEWS.md`, `docs/dev-log/check-log.md`

## Design Decisions

- **Reuse, do not fork.** The recovery summary calls the existing smoke runner
  and fit summariser; only the coverage layer and a higher default `n_rep` are
  new. No new DGP or fit code.
- **`ready_grid`, not a new status.** `phase18_correlation_block_dispatch_status()`
  errors on any status outside `{ready_grid, ready_or_smoke, diagnostic_only}`.
  The `smoke_formal_admission` precedent lives in the `structured_dependence`
  plan, whose dispatch logic differs. Rather than extend the correlation-block
  state machine blind, the recovery lane is admitted as `ready_grid` (a recovery
  grid is a runnable grid); reproducibility comes from its opt-in Actions task.
- **Opt-in dispatch.** The matrix entry uses `include_in_all: false`, so the
  heavier recovery run is dispatched deliberately, not in the default "all" run.

## Checks Run

Local R is unavailable in this container (the package repositories are blocked
by the network policy), so `devtools::test()`, `devtools::check()`, and
`pkgdown::*` were not run here. Validation relies on GitHub Actions
`R-CMD-check`, which runs the new recovery test (at a small replicate count, to
check the machinery and column contract, not to make a coverage claim) and the
updated registry-count assertions. The recovery summary mirrors the verified
`biv_rho12` coverage wiring, and the helper signatures
(`phase18_add_wald_intervals(conf.level = ...)`,
`phase18_summarise_interval_coverage`, `phase18_interval_evidence_table`) were
checked against their definitions before use.

## Known Limitations

This lane reports recovery for the scale-**intercept** block only. Bivariate
residual-scale random slopes remain closed (see
`docs/design/155-bivariate-residual-scale-random-slope-gate.md`). The continuous
-integration test makes no coverage claim; a formal coverage statement needs a
deliberately sized run (the ADEMP names at least 500 replicates per cell) and an
artifact audit. SD and scale-scale correlation interval coverage need profile,
derived-profile, or bootstrap methods and are deliberately deferred.

## Next Actions

Dispatch the `biv_gaussian_q2_scale_recovery` Actions task at formal replicate
count, audit the artifact tables, and only then record a coverage claim in the
registry and known-limitations notes. The same recovery pattern can next be
applied to the q6 location lane.
