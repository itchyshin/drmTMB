# Slices 569-578: Phase 18 Count Runner Cap

## Purpose

Ada migrated the paired count-family Phase 18 smoke runners to the bounded
replicate helper. This keeps the Poisson and NB2 `mu` random-effect simulation
lanes aligned with the 10-core cap before larger count grids are expanded.

## Team Notes

- Ada migrated only the simple constant-summary count runners.
- Fisher kept the profile interval rows visible for random-effect SDs.
- Curie checked the Poisson and NB2 smoke paths with focused tests and small
  multicore runs.
- Grace kept the worker contract serial or Unix `multicore`, capped at 10.
- Rose left Student-t and bivariate `rho12` unmigrated because those runners
  build per-replicate profile or bootstrap closures.

## Files Changed

- `inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R`
- `inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R`
- `inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R`
- `inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-poisson-mu-random-effect.R`
- `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`

## What Changed

The Poisson and NB2 `mu` random-effect smoke runners now accept `cores` and
`backend`, call `phase18_run_replicates()`, and return `parallel` metadata.
Their summary wrappers pass those controls through.

## Validation

Checks run:

```sh
air format inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R tests/testthat/test-phase18-poisson-mu-random-effect.R tests/testthat/test-phase18-nbinom2-mu-random-effect.R
Rscript -e "invisible(parse(file = 'inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R')); cat('count runner parse ok\n')"
Rscript -e "devtools::test(filter = '^phase18-poisson-mu-random-effect$|^phase18-nbinom2-mu-random-effect$|^phase18-sim-runner$')"
```

Additional two-core smoke checks:

```sh
Rscript - <<'RS'
devtools::load_all(quiet = TRUE)
source(system.file('sim/R/sim_registry.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_utils.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_runner.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/dgp/sim_dgp_poisson_mu_random_effect.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/fit/sim_summarise_poisson_mu_random_effect.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/run/sim_run_poisson_mu_random_effect_smoke.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
out <- phase18_run_poisson_mu_re_smoke(
  conditions = phase18_poisson_mu_re_conditions(n_group = 16L, n_per_group = 5L),
  n_rep = 2L,
  master_seed = 20260519L,
  cores = 2L,
  backend = 'multicore'
)
stopifnot(length(out$results) == 2L, all(vapply(out$results, `[[`, character(1L), 'status') == 'ok'))
print(out$parallel)
RS

Rscript - <<'RS'
devtools::load_all(quiet = TRUE)
source(system.file('sim/R/sim_registry.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_utils.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_runner.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/dgp/sim_dgp_nbinom2_mu_random_effect.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/fit/sim_summarise_nbinom2_mu_random_effect.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/run/sim_run_nbinom2_mu_random_effect_smoke.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
out <- phase18_run_nbinom2_mu_re_smoke(
  conditions = phase18_nbinom2_mu_re_conditions(n_group = 18L, n_per_group = 5L),
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

- Focused count and runner tests passed 137 expectations.
- Both small `backend = "multicore"` count smokes completed with `cores = 2`.

## Known Limitations

- Student-t and bivariate `rho12` runners still need a closure-aware migration
  plan because they construct per-replicate profile or bootstrap summary
  functions.
- Spatial and Gaussian random-slope smoke runners remain unmigrated.
