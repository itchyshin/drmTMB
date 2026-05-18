# Slice 243 Poisson Mu Wald Coverage

## Goal

Attach interval rows and coverage summaries to the Poisson `mu` random-effect
smoke output without pretending that random-effect SD intervals are already
available.

## Implemented

- Added `wald_intervals` to
  `phase18_summarise_poisson_mu_re_smoke()`.
- Added `wald_coverage` for fixed log-mean coefficient rows with finite
  standard errors.
- Kept random-effect SD rows in the interval table with failed status because
  direct SD profile intervals are a later producer.
- Updated tests, Phase 18 design notes, NEWS, and the check log.

## Mathematical Contract

For fixed log-mean coefficients, the smoke surface uses the existing Wald
interval helper:

```text
beta_hat +/- z_(0.975) SE(beta_hat)
```

The reported scale is `formula_coefficient`. Random-effect SD estimates are
positive public SDs, but this slice does not invent a Wald SE for them.

## Files Changed

- `inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R`
- `tests/testthat/test-phase18-poisson-mu-random-effect.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `NEWS.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format inst/sim/run/sim_summary_poisson_mu_random_effect_smoke.R tests/testthat/test-phase18-poisson-mu-random-effect.R docs/design/41-phase-18-simulation-programme.md NEWS.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-slice-243-poisson-mu-wald-coverage.md`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect', reporter = 'summary')"`
- `Rscript -e "devtools::test(filter = 'phase18-poisson-mu-random-effect|poisson-mean', reporter = 'summary')"`

## Tests Of The Tests

The updated test checks that two fixed `mu` rows receive `ok` Wald intervals,
that two random-effect SD rows remain visible with failed interval status, and
that coverage summaries are only produced for interval-ready fixed-effect rows.

## Consistency Audit

This keeps the interval rule aligned with the Phase 18 interval-producer
contract: fixed-effect Wald intervals are allowed when standard errors exist;
random-effect SD intervals need profile or another explicitly tested producer.

## What Did Not Go Smoothly

The tempting shortcut was to drop failed random-effect SD rows from the
interval table. Keeping them visible is better because it shows exactly which
important estimands still need profile coverage.

## Team Learning

Fisher kept the interval target honest. Curie made the test check both the
working fixed-effect rows and the intentionally missing SD interval rows. Pat
kept the output interpretable for a user reading coverage tables. Rose kept the
missing SD profile producer visible instead of silently filtered away.

## Known Limitations

This slice does not compute random-effect SD intervals for the Poisson
random-effect smoke surface. It also does not add NB2, zero-inflated, hurdle,
or cross-parameter count models.

## Next Actions

Add a direct profile interval producer for Poisson random-effect SD targets, or
advance to NB2 `mu` random-effect implementation if the next priority is
family breadth rather than interval depth.
