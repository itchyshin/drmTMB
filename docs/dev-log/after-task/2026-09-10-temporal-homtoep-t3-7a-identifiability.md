# After-task report: homogeneous Toeplitz T3-7a identifiability diagnosis

## 1. Goal

Determine whether the all-false pilot observed-Hessian flags indicate an
implementation failure, numerical weakness, or a structural property of the
free Toeplitz model with residual noise.

## 2. Implemented

An independent dense-covariance test now applies a covariance-preserving
reparameterization to a valid Toeplitz correlation matrix. It verifies positive
definiteness, inverse-Levinson coordinates, exact covariance equality, and
exact Gaussian likelihood equality after jointly changing process scale,
residual scale, and free lag correlations. T3-7a runs that test in an isolated
pure-R process.

## 3a. Decisions and Rejected Alternatives

The diagnostic rejects treating finite convergence, altered optimizer settings,
or a larger retained campaign as an inference fix. The exact ridge proves that
the current model cannot separate `sd_temporal`, `sigma`, and every free lag
correlation when there is one response per series--occasion. A later redesign
may model the total Toeplitz covariance, fix a nugget, or add information from a
different sampling design; none is silently selected here.

## 4. Files Touched

`tests/testthat/test-temporal-homtoep-identifiability.R`,
`tools/temporal-homtoep-gates.R`, the Unlazy ledger, check log, and this report.

## 5. Checks Run

- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-7a` emitted
  `TEMPORAL_HOMTOEP_T3_7A_PASS`.
- The pilot's 15 finite fits had a false `pd_hessian` flag and `NaNs produced`
  warning; an independent one-fit numerical outer Hessian had one eigenvalue
  near zero (`-3.66e-05`) while other directions were positive.
- The deterministic identity test keeps both dense covariance and Gaussian NLL
  unchanged to `1e-12` under a valid transformed Toeplitz correlation matrix.

## 6. Tests of the Tests

The test uses an independent dense covariance and likelihood implementation,
not the native provider. It checks the transformed matrix's positive
definiteness and valid inverse-Levinson representation before asserting exact
covariance and likelihood equality.

## 7a. Issue Ledger

No external issue was opened or changed. The separate phylogenetic OU work is
unaffected: its OU correlation function constrains off-diagonal covariance and
does not have this fully free Toeplitz ridge.

## 8. Consistency Audit

The pilot result, numerical Hessian diagnosis, algebraic transformation, test,
gate, ledger, and check log agree that the barrier concerns free lag
correlations plus a separately estimated residual scale.

## 9. What Did Not Go Smoothly

The first isolated gate attempted an unnecessary native rebuild and left a
compiler temporary file. The test is pure R, so T3-7a now explicitly loads the
already built library without compiling; this removes compiler state from the
diagnostic while retaining the isolated test process.

## 10. Known Residuals

T3-8 through T3-10 cannot proceed under the current direct parameterization.
No profile or Wald interval, coverage campaign, ordinary-intercept Toeplitz,
phylogenetic, spatial, forecasting, or newdata claim is supported by this
provider.

## 11. Team Learning

A covariance family can be mathematically positive definite yet scientifically
unidentifiable after adding a residual nugget. Before calibrating intervals,
prove that the parameter decomposition itself is identified at the observation
grain the interface admits.

## 12. Cross-Product Coverage

This work covers the direct Gaussian homogeneous Toeplitz covariance identity
with a separate residual scale and one response per series--occasion. It does NOT cover a total-covariance Toeplitz redesign, replicated within-occasion
sampling, REML, Julia, missing data, other families, ordinary intercepts,
phylogenetic or spatial structures, calibrated intervals, campaigns, forecasts,
or newdata prediction.
