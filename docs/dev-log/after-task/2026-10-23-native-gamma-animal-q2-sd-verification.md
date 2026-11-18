# After Task: Verify Native Gamma Animal Intercept-and-Slope SD Regression

## 1. Goal

Verify the exact native candidate test for Gamma animal intercept and independent-slope SD regressions, including the separate SD predictors and public outputs.

## 2. Implemented

No model code changed in this verification slice. The existing candidate test passed all 37 assertions after rerunning with an isolated temporary directory.

## 3a. Decisions and Rejected Alternatives

For `animal(1 + x | id)`, the intercept and numeric slope are independent latent Gaussian fields sharing the animal relationship kernel. Their log SDs have separate fixed-effect designs, `log(tau0) = z0 * alpha0` and `log(tau1) = z1 * alpha1`; the slope field enters the predictor multiplied by `x`. This test uses pedigree input and does not establish Julia's unit-diagonal covariance convention as parity with native TMB's supplied kernel scale.

No alternative implementation was selected because this slice verifies existing behavior and changes no model code. Coverage calibration remains required by the full goal; this test does not replace it.

## 4. Files Touched

Only evidence files were added or updated: this report, the source-hashed check receipt, the lane checkpoint, and `docs/dev-log/check-log.md`. Model code and tests were not edited.

## 5. Checks Run

- `TMPDIR=/tmp/codex-gamma-q2-test Rscript -e "devtools::test(filter = 'gamma-animal-pedigree-sd-regression')"`: 37 passed, 0 failures, 0 warnings, 0 skips in 28.4 seconds.
- The first identical test run with the default temporary directory passed all assertions but produced five testthat temporary-directory warnings. The isolated-temp repeat was clean.
- The Julia after-task report records a source-archive run of 35/35 assertions. Its current `src/gamma.jl` and test hashes exactly match that receipt. This report treats that as paired candidate evidence, not a live R-to-Julia parity check.
- The native candidate was 6 commits ahead and 245 behind the local `origin/main` at test time; this result is candidate-only.

## 6. Tests of the Tests

The synthetic test checks signed recovery for both SD slopes, group-keyed predictions, seeded simulation, save/reload preservation, constant-SD likelihood equivalence, ambiguous and duplicated target rejection, an all-zero slope loading, and the specified confounded design. These checks exercise both positive behavior and failure paths. No pre-implementation red run is claimed.

## 8. Consistency Audit

The formula grammar already documents this native Gamma animal q2 boundary in `docs/design/01-formula-grammar.md`. The test's selectors and independent-field interpretation match the current documentation. The prior check-log note that the combined q2 test was absent remains historically accurate for its execution date; this report records the later verification. No status inventory, NEWS, or pkgdown edits were needed because this verification changed no model behavior or advertised support.

## 7a. Issue Ledger

No issue action was taken. The scoped issue search returned only general test-sweep tracker issues, not a Gamma animal q2 feature issue.

## 9. What Did Not Go Smoothly

The default R temporary location caused five reporter warnings despite all tests passing. Setting `TMPDIR` to a task-specific directory removed those warnings; no source or expectation change was needed.

## 10. Known Residuals

This receipt does not establish Julia parity for non-unit-diagonal animal kernels, interval coverage, all-provider or all-family support, package-wide checks, or current-main integration. The programme ledger remains at 1 of 9 formal gates met.

## 11. Team Learning

When testthat reports failures to create local reporter directories after successful assertions, rerun once with a fresh task-specific `TMPDIR` before attributing the warnings to model code.

## 12. Cross-Product Coverage

This task covers only native TMB Gamma `mu`, pedigree animal q2 with separate intercept and independent-slope SD predictors, plus its tested prediction, simulation, and save/reload paths. It does NOT cover same-data R-to-Julia parity, Julia's covariance-scale convention, other providers or response families, calibrated uncertainty, package-wide checks, or current-main integration. The next action is to use the required-row map to select a genuinely missing cross-engine cell; retain this result as candidate-tested evidence without promoting broad support or closing a programme gate.
