# After Task: Native Binomial correlated q3 SD checks under probit and cloglog

## 1. Goal

Check that the existing native R/TMB q3 correlated Binomial route fits predictor-dependent SDs for the intercept and two numeric slopes under probit and complementary log-log links.

## 2. Implemented

Added one fixed-seed synthetic test for each link. The test checks fit convergence, finite correlation estimates, broad recovery of all three log-SD slopes, group-level SD predictions, and binary simulation. This slice adds recovery evidence; it does not change the model builder or likelihood.

## 3a. Decisions and Rejected Alternatives

Each coefficient has a group-level SD with a log-linear predictor, `log(tau_gk) = W_gk %*% alpha_k`. The three random coefficients retain the existing correlated Gaussian block and its existing correlation parameterization. The test makes no change to kernel scaling or the public formula grammar. I kept the non-logit test in a new file rather than changing the existing q3 logit fixture and its independent quadrature helper.

## 4. Files Touched

- `tests/testthat/test-binomial-correlated-q3-nonlogit-sd.R`
- `docs/dev-log/general-sd-regression/evidence/native-binomial-correlated-q3-nonlogit-20261028/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- This report and `docs/dev-log/check-log.d/2026-10-28-native-binomial-correlated-q3-nonlogit-sd.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-correlated-q3-nonlogit-sd", reporter = "summary", stop_on_failure = TRUE)'`: exit 0; 18 expectations passed.
- The source manifest hashes the test, R formula and target code, prediction and simulation methods, and TMB source.
- Evidence reconciliation passed: 19,678 candidate rows, 155 linked rows, and 175 receipt records. The six probit/cloglog q3 target rows link to this receipt and remain unreviewed.
- `python3 ~/shinichi-brain/tools/slop_check.py` on this report: 0 findings.
- The report validator and whitespace check are listed in the paired check log after passing.
- The aggregate acceptance runner is unavailable, so the overall gate remains UNKNOWN.
- Open issue search for `binomial random-effect SD predictor-dependent correlated` returned no matches. No issue was changed.
- No full R suite, Julia run, package check, or coverage campaign was run.

## 6. Tests of the Tests

The two link-specific datasets use fixed seeds and independently generated correlated three-dimensional random coefficients. Each SD predictor is constant within group. Assertions cover all three target selectors and predictor-to-group scale calculations. The test shares the q3 block structure with the existing logit test, but has no independent likelihood oracle for probit or cloglog and no negative-input case.

## 7a. Issue Ledger

No matching open issue was found in the targeted search. The issue tracker is unchanged.

## 8. Consistency Audit

The data generator uses the existing q3 partial-correlation construction and applies the same link to generation and fitting. The tested claim is limited to this native TMB block and these two links. The shared direct-SD ledger now links the six tested target rows to this receipt. No public support table or user documentation changed.

## 9. What Did Not Go Smoothly

The installed testthat version does not accept `info` on `expect_length`, `expect_lt`, or `expect_setequal`. I checked the installed function signatures and removed those arguments. The final focused run passed. The shared lease registry was slow, so I waited for a path-scoped claim before writing.

## 10. Known Residuals

This is one synthetic design per link with point-recovery checks. It does not establish interval coverage, cross-engine parity, broad q3 calibration, or support for other random-effect types and response families. The wider SD-regression goal remains active. The q3 logit target rows still need a source-current receipt.

## 11. Team Learning

When assertion helpers fail on an unsupported argument, inspect their installed signatures before changing the model test or weakening its checks.

## 12. Cross-Product Coverage

- Family: Bernoulli/Binomial.
- Engine: native R/TMB.
- Endpoint: `mu`.
- Links: probit and complementary log-log.
- Effects: one correlated q3 block with an intercept, two numeric slopes, and a separate predictor-dependent SD formula for each coefficient.
- Data: fixed-seed synthetic data with 128 groups and 40 observations per group per link.
- This slice does NOT cover q3 logit evidence registration, Julia parity, other providers or response families, cross-endpoint blocks, or interval coverage. Continue across the remaining Bernoulli correlated and structured effects.

## Style Assessment

Style: 2/10, medium confidence. Genre and coverage: short technical after-task report, read in full. Evidence and repair: the concrete 18-expectation result and exact six-row ledger registration give the reader a clear scope; no wording change was needed. Gates: science = pass for the stated test-only claim; facts = pass against the focused test output, source manifest, and reconciliation output; references = not applicable because the report cites no external sources. Provenance: self-review, final version, 2026-10-28; the existing crossed-intercept report was seen as a format example, not copied as evidence.
