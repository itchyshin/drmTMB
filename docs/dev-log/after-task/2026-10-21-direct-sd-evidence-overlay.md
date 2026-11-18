# After Task: Exact-key direct-SD evidence overlay

## 1. Goal

Make existing implementation receipts traceable to exact rows in the frozen candidate universe without changing that universe or treating a test receipt as a support decision.

## 2. Implemented

Added a fail-closed evidence reconciler and a separate receipt table. Two source-bound Julia Binomial/logit rows are linked: the ordinary random intercept and one independent numeric random slope. Both records remain `unreviewed`; the overlay makes no general support, identifiability, cross-engine parity, or interval-coverage claim.

## 3a. Decisions and Rejected Alternatives

No likelihood or covariance parameterization changed. I kept the overlay separate from the generated candidate universe so a receipt cannot promote a support claim. I did not add a cross-engine grade: parity requires separately reviewed evidence from both engines.

## 4. Files Touched

- `tools/general-sd-regression/reconcile_evidence.py`
- `tools/general-sd-regression/tests/test_reconcile_evidence.py`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-22-direct-sd-evidence-overlay.md`
- `docs/dev-log/after-task/2026-10-21-direct-sd-evidence-overlay.md`

## 5. Checks Run

- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 8 passed.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118 linked_rows=2 unlinked_rows=19116 evidence_records=2`.
- `python3 .../slop_check.py docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`: 0 findings.
- `git diff --check` on the four overlay files: passed.
- `required-rows.tsv` SHA-256 is unchanged at `3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.

## 6. Tests of the Tests

The first test run failed because the reconciler did not yet exist. Focused candidate-promotion and test-source-manifest tests then failed before their guards were added. The final suite exercises exact matching and rejects unknown or partial keys, duplicate identities, bad receipt, source-manifest, or test-source hashes, a test omitted from the manifest, unsupported grades, missing commands, and a candidate row whose claim is no longer `none`.

## 7a. Issue Ledger

No issue was changed. A read-only search for open issues on random-effect SD regression failed because the GitHub API connection was unavailable.

## 8. Consistency Audit

The required-row file and its 19,118-row denominator were not edited. The new report counts a row once even if it later receives multiple receipts. The summary explicitly says receipts do not establish support, admission, identifiability, or calibrated interval coverage. Graft CLI was unavailable; I read `graft/INDEX.md`, which had no task-specific node, then inspected the exact ledger and receipt artifacts.

## 9. What Did Not Go Smoothly

The lane-lease registry initially reported its lock as busy and could not persist the additional report paths under normal workspace permissions. The lease was then registered successfully with the approved elevated filesystem operation. The main `docs/dev-log/check-log.md` was left untouched because lane preflight reported 424 refs with edits absent from this checkout; the scoped `check-log.d` record carries this slice's evidence.

## 10. Known Residuals

Only two Julia Binomial/logit candidate rows have receipts linked, and both remain unreviewed. The other 19,116 rows remain unlinked in this overlay; this does not mean they lack implementation or evidence. No package-wide R/Julia checks, rendered-site checks, or uncertainty-coverage validation were run for this bookkeeping slice.

## 11. Team Learning

Continue the source-to-row audit family by family, adding links only where the test target and source manifest establish an exact match. Keep implementation and output gaps in the active programme ledger; coverage calibration remains deferred under the current goal.

## 12. Cross-Product Coverage

This bookkeeping slice does NOT cover implementation or output support beyond the two linked Julia Binomial/logit rows. It does NOT cover native TMB parity, other links, families, providers, correlated or structured effects, profile/bootstrap refits, package-wide R/Julia checks, or calibrated interval coverage. The full programme gates remain open.
