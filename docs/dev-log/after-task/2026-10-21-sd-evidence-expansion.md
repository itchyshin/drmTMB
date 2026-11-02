# After Task: Bernoulli SD Evidence Expansion

## 1. Goal

Link additional source-bound Bernoulli SD test receipts to their exact rows in the frozen candidate universe without changing the universe or upgrading implementation claims.

## 2. Implemented

Added two native TMB Bernoulli random-intercept workflow receipts, for profile and marginal simulation tests, and one Julia Bernoulli correlated q2 bridge smoke receipt. The overlay now links five receipts to four unique candidate rows. Every record remains unreviewed.

## 3a. Decisions and Rejected Alternatives

Kept the native profile and simulation evidence separate because each has its own source file and digest. Did not attach the native integration test: its manifest digest differs from the current test file. The Julia q2 row stays unresolved, and the smoke run's singular-Hessian warnings preclude stronger language. Receipts do not promote the frozen candidates or establish parity.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- `docs/dev-log/check-log.d/2026-10-21-sd-evidence-expansion.md`
- `docs/dev-log/after-task/2026-10-21-sd-evidence-expansion.md`

## 5. Checks Run

- `python3 tools/general-sd-regression/reconcile_evidence.py`: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118 linked_rows=4 unlinked_rows=19114 evidence_records=5`.
- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 8 passed.
- The reconciler rechecked receipt, manifest, and test-source hashes for all five records; every exact test path is listed in its source manifest.
- The after-task structural validator passed. The required absolute-path prose check reported zero findings for the report and generated evidence summary.
- Frozen `required-rows.tsv` SHA-256 remains `3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.

## 6. Tests of the Tests

The existing eight reconciler tests exercise exact-key matching and reject unknown keys, duplicates, altered hashes, omitted manifest bindings, invalid grades, missing commands, and candidate promotion. I will record their final rerun result after closeout checks.

## 7a. Issue Ledger

No issue was changed. This bookkeeping update does not alter model behaviour; the previous report records the failed GitHub API search.

## 8. Consistency Audit

The required-row universe and its `direct_sd_claim=none` state were preserved. Native integration evidence was excluded because its source hash did not match. The Julia q2 row remains unresolved and the receipt remains unreviewed. The evidence summary counts unique rows, not receipts, and explicitly makes no support or calibration claim.

## 9. What Did Not Go Smoothly

The repository graph CLI and prescribed route manifest were unavailable for this worktree, and the initial preflight command mishandled the space-containing repository path. I read `graft/INDEX.md`, reran lane preflight with the quoted path, and used the exact candidate and receipt files.

## 10. Known Residuals

The overlay covers four unique candidate rows out of 19,118. It does not establish a complete feature matrix, cross-engine parity, broad recovery, calibrated uncertainty, or public admission. The Julia correlated q2 run logged singular-Hessian warnings. No new model fit or package-wide test was run in this evidence-only slice.

## 11. Team Learning

Keep evidence links granular by test file. When a multi-test run has one source-manifest mismatch, retain only rows whose exact test source still matches the manifest and receipt. Keep structural status in the candidate universe unchanged until a separate reviewed gate.

## 12. Cross-Product Coverage

This slice links narrow native TMB and Julia Bernoulli receipts. It does NOT cover the remaining 19,114 candidate rows, does NOT establish native/Julia parity, and does NOT cover calibrated interval performance or programme completion.
