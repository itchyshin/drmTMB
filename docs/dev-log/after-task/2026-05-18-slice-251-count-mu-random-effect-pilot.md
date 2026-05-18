# Slice 251 Count Mu Random-Effect Pilot

## Goal

Start Phase 18 simulation with the first paired ready surfaces: ordinary
non-zero-inflated Poisson and NB2 `mu` random effects.

## Implemented

- Added `phase18_summarise_count_mu_re_pilot()` under `inst/sim/run/`.
- The helper runs the existing Poisson and NB2 `mu` random-effect smoke
  surfaces with separate result subdirectories.
- It returns combined aggregate, manifest, failure-ledger, Wald interval, Wald
  coverage, profile interval, and profile coverage tables.
- Added CRAN-safe tests for one paired Poisson/NB2 replicate and input
  validation.
- Updated the Phase 18 README, blueprint, roadmap, NEWS, and check log.

## Files Changed

- `inst/sim/run/sim_summary_count_mu_random_effect_pilot.R`
- `tests/testthat/test-phase18-count-mu-random-effect-pilot.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/run/sim_summary_count_mu_random_effect_pilot.R tests/testthat/test-phase18-count-mu-random-effect-pilot.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-251-count-mu-random-effect-pilot.md`
- `Rscript -e "devtools::test(filter = 'phase18-count-mu-random-effect-pilot|phase18-poisson-mu-random-effect|phase18-nbinom2-mu-random-effect', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-count-mu-random-effect-pilot|phase18-sim-aggregate|phase18-sim-runner|phase18-sim-uncertainty', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The smoke test runs one Poisson and one NB2 cell, checks that both manifests
finish with status `ok`, verifies combined aggregate and interval table sizes,
and confirms that separate result subdirectories are created for each surface.

## Consistency Audit

This is still a pilot, not a final operating-characteristic grid. It combines
only surfaces that already have smoke runners, fixed-effect Wald intervals,
direct random-effect SD profiles, and weak-SD diagnostics.

## Team Learning

Ada kept the pilot paired but narrow. Fisher kept coverage provenance explicit.
Curie kept the routine test to one replicate per family. Grace can use the
helper for optional scheduled grids without burdening CRAN checks. Florence now
has one combined count-family output shape to use for the later figure gallery.
Rose kept blocked surfaces out of the pilot.

## Known Limitations

This slice does not vary group count, repeats, true SD, mean count, or NB2
overdispersion across a real grid in routine tests. It does not add plotting
helpers or final simulation reports.

## Next Actions

Add a small optional condition grid summary for count-family pilots, then build
Florence's figure-gallery layer from the combined aggregate, interval, and
failure-ledger tables.
