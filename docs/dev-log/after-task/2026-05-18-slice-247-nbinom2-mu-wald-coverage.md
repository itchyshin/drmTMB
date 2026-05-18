# Slice 247 NB2 Mu Wald Coverage

## Goal

Attach the first real interval producer to the NB2 `mu` random-effect smoke
surface, covering fixed log-mean and log-overdispersion coefficients while
leaving random-effect SD intervals for the direct-profile follow-up.

## Implemented

- Added Wald interval rows to the NB2 summary-smoke wrapper using the generic
  Phase 18 interval-table helper.
- Marked fixed `mu` and fixed `sigma` coefficients as
  `formula_coefficient` intervals.
- Kept random-effect SD rows in the Wald interval table with failed status
  because direct SD profile intervals belong to the next slice.
- Added Wald coverage summaries for finite interval rows.
- Updated tests, the Phase 18 README, design blueprint, roadmap, NEWS, and
  check log.

## Files Changed

- `inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-nbinom2-mu-random-effect.R`
- `inst/sim/README.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

- `air format inst/sim/run/sim_summary_nbinom2_mu_random_effect_smoke.R tests/testthat/test-phase18-nbinom2-mu-random-effect.R inst/sim/README.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-247-nbinom2-mu-wald-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-nbinom2-mu-random-effect|nbinom2-location-scale', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-nbinom2-mu-random-effect|phase18-poisson-mu-random-effect|phase18-sim-uncertainty', reporter = 'summary')"`
- `git diff --check`

## Tests Of The Tests

The NB2 smoke test now expects six Wald interval rows: four successful
formula-coefficient intervals for fixed `mu` and `sigma` terms and two failed
public-SD rows for random-effect SDs. Coverage summaries are expected only for
the four finite fixed-effect intervals.

## Consistency Audit

This matches the staged Poisson pattern: fixed-effect Wald coverage first,
direct random-effect SD profile coverage second. Fisher's boundary is explicit
so readers do not mistake missing random-SD Wald intervals for a completed
coverage claim.

## Team Learning

Fisher separated the Wald and profile claims. Curie kept the smoke assertion
focused on row shape and interval provenance. Pat and Darwin kept the wording
reader-facing. Grace will let this run as a compact CI guard. Rose marked NB2
profile SD intervals as the next open evidence item.

## Known Limitations

This slice does not add direct profile-likelihood intervals for NB2 `sd:mu`
targets, bootstrap intervals, weak-SD grids, zero-inflated NB2 random effects,
or NB2 `sigma` random effects.

## Next Actions

Attach direct profile-likelihood interval rows for the two fitted NB2 `sd:mu`
targets, then decide whether the smoke surface is stable enough to admit a
small weak-SD grid.
