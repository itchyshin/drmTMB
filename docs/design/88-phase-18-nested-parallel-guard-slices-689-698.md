# Phase 18 Nested-Parallel Guard Slices 689-698

Reader: `drmTMB` contributors checking that interval-heavy Phase 18 surfaces
cannot accidentally run replicate-layer and bootstrap-layer multicore workers at
the same time.

Slices 689-698 validate the nested-parallel guard for Student-t fixed-effect
shape and bivariate residual `rho12` bootstrap smokes. The implementation is
already present in the current dirty tree: the shared runner computes an outer
parallel plan, the private bootstrap helper computes an inner parallel plan,
and interval-heavy runners reject runs where both plans would use more than one
worker.

## Source Evidence

- `phase18_runner_parallel_plan()` supports only `none` and Unix `multicore`,
  caps actual workers at 10 and at the number of replicate tasks, and records
  requested versus actual cores.
- `phase18_bootstrap_parallel_plan()` applies the same backend and worker-cap
  contract to private bootstrap refits.
- `phase18_assert_no_nested_parallel()` errors when both outer and inner plans
  have `cores > 1`.
- `phase18_run_student_shape_smoke()` and `phase18_run_biv_rho12_smoke()`
  compute both plans and call the guard before fitting.
- `sim_run_actions_cell.R` rejects manual interval-heavy dispatch when both the
  replicate layer and bootstrap layer request multicore with more than one
  worker.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 689-691 | Validate generic nested-plan guard | `phase18-sim-runner` passed |
| 692-694 | Validate Student-t shape nested-guard path | `phase18-student-shape-runner` and grid-writer tests passed |
| 695-697 | Validate bivariate residual `rho12` nested-guard path | `phase18-biv-rho12-runner` and grid-writer tests passed |
| 698 | Validate manual Actions preflight guard | `phase18-actions-runner` passed |

## Commands

```sh
Rscript -e "devtools::test(filter = 'phase18-(sim-runner|student-shape-runner|biv-rho12-runner|actions-runner|student-shape-grid-writer|biv-rho12-grid-writer|sim-bootstrap)', reporter = 'summary')"
```

## Result

The focused nested-parallel bundle completed with exit code 0. The passing
files were:

- `phase18-actions-runner`
- `phase18-biv-rho12-grid-writer`
- `phase18-biv-rho12-runner`
- `phase18-sim-bootstrap`
- `phase18-sim-runner`
- `phase18-student-shape-grid-writer`
- `phase18-student-shape-runner`

This closes Slices 689-698 as runner-safety validation. It does not add PSOCK,
nested parallelism, public bootstrap interval expansion, formula grammar,
likelihood code, or new user-facing API.
