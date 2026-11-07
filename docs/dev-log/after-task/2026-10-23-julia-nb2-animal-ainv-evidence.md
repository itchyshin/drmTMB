# After Task: Julia NB2 animal Ainv evidence receipt

## Goal

Bind the focused Julia NB2 animal-intercept precision-provider test to its exact frozen capability row without changing the 19,118-row inventory or promoting the row to general support.

## Implemented

Added a hash-bound, unreviewed focused-test receipt for the Julia `nbinom2`, `mu`, q1 animal-intercept route using `Ainv`. The receipt records the executed test path, a byte-identical in-repository test snapshot, test-time Julia source hashes, and the exact run result.

## Mathematical Contract

The test compares the fitted SD coefficients, likelihood, and group-named SD predictions for equivalent supplied `A` and `Ainv` inputs. It also exercises malformed precision rejection. It does not add or alter the model parameterization.

## Files Changed

- `docs/dev-log/general-sd-regression/evidence/julia-nb2-animal-ainv-20261023/`: receipt, source manifest, console summary, and byte-identical test-source snapshot.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and `direct-sd-evidence-summary.md`: exact-row evidence link and regenerated reconciliation summary.
- `docs/dev-log/check-log.d/2026-10-23-julia-nb2-animal-ainv-evidence.md` and `docs/dev-log/check-log.md`: check receipt and index.
- `LOOP/lanes/general-sd-regression/checkpoint.md`: current progress and limits.
- This report.

## Checks Run

- `JULIA_DEPOT_PATH=/private/tmp/general-sd-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_nb2_animal_sd_regression.jl` in the paired Julia worktree: **19/19 passed in 15.6 seconds** on Julia 1.10.0.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: **PASS**, 19,118 candidate rows, 20 receipts, 19 linked rows, 19,099 unlinked rows.
- `python3 -m unittest discover -s tools/general-sd-regression/tests -p 'test_reconcile_evidence.py' -v`: **11/11 passed**.
- Scoped `git diff --check` for the changed tracked ledger/checkpoint files passed. The full-worktree check still reports a pre-existing blank line at EOF in the unrelated `tests/testthat/test-binomial-sd-integration.R`; that file was left untouched.
- The required `slop_check.py` review reported **0 findings** for this report.
- GitHub issue search and inspection: open issues #59 and #1463 concern broader simulation reporting and a historical cross-package test sweep; neither tracks this exact evidence receipt.

## Tests Of The Tests

The test checks route equivalence and malformed precision input. The evidence reconciler independently checks the exact row key, receipt and manifest hashes, and the test snapshot hash. The snapshot hash matches the test source that was executed in the paired Julia worktree.

## Consistency Audit

No model code, user-facing support claim, formula grammar, or capability inventory row changed. The evidence summary explicitly says that receipts do not establish general support, identifiability, admission, or calibrated coverage. No broad documentation render was needed for this evidence-only update.

## GitHub Issue Maintenance

Issue #59 describes a broader staged simulation framework; #1463 records an earlier package comparison. Neither is an exact match for this one test receipt, so the issue tracker was left unchanged.

## What Did Not Go Smoothly

The reconciler requires referenced files to remain under the native candidate root. I therefore archived the executed Julia test as a byte-identical snapshot and recorded the original execution path and hashes in the manifest. The repository's documented lane-preflight script and route manifest were unavailable in this checkout; this update stayed within the active goal candidate's existing evidence paths.

## Team Learning

For paired-repository evidence, keep an in-root byte-identical test snapshot when the reconciler enforces root containment, and separately preserve the true execution path and source hashes so the snapshot cannot be mistaken for a different run.

## Known Limitations

This is one focused Julia route-equivalence and input-validation receipt. It does not establish an independent likelihood oracle, R/TMB parity, profile or bootstrap refitting, interval calibration, or support for other NB2 targets, effects, providers, or distributions. The record remains unreviewed.

## Next Actions

Continue the full required-row implementation and output audit. Keep the Bernoulli uncertainty/calibration work on its source-bound decision chain; this receipt does not close G3, G4, G5, G6, G7, or G8.
