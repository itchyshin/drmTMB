# After Task: Non-Gaussian `mu` Slope ADEMP Sheet

## Goal

Add the #441/#446 ADEMP sheet for selected ordinary non-Gaussian independent
`mu` random slopes.

## Implemented

- Added `docs/design/147-phase6c-nongaussian-mu-slope-ademp.md`.
- Linked the sheet from the Phase 18 simulation programme and the four-week
  sprint plan.

## Mathematical Contract

No likelihood, formula grammar, extractor, registry row, Actions task, or
simulation runner changed. The sheet plans future evidence only.

## Files Changed

- `docs/design/147-phase6c-nongaussian-mu-slope-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The focused source-test lane was rerun to verify the six families named in the
planning sheet still fit and expose the expected extractor/diagnostic rows.

## Consistency Audit

The sheet keeps selected non-Gaussian slopes at source-tested or
artifact-admission status. It does not promote coverage, power, correlated
slopes, structured dependence, or non-Gaussian scale/shape random effects.

## GitHub Issue Maintenance

This slice advances #441 and #446 after the commit is pushed.

## What Did Not Go Smoothly

The main risk was grouping too many family surfaces into one claim. The sheet
therefore names the six source-tested families explicitly and requires
family-separated evidence.

## Team Learning

Non-Gaussian slope plans should not borrow evidence across links or supports.
Each family needs its own boundary stress and artifact audit.

## Known Limitations

No DGP, runner, grid writer, interval-status table, MCSE target, or comparator
was added.

## Next Actions

Decide whether the first artifact lane should be one combined
family-separated writer or one smaller writer per family group.
