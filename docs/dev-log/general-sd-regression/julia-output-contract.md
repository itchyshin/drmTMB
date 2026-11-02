# Julia-to-R output contract for ordinary binomial `sd(group)`

**Purpose.** This note records the public R/Julia output contract for ordinary Bernoulli random-intercept SD regression, the implementation evidence, and the remaining validation limits.

**Availability status.** The Julia route described here is a development
candidate tested only with explicitly matched local drmTMB and DRM.jl source
checkouts. It is absent from the current shared and released DRM.jl companion. Two
narrow same-data intercept/slope comparisons are recorded in the check log,
but the bridge evidence does not establish general engine parity or availability
with an installed release.

## Canonical identities

| Layer | Canonical key / value | Contract |
|---|---|---|
| User-facing formula alias and native R registry key | `sd(g)` | Preserve the formula-derived spelling as the public alias for this single, unambiguous target. The parsed descriptor tuple supplies the stable target identity; the printed LHS supplies its public alias. Native assembly stores the compatibility key in `model$random_scale$mu$dpars`; `predict_random_scale_dpar()` evaluates its `X_list[[dpar]]`/terms and returns group-level predictions when `newdata = NULL`. |
| Julia working coefficient block | `:sd` | The Bernoulli fitter stores `blocks = [:mu => …, :sd => …]`, `coefnames[:sd] = nmsd`, and `coef(fit, :sd)` returns log-SD regression coefficients. Do not rename this internal block to `sd_g`; the fit block is the generic `:sd`. |
| Public cross-engine target alias | `sd(g)` → Julia block `sd` | The R bridge accepts the formula-derived canonical target and resolves it to the `sd` coefficient block through `drm_julia_lss_dpar_aliases()`. Ambiguous mappings are not silently selected. `sd_g` is not the public dpar spelling. |
| Predicted scale, link type | `Z_g alpha` | Group-level log SD, one row per observed group by default; when prediction data are supplied, match native `predict_random_scale_dpar()` output grain and validate group-level predictors. |
| Predicted scale, response type | `exp(Z_g alpha)` | Positive marginal random-intercept SD by group for this ordinary iid route, where the latent covariance diagonal is one. This is not residual `sigma` or observation-level Bernoulli residual dispersion. |

This note is limited to one ordinary Bernoulli random-intercept target. For a
structured effect with covariance `C`, `exp(W_g alpha)` is the kernel
multiplier; the latent marginal SD is `exp(W_g alpha) * sqrt(C_gg)` (or the
corresponding projected covariance diagonal). Preserve the existing kernel
scaling. The general target and covariance contract in
[`target-contract.md`](target-contract.md) governs selector identity and
structured outputs; this Bernoulli note does not establish those routes as
implemented or validated.

## Payload placement and bridge changes

The Bernoulli fitter stores `:sd`, `:sd_group`, `:sd_group_index`, `:aghq_nodes`, and `:trials` in `DrmFit.scales`. `_bridge_dpars()` filters these implementation/context keys so only the family dpar `mu` crosses as a distributional parameter. Trials travel in their dedicated bridge payload and are reconstructed on the R object from the retained response. This keeps Bernoulli `sigma()` empty and prevents implementation metadata from entering the family parameter table.

The R bridge keeps the fixed coefficient block `:sd` and its covariance coordinates in the ordinary coefficient/vcov payload. It derives the canonical formula identity and group SD values from the retained formula, data, and coefficient block. Group-index and quadrature-node values remain internal diagnostics, never family dpars.

Current `R/julia-bridge.R` integration:

1. One ordinary `sd(group)` target is mapped to the Julia `:sd` coefficient block and retains its canonical target in `coef()`, `predict()`, and profile/bootstrap target routing.
2. Group-level response/link predictions, reordered newdata predictions, and within-group predictor validation are exercised by the current Bernoulli test.
3. `predict_parameters()` now emits the shared long-table schema for Julia family dpars and random-effect SD targets. It uses the retained response-scale family dpars for fitted rows; SD coefficients receive explicit `wald_unavailable` status when a prediction-grid Wald basis is not available. `fitted_distribution()` dispatches through the same family table.
4. The bridge keeps SD metadata out of family dpars, Bernoulli residual `sigma()` stays empty, and binomial trial counts are reconstructed from the retained response.

## Integration tests and evidence, 2026-10-18

- The candidate-path Bernoulli bridge test exercises one synthetic fit and checks a single-coefficient recovery smoke, `coef()` names, response/link SD predictions, fresh-data row order, predictor constancy, save/reload, and profile plus three-refit bootstrap target routing. It sets `DRM_JL_PATH` to the matching candidate DRM.jl checkout.
- It verifies group-grain `predict_parameters()` output, `bridge$dpars = "mu"`, empty Bernoulli residual `sigma()`, per-row one-trial context in `fitted_distribution_params()`, and end-to-end `fitted_distribution()` dispatch.
- Focused R tests passed for `predict-parameters`, Julia module compatibility, Julia quantile plumbing, and Julia beta-binomial helper behavior; the live Julia Bernoulli bridge test passed with `JULIA_PROJECT` unset and emitted no LogExpFunctions warning.
- This is not a recovery campaign. The profile/bootstrap checks verify routing only; three bootstrap refits do not establish coverage. Cross-block covariance parity, broader event/group-size designs, missing-group cases, and uncertainty calibration remain unverified.
- On 2026-10-19, the live Bernoulli SD bridge suite passed 112 assertions with five live Julia tests against the matched dirty candidate pair at drmTMB HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl HEAD `70dbf564eb670144c63c08f61ea099084d95add2`. One synthetic correlated-q2 fixture compares fixed effects, both SD regressions, latent correlation, and group-level SD outputs between engines at the tolerances stated in the test. Its 64 group-level latent draws and near-singular Julia Hessian mean this is a plumbing/rough point-alignment check, not evidence that every estimate is practically well identified. The native correlated-q2 suite also passed 60 assertions. Julia emitted two singular-Hessian diagnostics (`rcond=9.23e-10`, with coordinate 7 flagged; and `rcond=3.879e-17`, with no flat coordinate flagged). The latter makes public Wald behavior a separate unresolved check; this comparison establishes neither usable q2 standard errors, profile calibration, nor broader parity. The native 95% first-look campaign is separate and remains unqualified.

## Crossed ordinary intercept targets, 2026-10-23

The development candidate now fits two independent Bernoulli random
intercepts on separate grouping factors, each with its own fixed-effect SD
regression. When more than one SD target is present, the R bridge resolves
each coefficient block using the descriptor-derived `sdtarget_...` identity.
For stored-group predictions, public `predict()` removes the target prefix and
returns group labels, matching native TMB; retained `fit$sdpars` entries keep
target-qualified labels. `predict_parameters()` uses matching group row labels
and estimates across the two engines.

The test `tests/testthat/test-julia-binomial-crossed-sd.R` uses one independent
synthetic draw with 40 groups per factor and four observations per crossed
pair. Its paired fit checks coefficient and SD-prediction agreement, group
labels, and log-likelihood agreement within `1e-3`. This is one point-parity
fixture and does not establish recovery across seeds, interval calibration,
or parity for other random-effect types or families.

## Boundary

The ordinary Bernoulli random-intercept path is implemented in native R/TMB;
the Julia bridge path remains a development candidate requiring matching local
source checkouts. R-side output plumbing has been exercised end to end for that
candidate pair. This evidence does not establish released Julia availability,
general same-data engine parity, calibrated uncertainty, or support for other families,
effect types, structured providers, or bivariate routes. Keep those capability
rows open until separately implemented and validated.
