# After Task: Comparator Result Scope Table

## Goal

Make the durable Gaussian location-scale comparator result note show both the
implemented `glmmTMB` overlap checks and the richer individual-difference
examples that remain blocked.

## Implemented

- Updated `docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md`.
- Linked the note to the current CSV output written by
  `tools/replicate-location-scale-gaussian.R`.
- Added a blocked-example table for shared `mu`/`sigma` covariance, bivariate
  group-level covariance, and non-Gaussian location-scale random effects.

## Mathematical Contract

No likelihood, formula grammar, or comparator calculation changed. This is a
documentation alignment for the existing optional comparator harness.

## Files Changed

- `docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md`
- `docs/dev-log/after-task/2026-05-11-comparator-result-scope-table.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `Rscript tools/replicate-location-scale-gaussian.R`: passed and rewrote
  `docs/dev-log/comparator-results/gaussian-location-scale-glmmtmb-current.csv`.
- `air format docs/dev-log/comparator-results/2026-05-10-gaussian-location-scale-glmmtmb.md docs/dev-log/after-task/2026-05-11-comparator-result-scope-table.md docs/dev-log/check-log.md`:
  passed.
- `git diff --check`: passed.

## Tests Of The Tests

The comparator command still fits the two implemented overlap models and stops
if their coefficient, random-effect SD, or log-likelihood differences exceed
the `1e-4` tolerance. The blocked rows remain informational and do not count as
failed comparator checks.

## Consistency Audit

The markdown result note now matches the CSV schema: implemented rows carry
numeric differences and `passed = TRUE`; blocked rows carry the planned feature
that prevents a current comparison.

## What Did Not Go Smoothly

The first recovered comparator note lagged behind the newer CSV schema, so the
blocked rows existed in machine-readable output but not in the human-readable
result note.

## Team Learning

Jason: comparator evidence should report what cannot yet be compared as clearly
as what passes today, otherwise roadmap readers can overread a narrow overlap
test.

## Known Limitations

- This remains a simulated Gaussian comparator harness, not a full real-data
  replication suite.
- The blocked rows do not implement covariance blocks or non-Gaussian random
  effects.

## Next Actions

- After PR #7 lands, add an issue #6 comment pointing to the current harness,
  CSV, and result note.
