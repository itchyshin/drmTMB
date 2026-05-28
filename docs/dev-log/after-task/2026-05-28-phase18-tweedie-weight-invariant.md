# After-Task Report: Phase 18 Tweedie Weight Invariant

Date: 2026-05-28

## Goal

Add an internal Tweedie row-weight invariant without opening the postponed
weighted external comparator.

## Implemented

`tests/testthat/test-tweedie-location-scale.R` now checks that constant
Tweedie row weights double the log-likelihood without changing `mu`, `sigma`,
or intercept-only `nu`, and that integer row weights including zero weights
match explicit row duplication.

## Files Changed

- `tests/testthat/test-tweedie-location-scale.R`
- `docs/design/131-phase-18-tweedie-weight-invariant-slice-1631-addendum.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-tweedie-location-scale.R docs/design/131-phase-18-tweedie-weight-invariant-slice-1631-addendum.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-28-phase18-tweedie-weight-invariant.md
Rscript --vanilla -e "devtools::test(filter = '^tweedie-location-scale$', reporter = 'summary')"
Rscript --vanilla -e "pkgdown::check_pkgdown()"
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.
Focused `test-tweedie-location-scale` passed, `pkgdown::check_pkgdown()`
reported no problems, and `git diff --check` was clean.

## Tests Of The Tests

The new test compares weighted optimization with two independent targets:
a constant-weight log-likelihood scaling identity and explicit row duplication
for integer weights. This checks the row-multiplier contract without relying
on another package's weighting interpretation.

## Known Limitations

This is not a weighted `glmmTMB` comparator. The external weighted comparator
remains postponed until a dedicated weighting-semantics target is written.
