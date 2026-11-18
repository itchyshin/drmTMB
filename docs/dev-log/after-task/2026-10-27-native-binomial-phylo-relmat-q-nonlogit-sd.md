# After Task: Native Binomial phylogenetic and relatedness non-logit Q inputs

## 1. Goal

Check whether the non-logit phylo-tree plus relmat pair retains K/Q equivalence under probit and complementary-log-log links.

## 2. Implemented

A fixed-seed test fits each link with relmat K covariance and Q precision on identical observations, then compares likelihoods, SD coefficients, and named predictions. No builder or likelihood code changed.

## 3a. Decisions and Rejected Alternatives

The scope is the exact phylo-tree plus relmat Q-precision pair under probit and cloglog. The test does not add other covariance inputs or response links.

## 3. Mathematical Contract

The precision matrix is `Q = solve(K)`. Both fits share the tree, latent groups, fixed effects, simulated responses, and SD predictors. The K and Q forms should yield equivalent fitted likelihood and outputs up to optimization tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-relmat-q-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-phylo-relmat-q-nonlogit-sd-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-phylo-relmat-q-nonlogit-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-relmat-q-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 14 expectations. Both links had converged K and Q fits; likelihoods, SD coefficients, and population-named predictions matched.

Evidence reconciliation passed with 19,678 candidate rows, 107 linked rows, 19,571 unlinked rows, and 129 evidence records. Interval coverage was not run.

## 6. Tests of the Tests

The test generates one response per link using that link's inverse function, fits both covariance representations to that same response, and compares outputs after aligning by population names.

## 7a. Issue Ledger

No matching open issue was identified or changed. The broader family and provider obligations remain in the active general SD ledger.

## 8. Consistency Audit

The candidate rows distinguish K covariance from Q precision. The new records cover only Q precision for probit and cloglog, while the prior evidence covers logit K/Q and non-logit K. Documentation and Julia lanes have been notified. No public support claim is added here.

## 9. What Did Not Go Smoothly

The four-fit focused test completed within the estimated one-to-two-minute range without failed fits or assertions.

## 10. Known Residuals

This is input-equivalence evidence. It does not establish interval coverage, Julia parity, or other family and provider combinations.

## 11. Team Learning

Repeating the exact same-data K/Q comparison under each link distinguishes link admission from covariance-input equivalence.

## 12. Cross-Product Coverage

The tested scope is native R/TMB Binomial probit and cloglog `mu`, q1 phylo-tree plus relmat Q precision compared with K covariance. This does NOT cover Julia fitting or bridge parity, interval calibration, or other provider-input types.

## 13. Next Actions

Continue the next unlinked Bernoulli provider-input rows while preserving link- and kernel-specific evidence boundaries.
