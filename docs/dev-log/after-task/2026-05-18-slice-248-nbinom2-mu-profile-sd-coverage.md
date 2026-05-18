# Slice 248 NB2 Mu Profile SD Coverage

## Goal

Attach direct profile-likelihood interval rows and coverage summaries for the
two fitted NB2 `mu` random-effect SD targets in the Phase 18 smoke output.

## Implemented

- Added optional direct profile calls to the NB2 smoke-fit summariser for
  random-intercept and independent random-slope SD parameters.
- Added `profile_intervals` and `profile_coverage` outputs to the NB2
  summary-smoke wrapper.
- Kept the smoke profile level at 0.70, matching the Poisson smoke surface and
  avoiding full-grid coverage claims.
- Updated tests, the Phase 18 README, design blueprint, roadmap, NEWS, and
  check log.

## Files Changed

- `inst/sim/fit/sim_summarise_nbinom2_mu_random_effect.R`
- `inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/fit/sim_summarise_nbinom2_mu_random_effect.R inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R tests/testthat/test-phase18-nbinom2-mu-random-effect.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-248-nbinom2-mu-profile-sd-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-nbinom2-mu-random-effect|nbinom2-location-scale', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-nbinom2-mu-random-effect|phase18-poisson-mu-random-effect|phase18-sim-uncertainty|profile-targets', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The NB2 smoke test now expects two profile interval rows, one for the random
intercept SD and one for the independent random-slope SD, and two coverage rows
when both profile intervals are finite.

## Consistency Audit

The profile targets are direct public SD targets exposed by the fitted NB2
random-effect path. The slice does not profile correlated or labelled blocks
because those model classes remain closed.

## Team Learning

Fisher got direct interval evidence for the NB2 random-effect SDs before any
larger NB2 grid. Gauss and Noether kept the profile target names aligned with
the fitted `sd:mu` rows. Curie kept the smoke profile small. Grace will watch
runtime on CI. Rose marked weak-SD and boundary grids as follow-up evidence,
not completed validation.

## Known Limitations

This slice does not add bootstrap intervals, weak-SD/boundary grids,
zero-truncated NB2 random effects, zero-inflated NB2 random effects, NB2
`sigma` random effects, or correlated/labelled NB2 random-slope blocks.

## Next Actions

Run a weak-SD NB2 diagnostic smoke or return to the next pre-simulation
non-Gaussian gate, depending on how CI handles the profile runtime.
