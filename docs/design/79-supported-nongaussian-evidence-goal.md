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
| `student()` | Fitted `mu`, `sigma`, and `nu`; likelihood, interval, malformed-input, and fixed-effect shape simulation evidence exist. | Ordinary unlabelled `mu` random intercepts are fitted; `sigma`, `nu`, slopes, and labelled covariance remain blocked. | Blocked for phylogenetic, spatial, animal, `relmat()`, and bivariate Student-t paths. | Supported fixed-effect heavy-tail route plus a first `mu` random-intercept slice. |
| `lognormal()` | Fitted `mu` on the log-response scale and `sigma`; likelihood, fitted-response, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts are fitted; `sigma`, slopes, labels, structured effects, and known covariance remain blocked. | Blocked. | Supported positive-response route plus a first `mu` random-intercept slice. |
| `Gamma(link = "log")` | Fitted mean-CV route with `log(mu)` and `log(sigma)`; likelihood, recovery, prediction, and non-log-link boundary tests exist. | Ordinary unlabelled `mu` random intercepts are fitted; `sigma`, slopes, labels, structured effects, and known covariance remain blocked. | Blocked. | Supported positive-response route plus a first `mu` random-intercept slice. |
| `beta()` | Fitted strict `(0, 1)` response route with `logit(mu)` and public `sigma`; likelihood, prediction, Wald-row, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts are fitted for strict `(0, 1)` responses; `sigma`, slopes, labels, exact 0/1 mass, and structured routes remain blocked. | Blocked. | Supported bounded-response route plus a first `mu` random-intercept slice. |
| `beta_binomial()` | Fitted denominator-aware route for `cbind(successes, failures)` with `mu` and `sigma`; likelihood, denominator, prediction, Wald-row, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts are fitted for counted successes out of known trials; `sigma`, slopes, labels, `zoi`/`coi`, and structured routes remain blocked. | Blocked. | Supported success-rate route plus a first `mu` random-intercept slice. |
| `poisson(link = "log")` | Fitted fixed-effect count route, including offsets and zero-inflated fixed-effect `zi` when requested. | Ordinary non-zero-inflated `mu` random intercepts and independent numeric slopes are fitted and have Phase 18 smoke/grid evidence. `zi` random effects are blocked. | Ordinary q=1 phylogenetic `mu` intercept is fitted with smoke/formal infrastructure; broader structured count paths are blocked. | Supported fixed-effect and first ordinary/phylogenetic `mu` random-effect count route. |
| `nbinom2()` | Fitted fixed-effect mean-overdispersion route, including fixed-effect `zi` when requested. | Ordinary non-zero-inflated `mu` random intercepts and independent numeric slopes are fitted; ordinary `sigma ~ z + (1 | id)` is fitted as a narrow log-overdispersion random-intercept gate. | Ordinary q=1 phylogenetic `mu` intercept is fitted but held at smoke/formal-admission status until the 500-replicate shard audit lands. | Supported fixed-effect and first count mixed-model route; broad NB2 scale/structured parity remains blocked. |
| `truncated_nbinom2()` | Fitted positive-count fixed-effect route with `mu` and `sigma`; likelihood, prediction, and boundary tests exist. | Ordinary unlabelled `mu` random intercepts are fitted; slopes, `sigma`, hurdle-side, and structured routes remain blocked. | Blocked. | Supported positive-count route plus a first `mu` random-intercept slice. |
| `truncated_nbinom2()` with `hu ~ ...` | Fitted hurdle NB2 fixed-effect route with `mu`, `sigma`, and `hu`; likelihood, fitted-response, and boundary tests exist. | Blocked for `hu` and positive-count random effects. | Blocked. | Supported fixed-effect hurdle route. |
| `cumulative_logit()` | Fitted fixed-effect ordinal location route with ordered cutpoints and expected-score prediction evidence. | Blocked. | Blocked. | Supported fixed-effect ordinal route. |

## Count Mixed-Model Closeout

The count mixed-model surface is deliberately narrower than the fixed-effect
family suite:

- ordinary Poisson and NB2 `mu` random intercepts and independent numeric
  slopes are admitted as first non-Gaussian count random-effect slices;
- ordinary Student-t, zero-truncated NB2, lognormal, Gamma, and beta `mu`
  random intercepts are admitted as narrow source-tested first slices;
- ordinary NB2 `sigma ~ z + (1 | id)` is admitted as a separate
  overdispersion-random-intercept smoke lane;
- ordinary Poisson and NB2 q=1 phylogenetic `mu` intercepts are fitted, but the
  formal q=1 NB2 promotion gate remains open until the sharded 500-replicate
  artifacts are merged and audited;
- zero-truncated NB2 random slopes, zero-inflation or hurdle random effects,
  correlated count slopes, labelled non-Gaussian covariance blocks, structured
  count slopes, NB2 `sigma` slopes, beta `sigma` or slope random effects, and
  non-Gaussian spatial/animal/`relmat()` effects remain planned or blocked.

## NB2 q1 Formal Shard Execution Rule

The next compute action is operational rather than statistical. Dispatch all 16
`nbinom2_phylo_q1_formal` shards from a workflow whose concurrency group
includes the shard index and shard count, then audit only the merged artifact
set. No single shard may set a promotion claim.

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

Until that audit lands, the NB2 q1 phylogenetic route remains
`hold_smoke_only`.

## Claim Boundary

The completed claim should be:

> drmTMB has an evidence-backed supported non-Gaussian fixed-effect family
> suite, plus first-slice ordinary `mu` random intercepts for selected
> non-Gaussian families, first-slice ordinary Poisson/NB2 count slopes, the
> narrow NB2 log-`sigma` random-intercept gate, and smoke/formal-admission
> Poisson/NB2 q=1 phylogenetic `mu` gates.

It should not be:

> drmTMB has broad non-Gaussian random-effect or structured-effect parity with
> Gaussian models.
