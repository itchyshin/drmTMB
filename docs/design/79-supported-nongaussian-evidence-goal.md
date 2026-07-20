# Supported Non-Gaussian Distribution Evidence Goal

This note records Slices 591-650 for the goal:

> Finish supported non-Gaussian distribution evidence.

The goal is an evidence closeout, not a broad parity claim. It keeps the
implemented fixed-effect family suite, ordinary `mu` random-effect first slices
including binomial, separate NB2/lognormal/Gamma log-`sigma` random-intercept
gates, and Poisson/NB2 q=1 phylogenetic `mu` gates separate from planned
neighbours.

## Completion Standard

A supported non-Gaussian row is complete only when these pieces agree:

- likelihood and link contract;
- response-scale `fitted()` or prediction contract;
- focused deterministic tests, including malformed or unsupported neighbours;
- simulation or recovery evidence appropriate to the row;
- interval or status rows where the row advertises inference;
- reader-facing documentation and fitted alternatives for blocked requests;
- check-log, roadmap, NEWS, readiness, and validation-debt entries.

Long grids remain optional Phase 18 artifacts. They are not CRAN tests.

## Supported Family Evidence Map

| Route | Fixed-effect evidence | Random-effect evidence | Structured evidence | Current status |
| --- | --- | --- | --- | --- |
| `student()` | Fitted `mu`, `sigma`, and `nu`; likelihood, interval, malformed-input, and fixed-effect shape simulation evidence exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; `sigma`, correlated slopes, and labelled covariance remain blocked. | The exact q1 `mu ~ spatial(1 + x | ...)` route is point/recovery-grade; intercept-only `mu ~ spatial(1 | ...)` and `nu ~ phylo()` are diagnostic-only single-smoke gates. All neighbouring structured providers, additional slopes, and bivariate Student-t paths remain blocked. | Supported fixed-effect heavy-tail route plus ordinary `mu`, one exact structured recovery gate, and two exact diagnostic-only gates; no interval/coverage promotion for any exact gate. |
| `skew_normal()` | Fitted `mu`, `sigma`, and residual-slant `nu` with density, recovery, normal-limit, and diagnostic evidence. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; exact `mc-0464` is inference-ready with caveats for true SD 0.50 and M>=16; `sigma`/`nu` random effects and correlated/labelled slopes remain blocked. | Blocked. | Supported fixed-effect asymmetry route plus ordinary `mu` recovery and exact Arc 4c slope-inference gate. |
| `lognormal()` | Fitted `mu` on the log-response scale and `sigma`; likelihood, fitted-response, and boundary tests exist. | Separate ordinary gates fit `mu` random intercepts/independent slopes or one `sigma` random intercept. The exact sigma-intercept domain is inference-ready with caveats; combining dpars, sigma slopes, labels, and structured effects remain blocked. | Blocked beyond the named gates. | Supported fixed-effect positive-response route plus bounded ordinary random-effect slices. |
| `Gamma(link = "log")` | Fitted mean-CV route with `log(mu)` and `log(sigma)`; likelihood, recovery, prediction, and non-log-link boundary tests exist. | Separate ordinary gates fit `mu` random intercepts/independent slopes or one `sigma` random intercept at recovery grade; combining dpars, sigma slopes, and labels remain blocked. | One exact q1 `mu ~ relmat(K/Q)` intercept-plus-one-slope route is recovery-grade; other structured providers remain blocked. | Supported fixed-effect positive-response route plus bounded ordinary gates and the exact relatedness point/recovery route. |
| `tweedie()` | Fitted `mu`, `sigma`, and intercept-only power `nu` with likelihood, high/low-zero recovery, simulation, and boundary evidence. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; exact `mc-0539` is inference-ready with caveats for true SD 0.50 and M>=16; `sigma` random effects, predictor-dependent `nu`, and correlated/labelled slopes remain blocked. | Blocked. | Supported fixed-effect Tweedie route plus ordinary `mu` recovery and exact Arc 4c slope-inference gate. |
| `beta()` | Fitted strict `(0, 1)` response route with `logit(mu)` and public `sigma`; likelihood, prediction, Wald-row, and boundary tests exist. Exact structural boundary mass belongs to `zero_one_beta()`. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; correlated slopes, labels, and exact 0/1 mass remain blocked. | Exact q1 `mu ~ animal()` intercept-plus-one-slope and separate `sigma ~ animal()` intercept routes are point/recovery-grade; other providers and combined endpoints remain blocked. | Supported strict bounded-response route plus ordinary `mu` and exact animal-model point/recovery gates. |
| `zero_one_beta()` | Fitted `[0, 1]` route with interior `mu`/`sigma`, exact-boundary probability `zoi`, and conditional-one probability `coi`; independent mixture-likelihood, recovery, Wald-row, fitted-response, simulation, malformed-neighbour tests, and Phase 18 artifact helpers exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; exact `mc-0575` is inference-ready with caveats for true SD 0.50 and M>=16, subject to its strictly-interior-generator caveat; `sigma`, `zoi`, and `coi` random effects remain blocked. | Blocked. | Supported fixed-effect zero-one route plus ordinary `mu` recovery and exact Arc 4c slope-inference gate; no structured or boundary-mass random effects. |
| `stats::binomial(link = "logit")` | Fitted ordinary Bernoulli/binomial route for 0/1 and `cbind(successes, failures)` responses with `logit(mu)` and no public `sigma`; fixed-path `stats::glm()` parity exists. | Ordinary `mu` random intercepts and independent slopes are fitted; only the exact `mc-0061` slope domain is inference-ready with caveats. Correlated/labelled slopes and structured effects are blocked. | Blocked beyond the named gates, including Julia bridge support. | Supported fixed-effect event-probability route plus bounded ordinary random-effect slices. |
| `beta_binomial()` | Fitted denominator-aware route for `cbind(successes, failures)` with `mu` and `sigma`; likelihood, denominator, prediction, Wald-row, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted for counted successes out of known trials; `sigma`, correlated slopes, labels, `zoi`/`coi`, and structured routes remain blocked. | Blocked. | Supported success-rate route plus first ordinary `mu` random-effect slices. |
| `poisson(link = "log")` | Fitted fixed-effect count route, including offsets and fixed-effect `zi`. | Ordinary non-zero-inflated `mu` random intercepts and independent numeric slopes are fitted. | q1 `mu` intercept-plus-one-slope routes fit for `phylo()`, `spatial()`, `animal()`, and `relmat()`; one exact q1 `zi ~ spatial()` intercept is diagnostic-only. Pure/multiple/labelled slopes and other `zi` structure remain blocked. | Supported fixed-effect and ordinary count route plus exact structured routes at their recorded tiers; no interval/coverage promotion. |
| `nbinom2()` | Fitted fixed-effect mean-overdispersion route, including fixed-effect `zi`. | Ordinary non-zero-inflated `mu` random intercepts/independent slopes and one ordinary `sigma` random intercept are fitted. | q1 `mu` and separate q1 structured-`sigma` routes fit for all four providers; one exact zero-inflated fixed-`zi` `mu ~ spatial()` route is local-fit only; one exact crossed `mu ~ spatial() + relmat()` route is recovery-only on the crossed design. | Supported fixed-effect and bounded mixed-model routes; richer/labelled or simultaneous structure beyond the exact crossed gate and structured-`sigma` intervals/coverage remain blocked. |
| `truncated_nbinom2()` | Fitted positive-count fixed-effect route with `mu` and `sigma`. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; correlated slopes and `sigma` random effects remain blocked. | The hurdle alias has one exact q1 `hu ~ relmat(K/Q)` intercept; other structured routes remain blocked. | Supported positive-count route plus ordinary `mu` and one exact hurdle-relatedness gate. |
| `truncated_nbinom2()` with `hu ~ ...` | Fitted hurdle NB2 fixed-effect route with `mu`, `sigma`, and `hu`. | One exact q1 `hu ~ relmat(K/Q)` intercept is diagnostic-only; positive-count and other hurdle random effects remain blocked. | Same exact relatedness gate only. | Supported fixed-effect hurdle route plus the exact diagnostic-only gate; no interval/coverage promotion. |
| `cumulative_logit()` | Fitted ordinal location route with ordered cutpoints and expected-score prediction evidence. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are recovery-grade. | One exact diagnostic-only q1 `mu ~ phylo()` intercept has local point-fit/extractor evidence; other providers remain blocked. | Supported fixed-effect and ordinary recovery routes plus one exact diagnostic-only phylogenetic gate. |

## Count Mixed-Model Closeout

The count mixed-model surface is deliberately narrower than the fixed-effect
family suite:

- ordinary Poisson and NB2 `mu` random intercepts and independent numeric
  slopes are admitted as first non-Gaussian count random-effect slices;
- ordinary Student-t, zero-truncated NB2, lognormal, Gamma, beta, and
  beta-binomial `mu` random intercepts and independent numeric slopes are
  admitted as narrow source-tested first slices;
- ordinary NB2 `sigma ~ z + (1 | id)` is admitted as a separate
  overdispersion-random-intercept smoke lane;
- ordinary Poisson and NB2 q=1 structured `mu` intercepts and unlabelled
  intercept-plus-one-slope terms are fitted for `phylo()`, `spatial()`,
  `animal()`, and `relmat()`, but the
  merged sharded 500-replicate NB2 artifact audit kept the q1 NB2 promotion gate
  at `hold_smoke_only`;
- correlated zero-truncated NB2 slopes, zero-inflation or hurdle random
  effects beyond the exact Poisson-spatial-`zi` and hurdle-relatedness-`hu`
  gates, correlated count slopes, labelled non-Gaussian covariance blocks,
  structured
  pure, multiple, or labelled structured count slopes, NB2 `sigma` slopes,
  beta scale/slopes beyond the exact animal-model gates, simultaneous
  structured types, richer/labelled structured `sigma`, and non-count
  structured effects beyond the exact Student-t/Gamma/beta/ordinal gates
  remain planned or blocked.

The #441 independent-`mu`-slope gate is recorded in
`docs/design/147-phase6c-nongaussian-mu-slope-ademp.md`. It promotes ordinary
Poisson and NB2 `mu` slopes as `ready_grid`, keeps Student-t, lognormal, Gamma,
beta, beta-binomial, and zero-truncated NB2 independent `mu` slopes at
`ready_source_test`, and routes formal recovery, coverage, and power claims to
#446.

## NB2 q1 Formal Shard Audit Rule

The next compute action was operational rather than statistical. All 16
`nbinom2_phylo_q1_formal` shards were dispatched from a workflow whose
concurrency group includes the shard index and shard count. No single shard may
set a promotion claim, and the merged artifact set is the only interpretable
audit unit.

The combined audit must check:

- all 288 formal condition cells are present;
- each cell has 500 completed target/comparator replicates;
- manifest, replicate, aggregate, failure-ledger, Wald, profile-target,
  interval-evidence, interval-diagnostic, and interval-failure artifacts are
  retained;
- fixed-effect `mu` and `sigma` recovery, phylogenetic SD recovery, grouped
  comparator behaviour, convergence, Hessian, boundary, warning/error, runtime,
  Wald coverage, and direct `log_sd_phylo` profile interval status are
  summarized together.

That audit has now landed as a hold decision. The full shard set has all 288
formal condition cells and 500 manifest rows per global shard-cell, but
profile-interval failures and fixed-`sigma` recovery problems remain too
strong for promotion. The NB2 q1 phylogenetic route remains `hold_smoke_only`.

## Zero-One Bounded-Response Gate Rule

Slice D3 chose fixed-effect zero-one beta as the next bounded-response design
gate; the first runnable fixed-effect slice now separates three cases:

- strict continuous proportions stay on `beta()` and require `0 < y < 1`;
- ordinary 0/1 events and counted successes out of known trials use
  `stats::binomial()` when binomial sampling variation is the intended model;
- overdispersed counted successes out of known trials use `beta_binomial()`,
  where 0 and all-success rows can be ordinary sampling outcomes;
- continuous responses with exact 0/1 structural mass can use
  `zero_one_beta()` when at least one interior response remains after
  missing-row filtering.

The completed first code slice and first artifact lane are fixed-effect only.
`zoi`/`coi` random effects, bounded-response covariance blocks, known sampling
covariance, structured bounded responses, and bivariate or mixed
bounded-response models remain future work.

## Claim Boundary

The completed claim should be:

> drmTMB has an evidence-backed supported non-Gaussian fixed-effect family
> suite, plus first-slice ordinary `mu` random intercepts and independent
> numeric slopes for selected non-Gaussian families, the
> narrow NB2 log-`sigma` random-intercept gate, and smoke/formal-admission
> Poisson/NB2 q=1 phylogenetic `mu` gates.

It should not be:

> drmTMB has broad non-Gaussian random-effect or structured-effect parity with
> Gaussian models.
