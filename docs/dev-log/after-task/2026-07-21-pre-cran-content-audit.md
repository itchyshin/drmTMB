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

**Corrected 2026-07-21.** This originally read "All seven content blockers found
by independent reader passes were corrected." Only three were real. The four
regression-`rho12` blockers were false positives: the reader passes read
`conf.status = "newdata_required"` as "no interval exists", when it means
"supply `newdata`". Those four edits have been reverted with a coverage
qualifier added; the three Julia/cross-family corrections stand. Three
clarity/performance follow-ups remain recorded in the release audit. Full
reversal record:
`docs/dev-log/after-task/2026-07-21-rho12-interval-audit-reversal.md`.

## 8. Consistency Audit

The Gamma wording matches the generated ledger; cross-family wording matches the
optional, post-0.6 Julia decision; zero-one-beta matches its terminal generator
caveat. **The `rho12` claim in this section was withdrawn on 2026-07-21**: there
is no "constant-only interval fence" to match. Row-specific intervals exist for
`rho12 ~ x` via `newdata`; the restored wording distinguishes *available* from
*coverage-certified*, and manifest §3/§5 were corrected accordingly.

## 9. What Did Not Go Smoothly

The first pkgdown batch used an unsupported vector argument, and one gallery
render exposed a missing-column assumption. Both were corrected before the
complete build.

## 10. Known Residuals

The live site needs its ordinary post-merge deployment read-back. The three
follow-ups in the audit are debt, not release blockers under the agreed fence.

## 11. Team Learning

**Revised 2026-07-21.** The original lesson — "reader examples must not imply a
released interval merely because an exploratory or row-specific API can compute
a numeric result" — is sound in general but was misapplied here, and applying it
deleted four true statements. The operative lesson is the converse discipline:
**do not infer a capability's absence from a status token without calling the
function.** A status string is an API message, not a capability verdict. And an
audit that cites one line must grep the claim token across `vignettes/`, `man/`,
`R/` roxygen, `NEWS.md`, and `_pkgdown.yml` before declaring the claim
discharged site-wide.

## 12. Cross-Product Coverage

This task does NOT cover tarball cleanliness, platform checks, CRAN submission,
or post-0.6 Julia implementation.
