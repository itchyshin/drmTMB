# Slice 242 Poisson Mu Random-Effect Smoke Surface

## Goal

Add a CRAN-safe Phase 18 smoke surface for the fitted ordinary
non-zero-inflated Poisson `mu` random-effect path.

## Implemented

- Added a seeded DGP for
  `bf(count ~ x + (1 | id) + (0 + x | id))` with
  `family = poisson(link = "log")`.
- Added a live `drmTMB()` fit wrapper, parameter summariser, replicate runner,
  and summary-smoke wrapper.
- Updated the simulation README, Phase 18 programme, roadmap, NEWS, and check
  log.
- Added targeted tests for seeded count data, live fit output, result
  manifests, warning/error ledgers, and malformed inputs.

## Mathematical Contract

The smoke surface generates:

```text
count_ij ~ Poisson(mu_ij)
log(mu_ij) = beta0 + beta1 x_ij + b0_j + x_ij b1_j
b0_j ~ Normal(0, sd0^2)
b1_j ~ Normal(0, sd1^2)
cov(b0_j, b1_j) = 0
```

This matches the current fitted non-Gaussian boundary: ordinary Poisson `mu`
random intercepts plus independent numeric slopes, not correlated Poisson
slope blocks or cross-parameter covariance.

## Files Changed

- `inst/sim/dgp/sim_dgp_poisson_mu_random_effect.R`
- `inst/sim/fit/sim_summarise_poisson_mu_random_effect.R`
- `inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R`
- `inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-poisson-mu-random-effect.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_poisson_mu_random_effect.R inst/sim/fit/sim_summarise_poisson_mu_random_effect.R inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R tests/testthat/test-phase18-poisson-mu-random-effect.R`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect', reporter = 'summary')"`
- `air format inst/sim/dgp/sim_dgp_poisson_mu_random_effect.R inst/sim/fit/sim_summarise_poisson_mu_random_effect.R inst/sim/run/sim_run_poisson_mu_random_effect_smoke.R inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R tests/testthat/test-phase18-poisson-mu-random-effect.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-242-poisson-mu-random-effect-smoke.md`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean', reporter = 'summary')"`

## Tests Of The Tests

The new tests exercise deterministic DGP seeding, count-valued output, truth
metadata, a live `drmTMB()` Poisson random-effect smoke fit, parameter-summary
shape, manifest and failure-ledger output, and malformed DGP/cell inputs.

## Consistency Audit

The smoke surface matches the non-Gaussian random-effect gate: it includes
ordinary Poisson `mu` random intercepts and independent numeric slopes, but it
does not claim zero-inflated Poisson random effects, NB2 random effects,
non-Gaussian scale or shape random effects, labelled covariance, or
cross-parameter covariance.

## What Did Not Go Smoothly

The main risk is teaching this as "non-Gaussian random effects are done." They
are not. This is the first Poisson `mu` surface, and it stays intentionally
separate from zero inflation, overdispersion, hurdle, bounded-response, shape,
and structured non-Gaussian surfaces.

## Team Learning

Ada moved the allowed Poisson pilot into the same Phase 18 harness as the
Gaussian surfaces. Curie kept the smoke deterministic and count-valued. Fisher
kept the estimands on the log-mean and SD scales. Pat kept the unsupported
neighbouring models visible. Rose kept the non-Gaussian claim narrow.

## Known Limitations

This slice does not add correlated Poisson random-slope blocks, labelled
non-Gaussian covariance, NB2 random effects, zero-inflated or hurdle count
random effects, non-Gaussian scale/shape random effects, structured count
random effects, or cross-parameter covariance.

## Next Actions

Use the next slice to decide whether NB2 `mu` random effects or count-family
inference hardening should come first.
