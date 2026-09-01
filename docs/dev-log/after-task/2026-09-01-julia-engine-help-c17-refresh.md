# C17 receipt refresh after Julia-engine help correction

## 1. Goal
Refresh the source-stamped C17 model-15 receipt required after an exported-help-only change to `R/drmTMB.R`.

## 2. Implemented
Ran the prescribed 12-fit compatibility runner under a new retained run ID, rewired the C17 final-source manifest to that artifact set, and appended a boundary note explaining the Julia-engine help change is outside the authenticated model-15 anchors.

## 3. Decisions and rejected alternatives
The whole-file pin remains intact. The source fingerprint was not broadened or changed because its authenticated anchors did not move. No model-15 cell was promoted and no tolerance was relaxed.

## 4. Files touched
The C17 current-source manifest, one new implementation-recovery artifact directory, and this report/check-log entry; the earlier help-source and generated-help files remain the user-facing change.

## 5. Checks run
The runner produced 4/4 passes for each of mc-0568, mc-0569, and mc-0576. Their `mean_tau_relative_error` values exactly matched the prior receipt. `python3 tools/capability_ledger.py --check`, 80 capability-ledger unit tests, and `git diff --check` passed.

## 6. Tests of the checks
The ledger tests exercise both fingerprint and pinned-file failure modes. The refresh preserved the immutable historical C14 receipts and revalidated the narrow C17 bridge.

## 7. Issue ledger
This clears the help PR's receipt-staleness failure only. It does not close a Julia bridge, profile, bootstrap, control-surface, or inference-calibration issue.

## 8. Consistency audit
The runner records five whole-file blobs, including the changed `R/drmTMB.R`, and verifies current behavior before rewiring. The source fingerprint remains `8603b3...`, showing the relevant model-15 symbols did not change.

## 9. What did not go smoothly
The generic recertification wrapper cannot choose a new run ID because its historical default output directory already exists. The prescribed runner accepts `C17_COMPAT_RUN_ID`, so it was run directly under a unique date-stamped path; the wrapper's no-drift checks were reproduced explicitly.

## 10. Known residuals
The Julia-engine help PR still needs a new full R-CMD-check after this receipt refresh. This evidence says nothing about model classes outside the three retained zero-one-beta compatibility cells.

## 11. Team learning
A documentation edit can correctly trip a whole-file evidence guard. Re-running its small authenticated compatibility receipt is safer than weakening the guard or treating CI red as unrelated.
