# PR #1612 paired C17 receipt refresh

- Scope: refresh only the three retained C17/C14 model-15 compatibility rows for PR #1612 source `07bb3b0a734d393811d0d4623a2198b7a553c695`.
- Comparator: the manifest's recorded source `8825b8b3e4cb010ed853327681a225cdc672b4e2`, rerun on the same Totoro host with the same runner SHA-256 `03e230c48539267d803a22e43ffcc68786b08236c4bd6bf9f11c1b1b37c9b1df`.
- Result: 12/12 raw attempt rows match in every field except `source_sha`; the `mc-0568`, `mc-0569`, and `mc-0576` mean relative-error summaries match exactly. The model-15 fingerprint is unchanged.
- Evidence: `docs/dev-log/implementation-recovery/2026-10-24-pr1612-c17-same-host-paired/` retains both runs and the row-wise comparison.
- Checks: `python3 tools/capability_ledger.py --check-c14-receipt-equivalence` passed; `python3 -m unittest tools.tests.test_capability_ledger` passed 87 tests. No tolerance change was made.
- Scope boundary: this is a source-compatibility check, not CMR recovery, interval capability, or interval coverage evidence. Phase B coverage/calibration remains deferred.
