# After Task: Native Binomial phylogenetic and relatedness links

## 1. Goal

Extend the existing native Binomial phylo-tree plus relmat q1 SD pair beyond logit to probit and complementary-log-log, while retaining the existing K/Q comparison.

## 2. Implemented

The synthetic test now fits logit, probit, and complementary-log-log responses. The logit case retains the K-covariance versus Q-precision equivalence checks. Probit and complementary-log-log are checked with relmat K covariance. No likelihood or builder code changed.

## 3a. Decisions and Rejected Alternatives

The non-logit additions use the already admitted pair and K covariance. This slice does not infer Q-precision support for probit or complementary-log-log from the logit comparison.

## 3. Mathematical Contract

For each link, the test simulates binary responses from a linear predictor with independent tree and population fields. Each field has its own log-SD regression with a group-constant binary predictor. The two providers retain their supplied covariance scaling. The K and Q inputs are compared only for the logit fit.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-relmat-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-relmat-links.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 24 expectations. The focused test covers convergence, SD-slope recovery bounds, target names, named predictions, logit K/Q likelihood and output equivalence, and the probit and cloglog K-covariance fits.

Evidence reconciliation passed with 19,678 candidate rows, 102 linked rows, 19,576 unlinked rows, and 124 evidence records. The exact test output and source hashes are retained with the receipt. Interval coverage was not run.

## 6. Tests of the Tests

The added probit and cloglog responses are generated from their respective inverse-link functions using the same synthetic latent fields. Each fit checks both SD slopes and the target-specific prediction names. The K/Q equivalence assertions remain attached to the logit fit and are not used to claim non-logit precision support.

## 7a. Issue Ledger

No matching open issue was identified or changed in this slice. The wider family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

The tested syntax matches the existing Binomial q1 phylo plus relmat route. The evidence receipt and ledger now distinguish logit K/Q from probit and cloglog K. The documentation audit lane was notified of this link-specific scope. No public support claim is added here.

## 9. What Did Not Go Smoothly

The test completed within the measured one-to-two-minute estimate. No fit or assertion failed.

## 10. Known Residuals

This is one-seed point-recovery evidence. It does not establish probit or cloglog Q-precision support, interval coverage, Julia parity, or support for other provider pairs and response families.

## 11. Team Learning

Using link-specific response generation lets one fixed latent covariance design check whether the same pair route behaves consistently across the three Binomial links.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial logit, probit, and cloglog `mu`, q1 phylo-tree plus relmat K-covariance intercepts, with logit-only K/Q equivalence. This does NOT cover non-logit Q precision, Julia fitting or bridge parity, or interval calibration.

## 13. Next Actions

Continue with the next unlinked Bernoulli provider-input rows. Keep documentation and Julia support maps coordinated with their lanes.
