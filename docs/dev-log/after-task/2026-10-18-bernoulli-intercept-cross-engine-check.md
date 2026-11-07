# After Task: Paired Bernoulli SD Engine Check

## 1. Goal

Check one frozen synthetic Bernoulli random-intercept SD regression with native TMB and live Julia, and record the evidence boundary.

## 2. Implemented

Added a same-data comparison to the live Julia Bernoulli test. Both engines fit the 300-group, 12-replicate fixture generated with seed 1701. The check covers convergence, SD-coefficient labels, recovery, and group-level SD predictions. No production likelihood code changed in this slice.

## 3. Mathematical Contract

For group `g`, `log(tau_g) = alpha_0 + alpha_1 * w_g`, `b_g ~ Normal(0, tau_g^2)`, and `logit(P(y_ig = 1)) = beta_0 + beta_1 * x_ig + b_g`. The Bernoulli random effect is on the link scale and has no free residual `sigma`.

## 3a. Decisions and Rejected Alternatives

Keep the existing ML/Laplace routes and public target spelling. Use a 0.05 coefficient and predicted-SD tolerance for this fixed high-information engineering comparison. This single-fixture tolerance is not a statistical coverage threshold and does not qualify other information levels or model cells.

## 4. Files Touched

- `tests/testthat/test-julia-binomial-sd.R`
- This report
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `devtools::test(filter = "binomial-sd-integration")` exited successfully. The filter ran the Binomial and beta-binomial SD integration files.
- `devtools::test(filter = "julia-binomial-sd")` ran three live Julia tests and exited successfully with `DRM_JL_PATH` set to the current Julia worktree. One Hessian-conditioning warning was emitted; it is not a coverage result.
- Julia `test/test_binomial_sd_regression.jl` passed 64 checks and `test/test_binomial_sd_public.jl` passed 42 checks.
- The calibration adapter's pure suite passed 29 tests. Python compilation and R parsing passed. No recovery campaign was launched.
- On the paired fixture, the true SD coefficients were `(-0.223144, 0.5)`, the TMB estimates were `(-0.289158, 0.517076)`, and the Julia estimates were `(-0.270376, 0.511753)`. The absolute engine differences were `(0.018782, 0.005323)`. TMB reported optimizer code 0 with a positive-definite Hessian; Julia reported optimizer code 0 and `bridge$converged = TRUE`.

The source trees were dirty during these checks. R commit `425bee81572c625a634b2b083050c5c57c1dc1f1` and Julia commit `70dbf564eb670144c63c08f61ea099084d95add2` identify their bases. Relevant R SHA-256 values: `test-julia-binomial-sd.R` `894343a9d988c1b302856202322ec6f2054d73403253c810b63c2d3e1ec799aa`, `R/drmTMB.R` `2d3ef33d211506c40644627e39fdaee04e681d181916fe100b1a293f63a6752b`, and `src/drmTMB.cpp` `4555de6f9c13fa7290f60cb1bdb08261d1c74a50514e6ca9c1d3943a2e6e5441`. Relevant Julia SHA-256 values: `src/binomial_sd_regression.jl` `7a74afa249bc0ab0f284e15472960bd640a1bb0c45488e5598a7f8a65bfe23e5` and `src/bridge.jl` `4c5c0f520ae5ee4d8eecaf2c3c9e26655f86cd0af2763c27b24c111e125a5e5a`.

## 6. Tests of the Tests

The live test calls both real engines on the same generated rows. An initial draft checked `fit$opt$converged`, but the R wrapper's documented optimizer slot contains only convergence code, iterations, and message. The test now checks the public code and the raw `fit$bridge$converged` value.

## 7a. Issue Ledger

The open issue search found #1457 on Gamma and Student correlated random slopes. It does not describe this independent Bernoulli random-intercept comparison, so no issue was changed.

## 8. Consistency Audit

The test uses the existing `sd(id) ~ w` syntax and the same response-scale SD target in both engines. No user-facing support statement, vignette, or formula grammar changed. Existing separate Bernoulli slope comparison remains in the test file.

## 9. What Did Not Go Smoothly

The first paired run used a wrapper field that does not exist, so that diagnostic assertion failed despite optimizer code 0. Reading `drm_julia_opt_slot()` clarified the public fields and the raw bridge field. A later live test emitted a near-singular Hessian warning; the warning remains visible and Wald uncertainty is not claimed from this check.

## 10. Known Residuals

This is one high-information seed and one intercept target. It does not establish interval calibration, coverage, structured-effect parity, or family-wide support. The Hessian warning also leaves Wald uncertainty unqualified. The full SD-regression capability and inference ledgers remain open.

Next action: finish Bernoulli uncertainty calibration using the retained first-look evidence and the repaired second-look adapter, then continue the family-by-effect-by-engine matrix.

## 11. Team Learning

Before asserting optimizer state across engines, inspect the public wrapper contract and the raw engine payload separately. The distinction prevents a test from confusing a missing wrapper field with a failed fit.

## 12. Cross-Product Coverage

The paired fit supports only the tested native TMB and Julia Bernoulli random-intercept cell. This slice does NOT cover calibrated uncertainty, other random-effect types, other response families, or the remaining public-output workflows.
