# After Task: Phylo Gaussian Mu Slope Artifact Writer

## Goal

Add a local Phase 18 artifact route for the phylogenetic Gaussian `mu`
one-slope lane without promoting the row to manual Actions dispatch,
`task = "all"`, recovery, coverage, power, multiple phylogenetic slopes, slope
correlations, residual-scale structured slopes, or non-Gaussian structured
effects.

## Implemented

- Added `inst/sim/dgp/sim_dgp_phylo_mu_slope.R`.
- Added `inst/sim/fit/sim_summarise_phylo_mu_slope.R`.
- Added `inst/sim/run/sim_run_phylo_mu_slope_smoke.R`.
- Added `inst/sim/run/sim_summary_phylo_mu_slope_smoke.R`.
- Added `inst/sim/run/sim_write_phylo_mu_slope_grid.R`.
- Added `tests/testthat/test-phase18-phylo-mu-slope.R`.
- Updated structured-dependence wrapper readiness so the `phylo()` one-slope
  row reports `grid_writer_available` while remaining a wrapper target.
- Updated source and rendered reader-facing ledgers to distinguish
  `spatial_mu_slope` Actions readiness, local `phylo()`/`animal()`/`relmat()`
  artifact readiness, and formal recovery/coverage/power evidence.

## Mathematical Contract

The DGP uses one Gaussian response with

```text
y_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta0 + beta1 x_ij + a0_j + a1_j x_ij
a0 ~ MVN(0, sd_intercept^2 A)
a1 ~ MVN(0, sd_slope^2 A)
Cov(a0, a1) = 0
```

where `A` is the tree-derived tip covariance matrix from a deterministic
balanced tree. The fitted model is

```r
bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1)
```

The writer records fixed `mu` coefficients, residual `sigma`, and the two
direct `phylo()` `mu` SD rows. It does not estimate or report a phylogenetic
intercept-slope correlation, multiple phylogenetic slopes, residual-scale
structured slopes, structured `rho12`, non-Gaussian structured slopes,
recovery, coverage, or power.

## Files Changed

- `NEWS.md`
- `README.md`
- `ROADMAP.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/design/143-phase-18-structured-workflow-registry.md`
- `docs/design/148-phase6c-structured-one-slope-ademp.md`
- `docs/dev-log/check-log.md`
- `inst/sim/README.md`
- `inst/sim/dgp/sim_dgp_phylo_mu_slope.R`
- `inst/sim/fit/sim_summarise_phylo_mu_slope.R`
- `inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R`
- `inst/sim/run/sim_run_phylo_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_phylo_mu_slope_smoke.R`
- `inst/sim/run/sim_write_phylo_mu_slope_grid.R`
- `tests/testthat/test-phase18-phylo-mu-slope.R`
- `tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The new test exercises reproducibility, truth metadata, the balanced tree,
tree-derived tip covariance, realised phylogenetic intercept and slope fields,
the local no-correlation extractor contract, smoke summaries, artifact
creation, overwrite protection, and malformed DGP inputs. The
wrapper-readiness test checks that `phylo()` moved to `grid_writer_available`
without being treated as an Actions task.

## Consistency Audit

The current ledgers now say the same thing: `spatial_mu_slope` has manual
Actions dispatch; `phylo()`, `animal()`, and `relmat()` have local Phase 18
writers as non-Actions wrapper targets; and recovery, coverage, power, multiple
structured slopes, slope correlations, residual-scale structured slopes, and
non-Gaussian structured slopes remain planned or outside this slice.

## GitHub Issue Maintenance

This slice advances #442 and #446 after the commit is pushed. It also updates
the sprint parent #436 and PR #445 closeout trail with the local-artifact versus
Actions boundary.

## What Did Not Go Smoothly

The first combined readiness test indexed `status_counts[["source_test_ready"]]`
after the last source-only row moved to `grid_writer_available`. The test now
asserts that the bucket is absent by name, which is the intended current state.

## Team Learning

Source-test fixtures are useful starting points, but each admitted simulation
lane should own its DGP under `inst/sim/dgp/` with enough truth metadata for
future recovery diagnostics. For `phylo()`, that means preserving the tree, tip
covariance, and realised phylogenetic fields together with scalar targets.

## Known Limitations

No manual Actions task, `task = "all"` route, interval-status table, formal
recovery grid, coverage grid, power grid, multiple-slope support, structured
slope correlation, residual-scale structured slope, structured `rho12`, or
non-Gaussian structured route was added.

## Next Actions

Decide whether any non-spatial structured one-slope writer should receive
manual Actions dispatch, then use #446 to design formal recovery, accuracy,
coverage, and power grids across the four structured routes.
