# Arc 6.2 contract: Gaussian × ordinary NB2 frozen-margin association

This is the second bounded Arc 6 pair class. It extends the post-fit
`associate_pairs()` architecture; it does not introduce a bivariate response
family or change `biv_gaussian()`.

## Admitted model

`associate_pairs(fit_g, fit_n, kernel = latent_normal(), association = ~ 1)`
accepts one fixed-effect ML `gaussian()` fit and one fixed-effect ordinary
`nbinom2()` fit on the same complete rows, in either order. The fitted margins
are frozen: Gaussian \(\mu_{Gi},\sigma_{Gi}\) and NB2
\(\mu_{Ni},\sigma_{Ni}\) may each depend on covariates. Ordinary NB2 means

\[
\operatorname{Var}(Y_{Ni})=\mu_{Ni}+\sigma_{Ni}^2\mu_{Ni}^2,
\qquad \operatorname{size}_i=1/\sigma_{Ni}^2.
\]

The only fitted association quantity is
\(\eta=0.999999\tanh(\alpha)\), a conditional latent-normal point estimate.
It is not `rho12`, an observed-scale correlation, a joint-MLE parameter, or an
inference claim.

## Exact contribution and tails

For observed Gaussian value \(y_{Gi}\), NB2 count \(y_{Ni}\), and
\(z_i=(y_{Gi}-\mu_{Gi})/\sigma_{Gi}\), define
\(a_i=F_{\rm NB2}(y_{Ni}-1)\), \(b_i=F_{\rm NB2}(y_{Ni})\), and
\(s=\sqrt{1-\eta^2}\). The contribution is

\[
f_G(y_{Gi};\mu_{Gi},\sigma_{Gi})
\left[
\Phi\!\left\{\frac{\Phi^{-1}(b_i)-\eta z_i}{s}\right\}
-
\Phi\!\left\{\frac{\Phi^{-1}(a_i)-\eta z_i}{s}\right\}
\right].
\]

The implementation treats \(F(-1)=0\) analytically. It selects normal
quantiles from the smaller NB2 CDF or survival tail and evaluates the
conditional normal interval in log space. End-point clipping, probability
flooring, and silently accepting an inverted or collapsed interval are
forbidden. Such a numerical failure is retained in diagnostics and withholds
`eta`. At \(\eta=0\), the contribution is exactly the product of the frozen
Gaussian density and NB2 mass.

## Deliberate boundary

The first slice rejects association slopes, non-ML fits, random/structured
effects, missing rows, weights, offsets, `mi()`, `meta_V`, zero-inflated,
hurdle, and truncated count models. `vcov()`, profiling, `confint()`,
residual extractors, and `rho12` extractors remain unavailable. Simulation is
a coupled latent-normal construction with exact NB2 quantiles and is a model
construction tool, not a recovery guarantee.

The independent validation oracle, comparator boundaries, research sources,
and separate Arc 6.1/6.2 smoke receipts are recorded in the
[Arc 6.2 after-task report](../dev-log/after-task/2026-07-23-arc6-2-gaussian-nbinom2-frozen-margin.md).
