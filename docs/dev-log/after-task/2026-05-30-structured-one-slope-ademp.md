# After Task: Structured Gaussian One-Slope ADEMP Sheet

## Goal

Add the #442/#446 ADEMP sheet for fitted Gaussian structured `mu` one-slope
paths.

## Implemented

- Added `docs/design/148-phase6c-structured-one-slope-ademp.md`.
- Linked the sheet from the Phase 18 simulation programme and the four-week
  sprint plan.
- Kept route maturity explicit: `spatial_mu_slope` has a manual artifact task,
  while `phylo()`, `animal()`, and `relmat()` remain fitted/source-tested
  wrapper targets.

## Mathematical Contract

No likelihood, formula grammar, extractor, registry row, Actions task,
simulation runner, artifact schema, recovery result, coverage result, or power
result changed. The sheet plans future evidence only.

## Files Changed

- `docs/design/148-phase6c-structured-one-slope-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

The focused Phase 18 structured tests were rerun to verify the existing
spatial artifact route and structured wrapper registry still expose the
one-slope rows named in the planning sheet.

## Consistency Audit

The sheet keeps Gaussian structured one-slope support separate from q2/q4
covariance, structured slope correlations, residual-scale structured slopes,
structured `rho12`, mesh/SPDE slopes, count structured slopes, and
non-Gaussian structured slopes.

## GitHub Issue Maintenance

This slice advances #442 and #446 after the commit is pushed.

## What Did Not Go Smoothly

The main risk was overstating parity across the four structured routes.
`spatial()` already has a manual Phase 18 artifact task; the other three
routes still need wrapper artifacts before Actions dispatch.

## Team Learning

Structured-slope status needs two axes in every report: fitted source support
and artifact maturity. Without both, readers can mistake a fitted route for
coverage or power evidence.

## Known Limitations

No DGP, runner, grid writer, interval-status table, MCSE target, or comparator
was added for `phylo()`, `animal()`, or `relmat()` one-slope artifacts.
Multiple structured slopes, slope correlations, structured residual-scale
slopes, structured `rho12`, and non-Gaussian structured slopes remain out.

## Next Actions

Add wrapper artifact writers for `phylo()`, `animal()`, and `relmat()` before
treating those rows as Actions-ready one-slope surfaces.
