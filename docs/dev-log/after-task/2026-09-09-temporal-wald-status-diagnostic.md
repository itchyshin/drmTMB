# After Task: temporal Wald-status diagnostic

**Branch:** `codex/temporal-ou-v1-20260908`

**Date:** 2026-09-09

**Scope:** make the temporal fixed-effect Wald inference boundary explicit in `check_drm()`.

## 1. Goal

Give users one diagnostic row that distinguishes an AR1 fit whose full observed Hessian supports its existing mean-only Wald method, an AR1 fit whose covariance is unavailable, and the intentional OU Wald guard.

## 2. Implemented

`check_drm()` now includes `temporal_mean_wald` for temporal Gaussian fits. A regular AR1 fit returns a note saying that Wald output is available for that fit but unqualified as a general coverage claim. A non-PD or unavailable AR1 covariance returns a warning. OU returns a note saying that its public Wald route is intentionally deferred by the inherited AR1 calibration prerequisite.

## 3a. Decisions and Rejected Alternatives

The new row does not use a numerical residual-SD boundary threshold. The dense C1 evidence shows why a simple threshold would be an unreliable replacement for likelihood geometry. It also does not make a fit-level positive-definite Hessian a pass for G7: that would confuse local numerical regularity with coverage calibration.

## 4. Files Touched

`R/check.R` implements the status row. `man/check_drm.Rd` is the regenerated public help. Temporal AR1 and OU regression tests exercise the three statuses. The check log and this report retain the scope.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `devtools::test(filter = "temporal", reporter = "summary")` | PASS: all temporal test files completed with no failures. |
| `devtools::document()` | PASS: regenerated `man/check_drm.Rd`. |
| Source and generated-document diff check | PASS: no whitespace errors; public help contains `temporal_mean_wald`. |

## 6. Tests of the Tests

The AR1 regression asserts a regular note and then mutates only `sdr$pdHess` to require the unavailable-full-Hessian warning. The OU regression requires the deferred-calibration note after asserting that `confint(..., method = "wald")` remains unavailable. These checks fail on the prior code because the diagnostic row did not exist.

## 7a. Issue Ledger

No issue was opened or edited. This is an unpushed local implementation lane.

## 8. Consistency Audit

The text aligns with the public `vcov()` and `confint()` guards, the temporal vignette's Hessian qualification, and the retained C1 dense-profile evidence. It does not call a point estimate invalid solely because its interval covariance is unavailable.

## 9. What Did Not Go Smoothly

An initial patch used a stale roxygen context and was rejected before changing files. The final patch was applied against the exact current diagnostic and test locations, then documented and tested.

## 10. Known Residuals

This diagnostic does not solve the AR1 C1 boundary or qualify OU covariance. G7, G14, and G15 remain open. No profile method, campaign, forecast, or new temporal family was introduced.

## 11. Team Learning

A diagnostic must name both the local condition and the scope of its inference claim. “Positive-definite” alone is not enough for a reader deciding whether an interval is calibrated for the intended design.

## 12. Cross-Product Coverage

This task covers temporal Gaussian `check_drm()` output and its generated help for regular AR1, non-PD AR1, and deferred OU Wald states. It does NOT cover a new covariance estimator, profile or bootstrap intervals, calibration coverage, variance-component intervals, remote campaigns, non-Gaussian families, REML, temporal slopes, forecasts, new-data prediction, ARMA/Toeplitz, random walks, seasonal states, Matérn, or gllvmTMB.
