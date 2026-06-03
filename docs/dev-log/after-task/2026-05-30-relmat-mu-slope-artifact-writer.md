# After Task: Relmat Gaussian Mu Slope Artifact Writer

## Goal

Add a local Phase 18 artifact route for the known-matrix `relmat()` Gaussian
`mu` one-slope lane without promoting the row to manual Actions dispatch,
`task = "all"`, recovery, coverage, or power evidence.

## Implemented

- Added `inst/sim/dgp/sim_dgp_relmat_mu_slope.R`.
- Added `inst/sim/fit/sim_summarise_relmat_mu_slope.R`.
- Added `inst/sim/run/sim_run_relmat_mu_slope_smoke.R`.
- Added `inst/sim/run/sim_summary_relmat_mu_slope_smoke.R`.
- Added `inst/sim/run/sim_write_relmat_mu_slope_grid.R`.
- Added `tests/testthat/test-phase18-relmat-mu-slope.R`.
- Updated structured-dependence wrapper readiness so the `relmat()` one-slope
  row reports `grid_writer_available` while remaining a wrapper target.
- Updated source and rendered reader-facing ledgers to distinguish
  `spatial_mu_slope` Actions readiness, local `relmat()` artifact readiness,
  and `phylo()`/`animal()` source-tested wrapper targets.

## Mathematical Contract

The DGP uses one Gaussian response with

```text
y_ij ~ Normal(mu_ij, sigma^2)
mu_ij = beta0 + beta1 x_ij + a0_j + a1_j x_ij
a0 ~ MVN(0, sd_intercept^2 K)
a1 ~ MVN(0, sd_slope^2 K)
Cov(a0, a1) = 0
```

The fitted model is

```r
bf(y ~ x + relmat(1 + x | id, Q = Q), sigma ~ 1)
```

The writer records fixed `mu` coefficients, residual `sigma`, and the two
direct `relmat()` `mu` SD rows. It does not estimate or report a structured
intercept-slope correlation, multiple `relmat()` slopes, residual-scale
structured slopes, structured `rho12`, recovery, coverage, or power.

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
- `inst/sim/dgp/sim_dgp_relmat_mu_slope.R`
- `inst/sim/fit/sim_summarise_relmat_mu_slope.R`
- `inst/sim/run/sim_phase18_structured_dependence_wrapper_readiness.R`
- `inst/sim/run/sim_run_relmat_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_relmat_mu_slope_smoke.R`
- `inst/sim/run/sim_write_relmat_mu_slope_grid.R`
- `tests/testthat/test-phase18-relmat-mu-slope.R`
- `tests/testthat/test-phase18-structured-dependence-wrapper-readiness.R`
- `vignettes/phylogenetic-spatial.Rmd`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The new test exercises reproducibility, truth metadata, realised structured
fields, the local no-correlation extractor contract, smoke summaries, artifact
creation, overwrite protection, and malformed DGP inputs. The wrapper-readiness
test checks that `relmat()` moved to `grid_writer_available` without being
treated as an Actions task.

## Consistency Audit

The current ledgers now say the same thing: `spatial_mu_slope` has manual
Actions dispatch; `relmat()` has a local Phase 18 writer; `phylo()` and
`animal()` remain source-tested wrapper targets. The public prose keeps this
separate from q2/q4 covariance, slope correlations, residual-scale structured
slopes, structured `rho12`, and non-Gaussian structured slopes.

## GitHub Issue Maintenance

This slice advances #442 and #446 after the commit is pushed. It also updates
the sprint parent #436 and PR #445 closeout trail with the local-artifact versus
Actions boundary.

## What Did Not Go Smoothly

The first pass wrote the DGP truth needed for aggregate SD recovery but did not
retain realised intercept and slope fields. Hume caught that gap because the
ADEMP sheet names conditional structured-slope signal as a later diagnostic.
The DGP now stores both fields in `truth`.

## Team Learning

When an ADEMP sheet names a future diagnostic that needs realised latent
fields, the corresponding DGP should retain those fields immediately, even if
the first artifact writer only summarizes fixed effects and SDs. New
independent-slope artifact lanes should also assert the absence of correlation
extractor rows locally, not only in neighbouring source tests.

## Known Limitations

No manual Actions task, `task = "all"` route, interval-status table, formal
recovery grid, coverage grid, power grid, multiple-slope support, structured
slope correlation, residual-scale structured slope, or non-Gaussian structured
route was added.

## Next Actions

Add local artifact writers for `phylo()` and `animal()` one-slope rows, then
decide whether any of the three non-spatial structured one-slope lanes should
receive manual Actions dispatch.
