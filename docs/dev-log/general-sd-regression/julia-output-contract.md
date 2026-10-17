# Julia-to-R output contract for ordinary binomial `sd(group)`

**Purpose.** This is a source-only output-contract audit for the private binomial q1 helper. The helper is not in the public Julia dispatcher, and this note does not authorize editing shared Julia or R bridge files.

## Canonical identities

| Layer | Canonical key / value | Contract |
|---|---|---|
| User formula and native R model registry | `sd(g)` | Preserve the exact formula LHS as the target identity. Native assembly stores it in `model$random_scale$mu$dpars`; `predict_random_scale_dpar()` evaluates its `X_list[[dpar]]`/terms and returns group-level predictions when `newdata = NULL`. |
| Julia working coefficient block | `:sd` | The private helper stores `blocks = [:mu => …, :sd => …]`, `coefnames[:sd] = nmsd`, and `coef(fit, :sd)` returns log-SD regression coefficients. Do not rename this internal block to `sd_g`; Julia’s existing LSS formula machinery has a group-specific `sd_g` formula key but the fit block is the generic `:sd`. |
| Public cross-engine target alias | `sd(g)` → Julia block `sd` | R should accept the canonical formula identity and resolve it to the bridge’s existing `sd` coefficient block, following the formula-derived alias pattern in `drm_julia_lss_dpar_aliases()`. Refuse if the alias is missing or ambiguous. `sd_g` is not the public dpar spelling. |
| Predicted scale, link type | `Z_g alpha` | Group-level log SD, one row per observed group by default; when prediction data are supplied, match native `predict_random_scale_dpar()` output grain and validate group-level predictors. |
| Predicted scale, response type | `exp(Z_g alpha)` | Positive random-intercept SD by group, not residual `sigma` and not observation-level Bernoulli residual dispersion. |

## Payload placement and bridge changes

`DrmFit.scales` is documented as residual scale(s) for simulation (`src/gaussian_core.jl`, `DrmFit` declaration). `sigma(fit)` returns a plain vector only for the sole `:sigma` key; otherwise it returns the entire scales dictionary. `_bridge_dpars()` currently copies every `fit.scales` key into its dpar table, deleting only `:trials` because trials are explicit context rather than a dpar (`src/bridge.jl`, `_bridge_dpars`). Therefore the private helper’s current `:sd_group`, `:sd_group_index`, and `:aghq_nodes` keys would leak as fictitious dpars, and `sigma(fit)` would expose them as if they were fitted scales. They must not pass through unchanged.

The preferred contract is a dedicated direct-random-scale payload, separate from residual `scales` and from `ranef` (conditional modes). It should carry the canonical formula identity, group name/level order, group design or validated scale predictor, and response-scale group SD values. The source bridge can construct this payload where both `fit` and input `data` are available in `_bridge_fit`/`drm_bridge`, then marshal it explicitly to R. Keep the fixed coefficient block `:sd` and its covariance coordinates in the ordinary coefficient/vcov payload. Keep quadrature-node count and group index as diagnostics/internal fields, never dpars. If the payload is instead retained directly on `DrmFit`, add a compatibility constructor default and keep all current `scales` and `sigma(fit)` contracts unchanged.

Required `R/julia-bridge.R` work at integration time:

1. Parse and validate one supported ordinary `sd(g) ~ …` target for this family, retaining canonical `sd(g)` identity and the exact group/predictor metadata. Do not admit `sd_phylo`, structured providers, or slopes through this path.
2. Translate the Julia `:sd` block and coefficient names into an R coefficient block addressable by canonical `sd(g)` while preserving stable coefficient labels and full covariance alignment. Existing `drm_julia_split_coef_name()` knows the block prefix `sd`; existing `drm_julia_lss_dpar_aliases()` is the nearest target-resolution pattern but currently principally documents the `sd_phylo(group)` short/long alias.
3. Expose group SD prediction through the dedicated payload and/or a dedicated prediction branch. `drm_julia_predict_entry()` and `drm_julia_predict_response()` currently reconstruct fixed-effect dpars; `predict_parameters(::DrmFit)` skips non-formula blocks, including `:sd`, and `_param_response()` has no ordinary `:sd` inverse-link rule. Add the explicit link/response conversion and group-level grain instead of pretending this is `sigma`.
4. Ensure `_bridge_dpars()` and `_bridge_dpars_newdata()` whitelist actual family dpars or explicitly add canonical direct-SD values; never serialize payload metadata as distributional parameters. Keep Bernoulli `sigma()` empty, and do not create a residual-sigma estimate.

## Minimum integration tests

- Same synthetic Bernoulli/binomial call through public `drmTMB(engine="julia")`; assert the R object has the canonical `sd(g)` formula/target and the Julia internal coefficient block is mapped without coefficient/covariance reordering.
- `coef()` and `vcov()` for the SD coefficients; verify names and covariance cross-block alignment against the engine result.
- `predict(fit, dpar = "sd(g)", type = "link"/"response")` and `predict_parameters()` on stored groups; response output equals exponentiated link output and is group-level, matching native semantics.
- Fresh-data predictions with reordered groups, a known group-level predictor, missing group/predictor, and predictor variation within a group; refuse ambiguous or invalid group mapping rather than recycling.
- `sigma(fit)` remains empty for Bernoulli; `bridge$dpars` contains no `sd_group_index`/`aghq_nodes` metadata or fake residual sigma. Verify `fitted_distribution_params()` does not mistake group SDs for per-row family parameters.
- Refit, save/reload, and formula/alias round trip preserve the model and target identities. Keep profile/bootstrap interval claims out until separately implemented and calibrated.

## Boundary

This is a design contract, not public integration evidence. The private helper test does not exercise `_bridge_dpars`, R-side `predict()`/`predict_parameters()`, coefficient aliases, refitting, or save/reload. Shared dispatcher ownership is pending, so no shared Julia files or `R/julia-bridge.R` were changed here.
