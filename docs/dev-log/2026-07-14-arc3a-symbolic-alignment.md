# Arc 3a symbolic alignment: positive-continuous structured `mu`

**Status:** pre-implementation contract, derived from `main` at `6b7c8f83` on
2026-07-14. **Scope:** native TMB, univariate ML, one unlabelled q1 structured
random intercept in `mu` for Gamma–`phylo()`, lognormal–`phylo()`, and
lognormal–`relmat()`. Existing Gamma–`relmat()` is the comparator. This document
does not authorize slopes, a structured `sigma`, multiple dependence fields,
q2+, REML, intervals, coverage, bivariate models, or Julia parity.

## 1. Symbols and provider covariance

For observation \(i\), let \(h(i)\) index the observed structured level, let
\(x_i^\top\) and \(w_i^\top\) be the fixed-effect rows for `mu` and `sigma`, and
let \(b\) be one structured latent intercept field. The common predictor is

\[
\eta_{\mu i}=x_i^\top\beta_\mu+b_{h(i)},\qquad
\eta_{\sigma i}=w_i^\top\beta_\sigma,\qquad
\tau=\exp(\lambda),\quad \lambda=\texttt{log_sd_phylo}.
\]

The q1 design value is exactly one for every row. There is one \(\tau\), no
among-coefficient correlation, and no latent term in `sigma`.

The provider defines the base precision \(Q\):

- `phylo(1 | species, tree = tree)` builds the augmented tree precision
  \(Q_T\). The implementation normalizes an ultrametric tree by its root-to-tip
  height, so the marginal tip covariance is a correlation matrix
  \(C_T\) with unit diagonal. Thus the observed tip field has
  \(b_{\mathrm{tip}}\sim N(0,\tau^2 C_T)\), and \(\tau\) is the marginal tip SD
  on the relevant linear-predictor scale. The tree normalization and augmented
  precision are explicit in `R/phylo-utils.R:210-244` and
  `R/phylo-utils.R:247-338`.
- `relmat(1 | id, K = K)` uses \(Q_K=K^{-1}\), while
  `relmat(1 | id, Q = Q)` uses the supplied precision. Therefore
  \(b\sim N(0,\tau^2K)\) or \(N(0,\tau^2Q^{-1})\), respectively. The matrix is
  aligned by dimnames and is not rescaled to unit diagonal
  (`R/phylo-utils.R:344-412`). Consequently, the reported \(\tau\) is a
  covariance multiplier; it equals every level's marginal latent SD only when
  `diag(K) == 1` (or `diag(solve(Q)) == 1`). Recovery must either use a
  correlation-scale matrix or name \(\tau\) as the multiplier, not as a generic
  per-level marginal SD.

For either provider the TMB prior contribution for a field of length \(m\) is

\[
-\log p(b\mid\tau,Q)=\frac12\left[
m\log(2\pi)+2m\log\tau-\log|Q|+\tau^{-2}b^\top Qb
\right].
\]

This is the prior currently used by the Gamma structured block
(`src/drmTMB.cpp:2568-2610`). TMB integrates `u_phylo` by Laplace because the R
spec places it in `random_names` (`R/drmTMB.R:4373-4387`). Arc 3a is ML only:
fixed effects and \(\lambda\) are optimized, and only \(b\) is integrated.

## 2. Family-specific likelihoods and units

### 2.1 Lognormal

The public family contract uses an identity link for `mu` and a log link for
`sigma` (`R/family.R:126-152`):

\[
\log Y_i\mid b \sim N(\eta_{\mu i},\sigma_i^2),\qquad
\sigma_i=\exp(\eta_{\sigma i}).
\]

On the original positive response scale,

\[
\log f(y_i\mid b)=
\log\phi\{\log(y_i);\eta_{\mu i},\sigma_i\}-\log(y_i),
\qquad
E(Y_i\mid b)=\exp(\eta_{\mu i}+\sigma_i^2/2).
\]

Therefore \(\beta_\mu\), \(b\), and \(\tau\) are all in log-response units;
\(\sigma\) is the conditional SD of `log(y)`, not an original-response SD.
The current C++ density has the correct Jacobian but no structured field
(`src/drmTMB.cpp:2487-2546`). The R builder likewise leaves
`structured$phylo_mu` empty and does not put `u_phylo` in `random_names`
(`R/drmTMB.R:4026-4039`, `R/drmTMB.R:4116-4160`). This is a real engine and
specification addition, not a parser-gate relaxation.

### 2.2 Gamma mean–CV

The native Gamma contract is

\[
\mu_i=\exp(\eta_{\mu i}),\qquad
\sigma_i=\exp(\eta_{\sigma i}),\qquad
a_i=\sigma_i^{-2},\qquad
s_i=\mu_i\sigma_i^2,
\]

\[
Y_i\mid b\sim\operatorname{Gamma}(\text{shape}=a_i,
\text{scale}=s_i),\qquad
E(Y_i\mid b)=\mu_i,\quad
\operatorname{Var}(Y_i\mid b)=\mu_i^2\sigma_i^2.
\]

Thus `sigma` is the conditional coefficient of variation and the conditional
response SD is \(\mu_i\sigma_i\). The structured field \(b\), its scale
\(\tau\), and \(\beta_\mu\) are on the log-mean scale. The current C++ branch
adds the field to `eta_mu`, exponentiates afterward, and uses exactly the
shape/scale conversion above (`src/drmTMB.cpp:2548-2635`). The R builder already
marshals one Gamma–`relmat()` term through the generic structured object and
includes `u_phylo` in the Laplace block (`R/drmTMB.R:4249-4251`,
`R/drmTMB.R:4343-4387`). Gamma–`phylo()` therefore reuses the existing Gamma
likelihood block but requires provider extraction, provider-specific admission,
and regression tests.

## 3. Public syntax contract

Only these new formulas are in Arc 3a:

```r
# Gamma x phylo
drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = stats::Gamma(link = "log"),
  data = dat
)

# lognormal x phylo
drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ z),
  family = lognormal(),
  data = dat
)

# lognormal x relmat covariance or precision
drmTMB(
  bf(y ~ x + relmat(1 | id, K = K), sigma ~ z),
  family = lognormal(),
  data = dat
)
drmTMB(
  bf(y ~ x + relmat(1 | id, Q = Q), sigma ~ z),
  family = lognormal(),
  data = dat
)
```

The comparator is the q1 subset of the existing Gamma–`relmat()` route. Its
current validator also admits one independent structured slope
(`R/drmTMB.R:8993-9023`); Arc 3a must not copy that broader rule to the three
new cells. A new `phylo()` route must remain intercept-only, and the new
lognormal routes must remain intercept-only. Labelled terms, slope-only terms,
`1 + x`, multiple structured terms, structured terms in `sigma`, and REML must
continue to fail before fitting.

The claimed recovery domain contains fixed effects plus one structured field.
An ordinary `mu` or `sigma` random effect combined with a new structured field
is outside this evidence domain and must not be newly admitted accidentally.
The pre-existing Gamma–`relmat()` parser is broader and should be preserved as
existing behavior, but its broader combinations cannot be used as Arc 3a
evidence.

## 4. Symbol-to-implementation alignment

| Symbol in prose | Keyword / internal object | DGP draw | TMB parameter and use | Recovery extractor | Truth value and units |
|---|---|---|---|---|---|
| \(\beta_\mu\) | fixed terms in the `mu` formula; `X_mu` | fixed vector; compute `X_mu %*% beta_mu` | `beta_mu`; identity predictor for lognormal, log-mean predictor for Gamma | `coef(fit)$mu` / `fit$coefficients$mu` | declared coefficient vector; log-response units for lognormal, log-mean units for Gamma |
| \(\beta_\sigma\) | `sigma ~ z`; `X_sigma` | fixed vector; `sigma <- exp(X_sigma %*% beta_sigma)` | `beta_sigma`, then `exp(log_sigma)` | `coef(fit)$sigma`; `sigma(fit)` after inverse link | coefficient truth is log-sdlog for lognormal and log-CV for Gamma; response-scale truth is sdlog or CV |
| \(C_T\) | `phylo(1 | species, tree = tree)`; `structured$phylo_mu$precision` | build normalized tree tip correlation in formula level order | `Q_phylo`, `log_det_Q_phylo`, `phylo_mu_node_index`, q1 all-one `phylo_mu_value` | `structured_effects(fit)` metadata; no fitted covariance parameter | fixed known correlation; not estimated |
| \(K\) or \(Q\) | `relmat(1 | id, K = K)` / `Q = Q` | fixed positive-definite named matrix aligned to `id` | supplied or inverted into `Q_phylo`; known `log_det_Q_phylo` | `structured_effects(fit)` metadata | fixed known covariance/precision; not estimated |
| \(\lambda=\log\tau\) | one unlabelled q1 structured `mu` term | fixed scalar; draw field using `tau <- exp(lambda)` | `log_sd_phylo`; contributes `2m*lambda` and `exp(-2*lambda) b'Qb` to NLL | internal `parList()$log_sd_phylo`; public profile naming remains out of scope | declared log structured-scale truth |
| \(\tau\) | same structured term | `exp(lambda)` | `sd_phylo = exp(log_sd_phylo)` is REPORT/ADREPORT | `fit$sdpars$mu[["phylo(1 | species)"]]` or `[["relmat(1 | id)"]]` | phylo marginal tip SD; relmat covariance multiplier (marginal SD only for unit-diagonal base covariance) |
| \(b\) | `u_phylo`; public block `phylo_mu` or `relmat_mu` | phylo: `MVN(0, tau^2 C_T)` at tips; relmat: `MVN(0, tau^2 K)` or `MVN(0, tau^2 solve(Q))` | `u_phylo`, declared random; row contribution selected by `phylo_mu_node_index` | `ranef(fit, "phylo_mu")` / `ranef(fit, "relmat_mu")`; `$values` and q1 `$terms` | conditional-mode field in the same units as `eta_mu`, not a standardized N(0,1) latent |
| \(\eta_{\mu i}\) | fixed `mu` predictor plus structured contribution | `X_mu %*% beta_mu + b[group]` | `mu` for model type 4; `eta_mu` for model type 5 | `predict(fit, dpar = "mu", type = "link")` on training data | lognormal log-location; Gamma log-mean |
| \(\mu_i\) | inverse `mu` link | lognormal: same as \(\eta_{\mu i}\); Gamma: `exp(eta_mu)` | reported `mu` vector | `predict(fit, dpar = "mu")` | lognormal meanlog; Gamma conditional response mean |
| \(E(Y_i\mid b)\) | `fitted(fit)` | lognormal: `exp(eta_mu + sigma^2/2)`; Gamma: `mu` | derived in R | `fitted(fit)` | arithmetic response mean conditional on fitted field |
| \(Y_i\) | positive response | `rlnorm(meanlog=eta_mu, sdlog=sigma)` or `rgamma(shape=1/sigma^2, scale=mu*sigma^2)` | original-scale family density | retained simulation row plus fit diagnostics | every attempted replicate, including failures, remains in denominator |

The density conversion is independently exposed in `R/family-dpq.R:412-477`.
The current SD extractor already places univariate non-Gaussian structured
scales in the endpoint-specific `sdpars$mu` block (`R/drmTMB.R:18824-18874`),
and the random-effect extractor already selects provider-specific block names
(`R/drmTMB.R:19181-19235`). These generic extractors should be reused, not
duplicated.

## 5. Required implementation trace

The implementation is aligned only if all of the following hold.

1. **Extraction and validation.** Each builder removes exactly one allowed
   `phylo()` or `relmat()` term before `drm_reject_phase1_terms()`, validates
   unlabelled intercept-only q1 syntax for the new cell, includes provider/group
   variables in missing-row filtering, and calls
   `build_structured_mu_structure()`. Gamma's existing one-slope `relmat()`
   validator remains provider-specific rather than becoming the new common
   rule.
2. **Spec and starts.** `structured$phylo_mu` holds the built field;
   `u_phylo` and `log_sd_phylo` starts have lengths \(m\) and one;
   `lognormal_ls_start()` derives its phylogenetic scale start from log-response
   residuals; and `u_phylo` appears in `random_names`. The existing
   `lognormal_ls_map()` already accepts a structured object but the builder must
   pass it (`R/drmTMB.R:15262-15325`).
3. **TMB data.** Both model types marshal `has_phylo_mu`, the observation-node
   index, the q1 all-one design, endpoint code `mu`, `Q_phylo`, and
   `log_det_Q_phylo`. The current lognormal data branch hard-codes the field off,
   whereas Gamma already marshals it (`R/drmTMB.R:17451-17580`).
4. **Likelihood.** Model type 4 adds the same q1 contribution and normalized
   Gaussian precision prior as model type 5 before evaluating the lognormal
   density. It must not add the field to `log_sigma`. Model type 5 is reused,
   not forked.
5. **Conditional prediction.** Training-data `predict()` and `fitted()` must
   include \(b_{h(i)}\). At baseline the gate in `predict.drmTMB()` is correct
   structurally (`R/methods.R:2699-2725`), but
   `has_structured_mu_effect()` and `has_phylo_mu_effect()` omit both `gamma`
   and `lognormal` from their model-type allowlists
   (`R/methods.R:5264-5282`). This already causes the Gamma–`relmat()`
   comparator's conditional prediction to omit its fitted field. Arc 3a must
   repair and directly test this; finite `ranef()` alone is insufficient.
6. **Extraction.** The fit exposes exactly one SD under `sdpars$mu`, one random
   block named `phylo_mu` or `relmat_mu`, correct structured metadata, and no
   structured `sigma` or correlation parameter. `u_phylo` values are already
   scaled field values, so neither simulation nor recovery may multiply
   `ranef()` by \(\tau\) a second time.

## 6. Invariants and negative controls

- **Family scale:** never describe lognormal `mu` as the arithmetic response
  mean or Gamma `sigma` as a residual SD.
- **Provider scale:** `phylo()` uses a unit-diagonal tip correlation, but an
  arbitrary `relmat()` matrix is not normalized. Report and recover the correct
  estimand.
- **One field:** q1 means one structured coefficient and one structured-scale
  parameter. It does not mean that a labelled q2 block has been reduced to one
  reported row.
- **One endpoint:** `phylo_mu_dpar` must encode only `mu`; no contribution may
  enter `log_sigma`.
- **No double scaling:** `u_phylo` is the field \(b\), unlike ordinary
  standardized `u_mu`; its Gaussian prior contains \(\tau\) directly.
- **No new combinations:** new structured routes must reject slopes, labels,
  multiple structured terms, structured `sigma`, and combined unvalidated
  random-effect configurations.
- **Representation parity:** lognormal–`relmat()` K and Q fits use
  `Q = solve(K)` and must agree within a predeclared numerical tolerance on
  objective, fixed effects, \(\tau\), and conditional field after level
  alignment.
- **Comparator parity:** Gamma–`relmat()` conditional `predict(type="link")`
  must equal `X_mu %*% beta_mu + phylo_mu_contribution`; the new three cells
  must satisfy the same identity.
- **Claim ceiling:** successful point recovery promotes only the exact q1 ML
  cells to `point_fit_recovery`. It gives no interval, coverage, REML,
  `inference_ready`, or `supported` evidence.

## 7. Recovery DGP contract

For each provider, fix and record `X_mu`, `X_sigma`, the ordered group levels,
the tree or matrix, \(\beta_\mu\), \(\beta_\sigma\), and \(\tau\). Then:

1. Draw one latent field from the provider covariance in exactly the formula's
   level order. For tree simulations, draw the tip field from the normalized tip
   correlation; the fitted augmented-node representation has the same tip
   marginal law. For K/Q parity, reuse the same K-based draw and fit both
   representations.
2. Form \(\eta_\mu=X_\mu\beta_\mu+b_h\) and
   \(\sigma=\exp(X_\sigma\beta_\sigma)\).
3. Draw `rlnorm(meanlog = eta_mu, sdlog = sigma)` or
   `rgamma(shape = 1 / sigma^2, scale = exp(eta_mu) * sigma^2)`.
4. Fit the exact formula above under ML. Store the seed, provider
   representation, all truth values, all estimates, optimizer result,
   `pdHess`, boundary flags, and failure stage for every attempted replicate.
5. Recover \(\beta_\mu\), \(\beta_\sigma\), and \(\tau\) term-by-term. Assess
   conditional fields separately; they are prediction targets, not fixed
   simulation parameters with unbiased per-level estimators.

Thresholds and the information ladder belong in the Fisher-approved campaign
manifest before the remote run. This document fixes estimands and units, not
post-hoc numerical pass thresholds.

## 8. Ambiguities and blockers found

1. **Existing Gamma prediction defect (blocking):** Gamma–`relmat()` is fitted
   and extracted, but the generic structured-effect allowlist excludes Gamma,
   so conditional `predict()`/`fitted()` omits its field. This must be repaired
   and regression-tested before the comparator can certify the new routes.
2. **Validator asymmetry (blocking if generalized):** the existing Gamma
   `relmat()` validator admits intercept plus one slope. It cannot be renamed
   into a provider-generic positive-continuous validator without a separate
   intercept-only rule for the new cells.
3. **Relmat estimand language (blocking for evidence prose):** unless the
   campaign fixes a unit-diagonal K, \(\tau\) is not a common marginal SD.
   Campaign columns and reports must say `structured_scale`/covariance
   multiplier or report the implied level SDs explicitly.
4. **Newdata behavior (deferred, not blocking):** current structured
   contributions are added only for training-data predictions (`newdata =
   NULL`). Arc 3a must not claim new-level or structured `newdata` prediction.
5. **Diagnostics (required audit):** adding these families to
   `has_phylo_mu_effect()` may activate phylogenetic diagnostics originally
   written for Gaussian/count routes. Each activated check must be reviewed for
   family-scale validity; a generic structured-effect predicate may be safer
   than broadening every phylogenetic diagnostic blindly.

## 9. Verdict

**READY WITH REQUIRED CORRECTIONS.** The symbolic model, public q1 syntax, DGP,
TMB parameterization, extractor targets, and truth units align exactly. Gamma's
existing TMB structured prior is reusable. Coding may proceed only while
preserving the invariants above, with the existing Gamma conditional-prediction
defect treated as part of the Arc 3a integration gate. No point-fit or recovery
claim is ready until the new routes pass the term-by-term extraction identities
and the retained-denominator campaign.
