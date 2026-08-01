# C15 zero-one-beta structured q1 adjudication

## 1. Goal

Adjudicate only the approved exact q1 structured zero-one-beta `mu` and
`sigma` leaves (`mc-0583`--`mc-0587`, `mc-0593`--`mc-0597`) against their raw
source SHA, provider-specific oracle, retained all-attempt receipt, and review
bridge. Promote only a complete source-bound point-fit case.

## 2. Implemented

No model, parser, TMB, estimator, or ledger-status code changed. C15 bound the
current canonical target to the retained C14 evidence manifests and recorded a
BLOCK for every approved leaf. The canonical ledger remains 317 implemented,
340 rejected-by-design, and 30 not implemented.

## 3a. Decisions and Rejected Alternatives

- **Decision:** retain all ten leaves as `not_implemented`.
- **Rejected:** treating a passing historical fixture as current evidence when
  its closed model-15 source fingerprint differs from canonical `main`.
- **Rejected:** changing, inferring, or substituting a missing raw source SHA.
- **Rejected:** a bulk provider or family claim. Every q1 provider/dpar leaf is
  an independent decision.

## 4. Files Touched

- `docs/dev-log/after-task/2026-08-01-lane-c-c15-zob-structured-q1-adjudication.md`

No capability ledger source or generated output was changed.

## 5. Checks Run

- `lane_preflight.sh .` — no Claude lane detected in the preceding 12 hours;
  weak all-clear only.
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence` — PASS:
  3 eligible ordinary receipts and 7 source-different retained receipts.
- `python3 tools/capability_ledger.py --check` — PASS (30 generated outputs).
- C14 candidate manifest and each exact q1 leaf in `cells.tsv` — inspected.

## 6. Tests of the Tests

The receipt-equivalence checker distinguishes byte-identical model-15 source
sections from a differing source fingerprint. Its seven `FALSE` entries prove
that a raw receipt cannot be promoted merely because its retained all-attempt
fixture passed. The checker deliberately contains no eligible C15 structured
leaf, so it cannot silently pass the requested promotion set.

## 7a. Issue Ledger

| Leaf(s) | C15 verdict | Binding reason |
| --- | --- | --- |
| `mc-0583` | BLOCK | raw attempts lack a source SHA |
| `mc-0584` | BLOCK | all attempts failed (0/4) at fixture name resolution |
| `mc-0585`--`mc-0587` | BLOCK | relevant model-15 source differs from canonical target |
| `mc-0593`--`mc-0595`, `mc-0597` | BLOCK | relevant model-15 source differs from canonical target |
| `mc-0596` | BLOCK | invalid run-1 remains excluded; corrected run-2 source differs |

None reaches the independent GO-review gate because none reaches a valid
current-source evidence bridge.

## 8. Consistency Audit

The audit checked all ten approved q1 leaves, not just the seven represented in
the source-fingerprint equivalence table. It also checked the adjacent q2-plus
boundary leaves (`mc-0695`--`mc-0704`): those remain package boundaries and
were not affected. The existing three eligible C14 ordinary zero-one-beta
receipts are a distinct cohort and were not reused to support structured
providers.

## 9. What Did Not Go Smoothly

The requested ten-cell cohort was initially a plausible bulk promotion target,
but its retained records span different model-15 source surfaces. Three cases
have no qualifying current-source receipt at all; one has no valid fixture
attempt. This is an evidence limitation, not a ledger-generator defect.

## 10. Known Residuals

All ten leaves still need new recovery evidence run against the canonical
source, followed by provider-specific independent GO/BLOCK review. No profile,
interval, coverage, calibration, REML, q2-plus, covariance, or family-wide
claim is supported.

## 11. Team Learning

For a closed TMB route, an all-passing recovery receipt is insufficient after
the governing R/C++ surface changes. Preserve raw attempts, fingerprint the
closed source surface, and require a new receipt where it differs.

Memory receipt: `/ask-brain` was queried; the repository C14 manifest was the
authoritative technical source. The repository route manifest was unavailable
for the temporary clean worktree, so no unverified route guidance was used.

Golden Set: not in scope. C15 changes neither an implementation nor a reusable
guard; the source-fingerprint checker already mechanises this failure class.

## 12. Cross-Product Coverage

This C15 evidence audit covers ✓ only ordinary ML zero-one-beta exact
structured q1 `mu`/`sigma` leaf provenance and the ledger decision to retain
them. It does NOT cover new formula admission, source-equivalent recovery,
profiles, intervals, coverage, `zoi`/`coi`, q2-plus, labels, covariance,
missing response, Lane A association, or Lane B scale work.
