# After Task: Direct-SD evidence count clarity

## Goal

Distinguish evidence receipt records from distinct candidate rows in the generated direct-SD evidence summary.

## Implemented

The report now prints the number of evidence records and the number of distinct candidate rows linked to at least one hash-verified receipt. The current counts are 19 records and 18 linked rows because the native Binomial intercept row has two receipts.

## Mathematical Contract

No model equation, likelihood, formula grammar, or support claim changed.

## Files Changed

- `tools/general-sd-regression/reconcile_evidence.py`
- `tools/general-sd-regression/tests/test_reconcile_evidence.py`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/check-log.d/2026-10-22-sd-evidence-count-clarity.md`
- This after-task report.

## Checks Run

- `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py`: 11 tests passed.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: `candidate_rows=19118 linked_rows=18 unlinked_rows=19100 evidence_records=19`.
- `Rscript -e 'devtools::test(filter = "binomial-(sd|animal|correlated)")'`: 827 assertions passed, 0 failed, 0 warnings, 8 Julia-engine skips, 640.7 seconds. This was a broad candidate smoke run, not an exact-source evidence capsule.
- `git diff --check` is run after this report is written.

## Tests Of The Tests

The new test failed before the summary change when two distinct receipt IDs referenced the same candidate row. After the change, the test passed and asserted both counts separately.

## Consistency Audit

The generated summary, TSV receipt rows, and linked-row count now agree. The required 19,118-row denominator and `direct_sd_claim=none` values remain unchanged. No user-facing model documentation or pkgdown page changed.

## GitHub Issue Maintenance

The open-issue search surfaced the broad simulation-programme issue #59 and missing-response issue #965, but neither tracks this receipt-count clarification. No issue was opened or changed.

## What Did Not Go Smoothly

The initial single-file `testthat::test_file()` invocation did not load the package or shared fixtures and therefore failed with missing-function errors. The package test harness passed. The broad test filter also included beta-binomial contexts and skipped live Julia cases because DRM.jl was not configured in this checkout.

## Team Learning

When an evidence table allows multiple receipts per candidate row, summaries should report both receipt-record and unique-row counts so duplicate evidence is visible without implying extra capability coverage.

## Known Limitations

This tooling change does not reconcile the full capability universe, review the 19 receipts, establish support for any additional family/effect row, or validate uncertainty coverage. The active goal still requires calibrated uncertainty; none is claimed here. G0, G1, G3, G4, G6, G7, and G8 remain open; G2 remains limited to its documented Bernoulli vertical slice.

## Next Actions

Continue the family/effect/backend matrix. Before the next implementation edit, review current ownership for the shared Julia cumulative-logit source; do not infer Julia parity from skipped tests.
