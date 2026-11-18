# After-task report: native beta-binomial SD smoke

## 1. Goal

Run a bounded native smoke for predictor-dependent random-effect SD regression in a core family beyond Bernoulli.

## 2. Implemented

No package code changed. The existing beta-binomial SD integration test completed in the current candidate worktree.

## 3. Mathematical Contract

No model, formula, likelihood, or covariance contract changed. The test exercises the existing beta-binomial mean random-intercept route with predictor-dependent SD.

## 3a. Decisions and Rejected Alternatives

This was a focused implementation check. It does not establish all beta-binomial random-effect types, Julia parity, or calibrated uncertainty.

## 4. Files Touched

- `docs/dev-log/check-log.d/2026-10-20-native-beta-binomial-sd-smoke.md`
- `docs/dev-log/after-task/2026-10-20-native-beta-binomial-sd-smoke.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-binomial-sd-integration")'`: 15 passed, 0 failed, 0 warnings, 0 skipped, 155.1 seconds.
- The test runner reported no live Julia tests.

## 6. Tests of the Tests

The existing test checks coefficient recovery, positive SD predictions, an independent groupwise quadrature likelihood, a deliberately reversed-group SD negative control, simulation, save/reload, profile and bootstrap dispatch, and constant-SD equivalence. Bootstrap uses two refits, which checks routing only. This does not establish interval coverage or Julia parity. No new test was added.

## 7a. Issue Ledger

No issue was opened, closed, or changed.

## 8. Consistency Audit

The test result is recorded as a native, focused smoke. It is not described as full family support, Julia parity, or interval calibration. The assertions support those exact behaviors for this synthetic fixture only.

## 9. What Did Not Go Smoothly

The test took 155.1 seconds, longer than the two-minute estimate. It completed without errors.

## 10. Known Residuals

Julia beta-binomial SD regression is not verified. The broad family, random-effect, provider, layout, and engine matrix remains open. Coverage validation remains deferred from the current goal.

## 11. Team Learning

Estimate short integration smokes with enough margin for slower fitting paths; the actual runtime exceeded the initial two-minute estimate by 35 seconds.

## 12. Cross-Product Coverage

Native drmTMB only. This smoke does NOT cover Julia, other beta-binomial effect types, structured providers, bivariate models, or interval coverage.

## Next Actions

Obtain a clear Julia source ownership handoff, then bind the Bernoulli bridge rerun to exact source hashes. Continue with independent native family/effect slices while that handoff is pending.
