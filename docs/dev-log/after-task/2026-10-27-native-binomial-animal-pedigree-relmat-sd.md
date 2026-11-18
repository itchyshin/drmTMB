# After Task: Native Binomial animal pedigree plus relatedness K

## 1. Goal

Check the native Binomial logit animal pedigree plus relmat K-covariance q1 pair against an A matrix generated from that pedigree.

## 2. Implemented

A fixed-seed test fits the same data with animal pedigree and animal A inputs, keeping the relmat K field fixed. It compares likelihood and target-specific outputs. No builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The check covers animal pedigree plus relmat K under logit. It does not infer other links or precision-input combinations.

## 3. Mathematical Contract

The relationship matrix A is derived from the pedigree. Both fits share responses, animal and population groups, fixed effects, and SD predictors. Their likelihoods, SD coefficients, and named predictions should agree within optimizer tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-pedigree-relmat-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-pedigree-relmat-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-pedigree-relmat-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-pedigree-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and seven expectations. Both fits converged, and likelihood, SD coefficients, and named predictions matched.

Evidence reconciliation passed with 19,678 candidate rows, 113 linked rows, 19,565 unlinked rows, and 135 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The same simulated response is used under both animal representations. The test reverses matrix order relative to factor order and compares predictions after aligning by names.

## 7a. Issue Ledger

No matching open issue was identified or changed. Remaining family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

The evidence is specific to native Binomial logit q1 animal pedigree plus relmat K covariance. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The two-fit comparison completed within the estimated 45-to-90-second range without failed fits or assertions.

## 10. Known Residuals

This is input-equivalence evidence. Independent recovery, other pedigree-provider combinations, interval coverage, and Julia parity remain unassessed for this route.

## 11. Team Learning

Pair-level equivalence checks should include the original structured provider and the second provider, since single-provider equivalence does not establish combined-input behavior.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit `mu`, q1 animal pedigree plus relmat K covariance, compared with the pedigree-derived A matrix. This does NOT cover alternate links, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the remaining native Bernoulli provider-input obligations and maintain exact link/kernel scope in each receipt.
