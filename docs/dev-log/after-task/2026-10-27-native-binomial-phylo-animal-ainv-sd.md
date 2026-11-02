# After Task: Native Binomial phylogenetic and animal A-inverse input

## 1. Goal

Check the native Binomial logit phylo-tree plus animal A-inverse q1 pair against the equivalent animal A-covariance representation.

## 2. Implemented

A standalone fixed-seed test fits the same synthetic data with A covariance and A-inverse precision, then compares likelihood and target-specific outputs. No builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The test is limited to the exact phylo-tree plus animal A-inverse precision input under logit. It does not infer other animal input or link support.

## 3. Mathematical Contract

The precision matrix is `Ainv = solve(A)`. Both models use the same animal field, tree field, fixed effects, and SD predictors. Their fitted likelihood, log-SD coefficients, and animal-named predictions should agree within numerical tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-animal-ainv-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-animal-ainv-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-animal-ainv-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-ainv-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and seven expectations. Both fits converged, and likelihood, SD coefficients, and animal-named predictions matched.

Evidence reconciliation passed with 19,678 candidate rows, 108 linked rows, 19,570 unlinked rows, and 130 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The same fixed-seed response is used for both covariance representations. Matrix labels are reversed relative to animal factor levels, and predictions are compared after matching by animal names.

## 7a. Issue Ledger

No matching open issue was identified or changed. Remaining family and provider obligations are in the active general SD ledger.

## 8. Consistency Audit

The evidence is limited to native Binomial logit q1 phylo plus animal A-inverse precision and its A-covariance comparison. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The two-fit comparison completed within the estimated 45-to-90-second range without failed fits or assertions.

## 10. Known Residuals

This is input-equivalence evidence. It does not establish independent recovery, interval coverage, Julia parity, or other links and animal inputs.

## 11. Team Learning

Using identical simulated data keeps the covariance-representation comparison focused on input scaling and group-name alignment.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit `mu`, q1 phylo-tree plus animal A-inverse precision, compared with animal A covariance. This does NOT cover other links or animal kernels, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the remaining unlinked Bernoulli provider-input rows and preserve the exact kernel representation in each evidence record.
