# After Task: Native Binomial iid plus related-matrix SD regression

## 1. Goal

Add the smallest useful native Bernoulli slice beyond a single random-effect provider: one ordinary iid intercept and one related-matrix intercept, each with its own predictor-dependent SD, under probit and complementary log-log links.

## 2. Implemented

The Binomial validator now admits this bounded combination when responses are complete, the ordinary term is one intercept, the related-matrix term is one unlabelled intercept, and each side has at most one matching SD formula. The likelihood already had separate ordinary and structured contributions, so no C++ likelihood edit was needed. A deterministic synthetic K/Q test checks both SD-slope directions and broad fixed-seed recovery bounds, convergence, matched likelihoods, coefficients, and named predictions.

## 3a. Decisions and Rejected Alternatives

Kept the change in family-specific validation instead of relaxing the generic structured-effect guard. Preserved the supplied covariance scale and matrix-label alignment. Coverage calibration remains deferred under the approved implementation-first goal.

## 4. Files Touched

- `R/drmTMB.R`
- `tests/testthat/test-binomial-iid-relmat-kernel-equivalence-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-iid-relmat-kernel-nonlogit-20261027/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- This after-task report and the paired check log.

## 5. Checks Run

- Focused `devtools::test()` run: 21 expectations passed for probit and cloglog; exit 0.
- Evidence reconciliation passed: 19,678 candidate rows, 143 linked rows, 19,535 unlinked rows, and 165 records.
- Source hashes and the focused test transcript are retained in the evidence folder.
- No full suite, full pkgdown build, live Julia test, or interval-coverage campaign was run.

## 6. Tests of the Tests

The test generates independent iid group effects and a correlated population field from the supplied covariance. The same response is fitted with equivalent covariance `K` and precision `Q` inputs. Assertions would detect a rejected formula, failed optimization, wrong SD slope direction or broad recovery, changed likelihood/coefficients, and misaligned named predictions.

## 7a. Issue Ledger

No GitHub issue was changed. The candidate-row evidence ledger now links the four tested combinations: two links crossed with K and Q inputs. All records remain unreviewed.

## 8. Consistency Audit

The R validator's added allowance is limited to one iid intercept plus one related-matrix intercept and preserves existing structured-only checks. The TMB objective already applies both latent contributions independently. The result supports this exact native point-recovery slice only; it does not establish package-wide admission.

## 9. What Did Not Go Smoothly

The first test wrapper used `testthat::test_file()` without loading the package and failed because `bf()` was unavailable. The corrected `devtools::test()` run reproduced the intended validator rejection. After the narrow admission change, the four fits passed. Shared lane-preflight and lease registry operations were unusually slow while many lanes were active; the scoped lease was acquired before source editing.

## 10. Known Residuals

This is one synthetic design with two non-logit links, not a recovery grid or calibrated-uncertainty result. It does not cover logit in this exact combined-provider test, multiple ordinary terms, structured slopes, labelled blocks, other structured providers, missing responses, Julia parity, simulation/extraction workflows, or other families. The broader SD goal remains active.

## 11. Team Learning

A family-specific validator can block a combination even when the likelihood already contains both additive latent contributions. Reproduce through the package test runner before interpreting a harness-level failure, and keep the new admission narrower than the mathematical likelihood capability.

## 12. Cross-Product Coverage

- Family: Bernoulli/Binomial.
- Engine: native R/TMB.
- Endpoint: `mu`.
- Links: probit and complementary log-log.
- Effects: one independent iid intercept and one related-matrix intercept, each with its own SD regression.
- Covariance input: equivalent K covariance and Q precision forms.
- Data: synthetic, fixed seed.
- This slice does NOT cover Julia, other families, other effect types, coverage calibration, or general provider-pair support.
