TITLE: [Dinnage audit Md-K] Halted Julia bridge's NAMESPACE footprint needs a public-status decision
LABELS: audit-dinnage, documentation, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-K; severity moderate).
Supporting working: a footprint count over the Julia-bridge route.

## What Russell found
The halted Julia bridge is 32 of 90 S3 methods (35.6%), 5,193 lines (8.3% of R
source), 17 test files, one `Suggests`, 6 example-less man pages, and one
exported generic -- for a route the package's own vignette tells users not to
rely on, and which has already hung a CRAN check for 2.9 hours. Coupling to the
rest of the package is one-directional and shallow (three call sites). "Decide
its public status before submission. This is a decision, not a defect."

## Where (at 945da24f)
`R/julia-bridge.R`, `NAMESPACE`, `NEWS.md:105`.

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT / UNCLEAR (a decision, not a code state). R/julia-bridge.R is now 8,688
lines (grown from the 5,193 cited, consistent with continued bridge work visible
in recent commit history, e.g. `feat(bridge): admit biv_student through
engine = "julia"`). The CRAN-check hang is confirmed in the repo's own record,
though at a different NEWS.md line (drift): NEWS.md:1405, "...hung Ligges
R-release for ~10448s" (~2.9 hours), matching the report. `vignettes/
capability-and-limits.Rmd:518` still calls Julia cross-family fitting "reachable
but experimental." No decision recorded anywhere in NAMESPACE, NEWS.md, or the
vignettes about withdrawing or formalizing the bridge's public export status --
this remains an open decision for Shinichi, not something a static read can
resolve either way.

## Proposed fix (Russell's, if stated)
Decide its public status before submission -- this is a decision, not a defect.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
