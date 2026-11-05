# After Task: Lognormal intercept SD gate re-verification

## 1. Goal

Reconcile the native lognormal location-intercept SD gate with current source tests and retained compiled evidence.

## 2. Implemented

The source-assembly and independent-reference gate checks pass. L1–L3 are now marked passed. L4 remains open for independent review and documentation agreement. The formula-grammar row now reflects the verified compiled workflow instead of saying those checks are still underway.

## 3a. Decisions and Rejected Alternatives

Accepted the retained Totoro receipt after confirming the current integration-test and helper hashes match its archive members. No new fit was started. Independent review and calibration remain open.

## 3b. Mathematical Contract

For the first complete-data slice, the log-response location includes a group effect with `tau_g = exp(W_g alpha)`, while residual `sigma` remains a fixed-effect regression on the log-response scale. The exact marginal reference integrates the normal group effect with covariance `diag(sigma_i^2) + tau_g^2 11'` and includes the response-scale Jacobian.

## 4. Files Touched

- `.unlazy/general-sd-regression/gates/lognormal-intercept.md`
- `docs/design/01-formula-grammar.md`
- `docs/dev-log/check-log.d/2026-10-18-lognormal-intercept-gate-reverification.md`
- `docs/dev-log/after-task/2026-10-18-lognormal-intercept-gate-reverification.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript tools/general-sd-regression/run-source-tests.R tests/testthat/test-lognormal-sd-assembly.R`: pass, exit 0, `SOURCE_ASSEMBLY_PASS`.
- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'testthat::test_file("tests/testthat/test-lognormal-sd-reference.R", reporter="summary", stop_on_failure=TRUE); cat("LOGNORMAL_REFERENCE_PASS\n")'`: pass, exit 0, `LOGNORMAL_REFERENCE_PASS`.
- Retained Totoro compiled integration log: 24 expectations passed; archive SHA-256 `bad56b4bf70e56972bc1fde2a10a578690789ccca6159e131e09e54176870ffa`. Current integration test and helper hashes match the tested archive members.
- Task-specific stale-status search covered README status, roadmap, NEWS, known limitations, formula grammar, the formula-grammar vignette, pkgdown navigation, and the random-effect-scale design. It found and corrected the outdated formula-grammar status sentence.
- `git diff --check`: pass.

## 6. Tests of the Tests

The exact marginal reference is independent of the fitted likelihood helper and checks a deliberately misassigned group covariate against the correct likelihood. The compiled integration additionally checks seeded recovery, fresh group-effect draw variance, prediction, simulation, save/reload, profile/bootstrap routing, and reduction to the constant-SD model.

## 8. Consistency Audit

The formula-grammar status now says compiled fitting, the marginal oracle, and public workflows pass, while interval calibration and independent review remain open. Broader family and effect support is unchanged.

## 7a. Issue Ledger

The open-issue search for “lognormal random effect sd regression” returned only the broad test-sweep issue #1463. It did not match this feature; no issue was created, edited, or closed.

## 9. What Did Not Go Smoothly

The independent review found that the shared compiled-test runner printed `NATIVE_BINOMIAL_SD_PASS` unconditionally, including for the retained lognormal run. That historical log remains unchanged. The runner now names the test files and prints the Bernoulli marker only when a binomial test file actually ran; a regression test covers lognormal, binomial, beta-binomial, and mixed-file selections. The tested tarball is not retained in the evidence directory, so its member hashes cannot be independently checked from the archive. L4 remains open pending a self-describing rerun or verifiable archive receipt.

## 11. Team Learning

Promote gate rows separately when their own evidence is complete. Keep the independent-review and calibration rows open rather than letting a successful fit close them by implication.

## 10. Known Residuals

This is one complete-data lognormal location-intercept target with fixed residual-scale regression. It does not establish interval calibration, other random-effect shapes, structured effects, or other parameter endpoints. Its compiled result is retained as a positive historical test log, but the runner marker was misleading and the tested tarball is unavailable for independent member-hash verification.

## Follow-up verification

`Rscript tools/general-sd-regression/test-native-runner-markers.R` passed four cases. The test extracts and evaluates the runner's actual trailing marker expressions, so it exercises the same path-selection and marker logic used after compiled tests. Runner parsing and `git diff --check` also pass. No model fit was run.

## 12. Cross-Product Coverage

This evidence covers the native TMB complete-data ordinary lognormal `mu` intercept SD target with fixed residual `sigma`. It does NOT cover Julia lognormal SD fitting, cross-engine agreement, interval calibration, random slopes, correlated or structured effects, or other parameter endpoints.

## Next Actions

Obtain independent review for L4, then continue the remaining family and effect rows. The full programme gates remain open.

## Prose Assessment

**Style:** 2/10, medium confidence; the report is short and tied to concrete test evidence. **Genre/coverage:** internal engineering report, reviewed in full. **Evidence/repair:** the exact commands and archive/test hashes identify the basis for the status; no edit needed. **Gates:** science = pass for the stated reference contract only; facts = pass against current test hashes and retained logs; references = not applicable, no external citations. **Provenance:** self-review, draft version 2, 2026-10-18; no held-out controls used.
