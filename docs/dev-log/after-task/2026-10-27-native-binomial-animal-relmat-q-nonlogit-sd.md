# After Task: Native Binomial animal plus related-matrix Q under probit and cloglog

## 1. Goal

Check whether the native Binomial animal `A` plus related-matrix `Q` precision route matches its equivalent `K` covariance route under probit and cloglog links.

## 2. Implemented

Added a fixed-seed synthetic test with the same response and model in each `K`/`Q` comparison. Each model has separate SD regressions for the animal and related-matrix fields. No builder or likelihood code changed because both existing routes fit and agreed.

## 3a. Decisions and Rejected Alternatives

`Q` is computed as the inverse of the labelled `K` matrix. The test holds the animal term, data, and link fixed, then compares only the related-matrix input representation. No broader provider combinations were inferred from this result.

Assumptions made without asking: the existing `K` matrix is positive definite and the `Q` input follows the established precision convention. The same-data likelihood and output comparisons test this for the fixture; they do not establish equivalence for every kernel.

## 4. Files Touched

- `tests/testthat/test-binomial-animal-relmat-q-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-relmat-q-nonlogit-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-animal-relmat-q-nonlogit-sd.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-animal-relmat-q-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 16 expectations. Source hashes remained stable during the captured run. Evidence reconciliation passed with 19,678 candidate rows, 127 linked rows, 19,551 unlinked rows, and 149 evidence records. The after-task structure checker and prose check passed. The aggregate gate runner remains unavailable, so aggregate status is UNKNOWN.

## 6. Tests of the Tests

For each link, one synthetic response is fit with both `K` and `Q`. Both fits must converge, and likelihood, both SD coefficient vectors, and predictions aligned by animal and population names must agree. The test therefore catches an incorrect precision convention or label ordering for this pair.

## 7a. Issue Ledger

No package issue was opened or changed. Other Bernoulli structured pairs and all remaining response families and Julia routes remain outstanding.

## 8. Consistency Audit

The fixture reverses the order of matrix labels relative to factor levels and uses the same labelled data in both fits. The ledger contains two exact rows, one for each tested link and the Q-precision input. No broader support claim was added.

## 9. What Did Not Go Smoothly

Nothing blocked the focused run. The second captured run finished in about 1 minute 15 seconds.

## 10. Known Residuals

This is focused input-equivalence and fit/output evidence. It does not establish calibrated uncertainty, parameter-recovery performance, Julia parity, or any other covariance pair, link, family, endpoint, or effect shape.

## 11. Team Learning

For precision-matrix routes, same-data covariance-versus-precision checks should compare both likelihood and label-aligned SD predictions, not only convergence.

## 12. Cross-Product Coverage

The evidence covers native R/TMB Binomial probit and cloglog `mu`, animal `A_covariance` plus related-matrix `Q_precision`, compared with equivalent `K_covariance`. It does NOT cover Julia fitting or bridge parity, interval coverage, other families, or other structured combinations. No Golden Set run was needed because no known-mistake class was changed.
