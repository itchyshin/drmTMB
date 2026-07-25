# After Task: Arc 6 pkgdown reference-index repair

## 1. Goal

Repair the pkgdown deployment failure so the merged Arc 6 reader articles and
reference pages can reach the live site.

## 2. Implemented

Added five missing exported topics to the pkgdown reference index and updated
the cross-family navbar label to its bounded current status.

## 3. Mathematical Contract

No model or mathematical contract changed. The site exposes the same separate
`eta` post-fit association and exact-special `rho12` routes already merged in
Arc 6.

## 3a. Decisions and Rejected Alternatives

The repair indexes the public topics rather than hiding them with
`@keywords internal`. The navbar says “association”, not generic bivariate
support, because the development-slice limitations remain material.

## 4. Files Touched

- `_pkgdown.yml`.
- Check log and this report.

## 5. Checks Run

- `pkgdown::check_pkgdown()`: PASS, no problems found.
- Hosted pkgdown rebuild and live-page read-back remain required.

## 6. Tests of the Tests

The original hosted failure named the exact five missing topics. The local
pkgdown checker now accepts the same reference configuration.

## 7a. Issue Ledger

No issue was created or changed; this directly repairs the failed deployment
of the already merged Arc 6 source.

## 8. Consistency Audit

The navbar and reference index now name the same Arc 6 reader surface. The
cross-family article itself retains its frozen-margin and no-inference limits.

## 9. What Did Not Go Smoothly

The Arc 6 source PR checks did not run the full pkgdown build; the
workflow-run deployment exposed the missing index entries after merge.

## 10. Known Residuals

This repair does NOT cover new model families, generic discrete pairs,
recovery, inference, intervals, coverage, random effects, Julia, or CRAN.
Arc 6.5's recovery HOLD remains unchanged.

## 11. Team Learning

Every exported reader-facing Arc topic needs an explicit reference-index audit
before claiming the served site is current.

## 12. Cross-Product Coverage

This covers the pkgdown reference/index and menu route for the five Arc 6
topics. It does NOT cover their capability tier, their numerical evidence, or
the separate exact-special Student-t reader surface beyond indexing it.
