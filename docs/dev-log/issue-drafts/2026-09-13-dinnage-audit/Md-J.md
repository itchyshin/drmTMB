TITLE: [Dinnage audit Md-J] bias-corrected confint() leaves no trace in conf.status
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-J; severity moderate).
Supporting working: none cited beyond the documented behaviour matching the code.

## What Russell found
`confint()`'s default `bias_correct = "location"` is documented and the
documentation is accurate: it shifts the interval centre off the point estimate
by `+log(g/(g-1))` for location-axis structured-RE SD targets. Two things
remain. Discoverability: `conf.status` is byte-identical to the uncorrected run,
so nothing on the returned object records that a correction was applied. And a
sharper question: `g = length(phylo_mu$group_levels)` is the number of tips,
which is exactly not the effective number of independent units for a
phylogenetic variance component, so the correction is largest on a small tree
and near-zero on a large one -- the opposite of where a degrees-of-freedom
correction should bite.

## Where (at 945da24f)
`R/profile.R` (`confint` bias-correct branch), `man/confint.drmTMB.Rd`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT (both parts). The bias shift is applied at R/profile.R:2152-2159
(`wald_target_log_bias()`, called with `location_only = identical(bias_correct,
"location")`), but `conf.status` is still set at R/profile.R:2228 as
`ifelse(interval_ready, "wald", "wald_unavailable")` -- no distinct status value
exists for a bias-corrected row. `g` is still `length(phylo_mu$group_levels)` at
R/profile.R:2389 (`structured_sd_group_count()`), the count of tips/group
levels, feeding both `wald_target_log_bias()` and `wald_target_df()`
(R/profile.R:2300-2331) via the shared `wald_sd_target_group_count()` path.
`man/confint.drmTMB.Rd` (via R/profile.R's roxygen) documents the scoping
accurately but does not mention a `conf.status` marker, matching the report.

## Proposed fix (Russell's, if stated)
Discoverability is a five-line fix: add a `conf.status = "wald_bias_corrected"`
level. The functional form (`g`) is a design question, not a fix.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
