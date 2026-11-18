# After Task: Bernoulli phylogeny and relatedness recovery assertions

## 1. Goal

Make the fixed-seed Binomial phylogenetic and relatedness-matrix SD recovery test reject near-zero or wrong-sign slope estimates.

## 2. Implemented

Tightened the logit, probit, and cloglog recovery assertions in `tests/testthat/test-binomial-phylo-relmat-sd.R`. The test now requires both SD slopes to be positive and larger than 0.2, with narrower absolute-error bounds around their generating values. The covariance and precision variants remain compared on the same data.

## 3a. Decisions and Rejected Alternatives

No likelihood change was needed. An earlier source review described the Binomial q1 phylogenetic scale as absent from the likelihood; exact-current-source review showed the model_type 18 path applies the predictor-dependent group SD to the latent field and reports it. The prior scale is fixed to one for this fitted SD-formula route. We kept the implementation unchanged and repaired the actual test weakness instead.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-relmat-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-sd-20261027/` and `direct-sd-evidence.tsv` with its generated summary
- This after-task report, its assessment record, the check log, the detail shard, and the SD-lane checkpoint

## 5. Checks Run

`devtools::test(filter = "binomial-phylo-relmat-sd", reporter = "summary", stop_on_failure = TRUE)` exited successfully on the local macOS R installation. It exercised the fixed-seed logit, probit, and cloglog fixtures, including covariance and precision representations. The test checks point recovery; it does not evaluate interval calibration or coverage.

## 6. Tests of the Tests

The stricter bounds passed on the existing independent synthetic DGP. Evidence reconciliation passed with 20,350 candidate rows, 195 linked, 20,155 unlinked, and 218 records. The four affected direct-evidence rows remain unreviewed. The DGP uses separate phylogenetic and relatedness fields whose log SDs vary with distinct group-level predictors, and the test compares covariance and precision representations.

## 7a. Issue Ledger

No issue was created or changed. The stricter assertions guard against near-zero and wrong-sign point estimates for both generating SD slopes.

## 8. Consistency Audit

The test covers one univariate Binomial model with separate phylogenetic and relmat intercept SD regressions, using logit, probit, and cloglog. It does not establish general provider support, cross-engine parity, or calibrated uncertainty. No support status was changed.

## 9. What Did Not Go Smoothly

A stale likelihood review initially sent investigation toward a missing scale multiplier. Checking the exact current source resolved that discrepancy before any likelihood edits.

## 10. Known Residuals

The test is a single fixed-seed recovery fixture. Its tolerances are regression checks and do not estimate repeated-sampling bias or interval coverage. Broader Bernoulli capability and cross-engine rows remain open.

## 11. Team Learning

For shared likelihood paths, bind source-review claims to the exact current candidate and verify parameter maps as well as the C++ branch before changing the likelihood.

Memory receipt: `MEMORY.md:2-5` and `MEMORY.md:55-56`; I kept the test evidence narrow and distinguished recovery from coverage. Golden Set: not run; no matching registered case applied. Prose assessment: `docs/dev-log/after-task/2026-10-29-binomial-phylo-relmat-recovery-assertions.md.assessment.json`.

## 12. Cross-Product Coverage

Covers native R/TMB fixed-seed Binomial phylogenetic plus relmat SD point recovery under logit, probit, and cloglog, including covariance/precision agreement.

Does not cover Julia parity, interval calibration, coverage, other providers, or package release readiness.
