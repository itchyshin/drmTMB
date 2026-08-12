# After Task: G5 artifact and profile-method guards

## Goal

Close the handover follow-ups #1007, #1008, and #967 without widening the authenticated G5 evidence boundary.

## Implemented

G5 reconciliation artifacts now retain their complete pre-selection registry and reject a cohort that silently drops cells from a selected route. G4 execution now stops if a frozen target's `profile_ready` or `interval_method` disagrees with the fitted `profile_targets()` registry. The missing-response ledger keys the authenticated `cumulative_logit` G5 result to `fixef:mu:x` only; ordinal cutpoints remain explicitly outside the claim.

## Mathematical Contract

No likelihood, estimator, formula grammar, or interval algorithm changed. The new checks preserve the predeclared target and attempted-cell denominator before a profile or Wald result can be recorded.

## Files Changed

`inst/sim/R/sim_missing_response_g4g5.R`, both G5 reconciliation tools, the G4/G5 foundation tests, and the capability-ledger source plus generated reader surfaces.

## Checks Run

- `python3 tools/capability_ledger.py --check`: PASS (31 generated outputs).
- `TMPDIR=/tmp python3 -m unittest tools/tests/test_capability_ledger.py`: PASS (67 tests).
- Loaded-package guard smoke: PASS for accepted profile targets, profile-method drift rejection, and same-route dropped-cell rejection.
- Earlier dependency integration receipts: #1004, #1005, and #1016 each had a local `--as-cran` result of 0 errors, 0 warnings, and one new-submission NOTE before their ordered merges.

## Tests Of The Tests

The new tests flip `interval_method`, flip `profile_ready`, remove a current target, and remove a same-route expected G5 cell; each must fail closed.

## Consistency Audit

Generated ledger outputs were regenerated and checked. The rendered missing-response table labels the `cumulative_logit` entry as `fixef:mu:x` only and says that cutpoint targets remain excluded. The historical all-dpars route rows are not reinterpreted as cutpoint evidence.

## GitHub Issue Maintenance

No issue was closed or duplicated. This branch is the implementation follow-up for #1007, #1008, and #967; it remains unmerged pending the final focused package receipt and PR CI.

## What Did Not Go Smoothly

Rose found a future-date ledger entry and reader-facing wording that incorrectly suggested no cumulative-logit G5 result existed. Both were corrected before regeneration. Direct `test_file()` lacks the loaded package namespace, so the guard smoke used `devtools::load_all()`.

## Team Learning

An artifact's post-filter registry cannot establish its original denominator. Retain the expected registry and check route-complete selection at reconciliation time; freeze interval declarations, then compare them again with the fitted runtime registry.

## Known Limitations

This work does not create ordinal-cutpoint intervals, extend G5 to all cumulative-logit parameters, rerun a campaign, change CRAN status, or re-freeze a release.

## Next Actions

Run the final focused package receipt, commit this narrow guard/ledger slice, open its follow-up PR, and merge only after its CI is green.
