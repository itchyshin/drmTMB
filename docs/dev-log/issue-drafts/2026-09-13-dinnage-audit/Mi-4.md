TITLE: [Dinnage audit Mi-4] Near-collinearity to r = 0.9999 fires no `check_drm()` row and no warning
LABELS: audit-dinnage, enhancement, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-4; severity minor).
Supporting working: design matrices at r from 0 to 0.9999, SE inflation compared against the analytic
`1/sqrt(1-r^2)`.

## What Russell found
SE inflation tracks the analytic `1/sqrt(1-r^2)` to within 3.9% at every r from 0 to 0.9999 (70.360
observed against 70.712 predicted) -- the numbers themselves are right -- but at r = 0.9999 zero
`check_drm()` rows fire and no warning is issued. The frozen design's a-priori criterion: "a design matrix
this close to singular should produce some signal on the diagnostic board."

## Where (at 945da24f)
`R/check.R`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `check_fixed_effect_design_size()` (`R/check.R:1566`) checks the design matrix's rank/size
relationship (column vs row count for estimability), not a condition-number/collinearity criterion.
`check_hessian_conditioning()` (`R/check.R:798`) checks the fixed-effect Hessian's condition number at the
optimum, which is a related but distinct quantity: high pairwise design-matrix collinearity does not
necessarily produce a large *Hessian* condition number if the likelihood curvature compensates (and per
the known overlap #1251, that row already has a documented false-positive risk in the opposite direction
on a *clean* fit). Name-scanning every `check_*` function in `R/check.R` finds none keyed on a design-
matrix pairwise-correlation or VIF-style criterion. `git log --oneline 945da24f..HEAD -- R/check.R` shows
commits touching `check_hessian_conditioning` and the clamp rows, none adding a collinearity row. No
existing-issue match beyond the related #1251 (hessian_conditioning NOTE on a clean fit, the opposite
direction of this gap): `gh issue list --search "collinear"` returns nothing.

## Proposed fix (Russell's, if stated)
"1 new row." No specific threshold proposed beyond the a-priori criterion that some signal should fire at
r = 0.9999.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after: a design matrix with r >= 0.9999 pairwise
      collinearity produces a `check_drm()` note/warning
- [ ] NEWS.md entry crediting the report
