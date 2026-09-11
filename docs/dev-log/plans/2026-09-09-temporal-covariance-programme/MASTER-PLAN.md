# Temporal covariance Ultra Master Plan

## 🎯 GOAL

~~~text
Platform: Codex. Planning lane: codex/temporal-ar1-plan-20260908.
Execution lane: a fresh worktree pinned from the completed temporal OU source before
any package file changes.
Deliverable: Gaussian temporal covariance models delivered in a gated sequence:
phylogenetic-stable plus independent OU, homogeneous Toeplitz, heterogeneous AR1,
heterogeneous Toeplitz, then one science-triggered item-6 candidate.
Headline: distinguish stable differences, temporal dependence and residual noise without
making a broad unsupported covariance menu.
Parallel work: source mapping, deterministic oracle design and reader workflows only
after each arc's parser/native contract is frozen.
Deferred: generic arbitrary covariance, higher-order ARMA, non-Gaussian temporal models,
temporal slopes, forecasting, a separable phylogeny-by-time field and spatiotemporal
fields.
Evidence: dense covariance/likelihood/score/Hessian oracles, mutation tests, retained
recovery, timed pilots, approved campaigns, independent review, rendered documentation
and a clean local commit per arc.
~~~

This document is the detailed execution specification. PLAN.md remains the concise
scientific roadmap. The master execution ledger is MASTER-GATES.md. A downstream arc
may add gates, but cannot weaken a condition here.

## Programme invariant

For every admitted repeated series:

\[
y_{it}=x_{it}^{T}\beta+b_i+a_{it}+\epsilon_{it}.
\]

The terms mean different things. Ordinary or phylogenetic structure defines stable
differences in b. The temporal provider defines a. sigma describes independent residual
noise. Spatial and phylogenetic covariance remain separate axes. rho12 remains a
bivariate residual correlation, never a temporal parameter.

Every first release is univariate Gaussian ML with fixed mean predictors, offsets and
sigma ~ 1. All covariance parameters are estimated in the native objective. Existing
AR1 and OU output conventions are reused only when their meaning is unchanged.

## Team, model and effort routing

| Role | Named lens | Model and effort | Owns | May not decide alone |
| --- | --- | --- | --- | --- |
| Programme owner | Ada | Terra high | source pins, dependency order, integration gates, final reconciliation | scientific promotion after a failed calibration |
| Source map | Ranga | Sol high, bounded | NotebookLM corpus, official/documented precedents, cited distillation | likelihood parameterisation |
| Formula/API | Boole | Astra high | temporal marker grammar, admissions, errors, metadata vocabulary | native numerical shortcuts |
| Native likelihood | Gauss | Astra high | TMB parameters, transforms, likelihood, starts and diagnostics | reader-facing scope |
| Oracle/recovery | Curie | Terra medium | independently coded dense references, mutations, recovery fixtures | inference claims |
| Inference | Fisher | Astra high | Hessian/profile target, calibration design and failure interpretation | changing thresholds after results |
| Methods | Emmy | Terra high | extractors, simulation, prediction/residual support and S3 coherence | covariance mathematics |
| Reader workflow | Pat | Terra medium | applied article, errors and rendered workflow | statistical promotion |
| Mathematical review | Noether | Astra high, bounded | symbolic/API/TMB alignment before every native merge | implementation ownership |
| Closure | Rose | Terra high | evidence audit, after-task, plan-versus-actual and stale-claim scan | acceptance of missing evidence |

Astra is reserved for the formula, native and adversarial mathematical decisions. Terra
does routine implementation, tests, documentation and integration. Sol is used only for
the bounded source map. At most two production children run at once. Parser, likelihood
and public-method work remain sequential within an arc.

### Dispatch board: phases, agents and hand-offs

Every covariance arc follows the same seven work packages. This is the execution order,
not a menu of optional perspectives. S4 and S5 may overlap only after S3 is green; all
other packages are sequential. A named owner accepts a path lease, writes the specified
artifact, runs its gate, and hands the recorded artifact to the next owner.

| Slice | Owner — model / effort | May start only when | Required product | Gate family | Handoff to |
| --- | --- | --- | --- | --- | --- |
| S0 contract and source freeze | Ada — Terra / high; Ranga — Sol / high | parent arc is admitted | source pin, child Unlazy ledger, cited source note, explicit exclusions | M00–M03 / child G0–G1 | Boole |
| S1 formula and layout | Boole — Astra / high | S0 gate is green | canonical `temporal()` call, admissibility code, raw-data diagnostics, parser tests, formula-grammar update | grammar gate | Gauss |
| S2 native likelihood | Gauss — Astra / high; Noether — Astra / high review | S1 is green | transform/start table, TMB provider, likelihood tests, likelihood-design update | native gate | Emmy and Curie |
| S3 public methods and inference boundary | Emmy — Terra / high; Fisher — Astra / high review | S2 native objective is green | labels, modes, fitted/residual/simulation behavior, interval boundary and diagnostics | methods gate | Curie |
| S4 oracle, mutations and recovery/pilot | Curie — Terra / medium; Fisher — Astra / high | S2 and S3 are green | independent dense reference, mutation tests, immutable fixtures, recovery/pilot receipt and compute estimate | oracle, recovery, pilot gates | Rose and Pat |
| S5 reader workflow | Pat — Terra / medium; Darwin — Terra / medium review | S3 is green | rendered vignette section with one ecological question, model-choice table and recovery guidance | render gate | Rose |
| S6 integration and close | Ada + Rose — Terra / high; Noether and Pat/Darwin independent reviews | S4 and S5 are green | package checks, review receipts, after-task report, plan-versus-actual and exact local commit | close gate | next child arc or explicit deferral |

The named model and effort are a routing recommendation, not a claim that a particular
agent is already running. Ada may substitute an equivalent available model only if the
record says why; the mathematical-review effort may not be lowered without a recorded
reason. Noether plus Pat or Darwin must independently review every structure before its
close gate can pass.

### Parent-to-child launch rule

P2, P3, P4 and any Phase-5 candidate are **not** implicitly authorised merely because
they appear in this master plan. The direct temporal OU parent closed at `0d66e62f3`; the optional phylogenetic-stable plus OU composition remains a separate extension whose pending calibration does not block P2. Ada opens a child arc only after its parent close gate is green and the following child receipt is committed: current source pin; exact public
interface check against the parent; S0–S6 file ownership; a fresh executable Unlazy
ledger; named oracle/mutation set; compute estimate; and a reader question. For P4 and
P5 it also records the concrete scientific data/use case. A later child may strengthen
this master plan but cannot weaken its gates or change a frozen campaign after results
are seen. The sole recorded exception is the 2026-09-11 user-authorized P1 evidence
amendment: it preserves the frozen G13 campaign and its failed coverage rows, while
changing the programme's promotion target from calibrated inference to interval
feasibility. It does not turn failed rows into passes or license a coverage claim.

## Shared implementation architecture

| Layer | Shared responsibility | Required rule |
| --- | --- | --- |
| Formula parser | temporal(1 | id, time = time, structure = keyword) | Reject unsupported combinations before response omission; preserve original row order. |
| Layout builder | sorted internal id/time nodes and original-row mapping | Never compress genuine time gaps or silently share a state between ids. |
| TMB provider | latent states, unconstrained parameters and normalized prior | A learned covariance parameter stays on the AD tape; no frozen R-side precision matrix. |
| Dense oracle | independently constructed marginal V and Gaussian likelihood | It cannot reuse the production provider's covariance builder. |
| Methods | labels, modes, simulation, fitted values and residuals | Report process SD, stable SD and residual sigma separately. |
| Evidence | deterministic fixture, mutation suite, recovery and pilot | Preserve every attempt, failure, seed, fingerprint and denominator. |
| Reader article | one biological question per structure | Explain why a simpler structure was inadequate. |

### Cross-arc parser and omission contract

Every temporal layout stores the same metadata: `id`; raw time/occasion values; sorted
internal values; retained-to-original row map; per-series offsets; genuine gaps;
structure keyword; level labels; and the error class/message used for rejection. The
parser validates raw id/time/tree metadata and duplicate keys **before** response
omission. It then applies the package's listwise omission rule, rebuilds the retained
layout, preserves real gaps, and rejects retained singleton temporal paths. Discrete
models additionally require every retained id to have the complete common schedule.
Methods and dense oracles consume this stored layout, rather than independently ranking
or reconstructing times. Each closeout updates
`docs/design/01-formula-grammar.md` with the admitted marker and early errors, and
`docs/design/03-likelihoods.md` with the matching covariance equation.

### Formula, parameter and output matrix

| Arc | Canonical call and time | Native parameters and transform | Start policy | Public labels and diagnostic | Early rejection |
| --- | --- | --- | --- | --- | --- |
| P1 phylo + OU | `phylo(1 | species, tree = tree) + temporal(1 | species, time = elapsed, structure = "ou")`; finite elapsed numeric time | `log(sd_phylo_stable)`, `log(sd_temporal)`, `log(decay_temporal)`, `log(sigma)` | fixed-only residual variance divided across positive variance components; two positive decay starts; retain every attempt | `sd_phylo_stable`, `sd_temporal`, `decay_temporal`, `sigma`; boundary and weak-identification diagnostics | unmatched tips, duplicate species-time keys, singleton retained paths, ordinary intercept, slopes, REML, newdata |
| P2 homtoep | `temporal(1 | id, time = occasion, structure = "homtoep")`; common equally spaced integer levels, at most 12 | `log(sd_temporal)`, chosen unconstrained valid-Toeplitz map, `log(sigma)`; P2.0 selects and tests the map before native code | fixed-only variance split; deterministic map starts recorded with P2.0 | `sd_temporal`, `cor_lag1`, …, `cor_lagK`, `sigma`; invalid-map/weak-information diagnostics | irregular time, aliases, partial schedule, duplicate id-level key, temporal scale formula |
| P3 hetar1 | `temporal(1 | id, time = occasion, structure = "hetar1")`; common equally spaced integer levels, at most 12 | `log(sd_level_k)` for each level, `atanh(phi)`, `log(sigma)`; `phi = tanh(eta)` permits both signs | fixed-only variance split across level SDs and sigma; `phi` starts at -0.3 and 0.3 | `phi`, `sd_temporal[level]`, `sigma`; level-specific boundary diagnostics | P2 discrete-layout failures plus unmatched level labels |
| P4 hettoep | `temporal(1 | id, time = occasion, structure = "hettoep")`; common equally spaced integer levels, at most 8 | `log(sd_level_k)`, P2.0's proven valid-Toeplitz map, `log(sigma)` | fixed-only variance split; fixed valid-correlation starts frozen before recovery | `sd_temporal[level]`, `cor_lag1`, …, `cor_lagK`, `sigma`; parameter-to-information warning | P2 discrete-layout failures, aliases and any invalid correlation map |

`sd_temporal` always denotes a stationary process SD, never an innovation SD. The map
used by P2 and P4 must be named and documented only after P2.0's positive-definiteness,
reconstruction and derivative gates pass; the plan does not pretend that choice is
already settled.

All execution arcs use one fresh worktree. The entry source is currently
a1d01dab3dbcd6e12bec0486ac0425f939f20c2d. G00 records the immutable source hash,
native-library hash and plan revision. The execution branch must not assume this local
source has landed on origin/main.

### File ownership before dispatch

| Arc | Parser/layout owner | Native/method owner | Oracle/evidence owner | Reader/closure owner |
| --- | --- | --- | --- | --- |
| P1 phylo + OU | R/formula-markers.R, R/parse-formula.R, R/temporal.R, R/drmTMB.R, R/check.R | src/drmTMB.cpp, R/methods.R, R/simulate.R, R/profile.R | tests/testthat/test-phylo-temporal-ou*.R, tests/testthat/helper-phylo-temporal-ou-reference.R, tools/phylo-temporal-ou-*.R | vignettes/phylogenetic-temporal-effects.Rmd, README.md, NEWS.md, _pkgdown.yml, docs/design/01-formula-grammar.md, docs/design/03-likelihoods.md, docs/dev-log/known-limitations.md, arc ledger, plan-versus-actual, check-log and closeout records |
| P2 homogeneous Toeplitz | R/formula-markers.R, R/parse-formula.R, R/temporal.R | src/drmTMB.cpp, R/drmTMB.R, R/methods.R, R/simulate.R | tests/testthat/test-temporal-homtoep*.R, tests/testthat/helper-temporal-homtoep-reference.R, tools/temporal-homtoep-*.R | vignettes/temporal-random-effects.Rmd plus design/reference docs |
| P3 heterogeneous AR1 | same parser path, after P2 transfer | src/drmTMB.cpp, R/drmTMB.R, R/methods.R, R/simulate.R | tests/testthat/test-temporal-hetar1*.R, helper-temporal-hetar1-reference.R, tools/temporal-hetar1-*.R | same article, expanded decision table and closeout records |
| P4 heterogeneous Toeplitz | same parser path, after P3 transfer | src/drmTMB.cpp, R/drmTMB.R, R/methods.R, R/simulate.R | tests/testthat/test-temporal-hettoep*.R, helper-temporal-hettoep-reference.R, tools/temporal-hettoep-*.R | same article, information warning and closeout records |

No worker claims the whole row. Ada transfers a single path group after its predecessor
is verified; a path-specific lease is mandatory before every write. The first P1
implementation cannot start on this planning branch.

### Gate-to-artifact map

| Slice | Runner and fixture owner | Retained artifacts | Gate proves |
| --- | --- | --- | --- |
| S0 | Emmy owns runner self-tests; Ranga owns source receipt | child ledger, source fingerprint, source map, negative-control receipt | the runner fails closed and the source basis is traceable |
| S1 | Boole owns parser test file | accepted/rejected formula fixtures, stored-layout inspection and grammar doc edit | an admitted call maps to the intended layout before native fitting |
| S2 | Gauss owns native test hooks; Noether reviews | transform/start table, native code receipt and likelihood doc edit | parameters remain differentiable and match the stated model |
| S3 | Emmy owns methods test file | labelled extractor/mode/simulation/profile tests and limitation entry | public methods expose only what the evidence supports |
| S4 | Curie owns independent helper and gate runner; Fisher reviews recovery | dense V/NLL/score/Hessian, mutations, frozen seeds, pilot/campaign receipt | likelihood identity and claimed inference/recovery evidence hold |
| S5 | Pat owns vignette/render check | runnable biological example, rendered HTML/PDF inspection and reader review | a scientist can choose, fit and interpret the structure |
| S6 | Rose owns reconciliation runner; Ada integrates | package-check record, Noether and Pat/Darwin reviews, after-task and plan-actual report | no unstated evidence, documentation or handoff gap remains |

## Phase 0 — freeze, source map and execution foundation

### Deliverables

1. Create a clean worktree from the pinned OU source and claim only the paths for P1.
2. Stage the P1 Unlazy ledger from the existing phylo-temporal-OU plan.
3. Emmy, Terra high, materializes tools/phylo-temporal-ou-gates.R and
   tools/temporal-source-map-gates.R plus their runner self-tests. The former fails on a
   missing fixture, stale source fingerprint and incomplete receipt; the latter fails on
   an uncited source or a lead labelled as verified. No model provider is added in this
   bootstrap package. Emmy holds the runner-file lease only through M01-bootstrap, then
   transfers tools/phylo-temporal-ou-gates.R to the P1 oracle/evidence owner.
4. Ranga creates one bounded NotebookLM notebook titled drmTMB temporal covariance source
   map. It contains the official glmmTMB covariance material, the Matilda ARMA guide, a
   primary reference on Toeplitz-positive correlation parameterisation, and one primary
   source for the selected phylogenetic covariance convention.
5. Distil only verified claims into a cited source-map note. Leads stay labelled
   unverified.
6. Commit and fingerprint this master plan revision, then record the current source, exact
   R/TMB versions and native-library fingerprint. M00 cannot be checked against an
   uncommitted or otherwise mutable plan.

### Acceptance

| Gate | Command or evidence | Stop condition |
| --- | --- | --- |
| M00 | Manual: user approval recorded against this master revision | No production file may be edited without it. |
| M01-bootstrap | Runner self-tests and negative controls for P1/source-map runners | M01-M03 may not call a runner that has not been materialized and reviewed. |
| M01 | Rscript --vanilla tools/phylo-temporal-ou-gates.R G1 | Source, runner and plan disagree or runner fails closed. |
| M02 | Ranga source-map receipt with citations and scope note | A source only says a package supports a model; it does not validate drmTMB. |
| M03 | git status and lane lease receipt | Any owned file overlaps another live lane. |

Expected effort: 3 to 5 agent-hours. No simulation and no campaign.

## Phase 1 — phylogenetically stable intercept plus independent OU

### Model contract

\[
b\sim N(0,s_b^2 A),\qquad
\operatorname{Cov}(a_{it},a_{js})=I(i=j)s_a^2\exp\{-\lambda|t-s|\},
\]
\[
V_{rq}=s_b^2A_{i_r i_q}+I(i_r=i_q)s_a^2\exp\{-\lambda|t_r-t_q|\}
       +I(r=q)\sigma^2.
\]

The first model is deliberately not the separable field
\(s_a^2A_{ij}\exp\{-\lambda|t-s|\}\). Cross-species temporal covariance is therefore
stable phylogenetic covariance only.

### Formula, admissions and outputs

~~~r
bf(y ~ treatment +
     phylo(1 | species, tree = tree) +
     temporal(1 | species, time = elapsed_days, structure = "ou"),
   sigma ~ 1)
~~~

Admit Gaussian ML only; finite numeric elapsed time; unique species-time keys; matched
tree tips; at least three observed species; at least two times per species; and at least
three distinct positive lags overall. Reject ordinary same-species intercepts, a second
structured term, REML, non-unit weights, slopes, newdata, temporal scale formulae and
non-Gaussian families.

Validate ID/time/tree metadata and duplicate species-time keys before response omission.
Then apply the existing listwise response/fixed-predictor omission policy. Recompute the
layout from retained rows, preserve genuine elapsed gaps and retain the original-row
mapping. Reject a species with fewer than two retained observations; P1 does not retain a
singleton temporal path. Minimum species, time and lag support is checked after omission.
G2 exercises each stage and its diagnostic.

Report sd_phylo_stable, sd_temporal, decay_temporal and sigma. The first uncertainty
target is fixed-mean profile endpoints only after dense agreement and finite-endpoint
checks pass. This is interval feasibility, not calibrated inference: the retained G13
coverage failures remain visible. Variance and decay intervals, forecasts and newdata
remain unavailable.

### Work packages

| Package | Agent/model | Files | Depends on | Gate |
| --- | --- | --- | --- | --- |
| P1.1 parser/layout | Boole, Astra high | R parser/layout and malformed-input tests | M00-M03 | G2 |
| P1.2 native block | Gauss, Astra high | TMB provider and two-start engine | P1.1 | G3-G6 |
| P1.3 dense oracle | Curie, Terra medium | independent V, score, Hessian, modes, mutations | P1.2 | G3-G7 |
| P1.4 public methods | Emmy, Terra high | extraction, simulation, residual and profile boundary | P1.2-P1.3 | G7-G8 |
| P1.5 recovery/pilot | Curie + Fisher, Terra medium/Astra high | 24 fixtures, 48 starts, five-seed timing pilot | P1.4 | G9-G11 |
| P1.6 reader article | Pat, Terra medium | rendered phylogenetic-temporal article | P1.4 | G14-G15 |
| P1.7 review/close | Noether + Pat + Rose | independent review and after-task | P1.5-P1.6 | G16-G18 |

The exact P1 gates remain those in the existing phylo-temporal-OU ledger: G2 grammar,
G3 dense covariance, G4 likelihood/score/Hessian, G5 reductions, G6 mutations, G7
methods/simulation, G8 profile target, G9 recovery, G10 pilot, G11 campaign contract,
G12 manual campaign approval, G13 retained campaign reverify, G14-G15 reader evidence,
G16 package check, G17 review and G18 closure. At the current execution checkpoint,
The direct temporal OU parent is fully qualified: its grammar, dense oracle, methods, rendered tutorial, package check and 3,000-data-set profile campaign all closed at `0d66e62f3` and campaign source `e57ed8c1`. The separately approved phylogenetic-stable plus OU G9b-full point-recovery study also passes. Its G10 timing pilot, G11 calibration contract and G12 campaign authorization are retained; G13 fails for three intercept-profile coverage rows. On 2026-09-11 the user explicitly reclassified this arc as interval-feasible, not inference-ready. Those extension results do not qualify a separable field and do not block the direct temporal P2 child. P2 closed at `ceff79d53` after its own deterministic, retained point-recovery, timed-pilot, profile-campaign, reader, review and package-check gates.

### Simulation and compute

The recovery design is 24 data sets: balanced and unbalanced layouts, sd_phylo_stable
at 0.3, 0.6 and 1.0, sd_temporal 0.8, sigma 0.4 and decay 0.15, 0.4 and 0.7. Retain both
positive decay starts for each data set and every failure.

The profile campaign is P1-P3 at 80 species with short, longer and unbalanced irregular
series, plus a 20-species stress cell. A local five-seed pilot first measures wall time,
memory, interval availability and output completeness. If the measured campaign exceeds
30 minutes, submit a resource plan for approval. Totoro holds rehearsal and immutable
mirrors. DRAC/Fir runs the approved one-dataset-per-array-task campaign with explicit
thread limits. No login-node compute or GitHub Actions campaign.

Expected implementation effort: 35 to 53 agent-hours plus measured campaign time.

## Phase 2 — homogeneous Toeplitz (closed)

P2 closed at `ceff79d53` on 2026-09-10. The original latent-process form,
`V = s_a^2 R + sigma^2 I`, is retained as a non-public diagnostic because a
one-response-per-ID--occasion panel cannot separately identify free Toeplitz lag
correlations, process scale, and residual scale. The delivered model is the identified
marginal covariance

\[
y_i \sim N(X_i\beta, \sigma_T^2R),
\]

where `R` is a positive-definite homogeneous Toeplitz correlation matrix using the
inverse-Levinson partial-autocorrelation map. `sigma()` is the total within-series SD;
it is not an independent residual SD. The provider admits complete, common, equally
spaced integer panels of three through twelve occasions, preserves row order, supports
mean-effect profile intervals in its frozen panel scope, and directs irregular time to
OU. It does not provide a temporal process in `sigma`.

Its closeout includes deterministic likelihood, derivative, reduction and mutation
evidence; retained point recovery and timing pilot; a separately authorised, retained
profile campaign; rendered reader workflow; independent Noether and Pat reviews; and a
package check. See `docs/dev-log/plans/2026-09-10-temporal-homtoep/unlazy/GATES.md` and
`docs/dev-log/evidence/temporal-homtoep/2026-09-10-p2-closeout.md`.

## Phase 3 — heterogeneous AR1

### Model contract

\[
\operatorname{Cov}(a_{ik},a_{il})=s_ks_l\phi^{|k-l|},\qquad s_k>0.
\]

This is a D R D covariance: D has occasion process SDs and R is AR1 correlation. The
diagonal reduction at phi equal to zero has occasion-specific process variances; it is
not a model for changing residual sigma.

### Admission and outputs

Require a common ordered schedule, adequate replication at every level, a maximum of 12
levels and a support table for every s_k. The canonical public form is:

~~~r
bf(y ~ x + temporal(1 | id, time = occasion, structure = "hetar1"), sigma ~ 1)
~~~

Report phi, each process SD, their level labels and sigma. Reject toep, aliases, an SD
formula, irregular time and a partial occasion schedule before omission with the
unsupported-temporal-structure or invalid-temporal-layout error. Validate raw metadata
first; after listwise omission every retained id must have the full 12-or-fewer common
schedule. P3-grammar fixes that maximum in parameter, label, oracle and error tests.

### Work packages

P3 reuses P2 layout but not P2 evidence. Boole owns grammar; Gauss owns the D R D TMB
block; Curie owns dense V and mutations; Fisher fixes recovery and interval feasibility;
Emmy owns methods; Pat owns the reader workflow; Noether and Rose review/close. The
runner is tools/temporal-hetar1-gates.R.

The executable P3 child receipt is `docs/dev-log/plans/2026-09-11-temporal-hetar1/`. It freezes interval feasibility rather than coverage calibration, retains P1's failed G13 coverage evidence as historical evidence, and requires direct child approval before source changes.

Required reductions: all s_k equal gives homogeneous AR1; phi equal to zero gives a
diagonal latent process; s_k zero for one level is a boundary diagnostic, not dropped
data. Required mutations: swapped process and residual SDs, a mislabelled level, use of
one global SD, missing D factors, compressed gaps and an unsorted level layout.

The recovery suite varies at least three occasion SD patterns, positive and negative phi,
and one near-homogeneous case. A stress cell makes a high-level SD weakly identified.
Expected effort: 40 to 60 agent-hours plus measured campaign time.

## Phase 4 — heterogeneous Toeplitz

### Model contract

\[
\operatorname{Cov}(a_{ik},a_{il})=s_ks_lr_{|k-l|}.
\]

This combines the T3 valid Toeplitz correlation map with T4 level-specific process SDs.
It is the largest routine covariance model in the programme.

### Admission, information and stop rule

The first release fixes a maximum of eight common levels. Require a large replicated
panel and sufficient pair support by level and lag. The canonical public form is:

~~~r
bf(y ~ x + temporal(1 | id, time = occasion, structure = "hettoep"), sigma ~ 1)
~~~

Reject toep, het_toep, aliases, temporal parameter formulae, irregular time and partial
schedules before omission with an actionable error; validate raw metadata first and
require a complete common schedule after omission. The builder emits an information
diagnostic showing free covariance parameters, observed ids, levels and pair counts.
If the recovery pilot repeatedly encounters singular Hessians or unavailable intervals
at the predeclared primary layouts, stop and retain the failure; do not relax the data
rule or reduce the model invisibly.

The runner is tools/temporal-hettoep-gates.R. It must prove valid D R D construction,
recover T3 when all process SDs are equal, recover T4 when r_d equals phi to power d,
and reject a non-positive-definite R matrix. Its interval-feasibility fixtures include a
primary well-informed panel, a near-homogeneous panel and one explicitly
non-promotional low-information stress panel. Coverage calibration is deferred to a
separate promotion arc.

Expected effort: 50 to 80 agent-hours plus measured campaign time. It may be deferred
after P3 if users do not present a use case with the required panel design.

## Predeclared evidence design for P2–P4

These are planning primary cells, not universal user data thresholds. Each
interval-feasibility run uses the production two-start engine, independent
dense-Cholesky data generation, frozen seeds and a small predeclared set of at most 24
fixtures. All generated data sets remain in the denominator. It records convergence,
Hessian status, finite public interval/profile availability, endpoint ordering,
diagnostics, recovery error, runtime and retained warnings. A stress cell is reported,
never promoted. This evidence does not estimate coverage, calibrate reported standard
errors or support an inference-ready claim; those require a separate approved campaign.

| Arc | Primary cells | Stress cell | Main non-mean estimands |
| --- | --- | --- | --- |
| P2 homogeneous Toeplitz | 80 ids by 6 levels with AR1-generated lags; 80 by 12 with valid non-exponential lags; 80 by 8 with negative first lag but positive-definite R | 20 by 6 with long-lag correlations weakly informed | lag-correlation bias, valid-R frequency, selected-lag Hessian diagnostics |
| P3 heterogeneous AR1 | 80 by 8 with monotone SDs and phi 0.5; 80 by 12 with U-shaped SDs and phi 0.8; 80 by 8 with unequal SDs and phi -0.5 | 20 by 6 with one sparse high-variance occasion | SD-pattern recovery, phi bias and process-versus-sigma separation |
| P4 heterogeneous Toeplitz | 120 by 6 with non-exponential R and three SD bands; 120 by 8 with near-homogeneous SDs; 120 by 6 with weak but valid long lags | 30 by 6, deliberately high parameter-to-information ratio | valid-R frequency, covariance reconstruction and information-warning rate |

The fixture set uses two starts per generated data set. A five-seed timing pilot may
measure wall time, memory, convergence, interval availability and artifact completeness
before the full feasibility set. A coverage campaign can be added only through a
documented decision before campaign approval; it cannot change seeds or thresholds after
outcomes are seen.

## Phase 5 — item-6 decision laboratory

This phase is not an implementation queue. It chooses at most one candidate after P4,
or records a justified deferral.

| Candidate | Scientific trigger | First admissible model | Non-negotiable oracle |
| --- | --- | --- | --- |
| Seasonal | known recurring ecological or measurement cycle | one stated period, one stationary seasonal state/covariance form | cycle-aware simulation and comparison with a mean seasonal covariate |
| Trend/random walk | latent baseline is scientifically nonstationary | one proper state evolution and explicit initial state | state-space likelihood and drift-vs-fixed-trend recovery |
| ARMA | regular repeated panel with persistence plus one-period shock mechanism | independent ARMA(1,1) within each id | dense/state-space agreement, stationarity/invertibility and innovation simulation |
| Temporal Matérn | continuous-time smoothness differs materially from OU | one fixed smoothness candidate | dense covariance and OU special-case comparison |

P5.0 is a Ranga/Darwin source-and-use-case ticket. P5.1 is a Noether/Gauss mathematical
contract. P5.2 is a Curie/Fisher simulation feasibility pilot. Only when all three are
green does Ada open a structure-specific Ultra Plan and ledger. No model-order selection
or generic ARMA(p,q) interface is in scope.

## Phase 6 — cross-arc integration and article

After each supported arc, update one temporal-random-effects article with a decision
table: data timing, scientific question, process covariance, key output, minimum
admission, and what it cannot answer. The article must distinguish stable, temporal and
residual variation with a complete runnable example. It must never imply that a model
became supported because glmmTMB has an analogue.

Rose's final programme report lists implemented, deferred, failed and abandoned arcs;
each has source commits, evidence hashes, rendered paths and campaign locations. A
future programme completion requires every implemented arc's closeout, but does not
require implementation of an item-6 candidate with no scientific trigger.

## Master schedule and boundaries

| Phase | Start condition | Earliest completion condition | Estimated work |
| --- | --- | --- | --- |
| P0 | M00 approval | source map, source pin and safe worktree | 3-5 h |
| P1 | P0 complete | all P1 gates including approved evidence if campaign is needed | 35-53 h plus compute |
| P2 | P1 close | positive-definite decision and all T3 gates | 35-55 h plus compute |
| P3 | P2 close | all T4 gates | 40-60 h plus compute |
| P4 | P3 close and real use case | all T5 gates or visible defer decision | 50-80 h plus compute |
| P5 | P4 close or a compelling submitted use case | one chosen candidate plan or defer receipt | 8-16 h planning |
| P6 | each arc closes | synchronized article and programme closeout | 3-6 h per arc |

No phase starts only because time passed. A failed primary calibration freezes
inference-promotion of that structure until a diagnosis and revised, approved decision
exist; it does not erase a separately documented interval-feasibility result. A campaign
approval never transfers to a later arc. Remote push, merge, release, deployment and
external messages are excluded from this programme.

## Required master checks

Run the detailed ledger parser before P0 dispatch:

~~~text
 /Users/z3437171/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  /Users/z3437171/.codex/skills/unlazy/scripts/gate-check.mjs --root . --status \
  docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/MASTER-GATES.md
~~~

The 34-gate ledger specifies phase/arc commands and manual authority points. Its status
is evidence, not permission to run an unchecked command.
