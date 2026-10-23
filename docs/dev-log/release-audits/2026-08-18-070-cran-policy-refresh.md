# drmTMB 0.7.0 CRAN policy refresh

Accessed: 2026-08-18

This refresh uses CRAN's own current pages and applies them to frozen candidate
`e9c5556ddf09707f1020099d5d87c6cf419d64f14d00c81ccd4931708d4d485b`
(10,090,216 bytes).

## Authoritative sources

- [CRAN Repository Policy](https://cran.r-project.org/web/packages/policies.html),
  revision 6875.
- [Checklist for CRAN submissions](https://cran.r-project.org/web/packages/submission_checklist.html).
- [CRAN URL checks](https://cran.r-project.org/web/packages/URL_checks.html).

## Current requirements applied

- The first-submission source tarball must be created by `R CMD build`, use the
  package-version filename, and be checked with `R CMD check --as-cran`, preferably
  under current R-devel. The frozen candidate has a same-byte local check and
  independent R-devel win-builder result.
- Warnings and significant NOTEs normally require correction or explanation.
  All three win-builder arms report only the expected new-submission/spelling
  NOTE. The explanation belongs in `cran-comments.md` before any submission.
- Copyright and intellectual-property ownership must be clear for every package
  component. The prior Gate 1 component ledger remains applicable; the current
  tarball change-impact audit found no added data, image, font, binary, or borrowed
  component and no change to `inst/COPYRIGHTS`.
- Packages should be portable across major R platforms. The current source state
  passed GitHub checks on Windows, Ubuntu, and macOS; win-builder R-release,
  R-devel, and R-oldrelease each completed with one expected NOTE.
- Source tarballs should, if possible, not exceed 10 MB. This candidate is
  10,090,216 bytes: 10.09 MB in decimal units (9.62 MiB), marginally above that
  preference. Grace must decide whether the existing package-content justification
  and a submission comment are sufficient or whether size reduction is required.
- Checks should minimize CPU time and examples should be brief. The CRAN-filtered
  Windows test stage is approximately 13–14 minutes, while whole checks were
  946–1,411 seconds plus installation. These measured timings must be reviewed by
  Grace rather than hidden by a green conclusion.
- CRAN recognizes that automated URL checks can differ from browser access and
  asks maintainers to explain justified exceptions. The two DOI 403s have
  independent Crossref resolution evidence and must be mentioned if retained.
- R-hub is supplementary and not maintained by CRAN. Its run-level red status is
  preserved: three sanitizers passed, while `rchk` reported four findings in
  installed TMB headers and none in `drmTMB.cpp`.

## Classification

The cited rules are current CRAN policy or current CRAN submission guidance.
The repository's approximately ten-minute Windows timing concern is a conservative
local/observed-incoming margin, not a quoted immutable CRAN policy threshold.

This refresh authorizes no upload and makes no submission-ready claim.
