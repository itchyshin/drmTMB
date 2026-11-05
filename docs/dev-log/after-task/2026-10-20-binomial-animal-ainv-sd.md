# After Task: Bernoulli Animal SD Regression With Ainv

## 1. Goal

Add a fixed-seed recovery check for predictor-dependent Bernoulli animal-intercept SDs supplied through an inverse relatedness matrix, and verify the neighboring animal tests.

## 2. Implemented

Added a synthetic `animal(1 | id, Ainv = Ainv)` test with `sd(id, level = "animal") ~ z`. It checks recovery of the log-SD slope, group-labelled predictions, simulation output, constant-SD equivalence, and correct reordering of a deliberately reversed precision matrix. The model route already fit successfully, so this slice adds test evidence rather than changing fitting code.

The neighboring `A` test had asserted that returned labels follow factor-level order. The public output is group-labelled, while structured inputs retain matrix-label order; no public contract promises vector order. The assertion now checks the complete set of labels. The new test additionally checks predicted values against the recovered SD formula by group name.

## 3a. Decisions and Rejected Alternatives

The slice tests the existing predictor-dependent SD route with an inverse relatedness input; it does not add a Bernoulli residual SD or normalize the kernel. The factor-order assertion was changed to a set comparison because no public contract promises that vector order follows factor levels.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-ainv-sd-regression.R` (new synthetic test)
- `tests/testthat/test-binomial-animal-sd-regression.R` (label-order assertion aligned with the group-label contract)

## 5. Checks Run

- `Rscript -e 'devtools::test(filter = "binomial-animal-.*sd-regression", reporter = "summary")'`: passed all three matching test files, including the new Ainv recovery case.
- `git diff --check -- tests/testthat/test-binomial-animal-sd-regression.R tests/testthat/test-binomial-animal-ainv-sd-regression.R`: passed.
- No package-wide test, documentation build, or cross-engine test was run; this was a focused test-only slice.

## 6. Tests of the Tests

The initial combined run exposed the overstrict factor-order assertion. The new fixture also asserts that factor order differs from matrix-label order and checks the resulting predictions by label. The recovery check uses an independently generated fixed-seed response and a declared tolerance around the known SD slope.

## 8. Consistency Audit

The test uses the existing animal selector and does not change formula grammar, likelihood code, public methods, or package support claims. `sdpars` labels and predicted values are checked by group identity; their incidental vector order is not treated as API. No status inventory or pkgdown navigation change is warranted for a test-only evidence addition.

## 7a. Issue Ledger

No issue was opened, changed, or closed. This test addition does not resolve the wider animal-provider parity or interval-calibration work.

## 9. What Did Not Go Smoothly

The first combined run failed because an older assertion conflated label identity with vector order. Replacing it with a set comparison resolved that mismatch without changing model code or weakening the new recovery checks.

## 11. Team Learning

For structured random effects, assert that labels identify the right groups and compare values after matching by label. Do not assume factor order and covariance-matrix order are interchangeable.

## 10. Known Residuals

This is one synthetic point-recovery check for Bernoulli animal intercepts with `Ainv`. It does not establish interval calibration, broad animal-model coverage, Julia parity, or support for other random-effect shapes.

## 12. Cross-Product Coverage

The test exercises the native R/TMB engine. It does NOT cover Julia parity, calibrated interval coverage, or wider animal-model support. Keep the broader SD-regression goal active, add this cell to the capability ledger during the next inventory reconciliation, and continue with an independently owned missing capability row.
