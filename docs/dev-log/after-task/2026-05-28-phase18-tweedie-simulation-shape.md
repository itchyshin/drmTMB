# After-Task Report: Phase 18 Tweedie Simulation Shape Hardening

Date: 2026-05-28

## Goal

Harden the fitted Tweedie `simulate()` method test for output shape,
missing-row filtering, exact-zero support, and seed reproducibility without
widening the fitted Tweedie surface.

## Implemented

`tests/testthat/test-tweedie-location-scale.R` now checks that a Tweedie fit
after ordinary model-frame filtering produces simulated draws with the expected
data-frame dimensions, column names, fitted-row count, finite non-negative
values, exact zeros, and repeated-seed reproducibility.

## Files Changed

- `tests/testthat/test-tweedie-location-scale.R`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-tweedie-location-scale.R docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-tweedie-simulation-shape.md
Rscript --vanilla -e "devtools::test(filter = '^tweedie-location-scale$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.
Focused `test-tweedie-location-scale` passed, `pkgdown::check_pkgdown()`
reported no problems, and `git diff --check` was clean.

## Tests Of The Tests

The hardened test changes the input data before fitting by making one
predictor row missing, then checks that simulated output follows the fitted
row count rather than the raw input row count. It also checks deterministic
seed replay and exact-zero/non-negative support in the same fixed-effect
Tweedie route.

## Known Limitations

This is not a recovery, coverage, or external-comparator test. It does not add
Tweedie offsets, predictor-dependent `nu`, random effects, structured effects,
bivariate Tweedie, zero-inflation aliases, or hurdle aliases.
