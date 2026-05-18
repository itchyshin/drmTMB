# Slice 252 Count Pilot Condition Grids

## Goal

Make the ready Poisson and NB2 `mu` random-effect pilot surfaces usable as
actual condition grids, not only one-cell smoke examples.

## Implemented

- Updated `phase18_poisson_mu_re_conditions()` to cross group count,
  observations per group, true random-effect SDs, and fixed log-mean effects.
- Updated `phase18_nbinom2_mu_re_conditions()` to cross the same mean-side
  conditions plus fixed log-overdispersion settings.
- Added tests for crossed Poisson and NB2 condition shapes and column names.
- Updated the Phase 18 README, blueprint, roadmap, NEWS, and check log.

## Files Changed

- `inst/sim/dgp/sim_dgp_poisson_mu_random_effect.R`
- `inst/sim/dgp/sim_dgp_nbinom2_mu_random_effect.R`
- `tests/testthat/test-phase18-poisson-mu-random-effect.R`
- `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/dgp/sim_dgp_poisson_mu_random_effect.R inst/sim/dgp/sim_dgp_nbinom2_mu_random_effect.R tests/testthat/test-phase18-poisson-mu-random-effect.R tests/testthat/test-phase18-nbinom2-mu-random-effect.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-252-count-pilot-condition-grids.md`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|phase18-nbinom2-mu-random-effect|phase18-count-mu-random-effect-pilot', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-sim-skeleton|phase18-sim-runner|phase18-sim-aggregate|phase18-sim-uncertainty', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The tests now check that Poisson conditions cross `n_group` and
`sd_intercept`, and that NB2 conditions additionally cross
`beta_sigma_intercept`. Existing one-cell DGP and smoke tests still use scalar
condition values.

## Consistency Audit

This is a simulation-design slice. It changes condition-table construction
only; fitted likelihoods, summaries, and interval producers are unchanged.

## Team Learning

Curie made the grid shape explicit. Fisher kept the varied quantities tied to
estimands we can already summarize. Florence benefits because plots can facet
or colour by true SD and overdispersion. Rose kept the slice out of model
implementation claims.

## Known Limitations

This slice does not run a large grid, choose replicate counts, or add figure
helpers.

## Next Actions

Add a compact pilot-grid report or plotting-data helper that turns count pilot
outputs into Florence's figure-gallery inputs.
