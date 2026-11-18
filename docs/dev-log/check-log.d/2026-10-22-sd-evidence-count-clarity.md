# Direct-SD evidence receipt count clarity

- Added explicit counts for receipt records and distinct candidate rows to the generated evidence reconciliation summary.
- RED test: two different receipt IDs for one candidate row produced one linked row but the summary did not expose the two-record count.
- GREEN: `python3 tools/general-sd-regression/tests/test_reconcile_evidence.py` passed 11 tests.
- Regenerated summary: `python3 tools/general-sd-regression/reconcile_evidence.py` reported `candidate_rows=19118 linked_rows=18 unlinked_rows=19100 evidence_records=19`.
- This documents ledger arithmetic only. It does not promote a direct-SD capability row or establish model support.
