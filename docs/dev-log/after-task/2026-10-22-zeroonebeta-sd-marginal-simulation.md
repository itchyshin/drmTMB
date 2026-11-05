# After Task: ZeroOneBeta SD marginal simulation

## 1. Goal

Make a fresh ZeroOneBeta marginal simulation draw use the newly sampled random effect for its Beta-component mean.

## 2. Implemented

The Julia candidate now transforms the random-effect-adjusted linear predictor with the logit inverse link and passes that Beta-component mean to the existing ZeroOneBeta sampler. It retains the fitted precision, zero-one probability, and conditional-one probability.

## 3a. Decisions and Rejected Alternatives

The implementation draws directly through `_rand_zeroonebeta()` after calculating the updated mean. Passing the mean through `_simulate_once(...; mu = ...)` was rejected because that route reads the fitted Beta-component mean and drops the newly sampled random effect. No likelihood or formula change was needed.

## 4. Files Touched

- Paired Julia candidate `src/inference.jl`: special-case fresh ZeroOneBeta mixture draws in `_marginal_simulator_build()`.
- Paired Julia candidate `test/test_zeroonebeta_sd_simulation_integrity.jl`: independent seeded oracle and one bootstrap refit check.
- This report, the dated check-log entry, the general-SD checkpoint, and G4 evidence in the program ledger.

## 5. Checks Run

- Focused test on the paired Julia candidate: 10/10 passed, including the seeded oracle and one successful bootstrap replicate.
- Neighboring ZeroOneBeta sweep in one Julia process: `test/test_zeroonebeta.jl` 6/6, `test/test_zeroonebeta_sd_regression.jl` 14/14, `test/test_zeroonebeta_sd_slope.jl` 9/9, and the new simulator test 10/10. Total: 39/39.
- `git diff --check -- src/inference.jl`: passed.
- An independent read-only code review found no concrete issue in the special case or its oracle.

## 6. Tests of the Tests

Before the implementation change, the new test passed 9 checks and failed the exact seeded comparison against its independently reconstructed draw. After the change, that comparison passes. The bootstrap check also confirms the marginal simulator can supply data to one successful refit.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --state open --search 'ZeroOneBeta marginal simulation' --json number,title --limit 20` returned no matching open issues. No issue was changed.

## 8. Consistency Audit

The simulator uses the same logit transform and `_rand_zeroonebeta()` sampler as the existing family implementation. It retains the observation-level random-effect loading used by the general simulator. No R/TMB likelihood, formula selector, or fitted-object structure changed. The goal ledger records this as partial G4 workflow evidence only.

## 9. What Did Not Go Smoothly

The first local Julia command was not on the login-shell `PATH`. Calling Julia by its installed path then hit a sandbox permission error on the compiled-package lock under `~/.julia`. The same test passed when rerun with filesystem access; neither failure reached model execution.

## 10. Known Residuals

This is one ZeroOneBeta ordinary-intercept simulator workflow on a dirty paired Julia candidate. It does not establish broad family or effect parity, native TMB parity for this simulator fix, interval coverage, or calibrated uncertainty. The general-SD gates remain open and coverage validation remains deferred.

## 11. Team Learning

For marginal mixture simulators, test the fresh latent effect against an independent seeded draw sequence. A finite-output check alone would not catch silently reusing the fitted component mean.

## 12. Cross-Product Coverage

The change covers the paired Julia candidate's ZeroOneBeta q1 ordinary-intercept marginal simulator and one bootstrap refit. It does NOT cover native R/TMB simulation, Julia structured or correlated effects, other distributional endpoints, other response families, broad prediction or refit semantics, or calibrated interval coverage. The public formula and fitted-object structure remain unchanged. No user-facing docs or site pages changed because the public interface did not change; the internal G4 ledger and checkpoint now carry the narrow evidence and its limits.
