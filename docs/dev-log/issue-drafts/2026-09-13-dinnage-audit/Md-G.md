TITLE: [Dinnage audit Md-G] Numeric-kernel oracle silently drops non-finite grid points
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-G; severity moderate).
Supporting working: the extreme-value kernel oracle's own grid, extended to the `beta_binomial` cell.

## What Russell found
The extreme-value kernel oracle is the test that should have caught the
`beta_binomial` guard gap (Md-H) below it. It did not because it silently drops
every non-finite grid point -- 50 of 140 in the `beta_binomial` cell, so only
51% of the grid is actually asserted -- and the reference shares the compiled
kernel's cancellation (`1 - plogis(eta)`), so both go non-finite together and
the disagreement is invisible by construction.

## Where (at 945da24f)
`tests/testthat/` (the `run_oracle()` helper).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `run_oracle()` at tests/testthat/test-numeric-kernel-oracle.R:84-108
computes `rel_err` for every grid point, then does
`kept_finite <- kept$rel_err[!is.na(kept$rel_err)]` (line 103) and asserts only
`max(kept_finite) <= tol` (line 105) -- there is no count of how many points
were `NA`/non-finite and excluded, and no assertion bounding that count. The
`beta_binomial` oracle at tests/testthat/test-numeric-kernel-oracle.R:446-465
uses this same `run_oracle()` helper, so the silent-drop behaviour applies to
it exactly as reported.

## Proposed fix (Russell's, if stated)
Fix the oracle before the code: make it count and assert its exclusions, and
make the reference independent at the boundary. Then watch which grid points
turn red.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
