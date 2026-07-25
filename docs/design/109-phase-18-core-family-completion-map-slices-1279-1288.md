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
| Ordinary counts | Fixed-effect Poisson, NB2, zero-inflated Poisson/NB2, zero-truncated NB2, and hurdle NB2 are fitted where documented. Ordinary non-zero-inflated Poisson/NB2 `mu` random intercepts and independent numeric `mu` slopes are fitted. Ordinary zero-truncated NB2 `mu` random intercepts and independent numeric slopes are fitted as positive-count first slices. Ordinary NB2 log-`sigma` random intercepts are fitted. Ordinary Poisson/NB2 q=1 structured `mu` intercept terms are fitted for `phylo()`, `phylo_interaction()`, `spatial()`, `animal()`, and `relmat()`, and unlabelled intercept-plus-one-slope terms are fitted as narrow first slices for `phylo()`, `spatial()`, `animal()`, and `relmat()`. One exact crossed NB2 `mu ~ spatial() + relmat()` route is fitted at recovery-only grade. | Paired Poisson/NB2 `mu` random-effect smoke and grid artifacts exist. Slices 1389-1398 add the zero-truncated NB2 `mu` random-intercept artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, manual `truncated_nbinom2_mu_random_intercept` Actions dispatch, fixed-effect Wald rows, and direct-SD profile rows; focused source tests now cover independent numeric zero-truncated slopes. NB2 log-`sigma` random-intercept smoke/grid artifacts exist. Poisson/NB2 q=1 phylogenetic intercept lanes have smoke/formal infrastructure; the completed NB2 500-replicate shard audit keeps NB2 at `hold_smoke_only`; spatial, animal, and `relmat()` q=1 count intercept routes have focused source-level recovery tests only; all four non-interaction providers now also have focused one-slope point-fit/extractor tests. The exact crossed route has recovery-only evidence for both variance components on a crossed design, without interval or coverage promotion. Slice C records the count first-wave closure in `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md`. | Treat the first-wave count story as "ordinary count mixed models, zero-truncated NB2 random intercepts/slopes, q=1 phylogenetic smoke/formal-admission routes, q=1 structured source-test routes, and one exact crossed NB2 recovery-only route." Do not add zero-inflation random effects, hurdle random effects, correlated zero-truncated slopes, pure or multiple structured count slopes, labelled structured covariance, simultaneous structured count routes beyond the exact crossed gate, COM-Poisson, or generalized Poisson until the project chooses a separate Slice D family or compute lane. |
| Proportions and bounded responses | Fixed-effect `beta()`, `zero_one_beta()`, and `beta_binomial()` are fitted for strict continuous proportions, structural exact-boundary continuous proportions, and successes out of known trials; beta and beta-binomial ordinary `mu` random intercepts and independent numeric slopes are fitted as later source-tested first slices. | At this planning point, the fixed-effect proportion ADEMP sheet existed but the DGP, summariser, smoke runner, and repeatable grid writer had not yet joined the first-wave artifact path. Slices 1289-1298 later added that artifact lane for beta and beta-binomial. Slices 1339-1348 add the matching fixed-effect zero-one beta artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, and manual Actions dispatch. Slices 1359-1368 add the bounded-response ordinary `mu` random-intercept artifact lane for beta and beta-binomial `(1 | id)` with fixed-effect Wald rows and direct-SD profile rows; focused source tests now cover independent numeric bounded-response slopes. | Keep broad grids narrow and surface-specific. Keep zero-one beta random effects, correlated bounded-response random slopes, labelled covariance, `sigma` random effects, structured bounded responses, and mixed-response bounded models in the failure ledger. |
| Ordinary continuous location-scale | Gaussian location-scale is fitted and already has first-wave simulation artifacts. | Gaussian location-scale DGP, smoke, grid-output, and report staging are part of the first-wave runner. | Treat this lane as the reference continuous surface. Use it as the comparator story when explaining Student-t shape, lognormal, and Gamma rather than adding new Gaussian syntax. |
| Positive continuous responses | Fixed-effect lognormal location-scale and Gamma mean-CV likelihoods are fitted. Ordinary `mu` random intercepts and independent numeric slopes are fitted for `lognormal()` and `Gamma(link = "log")` as narrow first mixed-model slices. | Slices 1299-1308 add the fixed-effect positive-continuous artifact lane. Slices 1369-1378 add the ordinary `mu` random-intercept artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, manual `positive_continuous_mu_random_intercept` Actions dispatch, fixed-effect Wald rows, and direct-SD profile rows; focused source tests now cover independent numeric positive-continuous slopes. | Keep correlated positive-continuous slopes, labelled covariance, `sigma` random effects, known sampling covariance, phylogenetic terms, structured effects, generalized Gamma, and bivariate positive-continuous models out. |
| Ordinal responses | Univariate `cumulative_logit()` models are fitted with ordered cutpoints, fixed latent logistic scale, ordinary recovery-grade `mu` random intercepts or independent slopes, and one exact phylogenetic `mu` intercept local-fit gate. | Slices 1309-1318 provide the fixed-effect ordinal ADEMP/artifact lane; later focused tests provide ordinary random-effect recovery and the exact phylogenetic point-fit/extractor contract. | Keep correlated/labelled or other structured ordinal effects, scale/discrimination formulas, interval/coverage promotion, bivariate ordinal, and mixed-response ordinal models out until separate evidence lands. |
| Shape and skewness | Fixed-effect Student-t `nu` is fitted, and ordinary Student-t `mu` random intercepts plus independent numeric slopes are fitted with fixed-effect `sigma` and `nu`. Skew-normal and skew-t are not fitted. | Student-t shape has a Phase 18 ADEMP sheet and DGP, summariser, smoke runner, grid writer, summary smoke, profile-smoke, and bootstrap-smoke evidence. Slices 1379-1388 add the Student-t ordinary `mu` random-intercept artifact lane with DGP, summariser, smoke runner, repeatable grid writer, first-wave runner inclusion, manual `student_mu_random_intercept` Actions dispatch, fixed-effect Wald rows for `mu`, `sigma`, and `nu`, and direct-SD profile rows; focused source tests now cover independent numeric Student-t location slopes. Skew-normal and skew-t are design gates only. | Keep Student-t as the only runnable shape family for now. Do not infer support for correlated Student-t slopes, `sigma` random effects, or `nu` random effects from the ordinary `mu` intercept/slope lane. For skew-normal, the next action is an implementation gate with density comparator, Gaussian-limit check, prediction contract, profile-target policy, diagnostics, and recovery tests. Skew-t waits until skew-normal is stable because it adds a second shape dimension, tentatively `tau`. |
| Semicontinuous positive responses | The first `tweedie()` route is fitted for univariate fixed-effect models with `mu`, public `sigma = sqrt(phi)`, and intercept-only `nu ~ 1`. | `docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`, and `tests/testthat/test-tweedie-location-scale.R` record the fixed-effect likelihood, link contract, high-zero and low-zero recovery, fitted-response, simulation, support-boundary, and malformed-neighbour evidence. | Keep Tweedie random effects, predictor-dependent `nu`, labelled covariance, `sd(group)`, known covariance, structured effects, bivariate or mixed-response Tweedie, zero-inflation aliases, and hurdle aliases out. |

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
   `beta_binomial()` as completed by Slices 1289-1298, and the ordinary `mu`
   random-intercept artifact lane for those same bounded-response families as
   completed by Slices 1359-1368.
3. Treat the fixed-effect positive-continuous artifact lane for `lognormal()`
   and `Gamma(link = "log")` as completed by Slices 1299-1308, and the
   ordinary `mu` random-intercept artifact lane for the same families as
   completed by Slices 1369-1378.
4. Treat the fixed-effect ordinal artifact lane for `cumulative_logit()` as
   completed by Slices 1309-1318.
5. Treat the Student-t ordinary `mu` random-intercept artifact lane as
   completed by Slices 1379-1388, and the independent numeric slope path as
   source-tested, while keeping correlated Student-t slopes, `sigma` random
   effects, `nu` random effects, structured effects, and known covariance
   planned. Historical note: the later Arc 6.4 exact `biv_student()` source
   slice remains outside this univariate artifact lane and has no recovery
   claim.
6. Treat the NB2 q1 formal shard audit as completed but held: the 16-shard
   500-replicate artifact set exists, but profile and fixed-`sigma` diagnostics
   block promotion.
7. Treat the zero-one bounded-response design gate as the chosen D3
   documentation lane and the later fixed-effect `zero_one_beta()` source slice
   as the narrow runnable route for structural exact 0/1 mass. Zero-one random
   effects, correlated bounded-response random slopes, structured bounded
   responses, and mixed bounded-response models stay planned.
8. Choose any later Slice D lane from the remaining skew-normal shape decision,
   Tweedie comparator or extension evidence beyond the fixed-effect first
   slice, or a later count-family design gate such as Conway-Maxwell-Poisson.

This order gives users broad measurement-process coverage before the package
adds higher-risk covariance, inflation-random-effect, or skew-family syntax.
