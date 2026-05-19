# After-Task Report: Slices 315-332 Student-T Shape Simulation Smoke Grid

## Goal

Move the shape-model simulation block from planning into one fitted,
deterministic Student-t `nu` lane, while keeping skew and latent-shape models
outside the evidence claim until their likelihood, interval, and recovery-test
gates close.

## Standing Roles

Ada coordinated the slice order, kept this branch stacked behind the
correlation-inference branch while CI was still running, and kept the work
scoped to one admitted shape surface.

Curie owned the Student-t DGP, runner, summary reducer, grid writer, and
focused tests.

Fisher kept the inference claim narrow: formula-coefficient Wald intervals are
available for this smoke lane, but response-scale `nu` profiles and bootstrap
coverage are not yet formal evidence.

Grace watched reproducibility, ignored result artifacts, branch state, and
pkgdown/check readiness.

Pat checked that the simulation outputs remain visible as CSVs with manifests,
failure ledgers, and interval-status tables.

Rose checked for claim drift: skew-normal, skew-t, second-shape `tau`, shape
random effects, and latent terms such as `skew(id) ~ x` remain planned or
failure-ledger only.

Florence was not active in this slice because no rendered figure grammar or
publication plot changed.

No spawned subagents were running.

## Implementation

`docs/design/53-phase-18-student-shape-ademp.md` records the Student-t shape
simulation design using the ADEMP structure. The admitted lane is
`bf(y ~ x, sigma ~ z, nu ~ w)` with `family = student()`.

`inst/sim/dgp/sim_dgp_student_shape.R` adds the seeded DGP, condition helper,
and named-grid truth helper. The DGP stores link-scale truth and uses
`nu = 2 + exp(eta_nu)` so the generated shape matches the fitted
finite-variance transform.

`inst/sim/fit/sim_summarise_student_shape.R` summarises fitted `mu`, `sigma`,
and `nu` formula coefficients, including standard errors when `summary(fit)`
exposes them.

`inst/sim/run/sim_run_student_shape_smoke.R`,
`inst/sim/run/sim_summary_student_shape_smoke.R`, and
`inst/sim/run/sim_write_student_shape_grid.R` add the live fit runner, aggregate
and MCSE summary, manifest, warning/error ledger, Wald interval and coverage
tables, interval-failure ledger, and repeatable CSV grid writer.

`inst/sim/R/sim_uncertainty.R` now handles zero or one finite interval width in
coverage summaries by returning `NA` interval-width MCSE rather than failing.
That keeps one-replicate smoke tests useful without pretending that a width
MCSE exists.

## Evidence

Focused Student-t shape, shared uncertainty, bivariate `rho12`, correlation
target, and private bootstrap tests passed after the branch was rebased onto
the merged correlation-inference branch:

```sh
Rscript -e "devtools::test(filter = '^phase18-(student-shape|sim-uncertainty|biv-rho12|correlation-targets|sim-bootstrap)')"
```

Result: 188 tests, 0 failures, 0 warnings, 0 skips.

`pkgdown::check_pkgdown()` passed with no problems, and `git diff --check`
passed.

The small Student-t shape grid was written to
`inst/sim/results/slice-332-student-shape-small-grid/`. Its concise artifact
check reported:

```text
manifest status: ok = 12
replicate rows: 72
aggregate rows: 24
failure rows: 0
interval-failure rows: 0
```

## Limitations

The small Student-t grid has only 3 replicates per cell. It validates the DGP,
runner, artifact contract, and gross recovery path; it is not formal bias,
RMSE, or coverage evidence.

Formula-coefficient Wald intervals are attached for `mu`, `sigma`, and `nu`
rows. Response-scale `nu` interval coverage, profile likelihood, and bootstrap
coverage are still follow-up work.

Skew-normal, skew-t, second-shape `tau`, shape random effects, zero-inflated
shape surfaces, and latent-effect shape terms remain outside the implemented
simulation evidence.

## Next Step

Merge the correlation-inference branch once CI completes, rebase this
Student-t shape branch onto the updated `main`, run pkgdown/check validation,
and then open the shape simulation PR. The next modelling slice after this
should decide whether to harden response-scale `nu` intervals or move into the
first skew-shape design gate.
