# After Task: Phase 18 Nested-Parallel Guard Slices 689-698

## Goal

Validate that Student-t shape and bivariate residual `rho12` bootstrap smokes
cannot run multicore replicate and multicore bootstrap layers at the same time.

## Implemented

Added `docs/design/88-phase-18-nested-parallel-guard-slices-689-698.md` to
record the current source and test evidence. No likelihood, formula grammar,
public API, roxygen topic, pkgdown navigation, or rendered site output changed.

## Mathematical Contract

No model changed. The checked contract is execution safety: simulations may
parallelize the replicate layer or the private bootstrap layer, but not both at
once when both would use more than one worker.

## Files Changed

- `docs/design/88-phase-18-nested-parallel-guard-slices-689-698.md`
- `docs/dev-log/after-task/2026-05-24-phase18-nested-parallel-guard-slices-689-698.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
nl -ba inst/sim/R/sim_runner.R | sed -n '415,490p'
nl -ba inst/sim/R/sim_bootstrap.R | sed -n '280,315p'
nl -ba inst/sim/run/sim_run_student_shape_smoke.R | sed -n '70,110p'
nl -ba inst/sim/run/sim_run_biv_rho12_smoke.R | sed -n '90,128p'
nl -ba inst/sim/run/sim_run_actions_cell.R | sed -n '45,66p'
nl -ba tests/testthat/test-phase18-sim-runner.R | sed -n '235,255p'
nl -ba tests/testthat/test-phase18-student-shape-runner.R | sed -n '150,178p'
nl -ba tests/testthat/test-phase18-biv-rho12-runner.R | sed -n '160,188p'
nl -ba tests/testthat/test-phase18-actions-runner.R | sed -n '55,78p'
Rscript -e "devtools::test(filter = 'phase18-(sim-runner|student-shape-runner|biv-rho12-runner|actions-runner|student-shape-grid-writer|biv-rho12-grid-writer|sim-bootstrap)', reporter = 'summary')"
```

Results:

- Source reads confirmed the shared no-nested-parallel guard, bootstrap planner,
  Student-t shape guard call, bivariate residual `rho12` guard call, and Actions
  preflight guard.
- The focused nested-parallel bundle completed with exit code 0.
- No files were staged or committed.

## Tests Of The Tests

The focused tests include direct unit coverage for `phase18_assert_no_nested_parallel()`,
runner-level nested bootstrap errors for Student-t shape and bivariate residual
`rho12`, grid-writer backend forwarding checks, bootstrap planner checks, and
Actions dry-run rejection for nested multicore requests.

## Consistency Audit

The report does not add PSOCK, public bootstrap interval expansion, nested
parallelism, formula grammar, likelihood code, or user-facing API. Student-t
shape remains fixed-effect `nu`; random effects in shape remain unsupported.

## GitHub Issue Maintenance

No GitHub issue mutation was done from this mixed dirty branch.

## What Did Not Go Smoothly

No blocker appeared. The work was validation and evidence recording because the
guard already exists in the current dirty tree.

## Team Learning

Nested parallelism should be rejected before any fit starts, especially for
interval-heavy smokes where a small command-line change could otherwise
multiply worker counts.

## Known Limitations

This guard is for package Phase 18 simulation helpers. It does not make a
general PSOCK contract for arbitrary user code.

## Next Actions

Continue with Slices 699-708 by validating or documenting the repeatable
`meta_V(V = V)` grid-output writer.
