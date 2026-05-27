# Phase 18 Core Family Completion Map, Slices 1279-1288

This note records the planning reset after the current-state revalidation
through Slices 909-1008. Its reader is an applied ecology, evolution, or
environmental-science user who wants to know which measurement processes are
nearly ready, and an R package contributor who needs the next implementation
lane to stay narrow.

The purpose is to finish the first public story for common one-response data
types before adding richer covariance or shape syntax. "Finish" here means a
coherent first-wave package claim: fitted likelihood, focused tests, simulation
or artifact evidence, user-facing examples, explicit unsupported-neighbour
errors, check-log evidence, and after-task notes.

## Status By Measurement Process

| Measurement process | Current fitted status | Simulation or artifact status | Next action |
| --- | --- | --- | --- |
| Ordinary counts | Fixed-effect Poisson, NB2, zero-inflated Poisson/NB2, zero-truncated NB2, and hurdle NB2 are fitted where documented. Ordinary non-zero-inflated Poisson/NB2 `mu` random intercepts and independent numeric `mu` slopes are fitted. Ordinary zero-truncated NB2 `mu` random intercepts are fitted as a positive-count first slice. Ordinary NB2 log-`sigma` random intercepts are fitted. Ordinary Poisson/NB2 q=1 phylogenetic `mu` intercepts are fitted as narrow first slices. | Paired Poisson/NB2 `mu` random-effect smoke and grid artifacts exist. Zero-truncated NB2 `mu` random-intercept focused recovery exists in the source test lane. NB2 log-`sigma` random-intercept smoke/grid artifacts exist. Poisson/NB2 q=1 phylogenetic lanes have smoke/formal infrastructure; the completed NB2 500-replicate shard audit keeps NB2 at `hold_smoke_only`. Slice C records the count first-wave closure in `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md`. | Treat the first-wave count story as "ordinary count mixed models, zero-truncated NB2 random intercepts, and q=1 phylogenetic smoke/formal-admission routes." Do not add zero-inflation random effects, hurdle random effects, zero-truncated random slopes, count spatial/animal/`relmat()` routes, structured count slopes, COM-Poisson, or generalized Poisson until the project chooses a separate Slice D family or compute lane. |
| Proportions and bounded responses | Fixed-effect `beta()`, `zero_one_beta()`, and `beta_binomial()` are fitted for strict continuous proportions, structural exact-boundary continuous proportions, and successes out of known trials; beta and beta-binomial ordinary `mu` random intercepts are fitted as later source-tested first slices. | At this planning point, the fixed-effect proportion ADEMP sheet existed but the DGP, summariser, smoke runner, and repeatable grid writer had not yet joined the first-wave artifact path. Slices 1289-1298 later added that artifact lane for beta and beta-binomial. Slices 1339-1348 add the matching fixed-effect zero-one beta artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, and manual Actions dispatch. The bounded-response ordinary `mu` random-intercept slices still need a separate ADEMP/artifact lane before broad grids. | Keep broad grids fixed-effect first. Keep zero-one beta random effects, bounded-response random effects beyond the beta and beta-binomial ordinary `mu` intercept slices, structured bounded responses, and mixed-response bounded models in the failure ledger. |
| Ordinary continuous location-scale | Gaussian location-scale is fitted and already has first-wave simulation artifacts. | Gaussian location-scale DGP, smoke, grid-output, and report staging are part of the first-wave runner. | Treat this lane as the reference continuous surface. Use it as the comparator story when explaining Student-t shape, lognormal, and Gamma rather than adding new Gaussian syntax. |
| Positive continuous responses | Fixed-effect lognormal location-scale and Gamma mean-CV likelihoods are fitted. Ordinary `mu` random intercepts are fitted for `lognormal()` and `Gamma(link = "log")` as a narrow source-test slice. | Slices 1299-1308 add the positive-continuous ADEMP/artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, and manual Actions dispatch for `lognormal()` and `Gamma(link = "log")`. Focused source tests cover the ordinary `mu` random-intercept slice. | Keep positive-continuous random slopes, labelled covariance, `sigma` random effects, known sampling covariance, phylogenetic terms, structured effects, generalized Gamma, Tweedie, and bivariate positive-continuous models out. |
| Ordinal responses | Fixed-effect univariate `cumulative_logit()` models are fitted with ordered cutpoints and fixed latent logistic scale. | Slices 1309-1318 add the ordinal ADEMP/artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, manual Actions dispatch, cutpoint rows, and cutpoint-ordering diagnostics. | Keep ordinal location-only. Do not add ordinal random effects, scale/discrimination formulas, bivariate ordinal, or mixed-response ordinal models yet. |
| Shape and skewness | Fixed-effect Student-t `nu` is fitted. Skew-normal and skew-t are not fitted. | Student-t shape has a Phase 18 ADEMP sheet and DGP, summariser, smoke runner, grid writer, summary smoke, profile-smoke, and bootstrap-smoke evidence. Skew-normal and skew-t are design gates only. | Keep Student-t as the only runnable shape family for now. For skew-normal, the next action is an implementation gate with density comparator, Gaussian-limit check, prediction contract, profile-target policy, diagnostics, and recovery tests. Skew-t waits until skew-normal is stable because it adds a second shape dimension, tentatively `tau`. |
| Semicontinuous positive responses | Tweedie is planned, not fitted. | The likelihood design names the intended fixed-effect first gate and comparator scale, but there is no fitted family route. | Do not start Tweedie until fixed-effect proportions and positive-continuous artifacts are complete. The first Tweedie route should be univariate, fixed-effect, and use intercept-only `nu ~ 1` before predictor-dependent power models. |

## Shape Family Answer

Student-t is done as the first fitted shape lane, within a narrow fixed-effect
contract:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = student(),
  data = dat
)
```

The fitted model uses `nu = 2 + exp(eta_nu)`, so the first shape parameter
models residual tail thickness while keeping finite variance. This is enough to
ask whether a Gaussian location-scale conclusion changes when heavy-tailed
residuals are allowed.

Skew-normal is not done. The planned first syntax is:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

That syntax remains planned. It should not be shown as runnable until the
skew-normal density branch, normal-limit comparator, prediction contract,
profile targets, diagnostics, and recovery tests exist. In that future model,
`nu` would represent residual asymmetry, not Student-t tail thickness.

Skew-t is further out. It needs two shape dimensions, so `tau` is reserved for a
future second shape parameter but is not current formula syntax. A fitted
skew-t route should come after skew-normal because asymmetry, tail thickness,
heteroscedasticity, outliers, and ordinary random effects can otherwise be
confounded.

## Recommended Order

1. Treat the count first-wave story as closed by Slice C without adding more
   count syntax.
2. Treat the fixed-effect proportion artifact lane for `beta()` and
   `beta_binomial()` as completed by Slices 1289-1298.
3. Treat the fixed-effect positive-continuous artifact lane for `lognormal()`
   and `Gamma(link = "log")` as completed by Slices 1299-1308.
4. Treat the fixed-effect ordinal artifact lane for `cumulative_logit()` as
   completed by Slices 1309-1318.
5. Treat the NB2 q1 formal shard audit as completed but held: the 16-shard
   500-replicate artifact set exists, but profile and fixed-`sigma` diagnostics
   block promotion.
6. Treat the zero-one bounded-response design gate as the chosen D3
   documentation lane and the later fixed-effect `zero_one_beta()` source slice
   as the narrow runnable route for structural exact 0/1 mass. Zero-one random
   effects, bounded-response random slopes, structured bounded responses, and
   mixed bounded-response models stay planned.
7. Choose any later Slice D lane from the remaining Student-t/skew-normal shape
   decision, the Tweedie fixed-effect design gate, or a later count-family design
   gate such as Conway-Maxwell-Poisson.

This order gives users broad measurement-process coverage before the package
adds higher-risk covariance, inflation-random-effect, or skew-family syntax.
