# Phase 18 Closure-Aware Summary Factory Slices 629-638

Reader: `drmTMB` contributors checking whether the shared replicate runner can
serve interval-heavy Phase 18 surfaces without losing replicate-specific seeds.

Slices 629-638 validate the closure-aware summary-factory path already present
in the current branch. This is a current-state audit and validation note; no
new likelihood, formula grammar, public API, or user-facing documentation
surface was added in this pass.

## Implementation Contract

The shared runner accepts either a single `summarise_fun` or a
`summarise_fun_factory`. When a factory is supplied, the runner calls it with
the current `cell` and `seed_row`, validates that the result is a function, and
uses that returned closure for the replicate. This lets interval-heavy
surfaces keep per-replicate profile or bootstrap state while still using the
shared runner.

Current source evidence:

- `inst/sim/R/sim_runner.R` lines 97-192 expose the
  `summarise_fun_factory` argument, create the per-replicate summary function,
  and reject factories that do not return a function.
- `inst/sim/run/sim_run_student_shape_smoke.R` lines 108-148 builds a factory
  that derives a replicate-specific `bootstrap_seed` and passes profile and
  bootstrap settings into `phase18_summarise_student_shape_fit()`.
- `inst/sim/run/sim_run_biv_rho12_smoke.R` lines 127-167 applies the same
  contract to bivariate Gaussian residual-correlation `rho12`.
- `tests/testthat/test-phase18-sim-runner.R` lines 174-233 checks that a
  factory can change replicate summaries and that a non-function factory result
  errors.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 629-631 | Shared runner accepts a closure factory | `phase18-sim-runner` factory test passed |
| 632-634 | Student-t shape runner keeps profile/bootstrap state through the shared runner | `phase18-student-shape-runner` and `phase18-student-shape-summary-smoke` passed |
| 635-637 | Bivariate residual `rho12` runner keeps profile/bootstrap state through the shared runner | `phase18-biv-rho12-runner` and `phase18-biv-rho12-summary-smoke` passed |
| 638 | Bootstrap helper remains coherent with the nested-parallel guard | `phase18-sim-bootstrap` passed |

## Commands

```sh
Rscript -e "devtools::test(filter = 'phase18-(sim-runner|student-shape-runner|student-shape-summary-smoke|biv-rho12-runner|biv-rho12-summary-smoke|sim-bootstrap)', reporter = 'summary')"
```

## Result

The focused closure-aware bundle completed with exit code 0. The passing files
were `phase18-biv-rho12-runner`, `phase18-biv-rho12-summary-smoke`,
`phase18-sim-bootstrap`, `phase18-sim-runner`, `phase18-student-shape-runner`,
and `phase18-student-shape-summary-smoke`.

This pass validates simulation execution plumbing. It does not add public
bootstrap intervals, PSOCK support, random effects in `rho12`, or any new
formula grammar.
