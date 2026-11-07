# After Task: Native Binomial ordinary and animal SD input equivalence

## 1. Goal

Record direct native evidence that equivalent animal relationship inputs retain fitted Binomial logit ordinary-plus-animal SD regression semantics.

## 2. Implemented

Added a fixed-seed synthetic test comparing additive relationship covariance `A` with `Ainv = solve(A)` and pedigree input. All three fits include an ordinary iid group intercept and predictor-dependent SD formulas for both terms. The test checks convergence, same-data likelihood, SD coefficients, and animal predictions aligned by labels. No likelihood or builder code changed.

## 3a. Decisions and Rejected Alternatives

The comparison holds data, model formula, and latent covariance constant while changing only the animal input representation. The fit with `A` is the reference. No broader recovery grid was added because this slice checks input equivalence only.

Assumptions made without asking: the existing pedigree helper and reversed matrix labels are appropriate for constructing equivalent inputs in a small independent fixture. If this assumption is false, the test should compare independently derived relationship matrices before fitting.

## 4. Files Touched

- `tests/testthat/test-binomial-ordinary-animal-kernel-equivalence-sd.R`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-ordinary-animal-kernel-equivalence-sd-20261027/`
- `docs/dev-log/check-log.d/2026-10-27-native-binomial-ordinary-animal-kernel-equivalence-sd.md`
- This report

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-ordinary-animal-kernel-equivalence-sd", reporter = "summary", stop_on_failure = TRUE)'` passed with exit 0 and 11 expectations. The R test took about 1 minute 55 seconds. Source hashes remained stable across the evidence run. `python3 tools/general-sd-regression/reconcile_evidence.py` passed: 19,678 candidate rows, 116 linked rows, 19,562 unlinked rows, 138 evidence records. The route manifest was absent for this worktree; repository instructions and the active checkpoint were used. Lane preflight confirmed the test path was not present in another ref.

## 6. Tests of the Tests

The same simulated observations are used in all three fits. The assertion set requires convergence and matching likelihood, coefficients, and named animal SD predictions. A changed covariance ordering or incorrect A-inverse/pedigree interpretation should fail these comparisons. No deliberate mutation control was run.

## 7a. Issue Ledger

No package issue was opened or changed. Broader family, link, engine, and provider rows remain in the active ledger.

## 8. Consistency Audit

The tested animal covariance is reordered deliberately and paired with a reversed animal factor level order, while predictions are compared after aligning labels. Existing Bernoulli ordinary-plus-animal and phylogenetic tests remain unchanged. The result is recorded only against the two exact native Binomial logit A-inverse and pedigree rows.

## 9. What Did Not Go Smoothly

The first evidence wrapper reached the successful test output but then failed because zsh reserves `status` as a read-only variable. A corrected wrapper reran the check and recorded exit code zero.

## 10. Known Residuals

This is a focused equivalence test, not broad parameter recovery or interval-coverage validation. It does not establish Julia parity, other Bernoulli links, other families, or other random-effect combinations. The aggregate gate runner remains unavailable, so aggregate gate state is UNKNOWN.

## 11. Team Learning

Use `rc` rather than `status` to capture exit codes in zsh evidence wrappers. Keep covariance-input equivalence receipts scoped to the exact response, link, provider pair, and engine tested.

## 12. Cross-Product Coverage

The evidence covers native R/TMB Binomial logit `mu`, an ordinary iid intercept plus animal SD regression, and equivalent A, A-inverse precision, and pedigree inputs. It does NOT cover Julia fitting or bridge parity, uncertainty calibration, other links, families, endpoints, or provider combinations. No Golden Set run was needed because no known-mistake class was changed.
