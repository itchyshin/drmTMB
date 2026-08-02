# C17-C2 symbolic alignment: ordinary `coi` random slope

## Claim

This slice adds one complete-response, ML-Laplace, point-fit-recovery
zero-one-beta model while retaining the C17-C1 intercept:

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ x + (0 + x | id))
```

The fixed and random `coi` slope must use the same untransformed raw symbol.
The slice does not admit a mismatch, transformation, intercept-plus-slope or
correlated term, label, multiple term, structured provider, simultaneous atom
or other random component, or missing response. Profiles, intervals, coverage,
`inference_ready_with_caveats`, and `supported` remain unavailable.

## Symbolic model

For group index `g(i)`, let

\[
\begin{aligned}
\eta_{\mu,i} &= X_{\mu,i}\beta_\mu, \\
\mu_i^{raw} &= \operatorname{logit}^{-1}(\eta_{\mu,i}), \\
\mu_i &= \epsilon_\mu+(1-2\epsilon_\mu)\mu_i^{raw},
  \qquad \epsilon_\mu=10^{-12}, \\
\widetilde\ell_{\sigma,i} &=
  \mathcal C(X_{\sigma,i}\beta_\sigma),
  \qquad \sigma_i=\exp(\widetilde\ell_{\sigma,i}), \\
\eta_{zoi,i} &= X_{zoi,i}\beta_{zoi},
  \qquad zoi_i=\operatorname{logit}^{-1}(\eta_{zoi,i}), \\
\eta_{coi,i} &= \beta_{coi,0}+\beta_{coi,1}x_i
  + \exp(\ell_{coi})u_{coi,g(i)}x_i, \\
coi_i &= \operatorname{logit}^{-1}(\eta_{coi,i}), \\
\ell_{coi} &\equiv \mathtt{log\_sd\_coi}, \\
u_{coi,g} &\stackrel{\mathrm{iid}}{\sim} N(0,1).
\end{aligned}
\]

Here \(\mathcal C\) is the exact `drm_softclamp_log_sigma` transformation when
the runtime log-`sigma` guard is enabled and the identity otherwise. Thus the
symbolic scale uses the same post-guard `log_sigma` value as model type 15 in
TMB rather than an unguarded shorthand.

The fixed slope `beta_coi,1 x_i` must match `(0 + x | id)`; the ordinary fixed
intercept `beta_coi,0` remains present. In carrier form,

\[
\operatorname{logit}(coi_i)=X_{coi,i}\beta_{coi}
+Z_{coi,i}\operatorname{diag}\{\exp(\ell_{coi})\}u_{coi},
\qquad u_{coi}\sim N(0,I),
\]

with exactly one `x` column in `Z_coi`. The fitted random-slope SD is
`sd_coi = exp(log_sd_coi)`. The non-centred standard-normal latent variable
carries no Jacobian term.

## Likelihood alignment

Define the interior precision and the exact guarded beta shapes by

\[
\phi_i=\exp(-2\widetilde\ell_{\sigma,i}),\qquad
\alpha_i=\max(\mu_i\phi_i,10^{-8}),\qquad
\beta_i=\max((1-\mu_i)\phi_i,10^{-8}).
\]

The `max` notation is the mathematical equivalent of TMB's
`CppAD::CondExpLt` shape floors. The per-observation log likelihood is

\[
\log p(y_i)=
\begin{cases}
\log(zoi_i)+\log(1-coi_i), & y_i=0,\\
\log(zoi_i)+\log(coi_i), & y_i=1,\\
\log(1-zoi_i)+\log f_{\mathrm{Beta}}(y_i;\alpha_i,\beta_i),
  & 0<y_i<1.
\end{cases}
\]

`eta_coi` receives the row-specific random-slope contribution before the
stable boundary calculations. In code, the four boundary log-probabilities use
the corresponding `logspace_add` forms, which are algebraically the log terms
shown above. Interior likelihood terms remain independent of `coi`.

For complete responses with observation weights \(w_i\), the exact objective
contribution for this carrier is

\[
\operatorname{NLL}
=-\sum_i w_i\log p(y_i\mid u_{coi})
-\sum_g\log\varphi(u_{coi,g};0,1),
\]

where \(\varphi(\cdot;0,1)\) is the normalized standard-normal density. The
second term is exactly
`-sum(dnorm(u_coi, 0, 1, log = TRUE))`; the non-centred carrier requires no
Jacobian.

## R-to-TMB mapping

| Layer | Exact C17-C2 representation |
| --- | --- |
| Parsed term | one unlabelled ordinary slope `(0 + x | id)` in `coi` |
| Fixed guard | `coi` fixed RHS is the same raw symbol `x` |
| Fixed matrix | existing `X_coi` / C++ `X_nu` |
| Random structure | existing `spec$random$coi`, one term and group index |
| TMB data | existing `n_coi_re_terms`, `coi_re_index`, `coi_re_value`, `coi_re_term` |
| TMB parameters | existing `u_coi`, `log_sd_coi` |
| Laplace integration | include `u_coi` in `random_names` only when live |
| Reporting | existing `u_coi`, `log_sd_coi`, `sd_coi_re`, and `eta_coi` |
| Extractors | `sdpars()` and `ranef()` label `(0 + x | id)` under `coi` |
| Prediction | conditional predictions multiply the fitted group mode by raw `x` |
| Profile discovery | direct SD target remains `point_fit_only_zero_one_beta_coi_q1` |

Every other model type retains inert zero-length/default `coi` fields, and the
C17-C1 intercept uses the same carrier without a shared atom-effect block.

## Required negative neighbours

The admission rejects `coi ~ z + (0 + x | id)`, `coi ~ log(x) +
(0 + x | id)`, `coi ~ x + (1 + x | id)`, labels, multiple random terms,
simultaneous `mu`, `sigma`, or `zoi` random effects, structured effects, and
missing responses. Errors name the exact intercept or raw-symbol slope forms
that are available. No q2-plus or inference claim follows from this q1 slope.
