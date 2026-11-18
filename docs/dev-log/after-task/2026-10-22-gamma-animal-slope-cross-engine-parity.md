# After Task: Gamma Animal Slope-Only Cross-Engine Parity

## 1. Goal

Verify the existing synthetic Gamma animal slope-only SD model through native TMB and Julia on the same data, and bind the result to the candidate source.

## 2. Implemented

No model code changed in this slice. The focused live R-to-Julia test passed after the bridge label repair. The test covers one `animal(0 + x | id, A = A)` model with a group-level SD predictor and unit-diagonal supplied covariance.

## 3a. Decisions and Rejected Alternatives

The result is recorded as one slope-only parity fixture. The broader capability row describes a structured intercept plus slope, so it remains open. The run does not establish additional animal block shapes, likelihood agreement, uncertainty agreement, or general engine parity.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/inventory.md` now records this one slope-only parity fixture and its limits.
- `docs/dev-log/check-log.d/2026-10-22-gamma-animal-slope-cross-engine-parity.md` records the command, result, source hashes, and candidate commits.
- `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261022/source-manifest-animal-slope.json` binds 198 native/Julia source files and the saved console log to the candidate commits.
- This report records the audit and remaining boundaries.

## 5. Checks Run

- Focused live test `live Julia Gamma animal slope SD estimates agree with native TMB`: passed, one live test.
- Direct whitespace checks on both new reports found no trailing whitespace or blank lines at end of file. Repository-wide `git diff --check` reported pre-existing blank lines at EOF in `docs/dev-log/check-log.md` and `tests/testthat/test-binomial-sd-integration.R`; neither file was changed in this slice.
- Source binding: exact SHA-256 values are in the check log; native commit `425bee81572c625a634b2b083050c5c57c1dc1f1`, Julia commit `70dbf564eb670144c63c08f61ea099084d95add2`.
- The report passes the prose slop check with 0 findings. The after-task structure check passed; it also warned that the acceptance ledger is present but not runnable in this checkout, so its overall gate state is unknown.

## 6. Tests of the Tests

The test checks convergence, coefficient names, positive SD slopes, cross-engine coefficient agreement, cross-engine group SD predictions, and Julia rowwise SD predictions against the fitted group SD values. It ran through the live Julia bridge rather than the skip path.

## 7a. Issue Ledger

No GitHub issue was changed. `gh issue list --search 'Gamma animal slope SD'` could not connect to `api.github.com`, so issue overlap could not be checked from this environment.

## 8. Consistency Audit

The Gamma inventory now distinguishes the tested slope-only comparison from the broader structured intercept-plus-slope capability row. No required row or programme gate was promoted. The full family/formula status inventory was not re-audited in this focused parity slice.

## 9. What Did Not Go Smoothly

The first attempted run was interrupted during Julia precompilation after an ownership audit raised concern about the paired checkout. That interrupted attempt is not counted as a test result. The subsequent run completed successfully. The lane lease registry is outside this checkout's writable roots, so the lease tool could not persist a new lease; lane preflight showed one unrelated active documentation lease and no foreign lane in the recent census.

## 10. Known Residuals

This evidence covers one unit-diagonal supplied-covariance Gamma animal slope-only fixture. It does not establish non-unit covariance scaling, intercept-plus-slope support, A-inverse or pedigree parity, cross-engine uncertainty agreement, or calibrated intervals. Both candidate worktrees contain unrelated uncommitted changes.

## 11. Team Learning

Before running cross-engine tests against a dirty paired checkout, bind the actual source hashes and verify that the result covers the same shape as the capability row. A passing slope-only fixture cannot promote an intercept-plus-slope row.

## 12. Cross-Product Coverage

The exercised cross-product is Gamma location, animal slope only, supplied unit-diagonal covariance, one group-level SD predictor, native R/TMB and Julia. This evidence does NOT cover other families, endpoints, providers, block shapes, bivariate routes, covariance scaling or uncertainty procedures.
