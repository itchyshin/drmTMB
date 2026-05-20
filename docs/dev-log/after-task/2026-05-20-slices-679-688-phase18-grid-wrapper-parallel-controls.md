# Slices 679-688: Phase 18 Grid Wrapper Parallel Controls

## Goal

Ada made the higher-level Phase 18 grid and gallery wrappers obey the bounded
parallel execution contract that the lower-level smoke runners already used.

## Implemented

Gaussian location-scale, Student-t shape, and bivariate residual `rho12` grid
writers now forward replicate-runner `cores` and `backend`. The paired count
pilot and count-gallery smoke wrapper also forward those settings. Student-t
shape and bivariate residual `rho12` now carry separate `bootstrap_cores` and
`bootstrap_backend` arguments into the private parametric-bootstrap interval
path, and bootstrap interval rows record backend, requested cores, and actual
cores.

## Mathematical Contract

No model likelihood, formula grammar, or estimand changed. This slice only
changes execution plumbing and artifact metadata for simulation runs.

## Files Changed

- `inst/sim/R/sim_bootstrap.R`
- `inst/sim/fit/sim_summarise_biv_rho12.R`
- `inst/sim/fit/sim_summarise_student_shape.R`
- `inst/sim/run/sim_run_biv_rho12_smoke.R`
- `inst/sim/run/sim_run_student_shape_smoke.R`
- `inst/sim/run/sim_summary_biv_rho12_smoke.R`
- `inst/sim/run/sim_summary_student_shape_smoke.R`
- `inst/sim/run/sim_summary_count_mu_random_effect_pilot.R`
- `inst/sim/run/sim_render_count_mu_gallery_smoke.R`
- `inst/sim/run/sim_write_biv_rho12_grid.R`
- `inst/sim/run/sim_write_gaussian_ls_grid.R`
- `inst/sim/run/sim_write_student_shape_grid.R`
- `tests/testthat/test-phase18-*.R` focused runner/grid/summary tests
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-(gaussian-ls-grid-writer|biv-rho12-grid-writer|student-shape-grid-writer|count-mu-random-effect-pilot|count-gallery-smoke-runner|student-shape-runner|biv-rho12-runner)$')"
Rscript -e "devtools::test(filter = '^phase18-(student-shape-summary-smoke|biv-rho12-summary-smoke|sim-bootstrap)$')"
Rscript -e "devtools::test(filter = '^phase18-')"
```

Results:

- Focused grid/runner/gallery tests: 126 expectations passed.
- Summary/bootstrap tests: 77 expectations passed.
- Full focused Phase 18 tests: 793 expectations passed.

## Tests Of The Tests

The first focused run failed because invalid bootstrap backend settings were
being swallowed inside a replicate failure and resurfacing only as "no
summaries." The fix validates bootstrap backend settings before fitting, and
the grid-writer tests now exercise that failure path.

## Consistency Audit

The execution contract is now consistent across lower-level smoke runners,
summary wrappers, grid writers, and the count-gallery smoke wrapper. Bootstrap
parallelism is intentionally separate from replicate parallelism so future
runs can avoid nested multicore oversubscription.

## What Did Not Go Smoothly

The naming looked deceptively complete after Slices 549-668 because the smoke
runners accepted `cores` and `backend`; the wrapper layer still hid those
settings. Rose's audit caught the mismatch before larger grids depended on it.

## Team Learning

- Ada: check all layers that call a helper, not only the helper itself.
- Curie: failure-path tests should assert where validation happens, not only
  that an error eventually appears.
- Fisher: bootstrap metadata belongs in the interval artifact because the draw
  table is not always retained by grid writers.
- Grace: keep PSOCK unsupported in the package path until fitted-object rebuild
  semantics are explicit.
- Rose: private infrastructure can still create public confusion if wrappers
  silently ignore its controls.

## Known Limitations

- Public bootstrap confidence intervals are still not implemented.
- PSOCK is still unsupported for the package simulation helper.
- Large grids should parallelize one layer at a time.

## Next Actions

1. Run the focused Phase 18 test set again when the next code slice finishes.
2. Continue with first-wave simulation report staging or the next package-doc
   audit, keeping broad grids separate from CRAN-safe smoke tests.
