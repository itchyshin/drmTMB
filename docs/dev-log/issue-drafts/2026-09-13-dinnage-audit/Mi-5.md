TITLE: [Dinnage audit Mi-5] The Wald `rho12`-boundary warning always recommends `method = "profile"`, even where the profile interval is provably a no-op
LABELS: audit-dinnage, documentation, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Mi-5; severity minor).
Supporting working: rho = 0.999 fit, Wald and profile confint() compared endpoint-by-endpoint.

## What Russell found
At rho = 0.999, Wald and profile coverage are both 0.9567, agreeing on the coverage indicator 300/300,
maximum endpoint difference 8.95e-08 -- the recommended remedy returns the same interval. The mechanism
was checked on purpose: the profile *is* genuine where one must differ (width ratio 1.0130 at n = 25,
converging to Wald monotonically), so at rho -> 1 there is no boundary on the estimation scale, which is
why the remedy is a no-op there. `?confint.drmTMB` already says a profile interval is not a fix at a
boundary (so the novelty of the underlying geometry is demoted); what is not demoted is the specific
warning text.

## Where (at 945da24f)
`R/check.R` (`check_rho12_boundary` message).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. The actual remedy text lives in `R/profile.R`'s `wald_boundary_targets`/Wald-interval path
(~line 2249), unconditionally: `"Wald coverage is unreliable on the boundary; use confint(method =
"profile") for {?this/these} target{?s}."` -- fired whenever `conf.status` is set to `"wald_at_boundary"`
for any variance-component or correlation target, with no distinction for the `rho12 -> 1` case where the
profile is measurably a no-op. `check_rho12_boundary()` itself (`R/check.R:1340-1368`) only states "close
to +/-1", not a remedy. `?confint.drmTMB`'s "Boundary intervals" section (`R/profile.R:213-220`) already
states the general caveat ("a profile interval is not a repair for a boundary"). `git log --oneline
945da24f..HEAD -- R/profile.R R/check.R` shows no commit narrowing the profile recommendation for this
case. No existing-issue match: `gh issue list --search "rho12 boundary"` returns nothing on point.

## Proposed fix (Russell's, if stated)
Message text change: do not recommend `method = "profile"` for the `rho12 -> 1` boundary specifically,
since it is measurably a no-op there (unlike other variance-boundary cases where profile does help).

## Acceptance
- [ ] the Wald boundary warning does not recommend `method = "profile"` when the target is `rho12` near
      its own +/-1 boundary (as opposed to a variance-component boundary, where profile does help)
- [ ] NEWS.md entry crediting the report
