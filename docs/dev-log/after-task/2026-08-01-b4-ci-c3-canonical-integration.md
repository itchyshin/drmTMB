# B4-CI C3 canonical Lane B integration

## Goal

Promote only the approved 36 C3 cells from retained source commit
`574c1108e16e3b0fe4ba88e254a34673508db901` into canonical Lane B.

## Authority and base

The authorized reconciled C3 packet is
`115dd44155c53b7928c6be0ee28990435d114feab2cc45f68f7d1a565e18b22b`.
The frozen base is `ee9d855fc6754c19174fd74078f8e6f2f62a9631`.
The separately approved frozen census is `point_fit_recovery: 127 -> 91`.

## Delivered scope

`tools/integrate_b4_ci_c3.py` imports the exact ordered 36-cell allowlist,
the matching 36 evidence rows, 36 verified-to-verified transitions, and 108
source-bound receipt/trace/interval blobs.  It writes a manifest with each
source blob SHA-256 and verifies every imported artifact against it.

The C3 allowlist digest is
`e3aef83e995ac82df7142eee0abd7d1a53bee6d146e6f239f708a84e2b514393`.
The four-cohort ordered-ID digest remains
`e169c35a1618d0f35ed2b39ae1987da9444060f14241d9f6ab7bf2d44e836fc2`.

## Boundaries preserved

B3 (`mc-0102`, `mc-0124`, `mc-0146`, `mc-0168`), the four named exclusions,
and all six association rows are compared directly with the frozen base before
application and during verification.  No package code, formula grammar, Lane
A/C, association material, coverage, missing-response material, or external
dashboard overlay was changed.

## Count reconciliation

The B4-scoped progression is 97 to 133.  A foreign association merge already
present on the frozen base contributes five interval-feasible association rows,
so the canonical global count is 102 to 138. The later C17-C1 point-fit
promotion is preserved; association rows remain bytewise equal to the frozen
base.

## Validation

Passed: C1 strict verifier; C2 later-cohort verifier; C3 source/manifest/blob
verifier; capability-ledger check; all 47 capability-ledger tests; C1, C2, and
C3 focused integration tests; and `git diff --check`.

The C2 verifier retains its strict 97-count default and exposes a separate
later-cohort mode that checks the C2 source closure while requiring the count
to be at least 97.  C3 regression tests reject unapproved IDs, B3/exclusion/
association drift, artifact changes, claim broadening, evidence deletion, and
transition deletion.

## Mission Control and release readout

Mission Control remains red solely on inherited external dashboard/DRM.jl
references: seven unresolved local evidence URLs, two Julia registry/artifact
count mismatches, and S011--S020 absent 100-slice evidence.  None is in C3
scope and no Mission Control file was modified.

## Risks and limits

Every promoted claim remains per-cell computational interval feasibility for a
finite, ordered, unclamped retained profile interval.  It is not coverage,
calibration, inference readiness, provider-wide, family-wide, or public
interval guidance.

## Next action

Commit this isolated C3 worktree.  Do not push or open a PR until explicit user
authorization.  C4 must wait for a C3 merge, a fresh `origin/main` freeze, a
new Arc 0 packet, and new approval.
