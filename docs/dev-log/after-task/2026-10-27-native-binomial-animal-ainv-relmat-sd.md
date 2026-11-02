# After Task: Native Binomial animal A-inverse plus relatedness K

## 1. Goal

Check the native Binomial logit animal A-inverse plus relmat K-covariance q1 pair against the equivalent animal A-covariance representation.

## 2. Implemented

A fixed-seed test fits the same response using animal A covariance and A-inverse precision, while keeping the relmat K field fixed. It compares fitted likelihood and target outputs. No builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

This check covers the exact animal A-inverse plus relmat K input under logit. It does not infer alternate links or relatedness precision support.

## 3. Mathematical Contract

The animal precision is `Ainv = solve(A)`. Both models share the observations, fixed effects, animal and population groups, and SD predictors. Their likelihoods, SD coefficients, and named predictions should agree within optimizer tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-ainv-relmat-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-ainv-relmat-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-ainv-relmat-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-ainv-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and seven expectations. Both fits converged, and likelihood, SD coefficients, and named predictions matched.

Evidence reconciliation passed with 19,678 candidate rows, 112 linked rows, 19,566 unlinked rows, and 134 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The same simulated response is fit under both animal matrix representations. Matrix labels are reversed relative to factor order, and both provider outputs are compared after matching group names.

## 7a. Issue Ledger

No matching open issue was identified or changed. Remaining family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

This evidence records animal A-inverse precision with relmat K covariance under native Binomial logit. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The two-fit comparison completed within the estimated 45-to-90-second range without failed fits or assertions.

## 10. Known Residuals

This is input-equivalence evidence. Independent recovery, alternate links, relmat Q precision, interval coverage, and Julia parity remain unassessed for this exact route.

## 11. Team Learning

An explicit A/A-inverse comparison checks covariance conversion and label alignment in the combined-provider path.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit `mu`, q1 animal A-inverse plus relmat K covariance, compared with animal A covariance. This does NOT cover other links or kernels, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the next unlinked Bernoulli provider-input row and keep its exact covariance representation in the evidence receipt.
