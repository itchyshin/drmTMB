# Arc 6.7 contract: ordinary NB2 × ordinary NB2 frozen-margin association

Arc 6.7 extends `associate_pairs()` to two ordinary fixed-effect ML
`nbinom2()` margins on identical complete rows, in either input order. Both
margins are frozen. The only fitted quantity is the intercept-only
latent-normal association \(\eta=0.999999\tanh(\alpha)\). It is not `rho12`,
an observed-scale correlation, a joint-MLE association, or an inference
estimand.

For count margin \(j\), use `size = sigma_j^-2` and the latent interval
\((a_{ij}, b_{ij}]\), where
\(a_{ij}=\Phi^{-1}\{F_j(y_{ij}-1)\}\) and
\(b_{ij}=\Phi^{-1}\{F_j(y_{ij})\}\), with \(F_j(-1)=0\). Each endpoint chooses
the stable log-CDF or log-survival tail before its normal quantile. The
per-row contribution is the conditional-normal rectangle integral

\[
 \int_{a_{i1}}^{b_{i1}} \phi(z)
 \left[\Phi\{(b_{i2}-\eta z)/s\}-
       \Phi\{(a_{i2}-\eta z)/s\}\right]dz,
 \qquad s=\sqrt{1-\eta^2}.
\]

The inner interval difference is evaluated in log space. Integration is
accepted only when its absolute error is no larger than
`max(1e-12, 5e-3 * rectangle_probability)`; unresolved endpoints or rejected
integrals withhold `eta` and retain row-level diagnostics. Four-corner
subtraction, clipping, and probability flooring are prohibited. At
`eta = 0`, the contribution is the product of the two NB2 masses.

Focused tests compare production rectangles with an independent
`mvtnorm::pmvnorm()` oracle, test normalization over a finite count grid,
rare/high-tail rectangles, response order, deterministic simulation, and
deliberately rejected endpoint and quadrature failures. This is construction
evidence only: S0 recovery, intervals, coverage, random effects, association
slopes, missingness, weights, offsets, REML, Julia, and generic count-pair
claims remain outside the contract.
