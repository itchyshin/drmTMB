TITLE: [Dinnage audit Md-L] make_tmb_data_core is 17 hand-maintained copies of one data literal
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-L; severity moderate).
Supporting working: the package's own in-code post-mortem for issue #1048.

## What Russell found
`make_tmb_data_core()` assembles the data list handed to the TMB template as 17
hand-maintained copies of a 54-field literal (918 field assignments). The
package's own in-code post-mortem records that this structure already produced
a silently wrong model (#1048: `has_phylo_mu = 0L` turned a validated `phylo()`
term into a no-op that fit, converged, and reported). A systematic sweep found
no live recurrence -- "the finding is the standing risk, not a present defect."

## Where (at 945da24f)
`R/drmTMB.R` (`make_tmb_data_core` and its 17 copies).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `make_tmb_data_core()` spans R/drmTMB.R:20487-21832 (~1,345 lines) and
still branches per family with `if (identical(spec$model_type, ...))` /
`return(list(model_type = <n>L, ...))`; a count of `model_type = <n>L,` literal
assignments inside the function returns exactly 17, matching the report. The
#1048 post-mortem comment is still present verbatim at R/drmTMB.R:21205-21208
("#1048: the first binomial structured slice. These five fields used to be...").
No single constructor has been introduced; `make_tmb_data()` (R/drmTMB.R:21833-
21841) is a thin wrapper that calls `make_tmb_data_core(spec)` once and adds
three MSPL fields, not a refactor of the 17-branch body.

## Proposed fix (Russell's, if stated)
Worth a single constructor the next time that file is open.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
