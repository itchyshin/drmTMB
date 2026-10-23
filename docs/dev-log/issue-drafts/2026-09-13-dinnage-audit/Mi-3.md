TITLE: [Dinnage audit Mi-3] `emmeans` support is numerically exact and `DHARMa` support works, and neither is documented anywhere
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4 and §7.6, Appendix A row Mi-3; severity minor).
Supporting working: hand-built contrast matrix comparison (six s.f. agreement); `createDHARMa()` +
`simulate()` KS test against U(0,1) at p = 0.92.

## What Russell found
`emmeans` support is measured, not asserted: cell means and SEs match a hand-built contrast matrix to six
significant figures, with correct `tran` registration across Poisson, nbinom2 and Gamma. `DHARMa` works
through `createDHARMa()` + `simulate()` -- `residuals(type = "quantile")` passes a KS test against U(0,1)
at p = 0.92. Both are already built and paid for, and both are undocumented: `grep -l emmeans man/*.Rd`
and `grep -rn DHARMa R/ man/ vignettes/` both return nothing.

## Where (at 945da24f)
`man/summary.drmTMB.Rd`, `man/residuals.drmTMB.Rd`, `vignettes/`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `grep -rl emmeans man/*.Rd` returns nothing (no man page mentions `emmeans`); `grep -rln DHARMa
R/ man/ vignettes/` returns nothing. The `.emm_register("drmTMB", pkgname)` call is still present in
`R/zzz.R:.onLoad()` (the emmeans hook is registered and functional), so the capability exists but stays
undiscoverable from documentation. `git log --oneline 945da24f..HEAD -- man/ vignettes/` shows no commit
adding `emmeans`/`DHARMa` documentation. No existing-issue match: `gh issue list --search "emmeans"` and
`--search "DHARMa"` return nothing.

## Proposed fix (Russell's, if stated)
"Document DHARMa together with the `simulate()` masking fix (M4)" and add `\seealso` plus a short section
for `emmeans`. Fix size: "`\seealso` + 6 lines".

## Acceptance
- [ ] `?summary.drmTMB` or `?residuals.drmTMB` gains a `\seealso`/section naming `emmeans` support
- [ ] a documented example of `DHARMa::createDHARMa()` + `simulate()` on a drmTMB fit
- [ ] NEWS.md entry crediting the report
