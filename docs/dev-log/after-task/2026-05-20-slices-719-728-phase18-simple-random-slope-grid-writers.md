# Slices 719-728: Phase 18 Simple Random-Slope Grid Writers

## Goal

Ada added repeatable grid-output writers for three first-wave smoke surfaces
that already had DGPs and summaries but not standalone artifact writers.

## Implemented

The new writers cover ordinary Gaussian `mu` random slopes, independent
Gaussian `sigma` random slopes, and coordinate-spatial Gaussian `mu` slopes.
Each writer saves aggregate, replicate, manifest, and failure-ledger CSV files
beside resumable per-replicate RDS files, and forwards `cores` and `backend`
to the private bounded runner.

## Mathematical Contract

No likelihood, formula grammar, or estimand changed. The new writers expose
artifact paths for already admitted smoke surfaces.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `inst/sim/run/sim_write_gaussian_mu_random_slope_grid.R`
- `inst/sim/run/sim_write_gaussian_sigma_random_slope_grid.R`
- `inst/sim/run/sim_write_spatial_mu_slope_grid.R`
- `tests/testthat/test-phase18-random-slope-grid-writers.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-(random-slope-grid-writers|gaussian-mu-random-slope|gaussian-sigma-random-slope|spatial-mu-slope)$')"
Rscript -e "devtools::test(filter = '^phase18-')"
```

Result:

- 109 expectations passed.
- Full focused Phase 18 tests passed with 853 expectations.

## Tests Of The Tests

The test runs all three writers, verifies output files, row counts, runner
metadata propagation, and overwrite/input validation. It also reruns the
neighboring smoke tests for the three surfaces.

## Consistency Audit

The Phase 18 README, roadmap, NEWS, and simulation-programme note now list the
random-slope and spatial simple writers beside the other first-wave artifact
writers.

## What Did Not Go Smoothly

Ada first placed shared simple-grid helpers inside the Gaussian `mu` writer,
which would have made the `sigma` and spatial writers fragile if sourced on
their own. The helpers now live in `inst/sim/R/sim_runner.R`, where all three
writers can use them.

## Team Learning

- Ada: shared writer helpers belong in the simulation helper layer, not in one
  concrete writer.
- Curie: simple artifact writers still need overwrite and row-count tests.
- Fisher: no interval claims should be added for these surfaces until interval
  rows exist in their summaries.
- Grace: source-order independence matters for optional scripts.

## Known Limitations

- These writers do not add Wald, profile, or bootstrap interval CSVs.
- Larger operating-characteristic grids remain future optional runs.

## Next Actions

1. Add any remaining first-wave grid writer, then build a reader/report staging
   helper that can consume the artifact directories.
2. Rerun the full focused Phase 18 tests before the next broad checkpoint.
