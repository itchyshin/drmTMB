# SUPERSESSION — `structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`

**Date:** 2026-08-15 · **Lane:** `claude/lane-irc-legacy-evidence`
**Applies to:** `docs/dev-log/dashboard/structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv`

## The problem, stated plainly

That TSV records, for all four of its rows:

```
promotion_decision      = do_not_promote
review_decision         = fisher_rose_grace_sr475_review_required_no_promotion
review_signal           = sr475_mcse_met_review_pending
linked_interval_status  = planned
linked_coverage_status  = planned
```

**Those fields are a snapshot taken BEFORE the review they were waiting on.** The review happened,
and it promoted three of the four. `docs/dev-log/after-task/2026-06-30-q-series-q1-mu-sr475-inference-ready.md`
records the outcome:

> *"Promote only the q1 `mu:(Intercept)` rows that Rose, Fisher, and Grace accepted … Promoted
> `qseries_phylo_q1_mu_intercept`, [`qseries_spatial_q1_mu_intercept`,]
> `qseries_relmat_q1_mu_intercept` to interval+coverage `inference_ready`."*
>
> and, for the fourth: *"`qseries_animal_q1_mu_intercept`: not promoted; 473/475 usable intervals…"*

The TSV was never updated afterwards. **Anyone auditing from it reaches the opposite conclusion from
the truth** — which is not hypothetical: on 2026-08-15 an audit did exactly that and briefly
concluded that `mc-0272`, `mc-0285` and `mc-0309` were making unsupported interval claims. They are
not; they are properly promoted and are now wired to `coverage_study` evidence rows.

## Current status of the four rows

| provider | coverage | MCSE | misses (lo/up) | TSV says | ACTUAL outcome |
| --- | ---: | ---: | ---: | --- | --- |
| phylo | 0.9832 | 0.005904 | 4 / 4 | `do_not_promote` | **PROMOTED** to interval+coverage `inference_ready` |
| spatial | 0.9705 | 0.007760 | 4 / 10 | `do_not_promote` | **PROMOTED** |
| relmat | 0.9789 | 0.006587 | 3 / 7 | `do_not_promote` | **PROMOTED** |
| animal | 0.9747 | 0.007200 | 6 / 4 | `do_not_promote` | **NOT promoted** — 473/475 usable, correctly withheld |

## Why the columns were not edited

The `promotion_decision` / `review_decision` / `linked_*_status` fields are a **frozen record of a
decision point**, and rewriting them would destroy the audit trail that shows the review was pending
and then resolved. The defect is the missing forward pointer, not the recorded values. This note is
that pointer; the TSV is left byte-intact.

## Two caveats that belong with these numbers wherever they are quoted

1. **All four providers OVER-cover** — 0.9705 to 0.9832 against a nominal 0.95. Over-coverage is not
   a safety margin; it means the intervals are wider than they need to be, and it is a calibration
   failure in the same sense under-coverage is. The reviewers accepted it; a reader should still be
   told.
2. **The misses are one-sided.** spatial 4 lower / 10 upper, relmat 3 / 7. Symmetric coverage at the
   nominal rate is not what these achieve.

## SCOPE EXTENDED (2026-08-15 overnight): this covers NINE files, not one

A repo-wide sweep for this defect class enumerated 406 dashboard + 1,941 simulation-artifact TSVs,
isolated the 190 carrying a `promotion_decision` column, and joined them against current truth. It
found **eight siblings of this file with the identical defect** — all committed together in
`d1b029cb6` (2026-06-30), all recording `promotion_decision = do_not_promote` for the same four
cells, and none touched again after the later after-task promoted phylo/spatial/relmat:

```
structured-re-gaussian-lowq-mu-intercept-sr475-results.tsv          (this note's original subject)
structured-re-gaussian-lowq-mu-intercept-nibi-smoke-results.tsv
structured-re-gaussian-lowq-mu-intercept-pregrid-results.tsv
structured-re-gaussian-lowq-mu-intercept-smoke-results.tsv
structured-re-gaussian-lowq-mu-intercept-pregrid-dispatch.tsv
structured-re-gaussian-lowq-mu-intercept-topup-dispatch.tsv
structured-re-gaussian-lowq-mu-intercept-smoke-contract.tsv
structured-re-gaussian-lowq-mu-intercept-dry-run.tsv
structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv
```

**This note supersedes the frozen verdict in all nine.** The correction in the table above applies
unchanged: phylo, spatial and relmat were promoted; animal was correctly withheld at 473/475.

**The sweep's reassuring half, stated because a negative result is also a finding.** Outside this
one 2026-06-30 cluster the class did not recur: 11 other decision-bearing clusters checked
CONSISTENT with current truth, and 1 UNDETERMINED. The closest call — the AGHQ + Cox-Reid
non-Gaussian REML arc (2026-07-18/22) landing after `structured-re-native-reml-scope-status.tsv`
(2026-07-14) — was read in depth and resolved CONSISTENT: the estimator was deliberately kept `ML`
and the vignette marks binomial REML diagnostic-only, so that gate's claim still holds. Full query
log: `scratchpad/overnight-staleness-sweep.md`.

## What this note does NOT establish

- It does not re-adjudicate the promotion. Rose, Fisher and Grace reviewed it; that stands.
- It does not check any other campaign TSV for the same staleness pattern. **This class of defect —
  a results file frozen before the decision that superseded it — has not been swept for elsewhere**,
  and there is no guard that would detect it.
