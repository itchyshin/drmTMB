# Slices 539-548: Phase 18 Bootstrap Parallel Cap

## Purpose

Ada closed one small infrastructure gap between the Ayumi bootstrap prototype
and the reusable Phase 18 helper. The optional private parametric-bootstrap
adapter can now use bounded Unix forked parallelism for developer pilots, while
the default remains serial and CRAN-safe.

## Team Notes

- Ada coordinated the slice and kept it scoped to `inst/sim/` helpers.
- Fisher and Curie asked for a reproducible uncertainty path for difficult
  Hessian and correlation cases without treating bootstrap as a public fitted
  `confint()` API.
- Grace kept the worker count bounded at 10 and left PSOCK out until fitted
  `TMB` object rebuilds are explicit.
- Rose checked that the change did not imply public bootstrap intervals or
  animal/skew model support.

## Files Changed

- `inst/sim/R/sim_bootstrap.R`
- `tests/testthat/test-phase18-sim-bootstrap.R`
- `docs/design/43-phase-18-interval-producer-contract.md`
- `NEWS.md`

## What Changed

`phase18_parametric_bootstrap()` and
`phase18_bootstrap_interval_columns()` now accept:

- `backend = "none"` for the serial default;
- `backend = "multicore"` for Unix forked bootstrap pilots;
- `cores`, with actual workers capped at 10 and at `nsim`.

Bootstrap draw tables now record `bootstrap_backend`,
`bootstrap_requested_cores`, and `bootstrap_cores`. PSOCK remains unsupported
because fitted `TMB` objects contain external pointers and need a separate
refit-or-rebuild worker contract before socket workers are safe.

## Validation

Checks run:

```sh
air format inst/sim/R/sim_bootstrap.R tests/testthat/test-phase18-sim-bootstrap.R docs/design/43-phase-18-interval-producer-contract.md NEWS.md
Rscript -e "invisible(parse(file = 'inst/sim/R/sim_bootstrap.R')); cat('sim_bootstrap parse ok\n')"
Rscript -e "devtools::test(filter = '^phase18-sim-bootstrap$')"
Rscript - <<'RS'
devtools::load_all(quiet = TRUE)
source(system.file('sim/R/sim_registry.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
source(system.file('sim/R/sim_bootstrap.R', package = 'drmTMB', mustWork = TRUE), local = TRUE)
dat <- data.frame(y = c(-0.8, -0.1, 0.2, 0.7, 1.1, 1.5), x = c(-2, -1, 0, 1, 2, 3))
fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
refit_fun <- function(fit, simulations, index) {
  dat$y <- simulations[[paste0('sim_', index)]]
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
}
statistic_fun <- function(fit) c(mu_x = unname(stats::coef(fit, dpar = 'mu')[['x']]))
draws <- phase18_parametric_bootstrap(fit, statistic_fun, refit_fun, nsim = 2L, seed = 20260519L, cores = 2L, backend = 'multicore')
stopifnot(nrow(draws) == 2L, all(draws$status == 'ok'), all(draws$bootstrap_cores == 2L))
print(draws[, c('bootstrap', 'parameter', 'status', 'bootstrap_backend', 'bootstrap_requested_cores', 'bootstrap_cores')])
RS
```

Results:

- `test-phase18-sim-bootstrap.R`: 25 expectations passed.
- The tiny `backend = "multicore"` smoke refit produced two successful
  bootstrap rows with `bootstrap_cores = 2`.

## Known Limitations

- This is still a private Phase 18 simulation helper, not a public
  `confint(..., method = "bootstrap")` interface.
- PSOCK and cluster execution remain planned until worker rebuild semantics are
  designed and tested.
- Large bootstrap grids still need cell-level scheduling and failure-ledger
  reporting before being treated as formal simulation evidence.
