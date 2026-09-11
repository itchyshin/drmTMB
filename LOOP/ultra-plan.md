# Temporal AR1 v2 execution scope

This lane implements the approved Gaussian temporal AR1 model in `drmTMB`.
The earlier planning packet under `docs/dev-log/plans/2026-09-08-temporal-ar1/`
is retained as historical evidence; this document records the superseding
execution decisions.

## Contract

The supported Gaussian mean is

\[
y_{it}=x_{it}^{T}\beta+b_i+a_{it}+\epsilon_{it},
\]

where the ordinary intercept has variance \(s_b^2\), the stationary temporal
process has covariance \(s_a^2\phi^{|t-s|}\), and the independent residual has
variance \(\sigma^2\).  The temporal process keeps true integer gaps and allows
negative as well as positive persistence.

The public formula admits exactly one
`temporal(1 | id, time = occasion, structure = "ar1")`, with an optional
ordinary `(1 | id)` using that same identifier.  This lane supports Gaussian
ML with constant `sigma ~ 1`, in-sample prediction and simulation, and Wald
intervals for mean coefficients from the full observed marginal-likelihood
Hessian.  It does not add OU fitting, slopes, other families, forecasting,
`newdata`, profile/bootstrap intervals, or variance-parameter intervals.

## Delivery slices

1. Formula marker, parsing, raw-data validation, and time-preserving layout.
2. Native TMB AR1 provider beside the existing ordinary random intercept.
3. Extractors, prediction/simulation, and mean-coefficient Wald inference.
4. Deterministic dense-oracle and mutation tests, then 12-dataset recovery.
5. A five-seed-per-cell timed calibration pilot, documentation, local render,
   review, after-task evidence, and a local implementation commit.

The full 1,000-dataset-per-cell calibration campaign is an explicit G17 stop:
this lane may prepare and time its pilot but must not submit or run the campaign
without Shinichi's recorded authorization.

## Gates

The ignored runtime ledger at `.unlazy/temporal-ar1-v2/GATES.md` is the source
of executable evidence.  G0, G15, and G17 require manual approval.  All other
gates remain pending until their checks are implemented and their success-only
evidence is retained.
