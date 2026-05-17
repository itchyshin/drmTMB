# emmeans Interface Contract

This note records the design boundary for `emmeans` compatibility in `drmTMB`.
Slices 117-121 built tests and private preflight helpers. Slice 122 adds the
first public bridge, limited to fixed-effect univariate `mu` estimated marginal
means with retained model frames and fixed-effect covariance available.

The official `emmeans` extension API says package support is supplied through
`recover_data.<class>()` and `emm_basis.<class>()` methods. `recover_data()`
reconstructs the data, terms, predictors, and response information for a fitted
object, while `emm_basis()` returns the linear-function matrix, coefficient
vector, covariance matrix, non-estimability basis, and degrees-of-freedom
function used by the reference grid. The same documentation also notes that
multivariate responses require consistent flattening of coefficients, model
matrices, and covariance matrices, and that packages can conditionally register
methods with `.emm_register()` when `emmeans` is installed:
<https://rvlenth.github.io/emmeans/reference/extending-emmeans.html>.

## Reader And Scope

The first reader is an applied user who has already fitted a `drmTMB` model and
wants adjusted means over an explicit reference grid. The second reader is a
package contributor who needs to implement `emmeans` support without confusing
distributional parameters, fitted response means, and residual-scale or
correlation parameters.

The first implementation supports only fitted fixed-effect univariate
models where the target is a single direct distributional parameter with a
linear fixed-effect predictor and a tested inverse link. It starts with
`dpar = "mu"` and link- or response-scale summaries for models whose
reference grid is already covered by `prediction_grid()` and Slice 117 tests.

## Non-Goals

Do not implement all Phase 17 estimands through one `emmeans` method.
Predictions, estimated marginal means, slopes, fitted response means, and
diagnostics must remain separate concepts. Generic contrasts among validated
EMMs can be computed from an `emmGrid`, but a drmTMB-specific contrast helper is
a separate contract.

Do not use `emmeans` to hide unsupported uncertainty. If `TMB::sdreport()` is
unavailable, the fitted object has no usable fixed-effect covariance matrix, or
the requested transformed response needs a delta method that is not implemented,
the method should error before constructing an `emmGrid`.

Do not support bivariate Gaussian, structured-effect, random-effect,
zero-inflated, hurdle, ordinal expected-score, or fitted-response targets in
the first public method. Those paths need additional algebra and tests because
the EMM target may combine multiple linear predictors or require flattened
coefficient blocks.

## Recover Data Contract

`recover_data.drmTMB()` should recover the model frame for the requested target
only. The method should:

- require `object$data` or `object$model$model_frame` to be available;
- reject fits created with insufficient stored data and tell the user to refit
  with stored data;
- use the terms for the requested `dpar`, not every formula in the model;
- preserve factor levels and ordered-factor status from the fitted data;
- carry the requested `dpar`, prediction `type`, and target kind in metadata
  passed to `emm_basis()`;
- preserve `mu` formula offsets when the corresponding reference-grid variables
  are supplied through `emmeans`;
- reject random-effect, structured-effect, and unsupported response
  transformations until each path has its own tests.

This mirrors `prediction_grid()` in spirit, but it should not call
`prediction_grid()` internally until the handling of `at`, `cov.reduce`,
weights, offsets, and factor levels is checked against `emmeans::ref_grid()`.

## Basis Contract

`emm_basis.drmTMB()` should be built from the fixed-effect design matrix for the
requested `dpar`.

For the first fixed-effect `mu` path:

```text
eta = X_mu beta_mu
```

The method should return:

- `X`: the reference-grid model matrix for the requested `dpar`;
- `bhat`: the fixed-effect coefficient vector for that `dpar`, including
  rank-deficient positions if they can occur;
- `V`: the fixed-effect covariance submatrix for that `dpar`;
- `nbasis`: a non-estimability basis, or the `emmeans` no-rank-deficiency
  convention if the model matrix is full rank;
- `dffun` and `dfargs`: asymptotic degrees of freedom unless a later inference
  design provides finite-sample degrees of freedom;
- `misc`: link and response-scale metadata that matches
  `docs/design/19-family-link-contract.md`.

Slice 119 adds the internal bridge for the `X`, `bhat`, `V`, offset, link, and
linear-predictor pieces. `drm_fixed_effect_basis()` is not an `emmeans` method,
but it gives future `emm_basis.drmTMB()` work one tested source for the fitted
linear predictor:

```text
eta = X beta + offset
```

When `covariance = TRUE`, the helper aligns `vcov(fit)` rows back to the
requested `dpar` coefficient names and returns a submatrix whose row and column
names match `bhat`. When covariance is unavailable, it errors with the same
refit guidance as `vcov.drmTMB()`. The first test evidence covers the
implemented count-model `mu` offset path, coefficient-name alignment,
link-scale prediction parity, and covariance opt-in behavior.

Slice 120 adds the internal gate that a future `emm_basis.drmTMB()` method
should call before creating an `emmGrid`. `drm_emmeans_mu_basis()` is private
and dependency-free. It accepts only fixed-effect univariate `mu` targets,
requires fixed-effect covariance, and rejects unsupported `dpar`, missing
covariance, zero-inflated, and random-effect paths with guidance back to
`prediction_grid()` and `predict_parameters()`. The gate is deliberately
narrower than the eventual design so that unsupported paths fail before a
partially valid reference grid can be returned.

Slice 121 adds the private recovery-side preflight for the same first target.
`drm_emmeans_recover_data()` checks the same eligibility gate, then returns the
retained `mu` model frame, terms, predictor names, response name, factor levels,
and row names. If `drm_control(keep_model_frame = FALSE)` was used, the helper
errors and asks for a refit with retained model frames. This mirrors the
requirement that future `recover_data.drmTMB()` support needs fitted-row
metadata, not only coefficients.

Slice 122 wires those preflights into the first public methods.
`recover_data.drmTMB()` delegates to `emmeans::recover_data()` using the
retained `mu` model frame and terms, while `emm_basis.drmTMB()` returns the
fixed-effect basis, covariance, asymptotic degrees of freedom, and link metadata
for the requested reference grid. The methods are conditionally registered with
`emmeans::.emm_register()` from `.onLoad()` when `emmeans` is installed. Tests
compare `emmeans::emmeans()` link-scale results to `predict(type = "link")`,
compare response-scale log-link results to `predict(type = "response")`, and
confirm unsupported paths still fail before an `emmGrid` is returned.

For `type = "link"`, the EMM is on the formula linear-predictor scale. For
`type = "response"`, `emmeans` should apply the same inverse link tested in
Slice 117. The method should not silently switch from distributional-parameter
scale to `fitted()` response mean. For example, lognormal `mu` remains the mean
of `log(y)`, not `E[y]`.

## First Supported Targets

The first public method should be allowed only when all of the following are
true:

- the model is univariate and fixed-effect for the requested `dpar`;
- the requested `dpar` is `mu`;
- `type` is `"link"` or `"response"`;
- the fitted object retained the needed model frame or data;
- `vcov(fit)` or an equivalent fixed-effect covariance submatrix is available;
- the model type is one of Gaussian, Student-t, lognormal, Gamma, beta,
  beta-binomial, Poisson, NB2, or zero-truncated NB2 after targeted tests exist;
- the result is documented as an EMM of the native distributional parameter, not
  necessarily the expected observed response.

Zero-inflated and hurdle models should wait because response-scale fitted means
combine the count component and the zero component. Cumulative-logit models
should wait because the most useful reader-facing target is often expected
ordered score or category probability rather than the latent `mu` alone.
Bivariate Gaussian models should wait because `emmeans` requires consistent
flattening for multivariate responses, and `drmTMB` also has separate
`mu1`/`mu2`, `sigma1`/`sigma2`, and `rho12` targets.

## Error Messages

Unsupported calls should tell the user which current helper to use instead:

- use `prediction_grid()` plus `predict_parameters()` for direct parameter
  predictions;
- use `prediction_grid(..., margin = "empirical")` plus
  `marginal_parameters()` for current plug-in empirical summaries;
- use `profile_targets()` and `confint()` for supported profile-likelihood
  intervals;
- use `corpairs()` and `plot_corpairs()` for fitted correlation rows.

The error should name the unsupported feature, such as random effects,
structured effects, bivariate response, zero-inflation, hurdle response mean,
ordinal expected score, slope, weight rule, or missing covariance matrix.

## Validation Gate

Before exporting an `emmeans` method, add tests that compare the method against
existing `prediction_grid()` and `predict_parameters()` output for every
supported family and link. At minimum:

1. Build an `emmeans::ref_grid()` for a simple factor or numeric focal term.
2. Build the matching `prediction_grid()` manually.
3. Check that link-scale EMMs equal the matching linear predictions.
4. Check that response-scale EMMs equal the documented inverse-link transform.
5. Check that unsupported `dpar`, random-effect, bivariate, zero-inflated,
   hurdle, ordinal, missing-data, and missing-covariance paths error before
   returning an `emmGrid`.
6. Run pkgdown and stale-claim scans that confirm the docs say `emmeans`
   support is limited to the implemented target set.

Slice 122 satisfied this gate for the first fixed-effect univariate `mu` path
before advertising public `emmeans` compatibility. Slice 124 adds the first
model-workflow example for that path and keeps `emmeans()` adjusted means
separate from `sigma`, random-effect, bivariate, zero-inflated, hurdle,
ordinal, and slope workflows.

Slice 125 extends the direct method tests across the remaining model types
admitted by the first gate: Student-t, lognormal, Gamma, beta-binomial, NB2, and
zero-truncated NB2. Those tests compare link-scale and response-scale
`emmeans()` summaries with `predict(dpar = "mu")` on the same reference grid;
they do not add support for blocked model structures or new estimands.

Slice 126 adds a narrow downstream contrast check for the returned fixed-effect
`mu` grid. `emmeans::emmeans(fit, pairwise ~ habitat, ...)` can compute generic
pairwise differences among the EMMs, so documentation should not treat contrast
itself as a pre-grid unsupported target. This is not a slope workflow, a custom
weighting contract, a non-`mu` contrast helper, or support for blocked model
structures.

Slice 127 adds the first public offset parity check for this contract. A
Poisson fixed-effect `mu` model with `offset(log(exposure))` verifies that
`emmeans(..., at = list(exposure = 2))` matches `predict(dpar = "mu")` on both
the link and response scales. This confirms that ordinary formula offsets can
travel through the first `mu` EMM grid when users supply the needed offset
variables, but it does not add support for non-`mu`, random-effect, bivariate,
zero-inflated, hurdle, ordinal, slope, custom-weight, or fitted-response
targets.

Slice 128 adds the matching transformed-predictor recovery check. A Gaussian
fixed-effect `mu` model with `log(size)` verifies that
`emmeans(..., at = list(size = 1.5))` matches `predict(dpar = "mu")`, while the
recover-data preflight confirms that raw source variables for transformed terms
are restored from stored data. This is not support for transformed responses,
slopes, custom weights, non-`mu` targets, or blocked model structures.

Slice 129 adds explicit coverage for the default numeric covariate-reduction
rule. A Gaussian fixed-effect `mu` model with an asymmetric numeric covariate
verifies that `emmeans(fit, ~ habitat)` matches `predict(dpar = "mu")` at
`mean(x)`. This is ordinary `emmeans` reference-grid behaviour, not a
drmTMB-specific empirical marginalisation or custom-weighting contract.

Slice 130 adds direct `type` argument coverage. A Poisson fixed-effect `mu`
model verifies that `emmeans(..., type = "response")` matches
`predict(dpar = "mu", type = "response")`, while `type = "link"` remains on the
formula linear-predictor scale. This preserves the contract that response-scale
summaries are inverse-link summaries of native `mu`, not fitted observed
responses for blocked models.

Slice 131 adds custom numeric covariate-reduction coverage. A skewed Gaussian
fixed-effect `mu` model verifies that
`emmeans(..., cov.reduce = stats::median)` matches `predict(dpar = "mu")` at
`median(x)`. This is ordinary `emmeans` reference-grid behaviour, not a
drmTMB-specific empirical-averaging or custom-weighting contract.

Slice 132 adds unreduced numeric covariate-grid coverage. A Gaussian
fixed-effect `mu` model verifies that `emmeans(..., cov.reduce = FALSE)`
matches `predict(dpar = "mu")` averaged over the observed `x` levels in the
`emmeans` reference grid. This is grid averaging by `emmeans`, not
drmTMB-specific row-wise empirical marginalisation.

Slice 133 adds multiple explicit `at` value coverage. A Gaussian fixed-effect
`mu` model verifies that
`emmeans(fit, ~ habitat | x, at = list(x = c(-0.25, 0.75)))` matches row-wise
`predict(dpar = "mu")` on the same conditional reference grid. This is explicit
conditioning, not a new marginalisation or slope contract.

Slice 134 adds public zero-inflated boundary coverage. A zero-inflated Poisson
model verifies that `emmeans()` errors before returning an `emmGrid`, names the
unsupported `"zi_poisson"` model type, and directs users to `prediction_grid()`
plus `predict_parameters()` for explicit prediction tables. This remains an
unsupported boundary, not zero-inflated `emmeans` support.

Slice 135 adds public hurdle boundary coverage. A hurdle NB2 model verifies that
`emmeans()` errors before returning an `emmGrid`, names the unsupported
`"hurdle_nbinom2"` model type, and directs users to `prediction_grid()` plus
`predict_parameters()` for explicit prediction tables. This remains an
unsupported boundary, not hurdle `emmeans` support.

Slice 136 adds public ordinal boundary coverage. A cumulative-logit model
verifies that `emmeans()` errors before returning an `emmGrid`, names the
unsupported `"cumulative_logit"` model type, and directs users to
`prediction_grid()` plus `predict_parameters()` for explicit prediction tables.
This remains an unsupported boundary, not ordinal expected-score `emmeans`
support.

Slice 137 improves the public bivariate boundary. Bivariate Gaussian fits now
error as unsupported `"biv_gaussian"` fits before returning an `emmGrid`, with
the same prediction-table guidance, instead of falling through to a generic
missing-`mu` message. This remains an unsupported boundary, not bivariate
`emmeans` support.

Slice 138 blocks transformed-response formulas in the first `emmeans()` bridge.
Fits such as `log(y) ~ x` now error before returning an `emmGrid`, with
guidance toward explicit transformed-scale prediction tables through
`prediction_grid()` plus `predict_parameters()`. This keeps transformed
responses separate from the transformed-predictor path added in Slice 128.

Slice 139 extends the public zero-inflated `emmeans()` boundary to NB2.
Zero-inflated NB2 fits now error as unsupported `"zi_nbinom2"` fits before
returning an `emmGrid`, matching the zero-inflated Poisson boundary. This
remains an unsupported boundary, not zero-inflated NB2 `emmeans` support.
