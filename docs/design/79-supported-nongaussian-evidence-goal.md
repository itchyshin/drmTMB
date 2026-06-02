# Supported Non-Gaussian Distribution Evidence Goal

This note records Slices 591-650 for the goal:

> Finish supported non-Gaussian distribution evidence.

The goal is an evidence closeout, not a broad parity claim. It keeps the
implemented fixed-effect family suite, the ordinary `mu` random-effect first
slices, the NB2 log-`sigma` random-intercept gate, and the Poisson/NB2 q=1
phylogenetic `mu` gates separate from planned neighbours.

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
| `student()` | Fitted `mu`, `sigma`, and `nu`; likelihood, interval, malformed-input, and fixed-effect shape simulation evidence exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; `sigma`, `nu`, correlated slopes, and labelled covariance remain blocked. | Blocked for phylogenetic, spatial, animal, `relmat()`, and bivariate Student-t paths. | Supported fixed-effect heavy-tail route plus first ordinary `mu` random-effect slices. |
| `lognormal()` | Fitted `mu` on the log-response scale and `sigma`; likelihood, fitted-response, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; `sigma`, correlated slopes, labels, structured effects, and known covariance remain blocked. | Blocked. | Supported positive-response route plus first ordinary `mu` random-effect slices. |
| `Gamma(link = "log")` | Fitted mean-CV route with `log(mu)` and `log(sigma)`; likelihood, recovery, prediction, and non-log-link boundary tests exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; `sigma`, correlated slopes, labels, structured effects, and known covariance remain blocked. | Blocked. | Supported positive-response route plus first ordinary `mu` random-effect slices. |
| `beta()` | Fitted strict `(0, 1)` response route with `logit(mu)` and public `sigma`; likelihood, prediction, Wald-row, and boundary tests exist. Exact structural boundary mass now belongs to `zero_one_beta()`, not `beta()`. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted for strict `(0, 1)` responses; `sigma`, correlated slopes, labels, exact 0/1 mass, and structured routes remain blocked. | Blocked. | Supported strict bounded-response route plus first ordinary `mu` random-effect slices. |
| `zero_one_beta()` | Fitted fixed-effect `[0, 1]` route with interior `mu`/`sigma`, exact-boundary probability `zoi`, and conditional-one probability `coi`; independent mixture-likelihood, recovery, Wald-row, fitted-response, simulation, malformed-neighbour tests, and Phase 18 artifact helpers exist. | Blocked; the first slice is fixed-effect only. | Blocked. | Supported fixed-effect zero-one bounded-response route for structural exact 0/1 mass. |
| `beta_binomial()` | Fitted denominator-aware route for `cbind(successes, failures)` with `mu` and `sigma`; likelihood, denominator, prediction, Wald-row, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted for counted successes out of known trials; `sigma`, correlated slopes, labels, `zoi`/`coi`, and structured routes remain blocked. | Blocked. | Supported success-rate route plus first ordinary `mu` random-effect slices. |
| `poisson(link = "log")` | Fitted fixed-effect count route, including offsets and zero-inflated fixed-effect `zi` when requested. | Ordinary non-zero-inflated `mu` random intercepts and independent numeric slopes are fitted and have Phase 18 smoke/grid evidence. `zi` random effects are blocked. | Ordinary q=1 phylogenetic `mu` intercept is fitted with smoke/formal infrastructure; broader structured count paths are blocked. | Supported fixed-effect and first ordinary/phylogenetic `mu` random-effect count route. |
| `nbinom2()` | Fitted fixed-effect mean-overdispersion route, including fixed-effect `zi` when requested. | Ordinary non-zero-inflated `mu` random intercepts and independent numeric slopes are fitted; ordinary `sigma ~ z + (1 | id)` is fitted as a narrow log-overdispersion random-intercept gate. | Ordinary q=1 phylogenetic `mu` intercept is fitted but remains held at smoke/formal-admission status after the completed 500-replicate shard audit. | Supported fixed-effect and first count mixed-model route; broad NB2 scale/structured parity remains blocked. |
| `truncated_nbinom2()` | Fitted positive-count fixed-effect route with `mu` and `sigma`; likelihood, prediction, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts and independent numeric slopes are fitted; correlated slopes, `sigma`, hurdle-side, and structured routes remain blocked. | Blocked. | Supported positive-count route plus first ordinary `mu` random-effect slices. |
| `truncated_nbinom2()` with `hu ~ ...` | Fitted hurdle NB2 fixed-effect route with `mu`, `sigma`, and `hu`; likelihood, fitted-response, and boundary tests exist. | Blocked for `hu` and positive-count random effects. | Blocked. | Supported fixed-effect hurdle route. |
| `cumulative_logit()` | Fitted fixed-effect ordinal location route with ordered cutpoints and expected-score prediction evidence. | Blocked. | Blocked. | Supported fixed-effect ordinal route. |

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
- ordinary Poisson and NB2 q=1 structured `mu` intercepts are fitted for
  `phylo()`, `spatial()`, `animal()`, and `relmat()`, but the
  merged sharded 500-replicate NB2 artifact audit kept the q1 NB2 promotion gate
  at `hold_smoke_only`;
- correlated zero-truncated NB2 slopes, zero-inflation or hurdle random
  effects, correlated count slopes, labelled non-Gaussian covariance blocks,
  structured
  count slopes, NB2 `sigma` slopes, beta `sigma` or slope random effects, and
  simultaneous structured types, structured `sigma`, and non-count
  spatial/animal/`relmat()` effects remain planned or blocked.

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
- counted successes out of known trials stay on `beta_binomial()`, where 0 and
  all-success rows can be ordinary sampling outcomes;
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
