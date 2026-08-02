# After Task: B4-CI C1 rebased canonical Lane B integration

## Goal

Rebuild the approved 24-cell C1 cohort on current canonical `main` after the
original C1 pull request conflicted with later generated-ledger changes.

## Frozen provenance

The immutable evidence source is `574c1108e16e3b0fe4ba88e254a34673508db901`.
The destination base is `7c3bc8b3f917b5d5c00099b1dee49ff5bbf70500`.
The read-only Arc 0 packet is
`e7bfdd77ec92351df7ea0f7a874eba69e7f9aab9e8bcf6abc0c97b5bb7d97ef7`.
It was explicitly approved for C1 before this rebuild.

## Implemented

Exactly the ordered C1 allowlist of 24 cells is promoted to
`interval_feasible`, with 24 matching source evidence records, 24
`verified -> verified` transitions, and 72 receipt/trace/interval blobs.
The main-derived surfaces were regenerated only after the ledger update. The
importer retains current `main` outside those source-bound ledger effects, so
the external dashboard overlay is not replaced by the old C1 snapshot.

## Claim boundary

Each promoted cell claims one finite, ordered, unclamped profile interval for
its named direct target under its retained fixture. This does not claim
coverage, calibration, inference readiness, or broader family/provider
support.

## Verification

- `python3 tools/integrate_b4_ci_c1.py --check` passed.
- `python3 tools/integrate_b4_ci_c1.py --check-current` passed.
- `python3 -m unittest tools/tests/test_b4_ci_c1.py tools/tests/test_capability_ledger.py` passed: 52 tests.
- `python3 tools/capability_ledger.py --check` and `git diff --check` passed.
- The packet confirms 108 exact source-only cells (24/25/36/23), 109 evidence
  references (101 relative plus eight mapped absolute paths), preserved B3,
  and zero source-level semantic mismatches.

## Inherited validation baseline

`validate-mission-control.py` and the release summary retain the same 17
external Julia/S011--S020 evidence-resolution failures. They concern deferred
external dashboard state and do not name a C1 cell, artifact, evidence row, or
transition. This rebuild does not waive or modify that validator.

## Deferred

C2--C4, q12, the four named exclusions, K=12, Lane A/C, missing response,
association, coverage, package code, and the dirty external dashboard overlay
remain outside C1.
