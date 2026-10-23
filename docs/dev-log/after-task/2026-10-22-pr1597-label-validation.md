# After Task: Validate C17 recertification labels

## 1. Goal

Prevent an invalid `--label` from interrupting C17 recertification after the committed receipt has been moved.

## 2. Implemented

`tools/recertify-c17.py` now accepts only labels matching `[A-Za-z0-9][A-Za-z0-9._-]{0,63}`. The check runs immediately after argument parsing, before manifest reads, output moves, or runner execution. A regression covers slash traversal and whitespace labels and verifies the receipt and manifest remain unchanged.

## 3a. Decisions and Rejected Alternatives

The allowed label characters are ASCII letters, digits, period, underscore, and hyphen; labels must start with a letter or digit and may contain at most 64 characters. This prevents path separators and whitespace from entering generated directory names without broadening the CLI surface.

## 4. Files Touched

- `tools/recertify-c17.py`
- `tools/tests/test_recertify_c17.py`
- `docs/dev-log/check-log.d/2026-10-22-pr1597-label-validation.md`
- `docs/dev-log/after-task/2026-10-22-pr1597-label-validation.md`

## 5. Checks Run

- `python3 -m unittest tools.tests.test_recertify_c17`: 5 tests passed.
- `git diff --check`: passed.
- The repository's `check-after-task.R` section/negative-space check is run before closeout.
- No R recertification run or package test suite was run; this change validates input before any fit or receipt movement.

## 6. Tests of the Tests

Before the validation was added, the new test failed for the expected reasons: `../escape` triggered `ValueError` while naming failure output, and `bad label` allowed the runner path to displace the committed receipt. After the fix, both inputs return status 2, the runner is not called, the manifest and receipt bytes remain unchanged, and no `.pre-recertify` directory appears.

## 7a. Issue Ledger

No issue comments or state changes were made. The work remains within PR #1597 and its existing issue scope.

## 8. Consistency Audit

The guard is limited to the documented short-slug argument and does not alter fit results, tolerances, or receipt contents. The regression exercises the vulnerable path and preserves the prior receipt. `NEWS.md` was not edited: its file-scoped lane preflight found 177 refs with parallel NEWS changes. A release-note entry remains deferred until a coordinated NEWS edit can safely reconcile those changes. No examples, model docs, capability inventory, or pkgdown navigation changed.

## 9. What Did Not Go Smoothly

The initial report headings did not match the repository's automated after-task checker and were corrected before closeout. The shared NEWS file also has many parallel branch edits, so it was left untouched to avoid a broad conflict in this focused fix.

## 10. Known Residuals

The label guard is tested locally, but no full package suite or exact-head CI has run for this patch. The NEWS release note remains deferred.

## 11. Team Learning

Validate path-derived labels before moving any protected output, and test invalid values against both filesystem state and runner invocation.

## 12. Cross-Product Coverage

This change covers input validation and output preservation in the Python C17 recertification utility only. It does NOT cover R package behavior, model fitting, statistical recovery, interval calibration, or other tools that construct paths from labels.
