# Slice 246 NB2 Mu Random-Effect Smoke

## Goal

Give the newly fitted ordinary non-zero-inflated NB2 `mu` random-effect path
the same Phase 18 smoke-runner bookkeeping that Poisson already has, before
any larger NB2 simulation grid or interval-coverage claim is made.

## Implemented

- Added a seeded NB2 DGP for log-mean random intercepts and independent numeric
  random slopes, with fixed-effect overdispersion `sigma ~ z`.
- Added a live smoke runner that fits
  `bf(count ~ x + (1 | id) + (0 + x | id), sigma ~ z)` with `nbinom2()`.
- Added a fit summariser for fixed `mu` coefficients, fixed `sigma`
  coefficients, and direct `sd:mu` random-effect SD targets.
- Added a summary-smoke wrapper that returns grouped bias/RMSE/MCSE summaries,
  replicate manifests, and warning/error ledgers.
- Added CRAN-safe tests for seeded reproducibility, live fit output shape,
  saved-result paths, finite summaries, and malformed inputs.
- Updated the Phase 18 README, design blueprint, roadmap, NEWS, and check log.

## Mathematical Contract

The smoke surface uses the fitted Slice 245 likelihood path:

```text
y_i | mu_i, sigma_i ~ NB2(mu_i, size_i)
log(mu_i) = beta_0 + beta_x x_i + b_0[id_i] + b_x[id_i] x_i
log(sigma_i) = gamma_0 + gamma_z z_i
size_i = 1 / sigma_i^2
b_0j = sd_0 u_0j
b_xj = sd_x u_xj
u_0j, u_xj ~ Normal(0, 1)
```

The smoke output records `mu` fixed effects, `sigma` fixed effects, and public
`sd:mu` estimates. It does not yet attach Wald or profile interval producers.

## Files Changed

- `inst/sim/dgp/sim_dgp_nbinom2_mu_random_effect.R`
- `inst/sim/fit/sim_summarise_nbinom2_mu_random_effect.R`
- `inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R`
- `inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_nbinom2_mu_random_effect.R inst/sim/fit/sim_summarise_nbinom2_mu_random_effect.R inst/sim/run/sim_run_nbinom2_mu_random_effect_smoke.R inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R tests/testthat/test-phase18-nbinom2-mu-random-effect.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-246-nbinom2-mu-random-effect-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-nbinom2-mu-random-effect|nbinom2-location-scale', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-nbinom2-mu-random-effect|phase18-poisson-mu-random-effect|phase18-sim-aggregate|phase18-sim-runner', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The live smoke test runs one small NB2 replicate, verifies a successful
manifest row, checks the six expected parameter-summary rows, confirms finite
estimates and errors, and verifies that the per-replicate RDS result was saved.
Malformed-input tests guard impossible group sizes, negative SDs, and missing
condition columns.

## Consistency Audit

This slice deliberately follows the Poisson smoke-runner shape but keeps NB2
interval inference separate. That boundary prevents the simulation programme
from implying coverage evidence before Wald and direct-profile producers have
been attached and tested for NB2.

## Team Learning

Ada kept this as a smoke-surface slice rather than a broad NB2 grid. Gauss and
Noether checked that the DGP mirrors the fitted NB2 parameterization from Slice
245. Curie kept the test deterministic and small enough for CRAN-style runs.
Fisher kept interval coverage out of the claim set. Pat and Darwin kept the
README and roadmap wording explicit for applied readers. Grace will use this
surface as a compact CI guard. Rose marked NB2 interval coverage as the next
unfinished evidence step.

## Known Limitations

This slice does not add NB2 Wald intervals, NB2 direct-profile SD intervals,
weak-SD/boundary grids, zero-truncated NB2 random effects, zero-inflated NB2
random effects, NB2 `sigma` random effects, or correlated/labelled NB2
random-slope blocks.

## Next Actions

Attach fixed-effect Wald interval rows for the NB2 smoke output, then add direct
profile-likelihood interval rows for the NB2 `sd:mu` targets if the tiny smoke
profile remains stable.
