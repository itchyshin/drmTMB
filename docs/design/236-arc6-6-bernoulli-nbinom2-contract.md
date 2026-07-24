# Arc 6.6 contract: Bernoulli × ordinary NB2 frozen-margin association

Arc 6.6 extends `associate_pairs()` to one literal `binomial(link = "logit")`
margin and one ordinary fixed-effect ML `nbinom2()` margin, on identical
complete rows, in either input order. Both margins are frozen. The only fitted
quantity is the intercept-only latent-normal association
\(\eta=0.999999\tanh(\alpha)\). It is not `rho12`, an observed-scale
correlation, joint-MLE association, or an inference estimand.

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

Focused tests use an independent `mvtnorm::pmvnorm()` rectangle oracle,
including zero-count, rare/high-tail, and response-order cases. The simulator
draws correlated latent normals, thresholds the Bernoulli coordinate using the
upper-tail threshold, and maps the other coordinate through a tail-stable NB2
quantile. This is source-level construction evidence only: S0 recovery,
intervals, coverage, random effects, association slopes, missingness, weights,
offsets, REML, Julia, and generic binary–count claims remain outside the
contract.
