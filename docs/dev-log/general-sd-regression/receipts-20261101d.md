# Receipts 2026-11-01d ledger merge

Backup of the prior ledger: scratchpad `direct-sd-evidence.tsv.bak6-20261101`.

## Reconciler counts
- Before: 333 ledger records, 265 candidate rows linked, 20085 unlinked (from the committed summary). The reconciler on the working tree failed at row 214 (stale test SHA-256) before the merge.
- After: 394 ledger records, 305 candidate rows linked, 20045 unlinked, 20350 candidate rows.
- Last line: `EVIDENCE_RECONCILIATION_PASS candidate_rows=20350 linked_rows=305 unlinked_rows=20045 evidence_records=394`

## Rows replaced (11)
Stale test hash; new evidence ids are old id plus `-20261101d`. Old evidence dirs kept.
- julia-binomial-animal-slope-ainv-nonlogit-20261029 (4 rows)
- native-gamma-animal-q2-correlated-sd-20261101 (2)
- gaussian-native-correlated-q2-sd-20261101 (2)
- gaussian-native-structured-direct-sd-providers-20261101 (3)

## Rows added (61 new, 72 appended in total including the 11 replacements)
- gaussian 14, count 34, gamma-binomial 13. No exact duplicates.

## Unmatched tests (no ledger rows)
- test-binomial-phylo-spatial-q2-sd.R (no binomial phylo/spatial q=2 row; log only)
- test-structured-plain-fits-no-sd-oracle.R (control, no SD regression; log only)
- Gaussian: relmat/phylo q2 oracle parts of test-gaussian-structured-q2-sd.R; mu:I member in sigma-endpoint-mixes; Gaussian Ainv quickwins test.
- gamma iid-plus-spatial fits (no row).
- Known stale outside this group: ledger rows for test-gaussian-sd-slope-regression.R (previously lines 176-177); the reconciler now passes, so recheck if needed.
