TITLE: [Dinnage audit Md-I] "estimator: REML" labels two different objects
LABELS: audit-dinnage, documentation, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-I; severity moderate).
Supporting working: comparison against `lme4` (agrees to 6.5e-13) for the exact case.

## What Russell found
`estimator: REML` prints on the first line of `summary()`, but it is not always
the same object: the exact restricted likelihood (Gaussian) and a Laplace /
Cox-Reid adjusted profile (binomial, and the scale-side route) both print the
same label. Nothing on the fitted object distinguishes them; a source comment is
honest about the difference but the qualifier never reaches the user.

## Where (at 945da24f)
`R/drmTMB.R:1140`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `spec$estimator <- "REML"` is set at a single site, R/drmTMB.R:1268
(line drift from :1140), used uniformly regardless of which underlying
mechanism produced it -- there is no `estimator_exact` (or similarly named)
field on the fitted object; a repo-wide search for `estimator_exact` found no
matches. `summary.drmTMB()` prints `cli::cli_text("estimator: {x$estimator}")`
at R/methods.R:37 and R/methods.R:4324, both reading the same single
`$estimator` field. The Cox-Reid distinction is still documented only in prose
(`?drmTMB`'s `REML` argument entry, R/drmTMB.R:185-186: "The package-private AGHQ
plus Cox-Reid (O3) estimator is not a `drmTMB()` argument and is not what
`REML = TRUE` runs"), not on the returned object.

## Proposed fix (Russell's, if stated)
One line: `fit$estimator_exact`.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
