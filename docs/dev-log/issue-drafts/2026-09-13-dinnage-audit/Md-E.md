TITLE: [Dinnage audit Md-E] Unused factor level leaves every SE NA behind a no-op refit hint
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-E, aliased A-1
in Appendix A; severity moderate).
Supporting working: fits compared against `lm`, `glmmTMB`, and `gamlss` on the same data with an
unused factor level (a `subset()` without `droplevels()`) and an exactly duplicated column.

## What Russell found
Estimates are exactly right (dLL 0 to 1.8e-09, 7 dp agreement with `lm`) but every
standard error is `NA` (0 of 8, 0 of 6, 0 of 5 finite SEs across three comparators),
with no fit-time warning. `check_drm()` is loud (`hessian_positive_definite`,
`standard_errors_finite`) but the printed remediation is a no-op: "Refit with
`control = drm_control(se = TRUE)`" when `se = TRUE` is already the default.
Refitting still gives 0 of 8 finite SEs; `droplevels()` gives 7 of 7. `lm` drops
the level automatically; `glmmTMB` and `gamlss` both return finite SEs on the
same data.

## Where (at 945da24f)
`R/drmTMB.R` (model-frame construction), the `drm_control(se = TRUE)` hint string.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. No `droplevels()` call exists anywhere in the model-frame construction
path: every `stats::model.frame(...)` call site in R/drmTMB.R (e.g. the `mf_mu`/
`mf_sigma` builds at R/drmTMB.R:4125-4134, 4749-4763, 5074-5084, and ten further
per-family sites) passes the frame through unchanged, with no `droplevels()`
anywhere in the file. The no-op hint is still present: R/check.R:815-824
(`check_hessian_conditioning`, the `hessian_conditioning` row) reads "...sdreport()
failed); refit with drm_control(se = TRUE) to compute fixed-effect covariance" and
`drm_control()`'s default is `se = TRUE` (R/control.R:169), confirmed by
`drm_sdreport_unavailable_message()` at R/methods.R:2484-2500, whose "failed"
branch names the same non-actionable hint. (Note: `R/julia-bridge.R:2087-2131`
does call `droplevels()` and offers a working hint for the `engine = "julia"`
route only — the default `engine = "tmb"` path this finding is about has no
such call.)

## Proposed fix (Russell's, if stated)
One `droplevels()` call on the model-frame factors, and delete the no-op hint.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
