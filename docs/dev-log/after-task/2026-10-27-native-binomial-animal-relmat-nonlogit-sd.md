# After Task: Native Binomial animal and relatedness non-logit SD pair

## 1. Goal

Add direct recovery/output checks for the animal A-covariance plus relmat K-covariance Binomial q1 pair under probit and complementary-log-log links.

## 2. Implemented

A new independent test fixture simulates and fits both links with separate SD formulas for the two provider groups. No shared builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The test uses the already admitted q1 pair and the covariance inputs named in the capability rows. This evidence does not extend to A-inverse, pedigree, or relmat Q precision inputs.

## 3. Mathematical Contract

The linear predictor contains independent animal and population fields, each scaled by its own predictor-dependent SD. Binary responses are generated from the same latent fields under each link's inverse-link function. The group-level predictors are constant within their respective latent groups.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-relmat-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-nonlogit-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-relmat-nonlogit-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 14 expectations. Both links check convergence, recovery bounds for both SD slopes, target coefficient names, and group-named predictions.

Evidence reconciliation passed with 19,678 candidate rows, 104 linked rows, 19,574 unlinked rows, and 126 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The fixed-seed fixture generates distinct binary responses with the probit and cloglog inverse links and checks both providers independently. It also reverses matrix-label order relative to factor levels to exercise named alignment.

## 7a. Issue Ledger

No matching open issue was identified or changed. The broader family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

The two formulas target animal and relmat separately. The recorded evidence is limited to the exact A-covariance and K-covariance inputs and the two tested links. The documentation and Julia parity lanes were notified. No public documentation claim is added here.

## 9. What Did Not Go Smoothly

The focused run completed within the estimated 45-to-90-second range and had no failed fits or assertions.

## 10. Known Residuals

This is one-seed point-recovery/output evidence. It does not establish Q-precision, A-inverse, or pedigree variants, logit for this exact provider input, interval coverage, Julia parity, or other response families.

## 11. Team Learning

A separate compact fixture lets us add link-specific evidence without editing the older shared structured-pair test file.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial probit and cloglog `mu`, q1 animal A-covariance plus relmat K-covariance intercepts. This does NOT cover alternate covariance inputs, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the next unlinked Bernoulli provider-input rows. Keep evidence tied to exact link and covariance-input combinations.
