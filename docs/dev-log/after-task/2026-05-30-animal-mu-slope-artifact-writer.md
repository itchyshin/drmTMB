# After Task: Animal Gaussian Mu Slope Artifact Writer

## Goal

Add a local Phase 18 artifact route for the dense-pedigree `animal()` Gaussian
`mu` one-slope lane without promoting the row to manual Actions dispatch,
`task = "all"`, sparse large-pedigree speed, recovery, coverage, or power
evidence.

## Implemented

- Added `inst/sim/dgp/sim_dgp_animal_mu_slope.R`.
- Added `inst/sim/fit/sim_summarise_animal_mu_slope.R`.
- Added `inst/sim/run/sim_run_animal_mu_slope_smoke.R`.
- Added `inst/sim/run/sim_summary_animal_mu_slope_smoke.R`.
- Added `inst/sim/run/sim_write_animal_mu_slope_grid.R`.
- Added `tests/testthat/test-phase18-animal-mu-slope.R`.
- Updated structured-dependence wrapper readiness so the `animal()` one-slope
  row reports `grid_writer_available` while remaining a wrapper target.
- Updated source and rendered reader-facing ledgers to distinguish
  `spatial_mu_slope` Actions readiness, local `animal()`/`relmat()` artifact
  readiness, and `phylo()` as the remaining source-tested wrapper target without
  a local writer.

## Mathematical Contract

The DGP uses one Gaussian response with

```text
y_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta0 + beta1 x_ij + a0_j + a1_j x_ij
a0 ~ MVN(0, sd_intercept^2 A)
a1 ~ MVN(0, sd_slope^2 A)
Cov(a0, a1) = 0
```

where `A` is the additive relationship matrix implied by the deterministic
pedigree. The fitted model is

```r
bf(y ~ x + animal(1 + x | id, pedigree = pedigree), sigma ~ 1)
```

The writer records fixed `mu` coefficients, residual `sigma`, and the two
direct `animal()` `mu` SD rows. It does not estimate or report an animal-model
intercept-slope correlation, multiple animal slopes, residual-scale structured
slopes, structured `rho12`, sparse large-pedigree timing, recovery, coverage,
or power.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/148-phase6c-structured-one-slope-ademp.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/team-improvements.md`
- `inst/sim/README.md`
- `inst/sim/dgp/sim_dgp_animal_mu_slope.R`
- `inst/sim/fit/sim_summarise_animal_mu_slope.R`
- `inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R`
- `inst/sim/run/sim_run_animal_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_animal_mu_slope_smoke.R`
- `inst/sim/run/sim_write_animal_mu_slope_grid.R`
- `tests/testthat/test-phase18-animal-mu-slope.R`
- `tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The new test exercises reproducibility, truth metadata, the pedigree and
relationship matrices, realised animal intercept and slope fields, the local
no-correlation extractor contract, smoke summaries, artifact creation,
overwrite protection, and malformed DGP inputs. The wrapper-readiness test
checks that `animal()` moved to `grid_writer_available` without being treated
as an Actions task.

## Consistency Audit

The current ledgers now say the same thing: `spatial_mu_slope` has manual
Actions dispatch; `animal()` and `relmat()` have local Phase 18 writers; and
`phylo()` remains the only source-tested Gaussian structured one-slope wrapper
target without a local writer. The public prose keeps this separate from q2/q4
covariance, slope correlations, residual-scale structured slopes, structured
`rho12`, sparse large-pedigree speed, and non-Gaussian structured slopes.

## GitHub Issue Maintenance

This slice advances #442 and #446 after the commit is pushed. It also updates
the sprint parent #436 and PR #445 closeout trail with the local-artifact versus
Actions boundary.

## What Did Not Go Smoothly

The dense-pedigree route needs a local pedigree, relationship matrix, and
inverse relationship matrix in the truth object so future diagnostics can
distinguish fitted SD recovery from pedigree construction. The first pass was
kept intentionally small by using a deterministic dense pedigree rather than
starting a sparse large-pedigree performance lane.

## Team Learning

Structured artifact writers should preserve the covariance object used by the
DGP, not only the scalar SD targets. For `animal()` lanes, that means keeping
the pedigree, `A`, `Ainv`, and realised animal fields together so later
recovery, signal-correlation, and diagnostic reports do not have to reconstruct
the generating structure from output rows.

## Known Limitations

No manual Actions task, `task = "all"` route, interval-status table, formal
recovery grid, coverage grid, power grid, sparse large-pedigree performance
claim, multiple-slope support, structured slope correlation, residual-scale
structured slope, or non-Gaussian structured route was added.

## Next Actions

Add the local artifact writer for the remaining `phylo()` one-slope row, then
decide whether any of the three non-spatial structured one-slope lanes should
receive manual Actions dispatch.
