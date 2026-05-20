# Slices 689-698: Phase 18 Nested Parallel Guard

## Goal

Ada enforced the Phase 18 execution rule that a heavy smoke grid should use
parallelism at either the replicate layer or the private bootstrap layer, not
both at the same time.

## Implemented

`phase18_assert_no_nested_parallel()` now checks two execution plans and errors
when both would use more than one worker. Student-t shape and bivariate
residual `rho12` runners validate the bootstrap plan and the replicate plan
before fitting, then stop early if the request would nest multicore work.

## Mathematical Contract

No model, likelihood, interval formula, or estimand changed. This is a runtime
guard for private simulation infrastructure.

## Files Changed

- `inst/sim/R/sim_runner.R`
- `inst/sim/run/sim_run_biv_rho12_smoke.R`
- `inst/sim/run/sim_run_student_shape_smoke.R`
- `tests/testthat/test-phase18-sim-runner.R`
- `tests/testthat/test-phase18-biv-rho12-runner.R`
- `tests/testthat/test-phase18-student-shape-runner.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript -e "devtools::test(filter = '^phase18-(sim-runner|student-shape-runner|biv-rho12-runner|student-shape-summary-smoke|biv-rho12-summary-smoke)$')"
```

Result:

- 159 expectations passed.

## Tests Of The Tests

The new tests include a direct helper check and two runner-level failure paths.
They request multicore replicate execution and multicore bootstrap execution
with more than one actual worker on both layers, and expect a clear early
error.

## Consistency Audit

The README, design programme, roadmap, and NEWS now all state the same policy:
the helpers support capped multicore execution, but larger runs should use one
parallel layer at a time.

## What Did Not Go Smoothly

The previous slice only documented the one-layer-at-a-time rule. This slice
turns that advice into code, which is safer before any larger local or
scheduled grids use the wrappers.

## Team Learning

- Ada: a resource-use recommendation should become a guard when violating it
  can silently oversubscribe a shared workstation.
- Curie: execution-plan tests can stay fast by checking early validation,
  without running real model fits.
- Grace: actual capped worker counts are the right quantities to compare.
- Rose: the same rule should appear in code, tests, and docs.

## Known Limitations

- PSOCK remains unsupported.
- The guard is implemented for the two current private-bootstrap smoke
  surfaces, Student-t shape and bivariate residual `rho12`.

## Next Actions

1. Run a broader Phase 18 test pass after the next code slice.
2. Continue staging first-wave simulation outputs with one-layer parallelism.
