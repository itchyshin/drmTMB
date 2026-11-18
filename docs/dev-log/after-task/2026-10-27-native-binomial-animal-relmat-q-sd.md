# After Task: Native Binomial animal and relatedness Q precision

## 1. Goal

Check the native Binomial logit q1 animal A-covariance plus relmat Q-precision route against the mathematically equivalent relmat K-covariance input.

## 2. Implemented

A standalone fixed-seed test fits the same data using both K covariance and Q precision. It checks likelihood, SD coefficients, and group-named predictions. No model-builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The test is scoped to the exact animal A-covariance plus relmat Q-precision pair. Its result does not infer Q support for other links or animal input types.

## 3. Mathematical Contract

The relatedness precision is `Q = solve(K)`. The two fits use identical observations, fixed effects, latent field, SD predictors, and covariance scale. Their optimized likelihood, SD coefficients, and population-named predictions should agree within numerical tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-relmat-q-precision-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-q-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-relmat-q-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-q-precision-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and eight expectations. Both fits converged, and log likelihood, SD coefficients, and named predictions matched.

Evidence reconciliation passed with 19,678 candidate rows, 105 linked rows, 19,573 unlinked rows, and 127 evidence records. This focused test does not assess interval coverage.

## 6. Tests of the Tests

The test uses the same fixed-seed synthetic dataset in both fits, deliberately reverses matrix-label order relative to factor order, and compares outputs after matching predictions by population names.

## 7a. Issue Ledger

No matching open issue was identified or changed. The remaining family and provider combinations stay on the active capability ledger.

## 8. Consistency Audit

The Q input is constructed as the inverse of K and passed through the same relmat formula target. The test supports only native Binomial logit for this exact provider pair. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The two-fit equivalence test completed within the measured 45-to-90-second estimate without failed fits or assertions.

## 10. Known Residuals

The evidence establishes input equivalence for this logit route. Independent recovery, probit or cloglog Q precision, other animal inputs, interval coverage, and Julia parity remain unassessed.

## 11. Team Learning

An exact same-data K/Q comparison catches precision conversion and label-order errors without adding likelihood code.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit `mu`, q1 animal A-covariance plus relmat Q precision, compared with relmat K covariance. This does NOT cover non-logit Q inputs, alternative animal kernels, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the next unlinked Bernoulli provider-input rows and keep each evidence row tied to its exact kernel representation.
