# After-task report: pre-CRAN content audit

## 1. Goal

Audit and correct false 0.6.0 shipped claims across pkgdown articles and
reference documentation without rerunning the frozen tarball-clean gate.

## 2. Implemented

Corrected Gamma, regression-`rho12`, Julia/cross-family, and zero-one-beta
reader claims; rendered the affected articles and rebuilt the complete site.

## 3a. Decisions and Rejected Alternatives

Kept native TMB as the release path and recast Julia/cross-family material as
post-0.6 development. No estimator, coverage floor, tier, or code capability
was changed.

## 4. Files Touched

README and the affected vignette sources, plus the release-audit record and
this report.

## 5. Checks Run

`capability_ledger.py --check`, `check-capability-runtime.R`, focused affected
article renders, `pkgdown::build_site()`, and `pkgdown::check_pkgdown()` passed.

## 6. Tests of the Tests

The figure-gallery correction first failed because removing an interval column
made its combined table asymmetric; the render then passed after the point-only
`rho12` row explicitly supplied missing interval columns.

## 7a. Issue Ledger

All seven content blockers found by independent reader passes were corrected.
Three clarity/performance follow-ups remain recorded in the release audit.

## 8. Consistency Audit

The Gamma wording matches the generated ledger; `rho12` wording matches the
constant-only interval fence; cross-family wording matches the optional,
post-0.6 Julia decision; zero-one-beta matches its terminal generator caveat.

## 9. What Did Not Go Smoothly

The first pkgdown batch used an unsupported vector argument, and one gallery
render exposed a missing-column assumption. Both were corrected before the
complete build.

## 10. Known Residuals

The live site needs its ordinary post-merge deployment read-back. The three
follow-ups in the audit are debt, not release blockers under the agreed fence.

## 11. Team Learning

Reader examples must not imply a released interval merely because an exploratory
or row-specific API can compute a numeric result.

## 12. Cross-Product Coverage

This task does NOT cover tarball cleanliness, platform checks, CRAN submission,
or post-0.6 Julia implementation.
