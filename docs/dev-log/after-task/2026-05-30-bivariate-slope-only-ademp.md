# After Task: Bivariate Slope-Only ADEMP Sheet

## Goal

Add the second #446 ADEMP sheet for the #440 matching bivariate Gaussian
`mu1`/`mu2` slope-only lane.

## Implemented

- `docs/design/145-phase6c-bivariate-slope-ademp.md` now plans the bivariate
  slope-only operating-characteristic lane.
- `docs/design/41-phase-18-simulation-programme.md` and
  `docs/design/80-four-week-random-slope-digital-twin-sprint.md` link to the
  new sheet.

## Mathematical Contract

No likelihood, formula grammar, extractor, registry row, Actions task, or
simulation runner changed. The sheet plans future evidence only.

## Files Changed

- `docs/design/145-phase6c-bivariate-slope-ademp.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/dev-log/check-log.md`

## Checks Run

Validation is recorded in `docs/dev-log/check-log.md`. It covered ADEMP section
headings, design links, residual `rho12` versus group-level slope-slope
covariance wording, excluded-surface boundaries, and `git diff --check`.

## Tests Of The Tests

No R tests were run because this was design documentation only.

## Consistency Audit

The sheet keeps residual `rho12` as residual coscale and group-level
slope-slope correlation as a separate `corpairs()`/covariance-table estimand.
It does not open intercept-plus-slope q4, p8/q8, random effects in `rho12`,
mixed-response bivariate families, or residual-scale slope covariance.

## GitHub Issue Maintenance

This slice advances #440 and #446 and should be linked from the PR and sprint
issue after the commit is pushed.

## What Did Not Go Smoothly

The most important design risk was wording: "correlation" appears in both
residual and group-level layers. The sheet therefore includes a dedicated
separation-error performance measure.

## Team Learning

Bivariate operating-characteristic reports should have separate truth and
estimate columns for residual `rho12` and group-level `corpairs()` rows.

## Known Limitations

No grid, artifact schema, replicate count beyond a pilot suggestion, or MCSE
target has been dispatched.

## Next Actions

Use this sheet to decide whether the existing `biv_gaussian_mu_slope` artifact
writer is enough for a pilot grid or whether it needs interval-status columns
before formal recovery work.
