TITLE: [Dinnage audit UX-3] `summary(fit)$derived` is a 0-row frame whenever a `sigma` submodel is present; the quantity is in `$sdpars`
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §7.2, Appendix A row UX-3; severity minor).
Supporting working: two first-contact runs; one nearly reported the quantity as absent.

## What Russell found
`summary(fit)$derived` is a 0-row frame whenever a `sigma` submodel is present. One run **nearly reported
"the random-effect SD is not reported."** It is -- in `$sdpars`.

## Where (at 945da24f)
`R/methods.R` (`summary.drmTMB`).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `drm_derived_summary_rows()` (`R/methods.R:4505-4563`) returns
`empty_derived_summary_parameters()` (a 0-row frame) unless `object$model$model_type == "gaussian"` AND
`drm_constant_residual_sigma(object)` is finite. `drm_constant_residual_sigma()` requires a single fixed
`"(Intercept)"` coefficient on `sigma`'s log link (per the same helper documented in the related S2 finding)
-- any `sigma ~ x` submodel with more than the intercept fails that guard and returns non-finite, so
`derived` is silently empty for exactly the case Russell hit. No sentence anywhere in `summary.drmTMB()`'s
output or documentation tells the user to look in `$sdpars` instead when `$derived` is empty. `git log
--oneline 945da24f..HEAD -- R/methods.R` shows a rename-only commit relabeling a denominator description
(`4dbc71653`, noted separately under the related S2 finding) but no commit adding a redirect note for the
empty-`derived` case. No existing-issue match: `gh issue list --search "summary derived"` returns nothing.

## Proposed fix (Russell's, if stated)
"1 sentence or 1 field" -- either a message pointing to `$sdpars` when `$derived` is empty for this reason,
or populate `$derived` for the `sigma ~ x` case too.

## Acceptance
- [ ] when `$derived` is empty because a `sigma` submodel disqualifies the constant-sigma computation,
      `summary.drmTMB()`'s printed output or documentation says to look in `$sdpars`
- [ ] NEWS.md entry crediting the report
