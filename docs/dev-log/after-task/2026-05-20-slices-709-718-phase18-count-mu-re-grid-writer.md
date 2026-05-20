# Slices 709-718: Phase 18 Count `mu` Random-Effect Grid Writer

## Goal

Ada added the repeatable output writer for the first paired count Phase 18
lane: Poisson and NB2 `mu` random effects.

## Implemented

`phase18_write_count_mu_re_grid_outputs()` writes aggregate, replicate,
manifest, failure-ledger, Wald interval, Wald coverage, direct-SD profile
interval, and profile coverage CSV files beside resumable per-replicate RDS
files. It forwards `cores` and `backend` to both count-family smoke surfaces.

## Mathematical Contract

No count likelihood or estimand changed. The writer preserves the existing
first-wave boundary: ordinary non-zero-inflated Poisson and NB2 `mu` random
effects only, with `sigma`, zero-inflation, hurdle, structured, and correlated
count random-effect surfaces outside this lane.

## Files Changed

- `inst/sim/run/sim_write_count_mu_random_effect_grid.R`
- `tests/testthat/test-phase18-count-mu-random-effect-grid-writer.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-count-mu-random-effect-(grid-writer|pilot)$')"
Rscript -e "devtools::test(filter = '^phase18-count-mu-random-effect-grid-writer$')"
Rscript -e "devtools::test(filter = '^phase18-(gaussian-ls-grid-writer|meta-v-grid-writer|count-mu-random-effect-grid-writer|biv-rho12-grid-writer|student-shape-grid-writer)$')"
```

Results:

- Count grid/pilot tests before trim: 41 expectations passed.
- Count grid writer after trim: 17 expectations passed.
- Grid-writer bundle: 75 expectations passed.

## Tests Of The Tests

The test checks all output files, row counts, runner metadata propagation for
both Poisson and NB2 runs, surface labels, overwrite protection, and input
validation. Ada removed a duplicate overwrite-TRUE rerun because it repeated
the slow count fits without adding much new evidence.

## Consistency Audit

The Phase 18 README, roadmap, NEWS, and simulation-programme note now list the
count grid writer beside the Gaussian, meta-analysis, Student-t, and bivariate
`rho12` writers.

## What Did Not Go Smoothly

The first version of the test reran the whole paired count grid for overwrite
coverage and took too long. Overwrite protection is still tested, but the
duplicate full rerun is gone.

## Team Learning

- Ada: first-wave surfaces should have parallel artifact writers, but tests
  should avoid unnecessary repeated live fits.
- Curie: output-file and row-count checks are enough here; overwrite-TRUE rerun
  coverage is not worth another count-model fit.
- Fisher: profile interval artifacts stay attached only to direct random-effect
  SD targets in this count lane.
- Grace: slow tests need a reason; remove duplicate runtime when it does not
  improve evidence.

## Known Limitations

- This writer does not include zero-inflation, hurdle, zero-truncation, or
  structured count random effects.
- No formal operating-characteristic grid was run.

## Next Actions

1. Add the next missing first-wave grid writer or start a first-wave report
   staging helper that can read the artifact directories.
2. Rerun focused Phase 18 tests after the next simulation-code slice.
