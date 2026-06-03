# After Task: Structured One-Slope Audit Table

## Goal

Advance #442 by recording the current Gaussian structured one-slope status
without changing formula grammar, likelihood code, extractors, or simulation
registries.

## Implemented

- `docs/design/80-four-week-random-slope-digital-twin-sprint.md` now has a
  structured one-slope audit table for `phylo()`, `spatial()`, `animal()`, and
  `relmat()`.
- The table separates the first fitted univariate Gaussian `mu` one-slope path
  from q2 covariance, q4 diagnostic-heavy covariance, count structured
  intercept lanes, and future multi-slope claims.
- The artifact-routing boundary is explicit: `spatial_mu_slope` is currently
  the manual Actions task for a Gaussian structured one-slope lane, while
  `phylo()`, `animal()`, and `relmat()` remain structured-dependence wrapper
  targets for standalone one-slope artifacts.

## Boundary

This is a documentation and status-ledger slice. It does not add structured
slopes, promote q4 interval readiness, create an Actions wrapper, or claim
coverage evidence for any structured layer. Multiple structured slopes,
structured slope correlations, residual-scale structured slopes, structured
`rho12`, and non-Gaussian structured slopes remain planned.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
checks covered the new #442 table, registry/status handles, and diff hygiene.

## Team Learning

Maxwell's source-only audit was useful because it forced the ledger to split
four different meanings that can otherwise blur together: fitted source path,
extractor/profile diagnostics, artifact dispatch, and operating-characteristic
evidence.

## Next Actions

- Patch public prose that still compresses fitted one-slope status and
  artifact readiness into one claim.
- Add wrapper targets for `phylo()`, `animal()`, and `relmat()` one-slope
  artifacts before treating those rows as Actions-ready.
- Route coverage, accuracy, and power questions through #446 rather than the
  fitted-status table.
