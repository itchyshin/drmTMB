# Slice 241 Spatial Mu One-Slope Smoke Surface

## Goal

Add a CRAN-safe Phase 18 smoke surface for the fitted coordinate spatial
Gaussian `mu` one-slope path before broad structured-effect simulations begin.

## Implemented

- Added a seeded DGP for
  `bf(y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1)`.
- Added a live `drmTMB()` fit wrapper, parameter summariser, replicate runner,
  and summary-smoke wrapper.
- Updated the simulation README, Phase 18 programme, structured-slope parity
  gate, roadmap, NEWS, and check log.
- Added targeted tests for seeded data, live fit output, result manifests,
  warning/error ledgers, and malformed inputs.

## Mathematical Contract

The smoke surface generates:

```text
eta_mu,ij = beta0 + beta1 x_ij + z0_j + x_ij z1_j
z0 ~ MVN(0, sd0^2 K_coords)
z1 ~ MVN(0, sd1^2 K_coords)
y_ij ~ Normal(eta_mu,ij, sigma^2)
```

The intercept and slope fields are independent and share the same coordinate
spatial precision. This matches the current fitted path; it does not estimate a
spatial intercept-slope correlation.

## Files Changed

- `inst/sim/dgp/sim_dgp_spatial_mu_slope.R`
- `inst/sim/fit/sim_summarise_spatial_mu_slope.R`
- `inst/sim/run/sim_run_spatial_mu_slope_smoke.R`
- `inst/sim/run/sim_summary_spatial_mu_slope_smoke.R`
- `tests/testthat/test-phase18-spatial-mu-slope.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/44-structured-slope-parity-gate.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_spatial_mu_slope.R inst/sim/fit/sim_summarise_spatial_mu_slope.R inst/sim/run/sim_run_spatial_mu_slope_smoke.R inst/sim/run/sim_summary_spatial_mu_slope_smoke.R tests/testthat/test-phase18-spatial-mu-slope.R`
- `Rscript -e "devtools::test(filter = 'phase18-spatial-mu-slope', reporter = 'summary')"`
- `air format inst/sim/dgp/sim_dgp_spatial_mu_slope.R inst/sim/fit/sim_summarise_spatial_mu_slope.R inst/sim/run/sim_run_spatial_mu_slope_smoke.R inst/sim/run/sim_summary_spatial_mu_slope_smoke.R tests/testthat/test-phase18-spatial-mu-slope.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md docs/design/44-structured-slope-parity-gate.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-241-spatial-mu-slope-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-spatial-mu-slope|spatial-gaussian', reporter = 'summary')"`

## Tests Of The Tests

The new tests exercise deterministic DGP seeding, truth metadata, a live
`drmTMB()` spatial one-slope smoke fit, parameter-summary shape, manifest and
failure-ledger output, and malformed DGP/cell inputs.

## Consistency Audit

The smoke surface matches `docs/design/44-structured-slope-parity-gate.md`:
only coordinate spatial Gaussian `mu` one-slope models enter Wave A. The docs
still keep phylogenetic, animal, `relmat()`, spatial `sigma`, bivariate
spatial covariance, and spatial slope correlations planned.

## What Did Not Go Smoothly

The main numerical risk is the same one Fisher flagged for other random-slope
smokes: tiny CRAN-safe fits can converge while Hessian behavior varies across
cells. The summary records `pdHess` instead of using it as the only success
criterion.

## Team Learning

Ada moved a fitted structured-slope surface from roadmap eligibility into the
simulation harness. Curie kept the test deterministic and small. Fisher kept
the smoke surface focused on parameter recovery shape rather than coverage
claims. Darwin kept the spatial question interpretable as baseline and
environmental-response similarity among nearby sites. Rose kept unsupported
structured siblings out of the implemented claim.

## Known Limitations

This slice does not add spatial slope correlations, multiple spatial slopes,
spatial `sigma`, bivariate spatial q=4 covariance, mesh/SPDE, animal, or
`relmat()` fitting. It does not make coverage or power claims.

## Next Actions

Run a neighbouring spatial-regression test set, then move to the next Wave A
non-Gaussian `mu` random-effect surface or start the count-family inference
scout translation from the gllvmTMB notes.
