# After-task: Bernoulli correlated q2 SD check

## 1. Goal

Check the existing native correlated Bernoulli intercept-and-slope SD route and its adjacent q3 tests on the current candidate source.

## 2. Implemented

No production code changed. The focused correlated-SD test file completed successfully on the candidate. It exercises coefficient-specific SD targets in correlated q2 blocks, q2 point recovery and workflows, and an independent two-dimensional Gauss-Hermite likelihood comparison. Probit and complementary log-log fixtures also check q2 recovery direction and magnitude.

## 3a. Decisions and Rejected Alternatives

For the tested q2 block, the two latent coefficients have group-specific SDs and a constant correlation. The test's likelihood oracle integrates both standard-normal latent coordinates and applies the fitted correlation and SDs. The Bernoulli fits use the selected link and do not add a residual scale parameter.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-27-binomial-correlated-block-q2.md`
- `docs/dev-log/check-log.d/2026-10-27-binomial-correlated-block-q2.md`
- `docs/dev-log/evidence/general-sd-regression/binomial-correlated-block-q2-20261027/run.txt`
- `docs/dev-log/evidence/general-sd-regression/binomial-correlated-block-q2-20261027/source.sha256`

The test file and model sources were read and tested but not modified in this slice.

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-sd", reporter = "summary", stop_on_failure = TRUE)'` exited 0. The focused file completed without reported failures, warnings, or skips. The installed reporter emitted progress dots without a numeric assertion total. The run receipt and source hashes are under the evidence directory.

## 6. Tests of the Tests

The test file includes an independent Gauss-Hermite marginal-likelihood calculation for the q2 fit and explicit recovery checks for probit and complementary log-log links. It also checks fitted convergence and positive-definite Hessians in the named fixtures, prediction, simulation, refitting, save/reload, constant-SD equivalence, and covariance reconstruction. This confirms the tested paths execute on this candidate; the fixed-seed checks are not a broad recovery study.

## 8. Consistency Audit

The audited target is the existing `sd(group, dpar = "mu", coef = ...)` interface for the intercept and numeric slope in one correlated block. The independent oracle uses the same fitted link, group-specific SD vectors, and fitted correlation. No formula, likelihood, or public capability wording changed. The capability-ledger rows remain unresolved pending source-bound row reconciliation and independent review.

## 7a. Issue Ledger

No issue was changed. This was a focused candidate check, and no matching open implementation issue was established during this slice.

## 9. What Did Not Go Smoothly

An initial attempt to pass a test-description `filter` to `testthat::test_file()` stopped before fitting because this installed testthat version does not accept that argument. The package-level file filter then ran successfully. The progress reporter did not print a numeric expectation count.

## 11. Team Learning

Use the package-level file filter when the installed testthat version does not expose a description filter through `test_file()`. Keep the full transcript and report the reporter's actual output rather than infer assertion totals.

## 10. Known Residuals

This does not establish interval coverage, performance under weak information, reliable Wald uncertainty, non-logit same-data Julia parity for correlated q2, all q2/q3 layouts, or support across other families and providers. It does not close a required capability row by itself.

## 12. Cross-Product Coverage

Covers the native Bernoulli correlated q2 focused test file on the current candidate, including q2/q3 covariance checks, q2 recovery/workflows, a two-dimensional Gauss-Hermite oracle, and probit/cloglog q2 recovery. It does NOT cover interval coverage, general correlated-block support, same-data Julia parity for non-logit q2, or completion of the Bernoulli universe. Next action: reconcile this exact test receipt against the native correlated-q2 rows, then choose the next unclosed Bernoulli provider or block from the pinned universe. Coverage calibration remains deferred.
