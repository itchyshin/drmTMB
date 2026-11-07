# After-task report: q2 receipt linkage

## Goal

Link the existing native q2 SD receipts for Gamma, Beta and Binomial to the frozen general-SD rows they already cover, and make the ledger usable on a clean checkout. No R fits were run and no engine or R code changed. This is evidence bookkeeping only, and every new row has status unreviewed.

## What changed

Thirteen rows were appended to `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`. Each uses a row key that already exists in `required-rows.tsv`, taken from the receipt's own candidate row list where one exists, and otherwise matched on engine, family, mechanism, link, endpoint and provider input.

| Evidence id | Rows | Test file bound |
|---|---:|---|
| native-gamma-phylo-q2-sd-20261027 | 1 | snapshot of test-gamma-phylo-q2-sd-regression.R |
| native-gamma-spatial-q2-sd-20261028 | 1 | snapshot of test-gamma-spatial-q2-sd-regression.R |
| native-gamma-relmat-q2-sd-20261027 | 2 (K and Q, mu, log) | current test-gamma-relmat-q2-sd-regression.R |
| native-beta-phylo-q2-sd-20261027 | 1 | current test-beta-phylo-q2-sd-regression.R |
| native-beta-relmat-q2-sd-20261027 | 2 | snapshot of test-beta-relmat-q2-sd-regression.R |
| native-beta-spatial-q2-sd-20261028 | 1 | snapshot of test-beta-spatial-q2-sd-regression.R |
| native-beta-animal-q2-sd-20261027 | 2 | snapshot of test-beta-animal-q2-sd-regression.R |
| native-beta-animal-pedigree-q2-sd-20261027 | 1 | current test-beta-animal-pedigree-q2-sd-regression.R |
| native-binomial-relmat-q2-sd-20261028 | 2 (K and Q, mu, logit) | snapshot of test-binomial-relmat-q2-sd.R |

Beta animal and pedigree receipts were included because their rows are the same animal_numeric_slope kind and the receipts name them.

## Stale test hashes and snapshots

For six of the nine receipts the test file in `tests/testthat` has been edited since the receipt, so its digest no longer equals the digest in the receipt's source manifest. The reconciler requires both to match. The receipted bytes are still inside each receipt's `source-capsule.tar.gz`, and the archive member digest equals the manifest digest. I extracted that file to `test-snapshot/tests/testthat/` in the same evidence directory and wrote a small `source-manifest-linked.json` that lists the snapshot path with the original digest and records the original manifest and its hash. This follows the existing precedent in the Julia Binomial q2 recovery evidence. The row therefore says what was actually run, not what the file says today. The changed files should be re-run before any review promotes these rows.

The Binomial relmat q2 receipt lives under `tools/general-sd-regression/bernoulli-relmat-q2/`, has no receipt.json and its manifest is a path-to-digest map that the reconciler cannot read, so a linked manifest was built there too. Its logged run has 58 passes and one skipped comparator block (skipped by an environment switch in that log). The ledger summary states this.

## Absolute paths

Six path cells in two ledger rows (zeroonebeta Julia intercept and slope) held absolute `.worktrees` paths. They were made relative. On a clean tree the reconciler failed on these before the change.

## Reconciler counts

Before (lane summary file): 20350 candidate rows, 320 records, 265 rows with a receipt. Run on a clean copy the reconciler failed on the absolute paths.

After: 333 records, 278 distinct rows with a receipt (13 new, none previously linked).

The full ledger does not yet pass. Seven existing rows (evidence ids julia-binomial-animal-slope-ainv-nonlogit-20261029 and gaussian-native-structured-direct-sd-providers-20261101) fail the test digest check because their test files changed after the receipt, and no capsule or git history holds the receipted bytes. I did not edit or remove them. With those seven set aside in a scratch copy of the ledger, the reconciler passes: 20350 candidate, 275 linked, 20075 unlinked, 326 records. The summary markdown was not regenerated for that reason. The tool tests under `tools/general-sd-regression/tests` pass (38 tests).

## Not covered

No receipt was reviewed. The links are evidence of point behaviour only, not admission, coverage or Julia parity. Gamma and Beta sigma-endpoint rows and Beta/Gamma Julia rows are untouched.
