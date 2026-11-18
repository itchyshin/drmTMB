# After Task: Binomial probit and cloglog animal SD regression with Ainv

## 1. Goal

Add live same-data R-to-Julia and native-TMB evidence for predictor-dependent animal-intercept SDs with a supplied inverse relationship matrix under probit and complementary log-log links.

## 2. Implemented

Added an opt-in synthetic bridge test for an animal intercept with `Ainv`, a non-unit-diagonal relationship matrix, and a group-constant SD predictor. The fixture checks both non-logit links against native TMB.

## 3a. Decisions and Rejected Alternatives

The current Julia and bridge routes already admit this animal-intercept shape. This slice adds a missing live non-logit `Ainv` provider check without broadening model admission or changing covariance scaling.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-animal-ainv-nonlogit-sd-bridge.R`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.d/2026-10-26-binomial-animal-ainv-nonlogit-bridge.md`
- This report.

## 5. Checks Run

- The opt-in live test passed for probit and cloglog, using native TMB and Julia fits for each link. It checks convergence, log-SD slope recovery against the synthetic truth and across engines, likelihood agreement, and predicted animal SD agreement.
- The first live run stopped at an unsupported `info=` argument in `expect_lt()`. The test assertion was corrected, and the same focused run then passed. The complete first failure and successful retry output are retained in the check-log receipt.
- An earlier invocation without `NOT_CRAN=true` skipped before fitting because `skip_on_cran()` applied; it is not counted as a live run.
- The successful run used JuliaCall with Julia 1.10.0 and the paired candidate at `../general-sd-julia`.
- `git diff --check` passed for the test and evidence files.

## 6. Tests of the Tests

The DGP samples correlated animal effects from a supplied covariance with non-unit marginal diagonals, then multiplies group effects by `exp(alpha_0 + alpha_z z)`. The SD predictor allocation is randomized over the correlated ordering. Both engines receive the same `Ainv`, response, and group ordering. These are point-recovery and output checks, not interval calibration.

## 7a. Issue Ledger

No issue was opened or changed.

## 8. Consistency Audit

The formula uses `animal(1 | id, Ainv = Ainv)` and `sd(id, level = "animal") ~ z`. `Ainv` is computed directly from the covariance used to generate latent effects. The returned SD predictions are compared between engines for the same observations and target.

## 9. What Did Not Go Smoothly

The first live test attempt exposed a testthat compatibility error in assertion labels. Removing the unsupported labels fixed the test. The initial CRAN-mode invocation also skipped before any fit; the successful run explicitly set `NOT_CRAN=true`.

## 10. Known Residuals

The test covers one animal intercept provider route only. It does not cover animal-plus-IID `Ainv`, animal slopes with non-logit links, phylogenetic or spatial effects, bivariate responses, other families, save/reload, profiles/bootstrap, or calibrated uncertainty. Programme gates G3, G4, G6, G7, and G8 remain open. Coverage calibration is deferred to the later follow-up.

## 11. Team Learning

Provider parity needs explicit synthetic coverage when a formula route accepts both a covariance matrix and its inverse; logit evidence for `Ainv` does not establish probit or cloglog likelihood dispatch.

## 12. Cross-Product Coverage

This slice covers one Bernoulli animal-intercept SD with a supplied non-unit-diagonal relationship matrix inverse under probit and cloglog in R-to-TMB and R-to-Julia fits. It does NOT cover `Ainv` with animal-plus-IID terms, animal slopes, other structured providers, other families, or interval calibration. The general capability ledger remains open.
