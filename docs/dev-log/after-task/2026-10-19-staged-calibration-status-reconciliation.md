# After Task: Staged Calibration Status Reconciliation

## 1. Goal

Align the staged-calibration contract's current status with the completed clean-current first-look record.

## 2. Implemented

The contract now says the integrated decision rule returned `look2_required`, while operational launch gates remain open. It marks the earlier instruction to rerun the first look as superseded by the completed clean-current 95% run. No model, threshold, or launch authority changed.

## 3a. Decisions and Rejected Alternatives

Keep the statistical continuation decision distinct from operational approval. Do not edit the historical result or imply that look two is cleared to launch.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/staged-calibration-contract.md`
- `docs/dev-log/check-log.md`
- This report.

## 5. Checks Run

- Cross-checked current status against `calibration-final-review.md` and `2026-10-19-bernoulli-sd-first-look-calibration.md`.
- The prose checker reported zero findings for this report.
- `git diff --check` passed.
- The required after-task section and negative-space check passed.
- Full package tests, site build, and acceptance-ledger scan were not run; this was an internal status-only documentation correction.

## 6. Tests of the Tests

No tests changed. The after-task structure check is run separately against the required section format.

## 7a. Issue Ledger

Queried open issues for “Bernoulli SD calibration”; no matches were returned. No issue action was needed because this internal status correction changes neither model behavior nor public support claims.

## 8. Consistency Audit

The contract separates the `look2_required` statistical decision from launch readiness and points readers to the current campaign report. Historical 97.5% fitted-profile statements remain labelled as superseded evidence.

## 9. What Did Not Go Smoothly

The opening contract status and one dated correction still instructed readers to rerun a first look that had since completed.

## 10. Known Residuals

The stage-two adapter, source/hash verification, runtime qualification, and execution approval remain open. The current calibration result remains unqualified.

## 11. Team Learning

When a staged rule requests a continuation, record the statistical decision and the separate operational launch gates together.

## 12. Cross-Product Coverage

This documentation correction does NOT cover implementation, uncertainty calibration, or engine parity beyond the single native Bernoulli first-look status. All family, effect, endpoint, provider, and Julia capability rows remain under the active programme inventory.
