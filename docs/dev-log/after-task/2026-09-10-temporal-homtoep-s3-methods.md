# After-task report: homogeneous Toeplitz S3 methods and simulation

## 1. Goal

Complete the in-sample methods required for the direct homogeneous Toeplitz
provider while keeping inference unavailable until Toeplitz-specific evidence
exists.

## 2. Implemented

Fresh Gaussian simulation now redraws one standardized Toeplitz path per series
from the fitted `cor_lag*` covariance and maps it back to input row order.
Conditional simulation continues to hold the fitted modes fixed. `vcov()`,
Wald summary/confidence-interval routes, and profile intervals now reject
homogeneous Toeplitz fits with a calibration-deferred message; `check_drm()`
reports the same boundary.

## 3a. Decisions and Rejected Alternatives

Fresh paths use a dense Cholesky draw from the fitted Toeplitz covariance. The
prior AR1/OU transition simulator was not extended by pretending Toeplitz has a
single persistence or decay parameter. Public intervals were blocked rather
than borrowed from the calibrated OU campaign.

## 4. Files Touched

`R/temporal.R`, `R/methods.R`, and `R/check.R` implement the fresh draw and
inference boundary. The independent reference helper and native Toeplitz test
cover all public methods. The gate runner, likelihood design note, ledger, and
check log record T3-4.

## 5. Checks Run

- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-4` emitted
  `TEMPORAL_HOMTOEP_T3_4_PASS`.
- The package-loaded, explicit-status regression harness emitted
  `TEMPORAL_HOMTOEP_S3_REGRESSION_PASS` for temporal AR1 smoke, temporal OU,
  and homogeneous Toeplitz methods.
- `git diff --check` passed before this report was written.

## 6. Tests of the Tests

The test sets a seed, independently draws each Toeplitz latent path with an
independent inverse-Levinson correlation transform and `t(chol(R))`, then draws
residual noise in the exact expected order. It checks this against
`simulate()` for both fresh and conditional draws. It also asserts original-row
mode reconstruction, labelled extraction, fitted values, residuals, all
interval errors, and the diagnostic rows.

## 7a. Issue Ledger

No external issue was opened or changed. The earlier search found only #1302,
which concerns the separate phylogenetic-stable plus OU provider.

## 8. Consistency Audit

The likelihood design note now distinguishes input-order conditional methods
from fresh Toeplitz simulation and repeats the deferred inference boundary.
The parser and public prediction still reject unsupported `newdata` paths.

## 9. What Did Not Go Smoothly

The prior generic temporal simulation assumed every non-AR1 provider was OU.
The added test exposed this before it reached a user-facing Toeplitz workflow.

## 10. Known Residuals

T3-5 reductions and mutation controls are next. Recovery, reader workflow,
ordinary-intercept composition, `newdata`, forecasts, all intervals, and
calibration remain pending.

## 11. Team Learning

A temporal provider needs an explicit fresh-path simulator; a shared
conditional-mode extractor is not enough to make marginal simulation correct.

## 12. Cross-Product Coverage

This work covers direct univariate Gaussian ML temporal AR1, OU, and Toeplitz
simulation paths and their in-sample method boundaries. It does NOT cover
REML, penalized estimators, the Julia engine, missing data, aggregation,
ordinary-intercept Toeplitz composition, phylogenetic or spatial effects,
non-Gaussian families, `newdata`, forecasts, profile or Wald intervals, or
calibration.
