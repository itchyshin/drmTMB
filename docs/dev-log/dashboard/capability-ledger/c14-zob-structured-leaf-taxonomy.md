# C14 zero-one-beta structured q1 leaf taxonomy

## Decision

C14 replaces ten lossily aggregated zero-one-beta structured rows with two
non-overlapping ledger leaves per provider/dpar combination:

- the existing `mc-0583`--`mc-0587` and `mc-0593`--`mc-0597` IDs become exact,
  unlabelled q1 intercept leaves; and
- ten new `mc-0695`--`mc-0704` rows retain the q2-plus boundary for the same
  combination.

The q2-plus leaves cover q2, q4, q6, q8, q12, slopes, labels, covariance,
and other forms outside the exact q1 intercept contract. They are package
boundaries, not failed fits and not evidence that those models are impossible.

## Consequence

The model census grows from 677 to 687 cells. Before any point-fit promotion,
the truthful status partition is 314 implemented, 340 package boundaries, and
33 actionable not-implemented leaves. If the fourteen independently reviewed
ordinary/q1 structured evidence bridges later pass, the intended end state is
328 implemented, 340 boundaries, and 19 actionable leaves.

## Guard

`tools/capability_ledger.py --split-c14-zob-structured-leaves` performs this
source transformation. It is idempotent, adds a source-bound taxonomy record
for every new or split leaf, and never changes an evidence tier or promotes a
cell. Point-fit transition remains a separate evidence decision.
