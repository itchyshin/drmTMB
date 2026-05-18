# Slice 237 Gaussian Mu Random-Slope Smoke Surface

## Goal

Give the fitted ordinary Gaussian `mu` q=3 random-slope block a Phase 18 smoke
surface before larger simulation grids are allowed.

## Implemented

- Added a seeded DGP for `(1 + x1 + x2 | id)` ordinary Gaussian `mu` models.
- Added a replicate runner that fits
  `bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ 1)`.
- Added a summariser for fixed `mu` coefficients, public residual `sigma`, q=3
  random-slope SDs, and q=3 random-effect correlations.
- Added an aggregate summary helper that returns bias/RMSE/MCSE summaries,
  manifests, and warning/error ledgers.
- Added CRAN-safe smoke tests for seeded data, the q=3 run path, and malformed
  input errors.

## Mathematical Contract

The DGP uses:

```text
mu_ij = beta0 + beta1 x1_ij + beta2 x2_ij + b0_j + b1_j x1_ij + b2_j x2_ij
[b0_j, b1_j, b2_j]' ~ MVN(0, Sigma_id)
y_ij ~ Normal(mu_ij, sigma^2)
```

The fitted model is the same ordinary grouped random-slope surface:

```r
bf(y ~ x1 + x2 + (1 + x1 + x2 | id), sigma ~ 1)
```

The q=3 SDs are direct fitted quantities. The q=3 correlations are reported as
derived random-effect correlations and remain outside direct profile-interval
coverage.

## Files Changed

- `inst/sim/dgp/sim_dgp_gaussian_mu_random_slope.R`
- `inst/sim/fit/sim_summarise_gaussian_mu_random_slope.R`
- `inst/sim/run/sim_run_gaussian_mu_random_slope_smoke.R`
- `inst/sim/run/sim_summary_gaussian_mu_random_slope_smoke.R`
- `tests/testthat/test-phase18-gaussian-mu-random-slope.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_gaussian_mu_random_slope.R inst/sim/fit/sim_summarise_gaussian_mu_random_slope.R inst/sim/run/sim_run_gaussian_mu_random_slope_smoke.R inst/sim/run/sim_summary_gaussian_mu_random_slope_smoke.R tests/testthat/test-phase18-gaussian-mu-random-slope.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-237-gaussian-mu-random-slope-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-gaussian-mu-random-slope', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|phase18-gaussian-mu-random-slope', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The new smoke test exercises a live q=3 random-slope fit, verifies the 10-row
summary surface, checks the manifest/failure-ledger output, and confirms that a
malformed cell errors before fitting.

## Consistency Audit

The Phase 18 blueprint, `inst/sim/README.md`, roadmap, NEWS, check log, and this
after-task note now agree that q=3 ordinary Gaussian `mu` random slopes have a
smoke surface. This is still an advanced fitted surface, not a claim that large
q blocks have reliable inference.

## What Did Not Go Smoothly

The first test draft expected every smoke fit to have a positive-definite
Hessian and finite fixed-effect standard errors. The live q=3 smoke fit showed
that convergence and `pdHess` can separate. The test now records `pdHess`
explicitly instead of requiring the advanced surface to look routine.

## Team Learning

Curie kept the smoke surface small. Fisher insisted that Hessian status remain
visible. Rose prevented the roadmap from turning one smoke fit into a broad
random-slope inference claim. Pat kept the fitted formula visible beside the
summary outputs. Grace kept the validation targeted for this slice.

## Known Limitations

This slice does not add Wald/profile coverage for q=3 SDs or derived
correlations. It does not cover factor slopes, bivariate slopes, correlated
Gaussian `sigma` slope blocks, phylogenetic slopes, or non-Gaussian random
slopes.

## Next Actions

Use Slice 238 to audit and harden the Gaussian `sigma` independent
random-slope boundary before any scale-side slope grid enters Phase 18.
