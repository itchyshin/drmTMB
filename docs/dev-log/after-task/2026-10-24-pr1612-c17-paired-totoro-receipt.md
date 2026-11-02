# After Task: Refresh PR #1612 C17 Receipt

## Goal

Clear the generated-capability CI gate for the exact CMR PR source without weakening the model-15 compatibility tolerance.

## Implemented

Added a same-host paired Totoro receipt for the C17/C14 compatibility routes and pointed only those three manifest rows at the current PR source run. The unchanged source fingerprint remains `773fb87a16549d8fb8c18b9b77007c8c827cdb498f34900eafb5d7f0491fc58c`.

## Mathematical Contract

The receipt covers the existing model-15 ordinary sigma-intercept, zoi-intercept, and sigma-slope compatibility cells only. It does not test CMR recovery or intervals.

## Files Changed

- The three C17/C14 rows in `docs/dev-log/dashboard/capability-ledger/2026-08-08-c17c2-c14-final-source-compatibility.tsv`.
- `docs/dev-log/implementation-recovery/2026-10-24-pr1612-c17-same-host-paired/` with candidate and baseline run artifacts and paired comparison.
- This report and `docs/dev-log/check-log.d/2026-10-24-pr1612-c17-paired-totoro-receipt.md`.

## Checks Run

- Current candidate and recorded-source runs used the same Totoro host, runner, and single-thread BLAS/OpenMP settings. All 12 raw attempts match except the recorded source SHA; all three summary values match exactly.
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: passed, 3 eligible and 7 retained source-different receipts.
- `python3 -m unittest tools.tests.test_capability_ledger`: passed, 87 tests.
- A fresh full R package suite was not run in this receipt-only repair; the exact PR checks will determine package-suite status.

## Tests Of The Tests

The ledger test suite checks receipt structure and the strict compatibility guard. It passed against the copied immutable run files. The row-wise comparison independently checked every raw field other than `source_sha`.

## Consistency Audit

The C14 target and model-15 fingerprint were preserved. No tolerance was raised, no model claim was added, and no coverage claim was made. The older cross-host difference remains in history and is not used as the comparator for this paired check. The open PR #1563 also edits this manifest; its branch was left unchanged, and any later merge conflict must preserve both PRs' evidence.

## GitHub Issue Maintenance

No issue was opened or closed. PR #1612 remains the active integration vehicle. The online article is not yet confirmed because the PR has not merged and the main-branch documentation deployment has not completed.

## What Did Not Go Smoothly

The recertifier's original comparison used a Mac receipt and a Totoro run, producing a very small cross-host difference. Rather than relaxing its zero-tolerance rule, I reran the recorded source and candidate source on the same Totoro host; the paired results were exact.

## Team Learning

When a source-bound receipt crosses platforms, rerun both exact source revisions on one host before deciding whether a tiny difference is model behaviour or a platform effect. Retain the raw attempts for both runs.

## Known Limitations

This evidence covers three pre-existing model-15 routes. It does not establish whole-package correctness or any CMR recovery, interval availability, coverage, or calibration result. Coverage and calibration remain deferred to Phase B.

## Next Actions

Push this narrow receipt update to PR #1612, verify all checks at the new exact head, then merge only when checks and review are clean. Verify the pkgdown deployment and live article URL after merge. After the article is online, return to the broader drmTMB and DRModels.jl package backlog; do not infer CRAN submission or Julia registry release authority from this update.
