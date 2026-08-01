# Arc 6.6 contract: Bernoulli × ordinary NB2 frozen-margin association

Arc 6.6 extends `associate_pairs()` to one literal `binomial(link = "logit")`
margin and one ordinary fixed-effect ML `nbinom2()` margin, on identical
complete rows, in either input order. Both margins are frozen. The only fitted
quantity is a latent-normal association: normally intercept-only
\(\eta=0.999999\tanh(\alpha_0)\), with one beta-only finite numeric
`association = ~ x` slope that gives
\(\eta_i=0.999999\tanh(\alpha_0+\alpha_1x_i)\). It is not `rho12`, an
observed-scale correlation, or a joint-MLE association. For
the association-link coefficients `alpha` now have a public two-stage Godambe
covariance and Wald intervals for both the intercept and admitted slope
formula; `eta` itself remains a point estimand.

For binary observation \(B_i\), define
\(c_i=\Phi^{-1}(p_i;\mathrm{lower.tail}=FALSE)\), with interval
\(( -\infty,c_i]\) for zero and \((c_i,\infty)\) for one. For count
\(Y_i\), ordinary NB2 uses `size = sigma^-2` and the latent interval
\((a_i,b_i]\), where \(a_i=\Phi^{-1}\{F(Y_i-1)\}\),
\(b_i=\Phi^{-1}\{F(Y_i)\}\), and \(F(-1)=0\). NB2 endpoints select
log-CDF or log-survival tails before taking normal quantiles.

The contribution is a state-specific conditional-normal integral,

\[
 \int_{I_{B_i}} \phi(z)\left[\Phi\{(b_i-\eta z)/s\}-
 \Phi\{(a_i-\eta z)/s\}\right]dz,\quad s=\sqrt{1-\eta^2}.
\]

The inner interval difference is evaluated in log space. Integration is
accepted only when its absolute error is no larger than
`max(1e-12, 5e-3 * rectangle_probability)`; unresolved endpoints or integrals
withhold `eta` and expose row-level diagnostics. Four-corner subtraction,
clipping, and probability flooring are prohibited. At `eta = 0`, the result
equals the Bernoulli mass times the NB2 mass.

For the public uncertainty route, let
(q=(\theta_B^\top,\theta_N^\top,\boldsymbol\alpha^\top)^\top) collect both
margin parameters and the association-link coefficients, and let (U_i(q)) be the corresponding
stacked per-row estimating equation. The covariance is

\[
\widehat{\operatorname{Var}}(\widehat q)
=n^{-1}H^{-1}JH^{-\top},\quad
H=-n^{-1}\sum_i\partial U_i/\partial q^\top,\quad
J=n^{-1}\sum_iU_iU_i^\top.
\]

`vcov()` returns only its named `alpha` block; `confint()` applies
(\widehat\alpha_j \pm z_{1-\gamma/2}\operatorname{SE}(\widehat\alpha_j))
coefficient by coefficient.

Focused tests use an independent `mvtnorm::pmvnorm()` rectangle oracle,
including zero-count, rare/high-tail, and response-order cases. The simulator
draws correlated latent normals, thresholds the Bernoulli coordinate using the
upper-tail threshold, and maps the other coordinate through a tail-stable NB2
quantile. The later F4R campaign adds coverage-backed
`inference_ready_with_caveats` evidence for the alpha-scale Godambe-Wald
interval over its exact 16-cell high-information grid (`n = 480` or `960`).
Public `vcov()` and `confint()` expose both intercept and slope alpha blocks;
the intercept has the stronger coverage-backed tier, while the slope is
`interval_feasible` with an experimental-coverage warning. The failed lower-
information F4 campaign remains a warning and availability caveat rather than
nullifying F4R. Random effects, missingness, weights, offsets, REML, Julia, eta
intervals, and generic binary–count claims remain outside the contract. A
full-refit bootstrap design for the slope remains specified separately in
`docs/design/240-arc6-staged-eta-uncertainty-followup.md`; it is a possible
future calibration method, not a prerequisite for the current Godambe-Wald
interval.
