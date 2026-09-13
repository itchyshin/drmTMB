TITLE: [Dinnage audit Md-C] predict(type="response") is not documented as returning E[Y]
LABELS: audit-dinnage, documentation, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-C; severity moderate).
Supporting working: cross-family comparison against `gamlss`.

## What Russell found
`predict(type = "response")` returns the component distributional parameter, not
`E[Y]`: the count-component rate for zero-inflated/hurdle families, `mu` for
lognormal, and for `cumulative_logit` the raw linear predictor (outside the
response support). `fitted()` is correct in every family. `gamlss` does the
identical thing and agrees to 4 dp, so this is "a name collision between two
model classes, not drmTMB being out of step" — the report explicitly says
**"do not read this as a defect relative to the incumbent."** `check_drm()`
returns 13/13 ok.

## Where (at 945da24f)
`man/predict.drmTMB.Rd`, `R/methods.R` (predict).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `man/predict.drmTMB.Rd` (generated from R/methods.R) documents
`type = c("response", "link", "quantile")` with no `"mean"` option, and its
Details section (a paragraph on `mi()` retained predictors) says predictions are
"a distributional-parameter prediction, not an integrated response mean" only
for that one retained-predictor case — there is still no Details paragraph
naming zero-inflated, hurdle, lognormal, or `cumulative_logit` as families where
`type = "response"` differs from `E[Y]`, and no `type = "mean"` alternative
exists in R/methods.R's `predict.drmTMB` type switch (confirmed against the
`type == "response"` branches at R/methods.R:3749-3955, which return the
component parameter per family as described).

## Proposed fix (Russell's, if stated)
One Details paragraph in `?predict.drmTMB` naming the families where
`type = "response"` is not `E[Y]`, and a `type = "mean"` option.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
