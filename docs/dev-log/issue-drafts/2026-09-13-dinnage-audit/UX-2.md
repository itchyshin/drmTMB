TITLE: [Dinnage audit UX-2] `summary(fit)$nobs` does not exist and returns `NULL` silently; propagated as `NA` through a scoring pass
LABELS: audit-dinnage, enhancement, minor
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §7.2, Appendix A row UX-2; severity minor).
Supporting working: one first-contact run's scoring pass.

## What Russell found
`summary(fit)$nobs` does not exist (`nobs(fit)` does) -- accessing it returns `NULL` silently rather than
erroring, and that `NULL` propagated as `NA` through a whole scoring pass before being noticed.

## Where (at 945da24f)
`R/methods.R` (`summary.drmTMB`).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `summary.drmTMB()`'s returned list (`R/methods.R:4297-4315`) has fields `call, coefficients,
parameters, covariance, derived, sdpars, corpars, ordinal, uncertainty, logLik, mspl, estimator,
convergence, conf.int, conf.level, conf.method, confint` -- no `nobs` field. `nobs.drmTMB()` exists as its
own generic method elsewhere (confirmed the package has a working `nobs()` accessor), but nothing on the
`summary.drmTMB` object surfaces it, so `summary(fit)$nobs` returns `NULL` by R's normal `$`-on-missing-
name semantics, with no error. `git log --oneline 945da24f..HEAD -- R/methods.R` (filtered to
`summary.drmTMB`) shows no commit adding an `nobs` field. No existing-issue match: `gh issue list --search
"summary nobs"` returns nothing.

## Proposed fix (Russell's, if stated)
"1 field" -- add `nobs = nobs(object)` to the `summary.drmTMB()` return list.

## Acceptance
- [ ] `summary(fit)$nobs` returns the same value as `nobs(fit)`, not `NULL`
- [ ] NEWS.md entry crediting the report
