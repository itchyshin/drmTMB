# After Task: Non-Gaussian Mu-Slope Admission Table

## Goal

Advance #441 by adding a conservative status table for non-Gaussian independent
`mu` slopes without changing likelihoods, formula grammar, or support
registries.

## Implemented

- `docs/design/80-four-week-random-slope-digital-twin-sprint.md` now separates
  fixed-effect likelihood support, independent `mu` slope source tests, Phase
  18 artifact routes, and #441 admission status by family.
- Ordinary Poisson and NB2 `mu` slopes are identified as the strongest current
  non-Gaussian count candidates because they have dedicated smoke/grid lanes.
- Student-t, lognormal, Gamma, beta, beta-binomial, and zero-truncated NB2
  independent `mu` slopes are labelled source-tested, with current artifact
  routes still focused on random intercepts.
- Tweedie, zero-one beta, hurdle or zero-inflated counts, ordinal, and shape
  parameters remain outside #441 random-slope admission.

## Files Changed

- `docs/design/80-four-week-random-slope-digital-twin-sprint.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-nongaussian-mu-slope-admission-table.md`

## Boundary

This is a documentation and status-ledger slice. It does not add random effects
to any family, promote correlated non-Gaussian slopes, add structured
non-Gaussian slopes, or claim slope-specific recovery, coverage, or power
evidence for families that only have source tests.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
checks covered source scans for the new #441 table and diff hygiene.

## What Did Not Go Smoothly

The family registry already had a correct top-level table, but lower prose in
the same document lagged behind it for some families. That follow-up cleanup is
tracked as a separate documentation slice so this table can stay focused on the
Phase 6c sprint ledger.

## Team Learning

Fermat's audit was useful because it forced the evidence vocabulary to stay
layered: fixed-effect likelihood, source-tested random-effect fit, artifact
dispatch, and operating-characteristic evidence are not interchangeable.

## Next Actions

- Harmonize stale family-registry prose where older "fixed-effect only" text
  conflicts with ordinary `mu` random-intercept or independent-slope rows.
- Route slope-specific recovery, accuracy, coverage, and power grids through
  #446 before promoting source-tested families to simulation-supported status.
