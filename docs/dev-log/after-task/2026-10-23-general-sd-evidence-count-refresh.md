# After Task: General-SD evidence count refresh

## 1. Goal

Reconcile the current direct-SD receipt table and correct the stale counts in
the human-readable inventory without treating receipt linkage as feature
completion.

## 2. Implemented

The hash-checking reconciler now generates a summary with 19,118 candidate
rows, 32 receipt records, 26 distinct linked row keys, and 19,092 unlinked
rows. The inventory reports the same counts and explains the denominator and
receipt limits.

## 3a. Decisions and Rejected Alternatives

No model equation, likelihood, or parameterization changed. The 19,118 rows
enumerate engine, family/endpoint, mechanism, provider, effect, and layout
candidates. A receipt may link to more than one row through separate records,
and neither a record nor a linked row establishes general support or interval
calibration. I retained the full candidate universe and corrected the stale
counts; I did not reinterpret a linked receipt as an admitted capability.

## 4. Files Touched

`docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`,
`docs/dev-log/general-sd-regression/inventory.md`,
`docs/dev-log/check-log.md`,
`LOOP/lanes/general-sd-regression/checkpoint.md`, and this report.

## 5. Checks Run

- `python3 tools/general-sd-regression/reconcile_evidence.py` exited zero and
  reported `candidate_rows=19118 linked_rows=26 unlinked_rows=19092
  evidence_records=32`.
- A direct TSV count grouped linked keys by initial row status: 25 `required`,
  1 `unresolved`, 0 `blocked_base_plumbing`, and 0
  `structural_inapplicable`.
- The bundled Node runtime ran the unlazy status command: G2 is met and G0,
  G1, G3-G8 remain unmet (1 of 9 gates met).
- `git diff --check` passed for the touched paths, and `slop_check.py` reported
  0 findings for this report.

## 6. Tests of the Tests

The reconciliation command verifies receipt, manifest, test-source hashes,
and exact row keys before writing the summary. Its dedicated Python self-test
passed 11/11, including row and hash validation cases.

## 7a. Issue Ledger

I tried `gh issue list --state open --limit 50 --search '"predictor-dependent random-effect SD"'`, but GitHub's API could not be reached. Issue overlap remains unknown; no issue action was taken.

## 8. Consistency Audit

The inventory and the latest goal checkpoint now agree with the generated
summary. Older checkpoint entries remain historical records. No feature or
calibration claim was promoted.

## 9. What Did Not Go Smoothly

The repository prose lagged behind its evidence table. The system `node`
command is not on this shell's PATH, so the bundled runtime was needed for the
gate-status read. The GitHub issue search also failed at the network boundary.

## 10. Known Residuals

Only 26 candidate rows have linked receipts, and receipt linkage alone does
not determine support. The broader required universe, calibrated uncertainty,
package-wide regression checks, and independent closeout remain open.

## 11. Team Learning

Receipt counts and candidate-row counts should be read from the generated
summary, with the inventory text refreshed in the same task.

## 12. Cross-Product Coverage

This count-refresh task covers only the general-SD evidence join and its
summary text. It does NOT cover any additional family, random-effect type,
provider, endpoint, engine fit, public output route, or calibrated interval
domain. Continue the full capability audit and implementation after verifying
exact source-file ownership; keep the programme goal active.
