# Bernoulli x NB2 frozen-margin association regression

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

Stage 2 accepts the association design \(X_{A,i}=(1,x_i)\), where \(x_i\) is
one finite numeric covariate. It estimates

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

`association = ~ x` is beta support only for this pair class and this one
numeric fixed-effect slope. Other reviewed Arc 6 pair classes remain restricted
to `association = ~ 1`. Factors, interactions, offsets, random effects,
new-data prediction, standard errors, confidence intervals, profiles, coverage
claims, and a generic discrete-pair association regression are all outside this
slice.

The stage-2 objective conditions on fitted margins. Therefore its coefficients
and fitted \(\eta_i\) values are point estimates only; they are not joint-MLE
`rho12` estimates and do not account for uncertainty from stage 1.

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
