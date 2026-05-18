# Slice 244 Poisson Mu Profile SD Coverage

## Goal

Attach direct profile-likelihood intervals and coverage summaries for Poisson
`mu` random-effect SD targets in the Phase 18 smoke output.

## Implemented

- Extended `phase18_summarise_poisson_mu_re_fit()` to profile random-effect SD
  targets by default during smoke summarisation.
- Added `profile_intervals` and `profile_coverage` outputs to
  `phase18_summarise_poisson_mu_re_smoke()`.
- Updated tests, Phase 18 design notes, NEWS, and the check log.

## Mathematical Contract

The profiled targets are direct `log_sd_mu` parameters:

```text
sd0 = exp(log_sd_mu[1])
sd1 = exp(log_sd_mu[2])
```

The profile fixes one `log_sd_mu` parameter at a time and re-optimizes the
remaining nuisance parameters, then reports intervals on the public SD scale.

## Files Changed

- `inst/sim/fit/sim_summarise_poisson_mu_random_effect.R`
- `inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-poisson-mu-random-effect.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/fit/sim_summarise_poisson_mu_random_effect.R inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R tests/testthat/test-phase18-poisson-mu-random-effect.R docs/design/41-phase-18-simulation-programme.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-244-poisson-mu-profile-sd-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean|profile-targets', reporter = 'summary')"`

## Tests Of The Tests

The updated smoke test checks that both random-effect SD rows receive profile
intervals and that each profile-ready SD row contributes one coverage row.

## Consistency Audit

This follows `docs/design/12-profile-likelihood-cis.md`: Poisson `mu`
random-effect SDs are direct `log_sd_mu` targets, while non-Gaussian
cross-parameter covariance, zero-inflation random effects, and NB2 random
effects remain separate future surfaces.

## What Did Not Go Smoothly

The profile route was faster than expected for the tiny smoke cell, but it
still belongs in a smoke harness rather than broad CRAN examples. Larger grids
should record profile failures instead of assuming every profile succeeds.

## Team Learning

Fisher moved the count smoke from point-estimate-only to interval-aware. Curie
kept the profile test small. Grace kept runtime risk visible. Pat kept the SD
scale explicit. Rose kept profile coverage limited to direct SD targets.

## Known Limitations

This slice does not add profile intervals for NB2, zero-inflated, hurdle,
scale, shape, structured, or cross-parameter non-Gaussian targets. It does not
claim final coverage, power, or runtime evidence.

## Next Actions

Use the next count-family slice to decide whether NB2 `mu` random intercepts
should be implemented now or whether the count-inference audit should first
record cross-package lessons once the gllvmTMB scout note is accessible.
