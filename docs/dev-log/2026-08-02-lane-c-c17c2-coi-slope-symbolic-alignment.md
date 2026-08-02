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
\operatorname{logit}(\mu_i) &= X_{\mu,i}\beta_\mu, \\
\log(\sigma_i) &= X_{\sigma,i}\beta_\sigma, \\
\operatorname{logit}(zoi_i) &= X_{zoi,i}\beta_{zoi}, \\
\operatorname{logit}(coi_i) &= \beta_{coi,0}+\beta_{coi,1}x_i
  + \exp(\ell_{coi})u_{coi,g(i)}x_i, \\
u_{coi,g} &\stackrel{\mathrm{iid}}{\sim} N(0,1).
\end{aligned}
\]

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

The per-observation log likelihood remains

\[
\log p(y_i)=
\begin{cases}
\log(zoi_i)+\log(1-coi_i), & y_i=0,\\
\log(zoi_i)+\log(coi_i), & y_i=1,\\
\log(1-zoi_i)+\log f_{\mathrm{Beta}}(y_i;\mu_i,\sigma_i),
  & 0<y_i<1.
\end{cases}
\]

`eta_coi` receives the row-specific random-slope contribution before the
stable boundary calculations. Interior likelihood terms remain independent of
`coi`. The objective contains the normalized latent penalty
`-sum(dnorm(u_coi, 0, 1, log = TRUE))`.

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
