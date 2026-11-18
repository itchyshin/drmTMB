# After Task: Native Binomial phylogenetic and animal pedigree input

## 1. Goal

Check the native Binomial logit phylo-tree plus animal pedigree q1 pair against the equivalent animal A-covariance representation.

## 2. Implemented

A standalone fixed-seed test fits the same synthetic data using animal covariance A and the equivalent pedigree input, then compares likelihood and target-specific outputs. No builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The test is limited to the exact phylo-tree plus animal pedigree input under logit. It does not infer other pedigree or link support.

## 3. Mathematical Contract

The pedigree defines the additive relationship covariance used for the animal field. Both fits use the same tree, animal groups, observations, fixed effects, and SD predictors. Their fitted likelihood, log-SD coefficients, and animal-named predictions should agree within numerical tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-animal-pedigree-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-animal-pedigree-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-animal-pedigree-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-animal-pedigree-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and seven expectations. Both fits converged, and likelihood, SD coefficients, and animal-named predictions matched.

Evidence reconciliation passed with 19,678 candidate rows, 109 linked rows, 19,569 unlinked rows, and 131 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The same simulated response is used for the two provider inputs. The pedigree defines founder and full-sibling relationships, and matrix order differs from data factor order. Predictions are compared after matching by animal names.

## 7a. Issue Ledger

No matching open issue was identified or changed. The wider family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

The evidence is limited to native Binomial logit q1 phylo plus animal pedigree and its A-covariance comparison. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The two-fit comparison completed within the estimated 45-to-90-second range without failed fits or assertions.

## 10. Known Residuals

This is input-equivalence evidence. Independent recovery, interval coverage, Julia parity, other links, and other pedigree combinations remain unassessed.

## 11. Team Learning

Comparing a pedigree with its generated A matrix checks relationship interpretation and ordering within the multi-provider SD route.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit `mu`, q1 phylo-tree plus animal pedigree, compared with animal A covariance. This does NOT cover other links, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the next unlinked Bernoulli provider-input rows and maintain the kernel-specific evidence boundaries.
