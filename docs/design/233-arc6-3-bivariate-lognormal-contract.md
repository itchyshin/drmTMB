# Arc 6.3 contract: exact bivariate lognormal model

## Purpose and estimand

`biv_lognormal()` is a distinct, exact two-response likelihood. It is not a
frozen-margin `associate_pairs()` fit, and it does not estimate the latter
route's latent-normal association `eta`.

For complete positive pairs, the admitted first slice is

\[
\begin{aligned}
 L_{i1} &= \log(Y_{i1}), & L_{i2} &= \log(Y_{i2}),\\
 (L_{i1}, L_{i2})^T &\sim N_2\left\{
   (\mu_{i1},\mu_{i2})^T,
   \begin{bmatrix}
     \sigma_1^2 & \rho_{12}\sigma_1\sigma_2\\
     \rho_{12}\sigma_1\sigma_2 & \sigma_2^2
   \end{bmatrix}
 \right\}.
\end{aligned}
\]

Thus `rho12` is the within-row residual correlation of `log(y1) - mu1` and
`log(y2) - mu2`. It is neither a raw-response Pearson correlation nor
`associate_pairs()`'s conditional `eta`.

The original-scale density includes both change-of-variable Jacobians:

\[
 \ell_i=\log\phi_2\{(\log y_{i1},\log y_{i2});\mu_i,\Sigma\}
          -\log y_{i1}-\log y_{i2}.
\]

The internal link is `rho12 = 0.999999 * tanh(eta_rho12)`; the guard makes the
log-scale covariance positive definite but does not make near-boundary fits
well identified. The derived raw-scale correlation is documented only:

\[
\operatorname{cor}(Y_1,Y_2)=
\frac{\exp(\rho_{12}\sigma_1\sigma_2)-1}
{\sqrt{[\exp(\sigma_1^2)-1][\exp(\sigma_2^2)-1]}}.
\]

It is not an additional fitted parameter or extractor in this slice.

## Public grammar and response semantics

```r
drmTMB(
  bf(mu1 = y1 ~ x, mu2 = y2 ~ z,
     sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
  family = biv_lognormal(), data = dat
)
```

`mu1` and `mu2` may have ordinary fixed-effect formulas. `sigma1`, `sigma2`,
and `rho12` are intercept-only in this first slice. `predict(..., dpar =
"mu1")` and `predict(..., dpar = "mu2")` return log-response locations;
`sigma1`/`sigma2` are log-response SDs; `rho12()` returns the log-residual
correlation. The fitted marginal response means are
`exp(mu_j + sigma_j^2 / 2)`.

## Explicit exclusions

The model rejects incomplete pairs, non-positive or non-finite responses,
weights, offsets, `meta_V`, `mi()`, random or structured effects, `sd()` and
`corpair()` terms, sigma/rho predictors, REML, Julia, intervals, profiles,
coverage, and capability claims. A finite Hessian or a focused test does not
change that claim ceiling.

## Symbolic-to-implementation alignment

| Symbol | API / implementation field | Simulator draw | Oracle / recovery check |
| --- | --- | --- | --- |
| `mu1`, `mu2` | fixed-effect `mu1`, `mu2` formulas | `X1 beta1`, `X2 beta2` | coefficient and swapped-response checks |
| `sigma1`, `sigma2` | intercept-only log links | Cholesky-scaled normal residuals | marginal lognormal density at `rho12 = 0` |
| `rho12` | guarded `tanh(beta_rho12)` | correlated standard-normal residuals | transformed-scale bivariate-normal oracle |
| `-log(y1)-log(y2)` | TMB Jacobian terms | exponentiation of both log outcomes | direct original-scale density comparison |

The independent oracle must not call the package likelihood: it evaluates the
bivariate normal density on `log(y)` and subtracts the two Jacobians. The
independent simulator draws the correlated normal log residuals first and then
exponentiates. Required tests are product margins at zero correlation,
response swap, unequal SDs, guarded-boundary behaviour, and rejection of zero,
negative, or non-finite data.
