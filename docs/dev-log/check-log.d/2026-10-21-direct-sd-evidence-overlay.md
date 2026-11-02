# Exact-key direct-SD evidence overlay

- Added `tools/general-sd-regression/reconcile_evidence.py` and eight focused Python tests. The tool joins receipts to exact frozen row keys, verifies receipt, source-manifest, and test-file SHA-256 values, and confirms the test file appears in the source manifest.
- Added two unreviewed receipt links for the Julia Binomial/logit ordinary random-intercept and independent-random-slope rows. Both link to the source-bound v4 bridge test log, the matching 167-file source manifest, and the exact test file. This is narrow fit/recovery evidence; it does not claim broad support, parity, or calibrated coverage.
- Reconciliation: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118 linked_rows=2 unlinked_rows=19116 evidence_records=2`.
- Focused tests: 8 passed. Negative checks cover unknown keys, duplicate evidence identities, receipt, manifest, and test-source hash mismatches, a test omitted from the manifest, invalid grades, missing commands, and candidate-row promotion.
- Frozen `required-rows.tsv` SHA-256 remained `3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253` before and after.
- `slop_check.py` reported 0 findings for the generated summary; `git diff --check` passed for all four overlay files.
- The broader `check-log.md` was not edited because lane preflight reported 424 refs carrying edits absent from this checkout. A GitHub issue search was attempted but the API was unreachable.
