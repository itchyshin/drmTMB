# Slice 238 Gaussian Sigma Random-Slope Smoke Surface

## Goal

Give the fitted Gaussian residual-scale one-slope path a Phase 18 smoke surface
while keeping the current independent-slope boundary explicit.

## Implemented

- Added a seeded DGP for `sigma ~ z + (0 + w | id)` Gaussian models.
- Added a replicate runner that fits
  `bf(y ~ x, sigma ~ z + (0 + w | id))`.
- Added a summariser for fixed `mu` coefficients, fixed `sigma` coefficients
  on the modelled `log(sigma)` scale, and the direct residual-scale
  random-slope SD.
- Added an aggregate summary helper that returns bias/RMSE/MCSE summaries,
  manifests, and warning/error ledgers.
- Added CRAN-safe smoke tests for seeded data, live one-slope fitting, and
  malformed input errors.

## Mathematical Contract

The DGP uses:

```text
mu_ij = beta0 + beta1 x_ij
log(sigma_ij) = gamma0 + gamma1 z_ij + w_ij a_j
a_j ~ Normal(0, sd_sigma_w^2)
y_ij ~ Normal(mu_ij, sigma_ij^2)
```

The fitted model is:

```r
bf(y ~ x, sigma ~ z + (0 + w | id))
```

The random-slope SD is a direct quantity on the `log(sigma)` scale. Correlated
scale intercept-slope blocks, labelled scale-slope covariance, and
cross-parameter slope covariance remain planned.

## Files Changed

- `inst/sim/dgp/sim_dgp_gaussian_sigma_random_slope.R`
- `inst/sim/fit/sim_summarise_gaussian_sigma_random_slope.R`
- `inst/sim/run/sim_run_gaussian_sigma_random_slope_smoke.R`
- `inst/sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R`
- `tests/testthat/test-phase18-gaussian-sigma-random-slope.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_gaussian_sigma_random_slope.R inst/sim/fit/sim_summarise_gaussian_sigma_random_slope.R inst/sim/run/sim_run_gaussian_sigma_random_slope_smoke.R inst/sim/run/sim_summary_gaussian_sigma_random_slope_smoke.R tests/testthat/test-phase18-gaussian-sigma-random-slope.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-238-gaussian-sigma-random-slope-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-sigma-random-slope', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|phase18-gaussian-sigma-random-slope', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The new smoke test exercises a live residual-scale one-slope fit, verifies the
5-row summary surface, checks manifest/failure-ledger output, and confirms that
malformed cells error before fitting.

## Consistency Audit

The Phase 18 blueprint, `inst/sim/README.md`, roadmap, NEWS, check log, and this
after-task note now agree that the Gaussian `sigma` independent one-slope path
has smoke-simulation bookkeeping. The docs still keep correlated scale-slope
blocks and labelled scale-slope covariance planned.

## What Did Not Go Smoothly

This slice was more straightforward than Slice 237 because the target is a
single independent scale-slope SD, not a q=3 unstructured covariance block.
The main caution is interpretation: this is group variation in residual scale
on `log(sigma)`, not mean plasticity and not `sd(group) ~ x`.

## Team Learning

Curie kept the smoke grid small. Fisher kept the modelled scale explicit.
Noether checked the equation and R syntax against the summary rows. Pat kept
the user-facing boundary separate from ordinary `mu` slopes. Rose kept
correlated scale-slope claims out of this slice. Grace kept validation targeted.

## Known Limitations

This slice does not add correlated Gaussian `sigma` slope blocks, multiple
scale-slope simulation grids, slope-level `mu`/`sigma` covariance, bivariate
scale slopes, or non-Gaussian scale random effects.

## Next Actions

Use Slice 239 to audit structured-effect one-slope parity across phylogenetic,
coordinate-spatial, animal, and `relmat()` surfaces before the count-family
and mixed-family gates.
