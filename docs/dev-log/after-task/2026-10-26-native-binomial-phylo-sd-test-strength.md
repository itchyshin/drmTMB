# After-task: Native Binomial phylogenetic SD test strength

## 1. Goal

Strengthen the native R/TMB Binomial phylogenetic SD recovery test without changing the fitted model.

## 2. Implemented

The logit test now requires its estimated SD slope to be within 0.3 of the generating value 0.55; the earlier 0.5 bound allowed nearly zero estimates to pass. It also compares the complete predicted tip-SD vector with the SD formula evaluated in observed tip order. The probit test retains its separate 80-tip fixture, 0.25 recovery bound, formula-aligned predictions, and constant-SD equivalence checks.

## 3a. Decisions and Rejected Alternatives

The test keeps its fixed seed and generated data. The logit assertion was tightened without changing the fixture because the stricter check passes. No likelihood, parameterization, or formula syntax changed.

## 3. Model contract

For tip `g`, the test generates a phylogenetic effect with SD `exp(alpha_0 + alpha_1 z_g)`, where `alpha_1 = 0.55`. The check measures recovery of that log-SD slope and verifies that predicted scales retain the same order as the observed tip rows.

## 4. Files Touched

- `tests/testthat/test-binomial-phylo-sd-regression.R`: tighter logit recovery bound and full formula-to-tip prediction comparison.
- `docs/dev-log/check-log.d/2026-10-26-native-binomial-phylo-sd-test-strength.md`: focused test receipt.
- `docs/dev-log/after-task/2026-10-26-native-binomial-phylo-sd-test-strength.md`: this report.
- `docs/dev-log/after-task/2026-10-26-native-binomial-phylo-sd-test-strength.assessment.json`: exact-draft prose assessment.

## 5. Checks Run

`OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-sd-regression", reporter = "summary")'` passed all 25 expectations on the current candidate with the native R/TMB engine. The focused run did not exercise live Julia fits. No package-wide suite or documentation build was run.

## 6. Tests of the Tests

Before this change, the same file passed 24 expectations with a 0.5 logit slope-error bound. The updated run passed 25 expectations, including the stricter bound and full tip-order check. The deterministic fixture and generating slope were unchanged. No deliberate mutation test was run.

## 7a. Issue Ledger

No external issue or pull request was created or changed. The broader predictor-dependent SD goal remains active.

## 8. Consistency Audit

The expected tip scales use the fitted `z_species` design matrix and the coefficient block returned by `coef()`. The prediction vector is checked in the first-seen species order, and the existing link-scale identity and new-data prediction checks remain in place. This is a test-only change for native R/TMB.

## 9. What Did Not Go Smoothly

The shared lane-lease helper stalled on the global registry lock. The exact-file preflight and read-only ownership check found no other owner or overlapping lease for this test path; the active Bernoulli goal lane made the scoped test-only change. The shared likelihood and formula files were not changed.

## 10. Known Residuals

This is one fixed-seed recovery check per link. It does NOT establish interval coverage, Julia direct-API parity, R-to-Julia bridge parity, or other Binomial random-effect types. The after-task structure validator passed; its acceptance-ledger subcheck remains unknown because the system Node runtime is unavailable and the detected ledgers concern earlier hurdle and Tweedie slices.

## 11. Team Learning

Recovery bounds should exclude estimates near zero when the scientific claim is a positive SD slope. Check the full group-prediction vector against formula order so that a correct set of scales attached to the wrong tips cannot pass.

## 12. Cross-Product Coverage

This slice strengthens native R/TMB logit phylogenetic-intercept test evidence and retains the existing native probit test. It does NOT cover Julia phylogenetic parity, bridge parity, interval calibration, structured slopes, or the remaining response families. It does not complete the general predictor-dependent random-effect SD goal.

## 13. Prose Assessment

The separate exact-draft assessment is recorded in `2026-10-26-native-binomial-phylo-sd-test-strength.assessment.json`.
