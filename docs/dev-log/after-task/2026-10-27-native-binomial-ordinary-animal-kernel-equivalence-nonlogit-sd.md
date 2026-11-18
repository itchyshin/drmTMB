# After Task: Native Binomial ordinary and animal SD non-logit equivalence

## 1. Goal

Record native R/TMB Binomial probit and cloglog evidence for equivalent animal relationship inputs in ordinary-plus-animal SD regression.

## 2. Implemented

Added a fixed-seed test that fits each link on one synthetic response under three animal inputs: additive relationship covariance `A`, its inverse precision `Ainv = solve(A)`, and pedigree input that reconstructs `A`. Every fit includes an ordinary iid group intercept and predictor-dependent SD formulas for both terms. The test checks convergence, likelihood, SD coefficients, and animal predictions aligned by labels. No builder or likelihood source changed.

## 3a. Decisions and Rejected Alternatives

The test compares input representations on identical data within each link. It does not compare probit and cloglog estimates to each other because those are distinct response models. The fixture uses fewer groups and repeats than the logit test to keep six fits bounded while preserving repeated observations per animal and group.

Assumptions made without asking: the existing pedigree helper constructs the intended A matrix and the simulated animal field uses that same labelled covariance. The deliberately reversed matrix ordering and aligned predictions exercise label handling. If the generator and fitter conventions differ, the test should compare the generated covariance directly before treating the fits as equivalent.

## 4. Files Touched

- `tests/testthat/test-binomial-ordinary-animal-kernel-equivalence-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-animal-kernel-equivalence-nonlogit-sd-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-ordinary-animal-kernel-equivalence-nonlogit-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-animal-kernel-equivalence-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 22 expectations across probit and cloglog. The captured six-fit run took about 1 minute 5 seconds. Source hashes remained stable during that run. Evidence reconciliation passed: 19,678 candidate rows, 122 linked rows, 19,556 unlinked rows, and 144 receipt records. Lane preflight confirmed the test and report paths were new and had no competing ref.

## 6. Tests of the Tests

Each link's three input representations use the same simulated response, SD predictors, fixed effects, and random effects. Convergence is required for all six fits. The likelihood, both SD coefficient vectors, and label-aligned animal predictions must match against A. No deliberate mutation control was run.

## 7a. Issue Ledger

No package issue was opened or changed. The wider Bernoulli provider and link requirements remain open.

## 8. Consistency Audit

The test exercises non-logit link construction separately, reverses animal matrix labels, and aligns predicted animal SDs by the original animal names. The logit A/A-inverse/pedigree test is retained in a separate source-stable test and receipt. The six evidence rows are limited to native Binomial `mu`, probit/cloglog, ordinary iid plus animal, and the three tested input representations.

## 9. What Did Not Go Smoothly

The first focused run passed but did not save its console log. A second run saved the output and exit code for the receipt; it also passed.

## 10. Known Residuals

This is direct fit and input-equivalence evidence only. It does not establish interval coverage, Julia parity, recovery of SD coefficients, or other response families, endpoints, providers, and combinations. The aggregate gate runner remains unavailable, so aggregate gate state is UNKNOWN.

## 11. Team Learning

One same-data baseline comparison can validate several covariance input encodings, but ledger evidence should remain split by exact link and provider representation. Keep test fixtures small enough for repeated focused checks and large enough to avoid sparse boundary-only fits.

## 12. Cross-Product Coverage

The evidence covers native R/TMB Binomial probit and cloglog `mu`, an ordinary iid intercept plus animal SD regression, and equivalent A, A-inverse precision, and pedigree inputs. It does NOT cover Julia fitting or bridge parity, calibrated uncertainty, parameter-recovery performance, other links, families, endpoints, or provider combinations. No Golden Set run was needed because no known-mistake class was changed.
