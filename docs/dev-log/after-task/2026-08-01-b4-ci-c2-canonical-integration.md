# After Task: B4-CI C2 canonical Lane B integration

## Goal

Promote the explicitly approved, ordered C2 allowlist of 25 retained Lane B
cells to `interval_feasible` on the C1-merged canonical base.

## Frozen provenance

The immutable source is `574c1108e16e3b0fe4ba88e254a34673508db901`; the
frozen destination base is `950636b378cad6fabe53a4b995e8c7de21b0aaec`.
The read-only C2 Arc 0 packet is
`68b5534646e2816df00334e95f3b782cdeb7ed2ec1709438ce9096711bfd3734`, which
received explicit cohort-2 approval before this worktree was created.

## Implemented

Exactly 25 ordered cell rows, 25 matching evidence rows, and 25
`verified -> verified` transitions were imported directly from the retained
source. Their 72-blob dependency closure consists of 21 receipt/trace/interval
triplets, three direct profile traces (`mc-0297`, `mc-0300`, `mc-0312`), and
two receipt triplets for the two named direct targets of `mc-0494`. Ledger
surfaces were regenerated only after the ledger update.

## Claim boundary

Every row remains limited to its named direct target and frozen retained
fixture: a finite, ordered, unclamped profile interval only. No coverage,
calibration, inference-ready, provider-wide, family-wide, public-API, or
formula-wide claim is introduced.

## Verification

- C1 and C2 source-bound checkers pass; C1 preserves its 72-cell baseline and
  C2 raises the canonical `interval_feasible` count to 97.
- The focused suite passes: 55 tests, including mutations for unapproved IDs,
  B3/exclusion drift, direct-trace/blob drift, evidence/transition loss, and
  broadened wording.
- `python3 tools/capability_ledger.py --check` and `git diff --check` pass.
- `tools/qseries_v1_release_check.py --summary --check-report --check-candidates`
  passes.

## Inherited validator baseline

`tools/validate-mission-control.py` retains exactly the inherited 17 external
Julia/S011--S020 evidence-resolution errors. None names a C2 cell, evidence
row, transition, or imported blob; this cohort does not waive or modify them.

## Deferred

C3--C4, q12, the four named exclusions, K=12, Lane A/C, missing response,
association, coverage, package code, and the dirty external dashboard overlay
remain outside C2.
