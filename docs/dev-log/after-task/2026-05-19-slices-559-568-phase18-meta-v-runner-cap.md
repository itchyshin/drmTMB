# Slices 559-568: Phase 18 Meta-V Runner Cap

## Purpose

Ada migrated the `meta_V(V = V)` smoke runner to the bounded Phase 18 replicate
helper. This gives the known-covariance simulation lane the same serial or
Unix-forked execution contract as the Gaussian location-scale lane.

## Team Notes

- Ada kept the slice to one core Phase 18 surface.
- Fisher treated `meta_V(V = V)` as a priority because known sampling
  covariance must stay separate from fitted residual heterogeneity.
- Curie and Grace checked that the migration reuses the capped runner helper
  rather than adding another loop.
- Rose confirmed this still does not imply public bootstrap or unsupported
  structured-effect capabilities.

## Files Changed

- `inst/sim/run/sim_run_meta_v_smoke.R`
- `inst/sim/run/sim_summary_meta_v_smoke.R`
- `tests/testthat/test-phase18-meta-v-runner.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`

## What Changed

`phase18_run_meta_v_smoke()` now accepts `cores` and `backend`, delegates to
`phase18_run_replicates()`, and returns `parallel` metadata. The summary wrapper
passes those controls through.

## Validation

Checks run:

```sh
air format inst/sim/run/sim_run_meta_v_smoke.R inst/sim/run/sim_summary_meta_v_smoke.R tests/testthat/test-phase18-meta-v-runner.R
Rscript -e "invisible(parse(file = 'inst/sim/run/sim_run_meta_v_smoke.R')); invisible(parse(file = 'inst/sim/run/sim_summary_meta_v_smoke.R')); cat('meta runner parse ok\n')"
Rscript -e "devtools::test(filter = '^phase18-meta-v-runner$|^phase18-meta-v-summary-smoke$|^phase18-sim-runner$')"
Rscript - <<'RS'
devtools::load_all(quiet = TRUE)
source(system.file('sim/R/sim_registry.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_utils.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_runner.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/dgp/sim_dgp_meta_v.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/fit/sim_summarise_meta_v.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/run/sim_run_meta_v_smoke.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
out <- phase18_run_meta_v_smoke(
  conditions = phase18_meta_v_conditions(n_study = 24L, known_v_type = c('vector', 'dense'), sigma = 0.20, sampling_sd = 0.12, sampling_rho = c(0, 0.10)),
  n_rep = 1L,
  master_seed = 20260519L,
  cores = 2L,
  backend = 'multicore'
)
stopifnot(length(out$results) == nrow(out$registry$seeds), all(vapply(out$results, `[[`, character(1L), 'status') == 'ok'))
print(out$parallel)
RS
```

Results:

- Focused meta and runner tests passed 86 expectations.
- The vector/dense `backend = "multicore"` smoke completed with `cores = 2`.

## Known Limitations

- Other Phase 18 runners still use their local loops until migrated and tested.
- Socket-worker execution remains planned, not implemented.
