# After Task: Bivariate Slope Artifact-Schema Audit

## Goal

Audit whether the existing `biv_gaussian_mu_slope` artifacts can support the
new #440/#446 bivariate slope-only ADEMP sheet without confusing residual
`rho12` with the group-level slope-slope correlation.

## Implemented

- Added `docs/design/146-phase6c-bivariate-slope-artifact-schema-audit.md`.
- Linked the audit from the Phase 18 simulation programme and four-week sprint
  plan.
- Strengthened `tests/testthat/test-phase18-biv-gaussian-mu-slope.R` so the
  replicate and aggregate artifacts must keep `random_correlation` and
  `residual_rho12` rows separate.

## Mathematical Contract

No likelihood, formula grammar, extractor, Actions task, or simulation runner
changed. The audit verifies artifact schema and test coverage for existing
outputs only.

## Files Changed

- `tests/testthat/test-phase18-biv-gaussian-mu-slope.R`
- `docs/design/146-phase6c-bivariate-slope-artifact-schema-audit.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The strengthened test checks the mapping that would fail if a future summariser
or CSV writer swapped the group-level slope correlation row and residual
`rho12` row.

## Consistency Audit

The audit keeps coverage and power planned because the bivariate slope-only
writer does not yet emit interval-status or rejection-rule artifacts.

## GitHub Issue Maintenance

This slice advances #440 and #446 after the commit is pushed.

## What Did Not Go Smoothly

The first temptation was to add new columns. The existing `parameter` plus
`parameter_class` schema already separates the two correlation layers, so the
lower-risk move was to test and document that contract.

## Team Learning

For bivariate artifacts, row classes are part of the scientific contract. A
correlation row should always say whether it is residual coscale or group-level
covariance.

## Known Limitations

No new grid, interval-status table, MCSE target, or power rule was added.

## Next Actions

Before a formal #440 pilot, decide whether this writer should gain an
interval-status artifact for direct SD, residual `rho12`, and group-level
correlation rows.
