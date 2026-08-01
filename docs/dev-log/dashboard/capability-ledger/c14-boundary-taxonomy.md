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

`c14-boundary-source.tsv` is the immutable, portable snapshot of those exact
330 IDs, extracted from that source revision. `tools/capability_ledger.py
--restore-c14-boundaries` validates its one-column schema and exact unique-ID
count, refuses to overwrite an implemented row, and accepts only a prior
`not_implemented/backlog/none` state. This lets CI validate the taxonomy
without requiring a historical local-only Git object. For every restored row it
records the matching C14 `backlog -> deferred` taxonomy transition with no
evidence IDs.

## Result

At completion of C14-A, the model surface remained 677 cells, partitioned into:

- 314 implemented;
- 330 not currently supported package-boundary cells; and
- 33 actionable not-implemented cells.

The subsequent approved C14-B q1/q2-plus leaf split adds ten package-boundary
leaves, so the current model surface is 687 cells with 340 boundary rows. The
Future-extension audit remains a separate presentation of those package
boundaries. No formula grammar, evidence tier, recovery claim, profile,
interval, coverage, or Mission Control runtime source is changed by this
restoration.

## Follow-up boundary

This repair does not make the requested `328 / 330 / 19` census valid. Ten
structured zero-one-beta representative rows collapse q1 through q12, so their
q1-only fixtures require a non-lossy leaf taxonomy before any promotion.
