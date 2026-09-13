TITLE: [Dinnage audit Md-N] dropped_rows says "no rows dropped" after MSPL drops rows
LABELS: audit-dinnage, bug, moderate
---
Reported by Russell Dinnage, independent evaluation of drmTMB 0.7.0 at 945da24f
(https://github.com/rdinnager/drmTMB_eval/blob/main/REPORT.md §4, Appendix A row Md-N; severity moderate).
Supporting working: an MSPL fit that silently discarded 100 of 400 rows.

## What Russell found
`dropped_rows` is the best row on the diagnostic board (per the report's §3.3),
but it does not hold on the experimental MSPL path: it reports "nobs=300;
dropped=0 -- No rows were dropped" after MSPL silently discarded 100 of 400
rows. `R/mspl-estimator.R` computes `kept`; `R/drmTMB.R` never reads it.
"Bounded by MSPL being flagged experimental. Same class as the Critical: the
diagnostic does not merely omit, it asserts a falsehood."

## Where (at 945da24f)
`R/mspl-estimator.R` (computes `kept`), `R/drmTMB.R` (never reads it).

## Since-audit status on main (4bfb9d721, 2026-09-13)
PRESENT. `R/mspl-estimator.R` still computes a `kept` vector at lines 145 and
165 (`kept = seq_len(nrow(data))` / `kept = which(keep)`), and a repo-wide
search finds no reference to this field anywhere outside that file -- it is
never wired into `object$model$keep`. `check_dropped_rows()` (R/check.R:1180-
1200) reads only `object$model$keep`, which for the ordinary family builders is
the complete-case filter set at 15 sites across R/drmTMB.R (e.g. R/drmTMB.R:
4468, 4875, 5171, "keep = keep"), unrelated to MSPL's own row-subsampling
`kept`. For an MSPL fit with no missingness, `object$model$keep` is therefore
all-`TRUE`, so `check_dropped_rows()` reports `dropped=0` regardless of how many
rows MSPL itself discarded, exactly as reported.

## Proposed fix (Russell's, if stated)
Thread `kept` into `model$keep`.

## Acceptance
- [ ] a test that fails on 945da24f-behaviour and passes after
- [ ] NEWS.md entry crediting the report
