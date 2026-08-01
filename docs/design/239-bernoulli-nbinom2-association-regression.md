# Bernoulli x NB2 frozen-margin association regression

> **Supersession (2026-08-01).** The implemented formula now accepts a full
> intercept-bearing fixed-effect model matrix, including multiple predictors,
> factors, interactions, and explicit transformations. Its alpha coefficients
> have a two-stage Godambe covariance and Wald intervals. `predict()` supplies
> pointwise eta standard errors and transformed confidence limits. The route
> remains `interval_feasible`; association-regression coverage is uncalibrated.

## Scope

This document specifies the first covariate-varying association extension for
the Arc 6 frozen-margin route. It is deliberately limited to a literal
Bernoulli outcome paired with an ordinary NB2 outcome. It does not change the
released direct Gaussian joint model or its residual correlation `rho12`.

## Model

For complete paired rows \(i=1,\ldots,n\), stage 1 fits and freezes

\[
  p_i = \operatorname{logit}^{-1}(X_{B,i}\widehat\beta_B),\qquad
  \mu_i = \exp(X_{C,i}\widehat\beta_C),\qquad
  \sigma_i = \exp(Z_{C,i}\widehat\gamma_C).
\]

Stage 2 accepts an intercept-bearing fixed-effect association design
\(X_{A,i}\). It estimates

\[
  a_i = X_{A,i}\beta_A,\qquad
  \eta_i = \tanh(a_i),
\]

by maximizing the plug-in rectangle likelihood

\[
  \ell(\beta_A\mid\widehat\theta_B,\widehat\theta_C) =
  \sum_i \log\Pr_{\eta_i}(B_i,C_i\mid p_i,\mu_i,\sigma_i).
\]

The probability is the same latent-normal rectangle probability already used
by the constant Bernoulli x NB2 adapter; only its row-specific correlation
changes. The `tanh` transform defines the scientific association on
\((-1,1)\). The implementation multiplies it by `0.999999` only as a numerical
safeguard, so that finite arithmetic never supplies an exact endpoint to a
latent-normal probability calculation.

## Public boundary

Association regression is available only for this pair class. Other reviewed
Arc 6 pair classes remain restricted to `association = ~ 1`. Multiple
predictors, factors, interactions, and explicit transformations are admitted;
offsets, random effects, missing predictors, aliased columns, dot expansion,
profiles, calibrated coverage, and a generic discrete-pair association
regression remain outside this slice.

The stage-2 objective conditions on fitted margins, so its conditional Hessian
is not used for uncertainty. The stacked two-stage Godambe covariance accounts
for stage-1 estimation. The coefficients and fitted \(\eta_i\) are not
joint-MLE `rho12` estimates.

## Validation contract

The implementation must retain the existing independent rectangle oracle,
fail closed on unresolved numerical rectangles, use unconstrained optimization
on the association-link coefficients, and test ten ordinary/edge combinations
across the admitted pair classes. The new slope route additionally requires a
deterministic simulated Bernoulli x NB2 fixture with a known two-coefficient
association signal, a constant-association backward-compatibility check, and
rejection tests for unsupported association formulas. A larger multi-seed
recovery study is a separate compute-gated evidence task; it is not implied by
this beta implementation.
