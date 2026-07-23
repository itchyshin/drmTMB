# Arc 6.4 exact bivariate Student-t contract

## Purpose and estimand

`biv_student()` is a distinct direct two-response likelihood. It is not an
`associate_pairs()` fit and does not estimate latent-normal `eta`.

For row \(i\),

\[
\begin{bmatrix}Y_{1i}\\Y_{2i}\end{bmatrix}
\sim t_{2,\nu}\left(
\begin{bmatrix}\mu_{1i}\\\mu_{2i}\end{bmatrix},
D_iR(\rho_{12})D_i
\right),
\qquad
D_i=\operatorname{diag}(\sigma_1,\sigma_2).
\]

`rho12` is the scatter/residual correlation. Because \(\nu>2\), it also equals
the ordinary residual correlation, but finite-\(\nu\) components remain
dependent when `rho12 = 0`.

## First public grammar

```r
drmTMB(
  bf(
    mu1 = y1 ~ x,
    mu2 = y2 ~ z,
    sigma1 = ~ 1,
    sigma2 = ~ 1,
    nu = ~ 1,
    rho12 = ~ 1
  ),
  family = biv_student(),
  data = dat
)
```

The first slice permits fixed effects in `mu1` and `mu2`. `sigma1`, `sigma2`,
the one shared `nu`, and `rho12` are intercept-only. The parameter transforms
are

\[
\sigma_j=\exp(\eta_{\sigma_j}),\qquad
\nu=2+\exp(\eta_\nu),\qquad
\rho_{12}=0.999999\tanh(\eta_\rho).
\]

`sigma1` and `sigma2` are Student-t scales. Marginal standard deviations are
\(\sigma_j\sqrt{\nu/(\nu-2)}\).

## Likelihood

Let \(z_{ji}=(y_{ji}-\mu_{ji})/\sigma_j\) and

\[
q_i=\frac{z_{1i}^2-2\rho_{12}z_{1i}z_{2i}+z_{2i}^2}
          {1-\rho_{12}^2}.
\]

Then

\[
\begin{aligned}
\log f_i={}&
\log\Gamma\left(\frac{\nu+2}{2}\right)
-\log\Gamma\left(\frac{\nu}{2}\right)
-\log(\nu\pi)
-\log\sigma_1-\log\sigma_2\\
&-\frac12\log(1-\rho_{12}^2)
-\frac{\nu+2}{2}\log\left(1+\frac{q_i}{\nu}\right).
\end{aligned}
\]

## Methods

- `fitted()` returns a two-column matrix of marginal means `mu1` and `mu2`.
- `predict(..., dpar=)` exposes `mu1`, `mu2`, `sigma1`, `sigma2`, shared `nu`,
  and `rho12` on their declared response scales.
- `sigma()` returns the two Student-t scales, not standard deviations.
- `rho12()` returns the scalar/vector scatter correlation.
- `simulate()` uses one shared chi-squared draw per response pair.
- Confidence-interval and profile entry points reject explicitly.

## Rejected first-slice surface

Reject `nu1`/`nu2`, predictors on `sigma1`, `sigma2`, `nu`, or `rho12`, random
or structured effects, partial/missing pairs, non-finite responses, explicit
weights, offsets, `meta_V()`, `mi()`, REML, penalties, Julia, intervals, and
coverage.

## Symbolic alignment

| Symbol | R keyword | DGP draw | Recovery extractor | First-slice truth |
| --- | --- | --- | --- | --- |
| \(\mu_{1i}\) | `mu1` | fixed predictor | `predict(..., dpar="mu1")` | fixed effects |
| \(\mu_{2i}\) | `mu2` | fixed predictor | `predict(..., dpar="mu2")` | fixed effects |
| \(\sigma_1\) | `sigma1` | positive scale | `sigma()` / `predict()` | intercept-only |
| \(\sigma_2\) | `sigma2` | positive scale | `sigma()` / `predict()` | intercept-only |
| \(\nu\) | `nu` | shared chi-square df | `predict(..., dpar="nu")` | shared, intercept-only |
| \(\rho_{12}\) | `rho12` | Gaussian scatter correlation | `rho12()` | intercept-only |
| \(Q_i\) | internal | one `rchisq()` per pair | simulator test | shared within pair |

## Validation ceiling

This slice can establish only source-level likelihood correctness and method
semantics. No smoke, recovery, interval, coverage, capability, Julia, or CRAN
claim follows.
