# After Task: Source-bound SD Evidence Expansion, Wave 2

## 1. Goal

Expand the exact-key SD evidence overlay across additional families and engines, and make the verifier accept retained JSON manifests without weakening source binding.

## 2. Implemented

Added three receipt links: Julia Gamma random-intercept and independent-slope bridge tests, and native Poisson random-intercept single-fixture recovery/oracle evidence. Together with the previous overlay entries, the table now contains eight receipts across seven exact candidate rows. Added JSON manifest support to the evidence reconciler and regression tests for valid and mismatched path/hash pairs.

## 3a. Decisions and Rejected Alternatives

Kept all new records unreviewed. Treat the Julia Gamma slope coefficient match as single-fixture evidence; general engine parity remains untested. Native Poisson has one synthetic fixture for signed coefficient recovery and likelihood-oracle agreement; recovery-grid performance remains unmeasured. Julia correlated q2 remains unresolved and its receipt logs singular-Hessian warnings. No candidate status or `direct_sd_claim` was changed.

## 4. Files Touched

- `tools/general-sd-regression/reconcile_evidence.py`
- `tools/general-sd-regression/tests/test_reconcile_evidence.py`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-21-sd-evidence-expansion-wave2.md`
- `docs/dev-log/after-task/2026-10-21-sd-evidence-expansion-wave2.md`

## 5. Checks Run

- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 10 passed.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118 linked_rows=7 unlinked_rows=19111 evidence_records=8`.
- Exact candidate-row keys, receipt digests, source-manifest digests, and current test-source digests were checked for the three additions.
- Frozen `required-rows.tsv` SHA-256 remains `3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.
- After-task structure validation and prose review passed; `git diff --check` passed on the leased paths.

## 6. Tests of the Tests

The new JSON-manifest tests were run before implementation. The valid pretty-printed manifest failed because the verifier only recognized same-line text receipts. A second case showed that path and hash substrings on separate JSON entries could be incorrectly paired when JSON was minified. The implementation now parses JSON entries and requires both exact fields in the same object. The full suite also confirms the existing text-manifest, hash-mismatch, missing-binding, and exact-row guards still pass.

## 7a. Issue Ledger

No issue was changed. This slice fixes the evidence verifier and adds receipt links; it changes no fitted-model behavior.

## 8. Consistency Audit

The overlay still validates all exact row keys and all eight receipt records. The candidate universe hash and candidate statuses are unchanged. The summary counts unique rows, keeps every row as a candidate obligation, and disclaims support admission, broad parity, and interval calibration.

## 9. What Did Not Go Smoothly

The first JSON-manifest reconciliation failed because the verifier assumed test path and digest appeared on one text line. A new test also exposed a false positive for path and hash values appearing in different JSON entries. A first compatibility repair rejected the existing absolute-path checksum fixture; path matching was adjusted to accept an exact repository-relative suffix while retaining an exact digest token. Ten focused tests now pass.

## 10. Known Residuals

Seven of 19,118 candidate rows have at least one linked receipt; 19,111 remain unlinked in this overlay. Receipts are unreviewed and do not determine row admission. No model fits, package-wide tests, interval coverage runs, or public claims were made in this slice.

## 11. Team Learning

Parse structured manifests by fields, not by line-substring coincidence. Test both the valid structured format and a malformed cross-entry pairing before accepting a new evidence format.

## 12. Cross-Product Coverage

The linked evidence spans native TMB Bernoulli and Poisson fixtures and Julia Binomial and Gamma bridge fixtures. This slice does NOT cover broad native/Julia parity, complete family or random-effect support, calibrated uncertainty, or programme completion.
