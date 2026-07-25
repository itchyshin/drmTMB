# Arc 6.2 research report — Gaussian × ordinary NB2 frozen-margin association

## Question and corpus

This report asks whether a two-response Gaussian margin plus ordinary NB2
margin can use a latent-normal copula while retaining the separately fitted
margins, and what likelihood must be evaluated. The corpus excluded drmTMB,
DRM.jl, drafts, and other own work from the prior-art conclusion.

NotebookLM notebook: `243afe20-7571-4642-aa28-bc7fc85f97ce`.
The source check retained the readable third-party sources below; PubMed and
PMC pages that contained reCAPTCHA rather than article text, and failed
publisher imports, were excluded from load-bearing claims.
The companion NotebookLM briefing, audio, and video artifacts completed as
`b4b144be-c859-4863-b45f-4958cd3d87b0`,
`b26de521-a351-40e7-9319-3647d2057ed3`, and
`e328f69f-99c2-4480-be63-ff5c824d04e8` respectively.

- de Leon and Wu (2011), [Copula-based regression models for a bivariate mixed
  discrete and continuous outcome](https://doi.org/10.1002/sim.4087).
- Masarotto and Varin (2017), [Gaussian Copula Regression in
  R](https://doi.org/10.18637/jss.v077.i08).
- Nikoloulopoulos (2013), [On the estimation of normal copula discrete
  regression models using the continuous extension and simulated
  likelihood](https://arxiv.org/abs/1304.0905).
- Christoffersen et al. (2021), [Asymptotically Exact and Fast Gaussian Copula
  Models for Imputation of Mixed Data
  Types](https://proceedings.mlr.press/v157/christoffersen21a.html).

## Findings that govern Arc 6.2

Mixed discrete–continuous Gaussian-copula regression is established prior art:
the margins can be separately meaningful while the copula specifies a
latent-scale association (de Leon and Wu, 2011). This supports the
margin-first architecture, but it does **not** make this package's frozen-margin
second-stage estimator a joint MLE. In Arc 6.2, `eta` is an IFM-style,
conditional, point-only association given the estimated Gaussian and NB2
margins. It is neither `rho12` nor an observed-scale correlation, and the
second-stage Hessian is not an uncertainty claim.

For the discrete margin, the likelihood must use its exact CDF jump. Let
\(F_i\) be the fitted ordinary-NB2 CDF and \(z_i\) the standardized Gaussian
response. With \(s=\sqrt{1-\eta^2}\), the row contribution is

\[
f_G(y_{Gi})\left[
\Phi\!\left\{\frac{\Phi^{-1}(F_i(y_{Ni}))-\eta z_i}{s}\right\}-
\Phi\!\left\{\frac{\Phi^{-1}(F_i(y_{Ni}-1))-\eta z_i}{s}\right\}
\right].
\]

Nikoloulopoulos (2013) specifically shows that continuous-extension/jittered
surrogate likelihoods can bias latent correlations and NB2 dispersion
parameters. Arc 6.2 therefore evaluates this CDF interval directly; it does
not use a randomized PIT, jitter, or a continuous-extension shortcut. At
\(\eta=0\), the interval is the NB2 mass, giving the mandatory Gaussian × NB2
product-margin check.

The bivariate setting makes the exact calculation practical: it is a
one-dimensional conditional-normal interval, not a high-dimensional rectangle
problem. The implementation must nevertheless obtain NB2 lower and survival
tails in log form, construct normal thresholds from the smaller tail, and
subtract normal probabilities in log space. A tail collapse, non-finite
endpoint, invalid endpoint order, failed multistart, or weak curvature withholds
the point estimate rather than clipping a probability.

## Comparator boundary

`glmmTMB` is suitable only to verify the NB2 convention
\(\operatorname{Var}(Y)=\mu+\sigma^2\mu^2\) and `size = 1/sigma^2`; it is not
a joint-copula oracle. DRM.jl's mixed-family implementation is a distinct
refitted shared-latent model, so it cannot be an equality comparator or donate
recovery claims. Arc 6.2 instead uses an independent R oracle: NB2 masses
formed independently of the production helper plus direct bivariate-normal
integration over the CDF interval.

## Decision

Proceed only with fixed-effect, complete-pair, ordinary-NB2 margins and
intercept-only `association = ~ 1`. Retain the point-estimate-only ceiling;
association slopes, uncertainty, coverage, zero-modified counts, and
capability promotion remain deferred.
