# Arc 6.4 prior-art and comparator report

Notebook: `7b163938-a89f-4cb6-a90b-5bcb56d38327`

## Decision

Arc 6.4 should use the ordinary elliptical bivariate Student-t distribution
with one shared degrees-of-freedom parameter. This is a direct joint
likelihood, not a frozen-margin `associate_pairs()` model.

For dimension two, location vector \(\mu\), and scale matrix \(\Sigma\),

\[
f(y)=
\frac{\Gamma((\nu+2)/2)}
     {\Gamma(\nu/2)\nu\pi|\Sigma|^{1/2}}
\left[
  1+\frac{(y-\mu)^\mathsf{T}\Sigma^{-1}(y-\mu)}{\nu}
\right]^{-(\nu+2)/2}.
\]

The equivalent simulator draws one \(Z\sim N_2(0,R)\) and one shared
\(Q\sim\chi^2_\nu\) for each response pair, then returns

\[
Y=\mu+\operatorname{diag}(\sigma_1,\sigma_2)Z\sqrt{\nu/Q}.
\]

The shared mixing draw is essential. At finite \(\nu\), a diagonal scatter
matrix gives zero correlation but not independence. Product-margin
factorisation is therefore not a valid `rho12 = 0` test. Independence is
recovered only in the Gaussian limit as \(\nu\rightarrow\infty\).

The diagonal elements of \(\Sigma\) are squared Student-t scales, not marginal
variances. For \(\nu>2\),

\[
\operatorname{Var}(Y_j)=\sigma_j^2\frac{\nu}{\nu-2}.
\]

This matches drmTMB's existing univariate `student()` meaning.

## Comparator

The independent numerical comparator is `mvtnorm::dmvt(..., type =
"shifted")`. It uses the standard shifted multivariate-t density with a scale
matrix and shared degrees of freedom. The package implementation must also be
checked against a separately written closed-form R oracle so the comparator is
not the only verifier.

## Curated sources

- Genz, Bretz, Miwa, Mi et al. `mvtnorm`: multivariate normal and t
  distributions, density and probability implementation:
  <https://cran.r-project.org/web/packages/mvtnorm/mvtnorm.pdf>
- Hothorn, Bretz, and Genz, *On multivariate t and Gauss probabilities in R*:
  <https://cran.r-project.org/web/packages/mvtnorm/vignettes/MVT_Rnews.pdf>
- Hintz, Hofert, and Lemieux, *Normal variance mixtures: distribution, density
  and parameter estimation*: <https://arxiv.org/abs/1911.03017>
- Ding, *On the conditional distribution of the multivariate t distribution*:
  <https://arxiv.org/abs/1604.00561>

## Evidence boundary

The sources establish the mathematical parameterisation, scale-mixture
construction, zero-correlation dependence, Gaussian limit, and comparator.
They do not establish drmTMB recovery, interval calibration, or a capability
tier. Those remain package-specific evidence tasks.
