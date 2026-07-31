# C14 package-boundary taxonomy restoration

## Purpose

C14 restores the distinction between the actionable model backlog and current
package boundaries. It is not a capability admission or a claim of
mathematical impossibility.

## Immutable source

The restoration set is the 330 `model_surface` rows explicitly marked
`rejected_by_design` in commit
`0ccffcb539e19c3b4eeabf394634ddbcfc930cd8`, at
`docs/dev-log/dashboard/capability-ledger/cells.tsv`.

`tools/capability_ledger.py --restore-c14-boundaries` reads that exact Git
object, requires exactly 330 unique IDs, refuses to overwrite an implemented
row, and accepts only a prior `not_implemented/backlog/none` state. For every
restored row it records the matching C14 `backlog -> deferred` taxonomy
transition with no evidence IDs.

## Result

The model surface remains 677 cells, partitioned into:

- 314 implemented;
- 330 not currently supported package-boundary cells; and
- 33 actionable not-implemented cells.

The Future-extension audit remains a separate presentation of those package
boundaries. No formula grammar, evidence tier, recovery claim, profile,
interval, coverage, or Mission Control runtime source is changed by this
restoration.

## Follow-up boundary

This repair does not make the requested `328 / 330 / 19` census valid. Ten
structured zero-one-beta representative rows collapse q1 through q12, so their
q1-only fixtures require a non-lossy leaf taxonomy before any promotion.
