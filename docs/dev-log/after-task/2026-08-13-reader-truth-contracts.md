# After Task: Reader-truth reliability contracts

## Goal

Make two reader-facing failure paths honest: a corrupted Student-`nu` profile
must fail closed, and a generated capability row must not retain stale
gate-dependent prose.

## Implemented

`TMB::tmbprofile()` traces with the documented monotone-sweep, isolated-low
sentinel, and reset pattern now return a `profile_failed` row with missing
endpoints, `profile.boundary = TRUE`, and
`profile.message = "tmbprofile_bracket_overflow"`. The result applies both to
ordinary target profiles and response profiles at supplied `newdata`.
The invalid trace's objective and likelihood-ratio columns are missing, and
`plot()` refuses to draw a profile with no valid curve.

The capability-ledger generator now reads a keyed live-prose sidecar for the
three threshold-free missing-response G5 routes. It verifies the current
policy name, each route's live state, the absence of the retired predicate,
and the required prose on that route's own rendered family-map row.

## Mathematical Contract

The sentinel detector does not change the fitted objective, the likelihood,
or a profile endpoint. It recognizes an invalid extraction trace and declines
to report an interval. The ledger contract does not alter an evidence tier or
calibration rule; it checks that the prose reporting the existing rule remains
true.

## Files Changed

- `R/profile.R` and `tests/testthat/test-profile-targets.R`
- `docs/dev-log/dashboard/capability-ledger/live-prose-contracts.tsv`
- `tools/capability_ledger.py` and `tools/tests/test_capability_ledger.py`
- `tests/testthat/test-reader-journeys.R`
- `vignettes/missing-data.Rmd`

## Checks Run

- Focused profile-target tests: passed, including direct, curve, and supplied-
  `newdata` sentinel paths.
- Focused ledger contract tests: passed (6 tests).
- `python3 tools/capability_ledger.py --check`: passed (31 generated outputs).
- Focused reader-journey test: 28 passes, 0 failures, warnings, or skips.
- `missing-data.Rmd` rendered successfully to a temporary directory.
- Fresh exact source-tarball `R CMD check --as-cran` on the final repaired
  branch passed with no errors or warnings and the expected new-submission NOTE
  only. GitHub Actions remains the cross-platform gate before merge.

## Tests Of The Tests

The profile tests construct the sentinel signature, a flat trace, an ordinary
lower basin, and a nonmonotone-above-fit trace. Only the sentinel fails closed,
with no objective, likelihood-ratio, or plottable curve retained.
The ledger tests independently remove a named route row and mutate a helper's
wording; the generated contract then fails. The reader diagnostic test fits a
real bivariate model and proves that `attr(check_drm(fit), "ok")` becomes
`FALSE` when the visible `rho12` boundary warning is present.

## Consistency Audit

The generated family-map row is checked by its exact marker rather than by a
concatenated document search. The missing-response vignette no longer exposes
`fit$missing_data`. Historical development notes and internal implementation
code remain intentionally searchable and were not rewritten.

## GitHub Issue Maintenance

This implements the fail-closed part of #1010 and the targeted live-prose
protection motivated by #1011. Their broader upstream/root-cause and
schema-design questions remain open until the merged state and issue scopes
are reconciled.

## What Did Not Go Smoothly

The first profile detector was too permissive about a low point in an ordinary
profile. Requiring a return to the preceding sweep range and a value below the
fitted baseline excludes that false positive. The first ledger version checked
a combined rendered blob; it was tightened to the exact named route row.

## Team Learning

User-facing status is part of the statistical result. A numerical extractor
must either return an interval whose path is valid or preserve the reason it
cannot do so. Generated prose needs a keyed contract when it refers to live
policy or evidence state.

## Known Limitations

This is a defensive wrapper around an apparent upstream `TMB::tmbprofile()`
bracket failure; it does not repair that upstream search. It adds no Student
`nu` calibration claim. The ledger guard covers the three threshold-free G5
routes that had stale gate wording; a general typed cross-reference schema is
a future design task. Julia, CRAN re-freeze, MSPL, new models, and simulation
campaigns remain out of scope.

## Next Actions

After the preceding reader-journey PR's required Ubuntu check is green, rebase
this integration branch onto `main`, rerun the focused contracts and the exact
source-tarball check, then submit it for fresh cross-platform review.
