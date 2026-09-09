# 🎯 GOAL

```text
Platform: Codex. Lane: temporal-covariance-programme; other live Codex lanes are
temporal-ou-v1 and ordinary-laplace-bridge, whose files this programme does not claim.
Deliverable: a master Ultra Plan and Unlazy programme ledger for Gaussian temporal
covariance in drmTMB, from the completed AR1 and OU providers through the six-part
roadmap.
HEADLINE: give applied scientists a small set of temporal models chosen by the
scientific process, while keeping stable, temporal, residual, phylogenetic and spatial
variation distinguishable.
IN PARALLEL: source mapping and reader teaching occur beside each bounded model arc;
they never substitute for the model's dense-oracle validation.
DEFER: automatic implementation of the item-6 candidates, generic covariance syntax,
non-Gaussian temporal models, temporal slopes, forecasting, and a spatiotemporal or
phylogeny-by-time field.
DISCIPLINE: verify = independently coded covariance, likelihood and simulation oracles;
compute = local timing pilot, Totoro rehearsal/storage, then an approved DRAC/Fir
campaign only when an arc needs calibration; closure = all arc gates reverified,
reviewed, rendered, checked and locally committed.
```

## Status and decision

This is a programme plan, not an implementation approval. It starts from the completed
independent-series Gaussian AR1 and OU provider on
`codex/temporal-ou-v1-20260908`, whose planning tip is `a1d01dab3`. That branch
was 67 commits ahead of locally recorded `origin/main` on 2026-09-09; every execution
arc must pin its actual source rather than assume that provider has landed.

The next bounded implementation is already planned separately: a phylogenetically
correlated stable intercept plus an independent within-species OU process. It remains
first because it tests the requested phylogeny-plus-time workflow without silently
turning it into a separable phylogeny-by-time field. Its plan is
[`2026-09-09-phylo-temporal-ou/PLAN.md`](../2026-09-09-phylo-temporal-ou/PLAN.md)
on the OU branch.

After that slice, homogeneous Toeplitz is the next temporal model. We plan the whole
route through item 6 now, but only implement an item-6 model after a named scientific
use case chooses it.

## Scientific language shared by every arc

For a repeated series, distinguish the predictable mean, stable series difference,
temporally correlated departure and independent observation noise:

\[
y_{it}=x_{it}^{T}\beta+b_i+a_{it}+\epsilon_{it}.
\]

The existing ordinary intercept supplies \(b_i\), where admitted. A temporal provider
defines covariance of \(a_{it}\); `sigma` remains the scale of \(\epsilon_{it}\).
A phylogenetic provider changes covariance among stable \(b_i\)'s; a spatial provider
changes covariance among spatial effects. Neither is a synonym for a temporal kernel.
`rho12` remains the bivariate residual correlation and is not a temporal parameter.

All first releases stay univariate Gaussian ML with fixed mean predictors, offsets and
`sigma ~ 1`. They use native TMB likelihoods, structured output, in-sample fitted
values/residuals, conditional modes and simulation. Each arc decides its own fixed-effect
inference only after an independent full-Hessian or profile target is validated; no
interval result transfers between covariance structures.

## The programme order

| Order | Structure and proposed keyword | Scientific question | Initial data boundary |
| --- | --- | --- | --- |
| 1 | AR1, `"ar1"` | Do deviations persist one discrete occasion at a time, possibly with negative lag-one association? | Integer occasions; genuine gaps preserved. |
| 2 | OU, `"ou"` | Does positive persistence decay continuously with elapsed time? | Numeric elapsed time, including irregular gaps. |
| 2a | Stable phylogeny + independent OU | Are evolutionary baseline similarity and within-species time variation both needed? | Valid tree plus OU admission. |
| 3 | Homogeneous Toeplitz, `"homtoep"` | Do discrete lag correlations depart from AR1's exponential pattern while process SD stays constant? | Common, equally spaced discrete schedule; enough replicated series and lag pairs. |
| 4 | Heterogeneous AR1, `"hetar1"` | Does AR1 persistence remain plausible while temporal process variability differs by occasion? | Common ordered occasions with support at each occasion. |
| 5 | Heterogeneous Toeplitz, `"hettoep"` | Do both lag correlations and occasion-specific process SDs vary? | Large, replicated common schedule; much stronger information than item 4. |
| 6 | Seasonal, trend/random walk, ARMA, temporal Matérn | Is the process cyclic, nonstationary, driven by persistent shocks, or smoother/rougher than OU? | Defined separately below. |

The names `"homtoep"` and `"hettoep"` are internal proposals. They avoid assuming
that another package's historical `toep` label means the same variance convention.
The user interface remains coherent:

```r
temporal(1 | id, time = occasion, structure = "homtoep")
```

No arc adds `p`, `q`, season or smoothness formulae until its model-specific plan
has chosen a parameterisation and scientific interpretation.

## Arc T3 — homogeneous Toeplitz

For shared ordered occasion levels \(k,l\), estimate

\[
\operatorname{Cov}(a_{ik},a_{il})=s_a^2r_{|k-l|},\qquad r_0=1.
\]

AR1 is the nested restriction \(r_d=\phi^d\). There is one process SD and one
admissible correlation parameter per nonzero lag. The implementation must not accept an
arbitrary vector \((r_1,\ldots,r_{K-1})\), because its matrix may not be positive
definite. Before fitting, the arc will choose and document a positive-definite map,
comparing partial-autocorrelation/Levinson recursion, constrained Cholesky and any
equivalent native form against four requirements: valid correlation matrices,
identifiable reported lag correlations, TMB differentiability, and a dense-oracle map.

The initial public version uses a common schedule represented by integer occasion levels.
It never turns irregular elapsed time into ranks. A row with a missing response follows
the package omission policy, but its retained layout must still pass explicit occasion and
pair-support checks. Balanced panels are required in deterministic validation; any
unbalanced admission is a separate tested decision.

T3 must compare against AR1, a diagonal temporal process and a dense multivariate-normal
oracle. Mutations must detect an invalid correlation map, a non-Toeplitz entry, a
compressed gap, an omitted normalizer, shared states across series and a dropped ordinary
intercept from a combined model.

## Arc T4 — heterogeneous AR1

For occasion-specific process SDs \(s_k>0\), estimate

\[
\operatorname{Cov}(a_{ik},a_{il})=s_ks_l\phi^{|k-l|}.
\]

This answers a different question from `sigma ~`: the latent temporal process varies by
occasion while residual measurement noise stays constant. It does not give every
observation its own variance. Initial admission requires a common ordered schedule,
positive replication at each occasion and declared minimum support for every reported SD.
The arc must demonstrate the homogeneous AR1 reduction when all \(s_k\) are equal, the
diagonal reduction at \(\phi=0\), and correct process-versus-residual labels in
extraction and simulation.

## Arc T5 — heterogeneous Toeplitz

Estimate

\[
\operatorname{Cov}(a_{ik},a_{il})=s_ks_lr_{|k-l|}.
\]

It combines T3's positive-definite Toeplitz correlation with T4's occasion-specific
process SDs. Its parameter count grows quickly with occasions, so the first release is
limited to a prespecified maximum number of common levels, a large replicated panel and
an information diagnostic. T5 does not inherit support merely because T3 and T4 pass.
Its recovery plan must include a low-information stress cell that can fail visibly.

## Arc T6 — a decision map, not a queue of promised code

| Candidate | Start only when the data-generating question is this | First restricted form | Do not use it merely because |
| --- | --- | --- | --- |
| Seasonal | The same ecological or measurement cycle repeats at a known period after mean covariates are considered. | One declared period and a stationary seasonal covariance/state model. | A covariate happens to be monthly. |
| Trend / random walk | The latent baseline can drift without returning to a fixed stationary distribution. | One proper state evolution with an explicit initial-state rule. | A stationary fit leaves an apparent visual trend. |
| ARMA | A regular repeated panel has within-series persistence plus a short-lived shock that carries to the next observation. | ARMA(1,1) only, with independent ARMA processes within each `id`, one shared regular schedule, and explicit stationarity/invertibility transforms. | ACF/PACF plots suggest a higher order after looking at the same data. |
| Temporal Matérn | Continuous time needs a smoothness class different from OU; OU is Matérn \(\nu=1/2\). | One fixed smoothness candidate, selected by the use case and benchmarked against OU. | A spatial Matérn provider already exists. |

ARMA is technically reachable, but it is not the cheap next step after Toeplitz. It is
a state/innovation model, not a sum of independent AR and MA random effects. Its first
form is one independent process per sampled individual or site; a population-wide shared
temporal shock is a different future model. Even ARMA(1,1) needs a stationary initial-
state distribution, differentiable stationarity and invertibility transforms, regular
time, independent dense/state-space likelihood agreement, innovation-aware simulation
and a new forecasting boundary. The supplied
[Matilda ARMA guide](https://matilda.fss.uu.nl/articles/arma-model.html) makes the same
basic distinction and warns that model order needs substantive justification rather than
mechanical ACF/PACF selection.

Every T6 candidate begins with four tickets before production code: a named
ecology/evolution use case and data layout; a covariance/state contract with nested
reductions; a simulation/recovery design; and a reader workflow explaining why AR1, OU
and Toeplitz were inadequate. Without that case, it remains deferred.

## What drmTMB learns from glmmTMB

The official glmmTMB covariance documentation is a source map: it documents AR1, OU,
Toeplitz, heterogeneous AR1, Matérn and other structures, and marks several structured
choices experimental. [Covariance vignette](https://glmmtmb.github.io/glmmTMB/articles/covstruct.html)
and [reference](https://glmmtmb.github.io/glmmTMB/reference/glmmTMB.html).

drmTMB should learn its model names, parameterisation questions and warning posture. It
should not copy factor-level time semantics, silently rank elapsed time, or present all
models through a generic unbounded syntax. Its existing phylogenetic and spatial
providers remain separate covariance axes. A separable phylogeny-by-time or
spatiotemporal field needs a separate plan.

## Delivery architecture

Each implementation arc follows the same lifecycle:

1. **Freeze:** pin source, formula, covariance, inference boundary and executable
   Unlazy ledger before code.
2. **Native model:** build parser/layout, native likelihood and a separately coded dense
   covariance oracle. T3 also freezes the positive-definite map before fitting.
3. **Public workflow:** add extraction, prediction, simulation and diagnostic labels; render
   one realistic reader example.
4. **Evidence:** retain reductions/mutations, recovery and a timed local pilot. If the
   measured campaign exceeds 30 minutes, propose DRAC/Fir resources and wait for separate
   campaign approval; mirror retained artifacts to Totoro.
5. **Close:** obtain independent mathematical and reader reviews, reverify gates, run
   package checks, write an after-task report and commit locally.

No more than two production leaves run concurrently. Parser/native/method work is
sequential within an arc. Once the native interface stabilises, evidence and reader work
may overlap only with disjoint ownership.

| Part | Owner/lens | First output | Depends on |
| --- | --- | --- | --- |
| P0 source map | Ada + Ranga | Exact source pin; official/primary source map; NotebookLM distillation | G0 |
| P1 phylogeny + OU | Ada, Gauss, Noether, Pat | Existing phylo-temporal-OU plan | P0 |
| P2 homogeneous Toeplitz | Boole, Gauss, Curie, Fisher | T3 plan and positive-definite decision | P1 closeout |
| P3 heterogeneous AR1 | Boole, Gauss, Curie, Pat | T4 plan and common-schedule admission | P2 closeout |
| P4 heterogeneous Toeplitz | Gauss, Fisher, Curie | T5 information boundary and recovery design | P3 closeout |
| P5 candidate selection | Ranga, Darwin, Noether | One T6 ticket or documented deferral | P4 closeout or a real use case |
| P6 integration | Ada, Rose | Reader article refresh and plan-versus-actual record | Every implemented arc |

The NotebookLM task is bounded: collect primary or official sources for Toeplitz validity,
heterogeneous covariance and one selected T6 candidate; distinguish verified sources from
leads; file a citation-backed distillation before a plan claims a scientific use case. It
does not decide the native likelihood.

## Programme gates and authority

[`unlazy/GATES.md`](unlazy/GATES.md) contains 19 gates: 16 runnable planning or
arc-contract checks and three manual gates (G0, G12, G17). Its exact runner is
`unlazy/check-programme.R`. The runner's self-test must pass before an execution arc
relies on it. This programme stays pending until the user approves the exact sequence and
an implementation arc pins its source. Each future arc writes its own executable ledger;
it may add gates but may not weaken this programme's boundaries.

Routine scoped edits, tests, local rendering and local commits belong to an approved arc's
reversible envelope. Compute campaigns, pushes, merges, releases, deployments and external
messages remain separately authorized. A final programme reverify reads retained evidence;
it never launches a new campaign.

## Prior-work receipt

| Surface | Inspection | Finding |
| --- | --- | --- |
| Current temporal branch | AR1/OU code, OU closeout and `a1d01dab3` plan | AR1 and OU already define independent temporal processes. |
| Current planning branch | 2026-09-08 AR1 plan and Unlazy templates | Reuse gate discipline, not its AR1-only scope. |
| glmmTMB | Official covariance vignette/reference | Broad source map; experimental labels and factor-level semantics require a narrower drmTMB contract. |
| Matilda | ARMA page supplied by the user | ARMA combines AR and MA dynamics; order needs substantive justification. |
| NotebookLM inventory | Connected inventory read on 2026-09-09 | No dedicated temporal-covariance notebook found; P0 creates a bounded cited source map. |
| Brain retrieval | Memory record and attempted local search | Existing decisions separate phylogenetic, spatial and temporal variation; restricted-sandbox local search failed, so no unsupported retrieval result is treated as evidence. |

## Explicit deferrals

This programme does not authorize a generic `temporal_covariance()` API, arbitrary
higher-order ARMA selection, multivariate/non-Gaussian temporal likelihoods, temporal
random slopes, time-varying residual `sigma`, forecasts/newdata intervals, automatic
model selection, periodicity discovery, covariance-parameter regression, a gllvmTMB port,
a phylogeny-by-OU field or a spatial-temporal product. Each needs its own scientific and
numerical contract.
