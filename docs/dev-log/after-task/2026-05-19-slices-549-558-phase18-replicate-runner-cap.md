# Slices 549-558: Phase 18 Replicate Runner Cap

## Purpose

Ada added a bounded replicate-runner helper so Phase 18 simulation grids can
eventually use parallel workers without each smoke surface hand-rolling its own
loop. The default stays serial; the first wired surface is the Gaussian
location-scale smoke runner.

## Team Notes

- Ada kept the slice infrastructural and avoided changing likelihood code.
- Fisher and Curie wanted one reusable scheduling primitive before larger
  simulation cells are expanded.
- Grace kept Unix `multicore` capped at 10 workers and left PSOCK out for now.
- Pat and Rose kept the migration one surface at a time so reports stay
  auditable.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `inst/sim/run/sim_run_gaussian_ls_smoke.R`
- `inst/sim/run/sim_summary_gaussian_ls_smoke.R`
- `tests/testthat/test-phase18-sim-runner.R`
- `tests/testthat/test-phase18-gaussian-ls-runner.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`

## What Changed

`phase18_run_replicates()` now runs a seed table against cell definitions,
names each result as `cell_id:repXXXX`, and records a `phase18_parallel`
attribute with backend, requested cores, and actual cores.

`phase18_runner_parallel_plan()` supports:

- `backend = "none"` for serial execution;
- `backend = "multicore"` for Unix forked execution;
- `cores`, with actual workers capped at 10 and at the number of tasks.

The Gaussian location-scale smoke runner and summary wrapper now accept
`cores` and `backend`, and the run object includes a `parallel` element.

## Validation

Checks run:

```sh
air format inst/sim/R/sim_runner.R inst/sim/run/sim_run_gaussian_ls_smoke.R inst/sim/run/sim_summary_gaussian_ls_smoke.R tests/testthat/test-phase18-sim-runner.R tests/testthat/test-phase18-gaussian-ls-runner.R
Rscript -e "invisible(parse(file = 'inst/sim/R/sim_runner.R')); invisible(parse(file = 'inst/sim/run/sim_run_gaussian_ls_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_gaussian_ls_smoke.R')); cat('runner parse ok\n')"
Rscript -e "devtools::test(filter = '^phase18-sim-runner$|^phase18-gaussian-ls-runner$|^phase18-gaussian-ls-summary-smoke$')"
Rscript - <<'RS'
devtools::load_all(quiet = TRUE)
source(system.file('sim/R/sim_registry.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_utils.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_runner.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/dgp/sim_dgp_gaussian_ls.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/fit/sim_summarise_gaussian_ls.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/run/sim_run_gaussian_ls_smoke.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
out <- phase18_run_gaussian_ls_smoke(
  conditions = phase18_gaussian_ls_conditions(n = 80L, sigma_slope = 0.15, collinearity = 0.05),
  n_rep = 2L,
  master_seed = 20260519L,
  cores = 2L,
  backend = 'multicore'
)
stopifnot(length(out$results) == 2L, all(vapply(out$results, `[[`, character(1L), 'status') == 'ok'))
print(out$parallel)
RS
```

Results:

- Focused runner tests passed 88 expectations.
- The two-replicate Gaussian `backend = "multicore"` smoke completed with
  `cores = 2`.

## Known Limitations

- Only the Gaussian location-scale smoke surface is wired through the new helper
  so far.
- Other surfaces should migrate one at a time, especially those that construct
  per-replicate profile or bootstrap summary functions.
- Socket clusters remain planned until fitted-object rebuild semantics are
  designed and tested.
