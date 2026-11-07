# After Task: Julia Tweedie Related-Matrix SD Save/Reload

## 1. Goal

Verify that serialization preserves the fitted predictor-dependent random-effect SD for the Julia Tweedie related-matrix intercept route.

## 2. Implemented

Extended the paired Julia test to serialize and reload a fitted Tweedie model, then compare its SD coefficients, kernel-adjusted marginal SDs, and predicted SDs with the original fit.

## 3a. Decisions and Rejected Alternatives

The test uses Julia's standard `Serialization` library and checks the existing fit object. It does not add a persistence API or change model calculations.

## 4. Files Touched

- Paired Julia candidate: `test/test_tweedie_relmat_sd_regression.jl`.
- This report and `docs/dev-log/check-log.d/2026-10-23-julia-tweedie-relmat-save-reload.md`.

## 5. Checks Run

- Focused Julia test: 39/39 assertions passed; the related-matrix SD fit test took 2m38.3s. Command: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/tmp/drmTMB-julia-depot:/Users/z3437171/.julia /Users/z3437171/.juliaup/bin/julia --project=. --startup-file=no test/test_tweedie_relmat_sd_regression.jl`.
- Paired R-to-Julia/TMB test: 24/24 expectations passed in 507.4s, with one live Julia bridge test. JuliaCall emitted its known `LogExpFunctionsInverseFunctionsExt` warning; it did not prevent the fits or assertions.
- `git diff --check` passed on the changed Julia test, this report, and the check-log note; the after-task structure checker passed, and `slop_check.py` reported zero findings.

## 6. Tests of the Tests

The existing test reconstructs seeded Tweedie draws from the fitted kernel and SD multipliers, rejects a deliberately constant-SD simulator, and checks one bootstrap refit. The new assertions confirm the target and derived SD values survive serialization.

## 7a. Issue Ledger

The GitHub issue query failed because `api.github.com` was unreachable. No issue was changed; this test adds no new public support claim.

## 8. Consistency Audit

No likelihood, formula, or user-facing support boundary changed. The paired parity test remains one complete-data Tweedie related-matrix mean-intercept comparison using a supplied non-unit-diagonal kernel.

## 9. What Did Not Go Smoothly

The first paired-test attempt could not find Julia because its binary directory was absent from `PATH`. A later attempt was interrupted at 501.7s, just below the prior measured 522.6s runtime; the corrected rerun passed in 507.4s. Future paired runs should preserve the explicit Julia `PATH` prefix and allow at least nine minutes.

## 10. Known Residuals

The checks do not establish interval coverage, general recovery across conditions, missing-row save/reload behavior, or parity for other families and effect types.

## 11. Team Learning

The direct Julia test validates the fit's serialization behavior, while the public bridge test validates a separate paired point-comparison cell. Keep these evidence claims distinct.

## 12. Cross-Product Coverage

This task covers one Julia Tweedie q1 related-matrix mean-intercept fit's save/reload outputs and the existing paired TMB/Julia point comparison. It does NOT cover the full family-by-effect inventory, calibrated uncertainty, or programme completion.
