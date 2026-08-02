# C17-C1 symbolic alignment: ordinary `coi` random intercept

## Claim

This slice admits one complete-response, ML-Laplace, point-fit-recovery
zero-one-beta model:

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

It does not admit a `coi` slope, more than one random term, a labelled or
correlated term, a structured provider, another simultaneous random-effect
component, or a missing response. Profiles, intervals, coverage,
`inference_ready_with_caveats`, and `supported` remain unavailable.

## Symbolic model

For group index `g(i)`, let

\[
\begin{aligned}
\operatorname{logit}(\mu_i) &= X_{\mu,i}\beta_\mu, \\
\log(\sigma_i) &= X_{\sigma,i}\beta_\sigma, \\
\operatorname{logit}(zoi_i) &= X_{zoi,i}\beta_{zoi}, \\
\operatorname{logit}(coi_i) &= X_{coi,i}\beta_{coi}
  + \exp(\ell_{coi})u_{coi,g(i)}, \\
u_{coi,g} &\stackrel{\mathrm{iid}}{\sim} N(0,1).
\end{aligned}
\]

Equivalently, the carrier is

\[
\operatorname{logit}(coi_i)=X_{coi,i}\beta_{coi}
+Z_{coi,i}\operatorname{diag}\{\exp(\ell_{coi})\}u_{coi},
\qquad u_{coi}\sim N(0,I),
\]

with exactly one intercept column in `Z_coi` for C17-C1. The fitted random
effect SD is `sd_coi = exp(log_sd_coi)`. The non-centred standard-normal latent
variable carries no Jacobian term.

## Likelihood alignment

The per-observation log likelihood is

\[
\log p(y_i)=
\begin{cases}
\log(zoi_i)+\log(1-coi_i), & y_i=0,\\
\log(zoi_i)+\log(coi_i), & y_i=1,\\
\log(1-zoi_i)+\log f_{\mathrm{Beta}}(y_i;\mu_i,\sigma_i),
  & 0<y_i<1.
\end{cases}
\]

Therefore `eta_coi` receives the random contribution before the stable
`log_coi` and `log_one_minus_coi` calculations. Interior likelihood terms are
independent of `coi`. The objective additionally contains
`-sum(dnorm(u_coi, 0, 1, log = TRUE))`.

## R-to-TMB mapping

| Layer | Exact C17-C1 representation |
| --- | --- |
| Parsed term | one unlabelled ordinary intercept `(1 | id)` in `coi` |
| Fixed matrix | existing `X_coi` / C++ `X_nu` |
| Random structure | `spec$random$coi` with one term and group index |
| TMB data | `n_coi_re_terms`, `coi_re_index`, `coi_re_value`, `coi_re_term` |
| TMB parameters | `u_coi`, `log_sd_coi` |
| Laplace integration | include `u_coi` in `random_names` only when live |
| Reporting | `u_coi`, `log_sd_coi`, `sd_coi_re`, and the existing `eta_coi` |
| Extractors | `sdpars()` and `ranef()` identify the `coi` component |
| Prediction | conditional predictions add the fitted `coi` latent contribution |
| Profile discovery | expose the direct SD target but mark it `point_fit_only_zero_one_beta_coi_q1` |

Every other model type supplies inert zero-length/default `coi` fields so the
shared TMB signature remains stable.

## Required negative neighbours

The admission must reject slopes in this milestone, transformed predictors,
multiple terms, labels/covariance, correlated `(1 + x | id)` terms, structured
providers, missing responses, and any simultaneous `mu`, `sigma`, or `zoi`
random effect. Each error must state the exact admitted intercept form and a
useful alternative where one exists.
