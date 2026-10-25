# After-task report: homogeneous Toeplitz T3-7c marginal candidate spike

## 1. Goal

Test whether the recommended marginal homogeneous Toeplitz covariance removes
the exact residual/process ridge before selecting it as a public contract.

## 2. Implemented

A standalone base-R runner simulates an 80-series by six-occasion panel and
optimizes the dense likelihood `V_i = s_T^2 R`. Its PACF map, likelihood, and
numerical Hessian are independent of the current TMB temporal provider. T3-7c
runs the spike and requires converged finite, positive observed information.

## 3a. Decisions and Rejected Alternatives

The spike omits a separate residual SD by design: it evaluates M's total-
covariance interpretation, not a disguised version of the non-identified direct
prototype. It does not choose M; T3-7b remains the user-facing semantic decision.

## 4. Files Touched

`tools/temporal-homtoep-marginal-spike.R`,
`tools/temporal-homtoep-gates.R`, the redesign brief, Unlazy ledger, check log,
and this report.

## 5. Checks Run

- The pure-R spike emitted `MARGINAL_HOMTOEP_SPIKE_PASS` with objective
  507.260020 and minimum Hessian eigenvalue 47.771361.
- `Rscript --vanilla tools/temporal-homtoep-gates.R T3-7c` emitted
  `TEMPORAL_HOMTOEP_T3_7C_PASS`.

## 6. Tests of the Tests

The runner uses an independent inverse-Levinson recursion and dense Cholesky
likelihood. It returns an infeasible objective when a floating-point Cholesky
factorization reaches the PACF boundary, so numerical boundary exploration is
not mistaken for a covariance failure.

## 7a. Issue Ledger

No external issue was opened or changed. This candidate result does not change
the pending T3-7b model-contract selection.

## 8. Consistency Audit

The spike, gate, decision brief, and ledger all identify its model as total
marginal Toeplitz covariance, with no residual/process variance split.

## 9. What Did Not Go Smoothly

Unconstrained BFGS briefly reached a numerical PACF boundary even though the
map is theoretically positive definite. The oracle now records that region as
infeasible rather than allowing a Cholesky error to terminate the diagnostic.

## 10. Known Residuals

The result is one large-information feasibility spike only. It does not qualify
the M provider, its formula, recovery, confidence intervals, calibration,
ordinary intercept composition, or reader workflow.

## 11. Team Learning

A candidate covariance redesign needs its own independent observed-information
check before it inherits any testing or inference claim from a different latent
parameterization.

## 12. Cross-Product Coverage

This work covers one independent marginal homogeneous Toeplitz feasibility spike
for a complete Gaussian panel. It does NOT cover production TMB code, public
syntax, residual/process decomposition, replicated latent panels, REML, Julia,
missing data, ordinary intercepts, phylogenetic or spatial structures,
calibration, campaigns, forecasts, or newdata prediction.
