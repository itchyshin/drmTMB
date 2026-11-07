# After Task: Live Bernoulli Julia Bridge Rerun

## 1. Goal

Verify that the ordinary Bernoulli predictor-dependent random-intercept SD route still runs through the current native TMB and Julia candidate engines on identical synthetic data.

## 2. Implemented

No package behavior changed. This task reran the existing paired test and retained its exact result.

## 3a. Decisions and Rejected Alternatives

The test uses a fixed predictor in `sd(id) ~ w` and compares the fitted SD coefficients and group-specific SD predictions from the native and Julia engines. I retained the existing focused test rather than broadening this rerun to a simulation campaign. This is a point-estimation and public-output check, not an interval-coverage test.

## 4. Files Touched

- Added `docs/dev-log/check-log.d/2026-10-22-live-julia-bernoulli-parity-rerun.md`.
- Added this after-task report.
- Added a supplemental current-candidate execution receipt under G2 in `.unlazy/general-sd-regression/GATES.md`; gate status and scope are unchanged.
- No source, test, or user-facing documentation files changed.

## 5. Checks Run

- Exact live command and environment are recorded in the check-log receipt.
- The selected test in `tests/testthat/test-julia-binomial-sd.R` completed with 36 assertions passed, 0 failed, 0 skipped, and 1 warning.
- The exact native and Julia candidate commits and SHA-256 hashes for the R builder, TMB source, test, Julia Bernoulli SD builder, bridge, and Julia project are recorded in the check-log receipt.
- One native fit and one Julia fit ran on the same 300-group synthetic Bernoulli data. The test checked convergence, coefficient recovery and agreement, group SD predictions, saved-object prediction, and target extraction.
- The warning came from JuliaCall's dependency-install command and a `LogExpFunctionsInverseFunctionsExt` precompile error (`loglogistic` undefined). JuliaCall continued and the live test completed, but this is not a warning-free environment check.
- The first invocation omitted package loading and failed before fitting because `bf()` was unavailable. The corrected invocation loaded the package and then ran the selected test.

## 6. Tests of the Tests

The selected test is scoped by its exact test description. Assertions include successful convergence and same-data TMB-to-Julia coefficient and prediction comparisons, so this run exercised both engines rather than only formula construction.

## 7a. Issue Ledger

No GitHub issue was changed. This was an execution check for an existing candidate implementation, not a newly discovered defect or a completed feature requiring issue closure.

## 8. Consistency Audit

The test and its current documentation describe one ordinary Bernoulli intercept route. This receipt does not change the capability claim. The overall ledger still has breadth and calibration gates open.

## 9. What Did Not Go Smoothly

Calling `test_file()` without loading the package failed before fitting. After loading the package, JuliaCall reported a dependency-install/precompile warning even though the live bridge test passed.

## 10. Known Residuals

This evidence covers one ordinary Bernoulli candidate parity cell. It does not establish calibrated uncertainty, structured random effects, other response families, all public workflows, or released DRM.jl support. Full-programme G3 and G5 remain open.

## 11. Team Learning

For a selected `testthat::test_file()` rerun, explicitly load the package first; otherwise exported formula constructors may be absent. Preserve JuliaCall warnings in the receipt even when assertions pass.

## 12. Cross-Product Coverage

This rerun covers native TMB and the paired local Julia candidate for one ordinary Bernoulli random-intercept SD formula. It does not cover structured effects, other response families, other random-effect types, the Julia package outside this paired candidate, or interval calibration.

## Next Actions

Resolve the JuliaCall extension warning in a separate environment-maintenance slice, then continue the incomplete family/effect/backend rows in the acceptance ledger. Do not promote this test result beyond its stated scope.
