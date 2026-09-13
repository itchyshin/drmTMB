TITLE: [Dinnage audit Mi-8] `?residuals.drmTMB` enumerates its per-family formulas and omits `student`, `skew_normal`, and `beta`
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-8; severity minor).
Supporting working: family-by-family reading of `?residuals.drmTMB`'s Details section.

## What Russell found
`?residuals.drmTMB` enumerates 15 families and omits `student`, `skew_normal` and `beta`, while
`?sigma.drmTMB` states the correct scale-vs-SD conversion for these families. Related but distinct credit:
Student-t Pearson residuals divide by the scale (not the SD), so their SD is `sqrt(nu/(nu-2))` (+67% at nu
= 3) -- but `glmmTMB` does the identical thing (1.4106 vs 1.4107), so that part is a shared model-class
convention, not a defect. The defect is narrower: the omission from the family enumeration itself.

## Where (at 945da24f)
`man/residuals.drmTMB.Rd`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `man/residuals.drmTMB.Rd`'s per-family Details paragraphs (checked via `grep -n "student\|
skew_normal\|beta\b"`) name Gaussian, lognormal, Gamma, zero-one-beta, beta-binomial, binomial,
negative-binomial-2, hurdle-NB2, zero-inflated-NB2, and bivariate Gaussian explicitly, but contain no
paragraph naming `student`, `skew_normal`, or plain `beta`. `git log --oneline 945da24f..HEAD --
man/residuals.drmTMB.Rd` shows no commit adding these three families' residual-scale conventions. No
existing-issue match: `gh issue list --search "residuals.drmTMB"` returns nothing on point.

## Proposed fix (Russell's, if stated)
"Two sentences" -- add the `student`, `skew_normal`, and `beta` Pearson-residual conventions to the
existing enumeration.

## Acceptance
- [ ] `?residuals.drmTMB` documents the Pearson-residual scale convention for `student`, `skew_normal`,
      and `beta`, matching the other enumerated families
- [ ] NEWS.md entry crediting the report
