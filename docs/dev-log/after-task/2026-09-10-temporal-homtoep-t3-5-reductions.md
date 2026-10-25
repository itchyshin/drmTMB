# After-task report: homogeneous Toeplitz T3-5 reductions

## 1. Goal

Prove the homogeneous Toeplitz provider's required AR1 and diagonal reductions
and retain mutations that would invalidate its covariance interpretation.

## 2. Implemented

Added deterministic reduction and mutation tests, then wired T3-5 into the
fail-closed temporal gate runner.

## 3a. Decisions and Rejected Alternatives

The AR1 reduction uses the exact partial-autocorrelation identity
`kappa = (phi, 0, ...)`; the diagonal reduction uses all-zero partial
autocorrelations. An irregular schedule is rejected rather than rank-compressed,
because homogeneous Toeplitz is defined for a common discrete schedule.

## 4. Files Touched

`tests/testthat/test-temporal-homtoep-reductions.R`, the gate runner, ledger,
check log, and this report.

## 5. Checks Run

`Rscript --vanilla tools/temporal-homtoep-gates.R T3-5` emitted
`TEMPORAL_HOMTOEP_T3_5_PASS`; its direct test passed with nine expectations.
`git diff --check` passed before this report was written.

## 6. Tests of the Tests

The reductions evaluate the native objective at fixed outer parameters and
compare it with an independent dense covariance likelihood. Mutations compare
specific covariance entries and normalized versus quadratic-only likelihoods;
they cannot pass merely because a fit converges.

## 7a. Issue Ledger

No external issue was opened or changed. The direct Toeplitz gate remains local
implementation evidence.

## 8. Consistency Audit

The ledger and check log now state the discrete-schedule boundary and every
predeclared mutation covered by T3-5.

## 9. What Did Not Go Smoothly

The deliberate shared-series matrix was initially left as a vector after matrix
indexing; the test now restores its intended square dimensions before replacing
its diagonal. This was a test-construction repair, not a likelihood change.

## 10. Known Residuals

Recovery fixtures and a measured pilot are next. Intervals, calibration, and all
wider temporal structures remain pending.

## 11. Team Learning

For covariance mutations, assert the targeted wrong matrix or normalizer
explicitly; comparing only final fitted estimates would hide the mechanism.

## 12. Cross-Product Coverage

This work covers direct univariate Gaussian ML homogeneous Toeplitz reductions
and covariance mutations. It does NOT cover REML, the Julia engine, missing
data, aggregation, ordinary-intercept composition, phylogenetic or spatial
providers, non-Gaussian families, forecasts, intervals, recovery, or calibration.
