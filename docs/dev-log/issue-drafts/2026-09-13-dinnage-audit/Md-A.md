TITLE: [Dinnage audit Md-A] drm_clamped_scale_families() omits biv_lognormal/biv_student
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-A; severity moderate).
Supporting working: none cited beyond the diffed family list vs. clamp call sites.

## What Russell found
`drm_clamped_scale_families()` is the R-side list `check_drm()` consults to decide
whether the log(sigma) soft-clamp applies to a family. It lists `biv_gaussian` but
omits `biv_lognormal` and `biv_student`, so `check_drm()` prints the **false**
sentence "The log(sigma) clamp does not apply to this family" for those two, while
the C++ clamps both scales identically for all three bivariate families. Demonstrated:
the clamp compressed `log_sigma2` from 1.21029 to 1.19731 in both a `biv_gaussian`
and a `biv_lognormal` fit, and only one of the two said so.

## Where (at 945da24f)
`R/drmTMB.R:2895-2911`, `R/drmTMB.R:341`, `src/drmTMB.cpp:5166-5170`,
`tests/testthat/test-clamp-extension.R`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `drm_clamped_scale_families()` (R/drmTMB.R:3496-3511) still lists
`"gaussian", "biv_gaussian", "student", ...` without `"biv_lognormal"` or
`"biv_student"`. The C++ side clamps both bivariate scales identically for
`model_type == 2 || 19 || 20` (biv_gaussian/biv_lognormal/biv_student, per the
switch at R/drmTMB.R:21723-21727) at src/drmTMB.cpp:5166-5170
(`drm_softclamp_log_sigma(log_sigma1, ...)` / `log_sigma2`). The consuming
check, `check_logsigma_clamp_active()` at R/check.R:571-579, still returns
`"ok"` with the same false sentence for any `model_type` not in the list.
`tests/testthat/test-clamp-extension.R` does not mention `biv_lognormal` or
`biv_student`, so no test currently catches this.

## Proposed fix (Russell's, if stated)
Add `"biv_lognormal"` and `"biv_student"` to `drm_clamped_scale_families()`, plus
one test. Note: this repo's worktree currently has an uncommitted fix in progress
for the related Critical finding (C1) touching R/drmTMB.R and
tests/testthat/test-clamp-active-guard.R — coordinate with that lane before
editing the same function.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report

## Status note at posting (2026-09-13)
Fix in progress on branch `claude/audit-dinnage-wave1-20260913` together with C1.
