# Slices 629-638: Phase 18 Closure-Aware Runner Migration

## Purpose

Ada completed the Phase 18 bounded-runner migration by adding a closure-aware
summary factory path. Student-t shape and bivariate residual `rho12` runners can
now use the same capped replicate helper while preserving per-replicate profile
and bootstrap seeds.

## Team Notes

- Ada extended `phase18_run_replicates()` instead of duplicating local loops.
- Fisher and Curie asked for practical checks with bootstrap enabled, because
  that is where per-replicate closure state matters.
- Grace kept validation smokes at two workers and preserved the 10-core cap.
- Rose checked that this remains private Phase 18 infrastructure, not public
  bootstrap confidence intervals.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `inst/sim/run/sim_run_student_shape_smoke.R`
- `inst/sim/run/sim_summary_student_shape_smoke.R`
- `inst/sim/run/sim_run_biv_rho12_smoke.R`
- `inst/sim/run/sim_summary_biv_rho12_smoke.R`
- `tests/testthat/test-phase18-sim-runner.R`
- `tests/testthat/test-phase18-student-shape-runner.R`
- `tests/testthat/test-phase18-biv-rho12-runner.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`

## What Changed

`phase18_run_replicates()` now accepts either a constant `summarise_fun` or a
`summarise_fun_factory(cell, seed_row)` that returns a per-replicate summary
function. The factory route is used by:

- `phase18_run_student_shape_smoke()`;
- `phase18_run_biv_rho12_smoke()`.

Both runners now accept `cores` and `backend`, return `parallel` metadata, and
can use Unix `multicore` execution capped at 10 workers.

## Validation

Checks run:

```sh
air format inst/sim/R/sim_runner.R inst/sim/run/sim_run_student_shape_smoke.R inst/sim/run/sim_summary_student_shape_smoke.R inst/sim/run/sim_run_biv_rho12_smoke.R inst/sim/run/sim_summary_biv_rho12_smoke.R tests/testthat/test-phase18-sim-runner.R tests/testthat/test-phase18-student-shape-runner.R tests/testthat/test-phase18-biv-rho12-runner.R
Rscript -e "invisible(parse(file = 'inst/sim/R/sim_runner.R')); invisible(parse(file = 'inst/sim/run/sim_run_student_shape_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_run_biv_rho12_smoke.R')); cat('closure runner parse ok\n')"
Rscript -e "devtools::test(filter = '^phase18-sim-runner$|^phase18-student-shape-runner$|^phase18-student-shape-summary-smoke$|^phase18-biv-rho12-runner$|^phase18-biv-rho12-summary-smoke$')"
```

Additional two-core multicore smokes:

- Student-t shape with `n_rep = 2`.
- Bivariate residual `rho12` with `n_rep = 2`.
- Student-t shape with `bootstrap_nsim = 2`.
- Bivariate residual `rho12` with `bootstrap_nsim = 2`.

Results:

- Focused closure-runner tests passed 149 expectations.
- Basic two-core Student-t and bivariate `rho12` smokes completed.
- Two-core bootstrap smokes completed with all bootstrap rows reporting
  `bootstrap.status = "ok"`: 12 Student-t rows and 20 bivariate `rho12` rows.

## Known Limitations

- This is still private Phase 18 simulation infrastructure.
- The change does not expose public bootstrap intervals for fitted models.
- A full Phase 18 and package validation pass should follow.
