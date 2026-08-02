# C18 zero-one-beta ATOM leaf taxonomy

## Decision

C18 replaces ten lossily aggregated zero-one-beta structured ATOM rows with
two non-overlapping ledger leaves per atom/provider combination:

- the existing `mc-0603`--`mc-0607` (`zoi`) and `mc-0613`--`mc-0617` (`coi`)
  IDs become exact, unlabelled q1 intercept leaves; and
- ten new `mc-0705`--`mc-0714` rows retain the q2-plus boundary for the same
  combination.

The q2-plus leaves cover q2, q4, q6, q8, q12, slopes, labels, covariance,
and other forms outside the exact q1 intercept contract. They are package
boundaries, not failed fits and not evidence that those models are
impossible.

This is a sibling split to C14's, not a mutation of it. C14's dated taxonomy
document, its `C14_ZOB_LEAF_TAXONOMY` constant, and its receipt-equivalence
fingerprint are unchanged. C18 introduces its own `C18_ZOB_ATOM_LEAF_TAXONOMY`
constant and its own source document (this file) so the two splits remain
independently auditable.

## Consequence

The model census grows from 687 to 697 cells. Immediately after this split,
before any point-fit promotion, the truthful status partition is:

- 330 implemented
- 350 rejected by design (the 330 C14 package boundaries, ten C14 q2-plus
  structured leaves, and ten new C18 q2-plus ATOM leaves)
- 17 not implemented (the ten exact q1 ATOM leaves plus the seven remaining
  representative rows outside this split)

This split promotes nothing: every one of the ten original `mc-06xx` rows
stays `capability_status = "not_implemented"`, `work_status = "backlog"`,
`evidence_tier = "none"`. It only makes each row's scope exact instead of a
lossy q1/q2/q4/q6/q8/q12 aggregate.

If eight of the ten q1 ATOM leaves later pass independent provider-specific
recovery evidence and review, the intended end state is 338 implemented /
350 rejected by design / 9 not implemented. `mc-0606` (`zoi`, spatial) and
`mc-0616` (`coi`, spatial) are deliberately deferred pending mesh/SPDE
reconciliation and are not part of that eight-cell target.

## Guard

`tools/capability_ledger.py --split-c18-zob-atom-leaves` performs this
source transformation. It shares its implementation with
`--split-c14-zob-structured-leaves` through a common, taxonomy-parameterised
helper (`_split_zob_leaf_taxonomy`); the two entry points differ only in
which taxonomy, source document, tranche, date, and naming prefixes they
pass in. The split is idempotent, adds a source-bound taxonomy record for
every new or split leaf, and never changes an evidence tier or promotes a
cell. Point-fit transition remains a separate, later evidence decision.
