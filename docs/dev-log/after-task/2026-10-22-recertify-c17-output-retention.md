# After Task: Preserve C17 recertification output

## Goal

Protect the committed C17 compatibility receipt and every new runner output when `tools/recertify-c17.py` fails or encounters an existing destination.

## Implemented

The tool now preserves partial runner output under a collision-safe `.failed-<label>` sibling when an exception interrupts the run. It preserves completed output under `.collision-<label>` when the dated destination already exists. Rejected outputs also receive a unique sibling path instead of being moved inside an older rejected directory.

## Mathematical Contract

No model, likelihood, parameterization, tolerance, or acceptance rule changed. The C17 runner still compares the same three `mean_tau_relative_error` values, with exact equality as the default tolerance.

## Files Changed

- `tools/recertify-c17.py`
- `tools/tests/test_recertify_c17.py`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-22-recertify-c17-output-retention.md`

## Checks Run

- `python3 -m unittest tools.tests.test_recertify_c17 -v`: 4 tests passed.
- The new partial-output and destination-collision tests failed against the original implementation because the outputs were deleted. They pass with the fix.
- `python3 tools/recertify-c17.py --label codex-safety-fix --dry-run`: the three values matched exactly (`0.000e+00` change); the prior receipt and manifest were left unchanged.
- `git diff --check`: passed.
- Runtime: Python 3.14.8 and R 4.6.0 on macOS ARM64. The exact-head GitHub CI for the updated commit has not run yet.
- No full package suite, `R CMD check`, or statistical coverage campaign was run.

## Tests Of The Tests

The partial-runner-output test writes a real partial file before raising an exception, then checks both retention of that file and restoration of the committed receipt. The destination-collision test verifies the existing dated receipt remains intact and the fresh result is preserved beside it. A rejected-output collision test verifies that the second output is a sibling rather than nested inside the first. These tests exercise the failure paths that previously removed or misfiled output.

## Consistency Audit

The tool continues to preserve the existing manifest, source fingerprint, and three-cell comparison contract. Dry-run deletes only the verified fresh output after exact reproduction; exception, collision, and tolerance-rejection paths preserve the fresh output. No user-facing model behavior, examples, vignettes, NEWS entry, capability inventory, or pkgdown navigation changed.

## GitHub Issue Maintenance

The existing PR addresses issue #1591. No issue comment or new issue was created. The PR is ready for review; current-head CI and review are still pending.

## What Did Not Go Smoothly

An initial command invoked the Python utility with `Rscript` and exited before running any fits. The command was corrected to `python3`; the subsequent dry-run completed successfully.

## Team Learning

Do not treat a hardcoded output folder as disposable merely because a run is temporary. Failure and collision paths must preserve the new result and the prior receipt independently.

## Known Limitations

The dry-run confirms deterministic reproduction on this Mac, not cross-platform package behavior or model recovery/interval calibration. Exact-head CI and independent review remain outstanding.

## Next Actions

Inspect exact-head CI, obtain the repository review, and merge only after all required checks pass.
