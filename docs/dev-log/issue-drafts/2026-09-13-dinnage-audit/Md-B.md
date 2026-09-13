TITLE: [Dinnage audit Md-B] standard_errors_inflated loses sensitivity as its own median inflates
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-B; severity moderate).
Supporting working: two independent runs, one a rank-deficient design built in the source, one an
external degenerate meta-analysis fit.

## What Russell found
`standard_errors_inflated` flags when SE >= 50 AND SE >= 1000x the median of all
finite SEs — but that median **includes the inflated SEs**, so sensitivity falls
as the pathology spreads. Three collinear predictors of five gave `n_inflated = 0`
and `attr(ok) = TRUE` on a coefficient table reading 774, -873, 99 for three copies
of the same variable. On an external degenerate meta fit, `summary()` printed an SE
of 1.53e+04 beside `mu` SEs of 0.09 (a 182,112:1 spread) with `check_drm()` still
returning "13 ok / 0 not-ok". `metafor` on the identical column warns and returns
`NA` SEs.

## Where (at 945da24f)
`R/check.R:764-800`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `check_standard_errors_inflated()` at R/check.R:1124-1163 computes
`median_se <- stats::median(finite_standard_errors)` over *all* finite SEs
(R/check.R:1139), then flags `standard_errors >= inflated_standard_error_ratio *
median_se` (R/check.R:1142-1144), where `inflated_standard_error_floor <- 50` and
`inflated_standard_error_ratio <- 1000` (R/check.R:1121-1122). The median is not
computed over a reference/non-flagged subset, so it inflates along with the
pathology exactly as reported.

## Proposed fix (Russell's, if stated)
Compare max-to-min instead of max-to-median, or key the check on the fitted
`sigma` range collapsing.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
