# Arc 6.1 ultra-plan — first mixed-pair implementation

> **Implementation authority 1 of 2 (planning only).** This document governs
> **Arc 6.1**, the first bounded Arc 6 implementation slice. The cross-family sequence,
> exact-special-family lanes, and later direct-kernel choices live in
> [`docs/design/230-arc6-bivariate-series-overview.md`](../design/230-arc6-bivariate-series-overview.md).
> The cited prior-art record remains
> [`2026-07-23-arc6-latent-normal-research-report.md`](2026-07-23-arc6-latent-normal-research-report.md).

## 🎯 GOAL — paste verbatim into a fresh task

```text
PLATFORM: Codex, plan then execute only after owner approval. DELIVERABLE:
replace Arc 6's bespoke-family direction with a composable two-response,
margin-first association architecture plus an honest roadmap for later margin
classes. HEADLINE: fit two declared drmTMB margins on the same complete paired
rows, freeze their estimates, then estimate an optional Gaussian-copula
latent-normal association parameter eta; do not silently refit or change either
marginal model. FIRST IMPLEMENTATION: fixed-effect Gaussian × Bernoulli,
complete pairs, intercept-only eta, point estimate and diagnostics only. NEXT
(only after its review gate): Gaussian × NB2.
IN PARALLEL: exact likelihood/oracle design, formula/API review, and a Mission
Control feasibility record. DEFER: association slopes, intervals/coverage,
random/phylogenetic/structured effects, partial pairs, offsets, weights, mi(),
meta_V(), REML, Julia, CRAN, capability promotion, arbitrary-margin claims, and
all compute until separately approved. DISCIPLINE: latent-normal association is
conditional on frozen margins, never rho12 or observed-scale correlation;
retain all failures; smoke and recovery need separate owner approvals; exact
direct count/Bernoulli kernels stay independent later lanes.
```

## Operating envelope

**Arc identity:** Arc 6.1 only. This is one mixed-pair proof, not an
implementation of the series in
[`docs/design/230-arc6-bivariate-series-overview.md`](../design/230-arc6-bivariate-series-overview.md).

**Why it fits one bounded arc:** the association model is post-fit and
one-dimensional. It consumes two already-fitted, fixed-effect drmTMB margins;
it does not add a new TMB family ID, alter `src/`, modify the marginal fitting
engine, or change the interpretation of an existing `biv_gaussian()` object.
The likely implementation is a small pure-R object and likelihood evaluator.

**Fresh-task boundary:** execute Arc 6.1 in at most two implementation tasks:

1. contract, post-fit object, likelihood/oracle, and targeted tests; then
2. documentation, independent review, and an owner decision on a smoke.

Do not start Arc 6.2 in either task. If either task compacts once, freeze to
its current milestone; a second compaction requires a written checkpoint and a
fresh task. Estimated work after approval is two focused implementation tasks,
two to four bounded reviewers, and no compute campaign by default.

**Hard stops:** this document authorizes neither code nor a smoke while it is
being planned. After implementation review it stops for the owner's separate
smoke decision. A smoke passing does not authorize a recovery campaign, Arc
6.2, an interval, a capability claim, or a tier change.

## Entry criteria and non-negotiable scope

The owner must approve all of the following before code begins:

1. `associate_pairs()` is a distinct post-fit object, not `drmTMB()` and not a
   new `biv_*()` family;
2. the first pair is **Gaussian × literal Bernoulli**, and both margins are
   fitted on one externally constructed complete-pair analysis data set;
3. all stage-1 values are frozen: no refitting, profiling, updating, or
   reweighting of either margin occurs in stage 2; and
4. the public result is an intercept-only point estimate of latent-normal
   association plus diagnostics, without standard errors or intervals.

The first implementation rejects a non-Gaussian first margin, `cbind()`
binomial trials, values other than literal 0/1, different analysis rows,
weights, offsets, missing pairs, `mi()`, random/structured/phylogenetic terms,
`REML`, `meta_V()`, association slopes, and any ordinary `rho12` formula.

## Exact Arc 6.1 likelihood

For complete row \(i\), frozen stage-1 fits supply \(\mu_i,\sigma_i\) for the
Gaussian response \(Y_{Gi}\), and
\(p_i=\operatorname{logit}^{-1}(x_{Bi}^{\mathsf T}\hat\beta_B)\) for the
Bernoulli response \(Y_{Bi}\in\{0,1\}\). Define

\[
z_i=(y_{Gi}-\mu_i)/\sigma_i,\qquad
c_i=\Phi^{-1}(1-p_i),\qquad
\eta=0.999999\tanh(\alpha).
\]

The latent variables obey

\[
(Z_{Gi},Z_{Bi})\sim N\!\left(0,
\begin{bmatrix}1&\eta\\\eta&1\end{bmatrix}\right),
\qquad Y_{Bi}=\mathbb{1}(Z_{Bi}>c_i).
\]

The exact conditional Bernoulli probability is

\[
r_i=\Pr(Y_{Bi}=1\mid Z_{Gi}=z_i)
=1-\Phi\!\left(\frac{c_i-\eta z_i}{\sqrt{1-\eta^2}}\right),
\]

and the stage-2 log likelihood is

\[
\ell(\alpha)=\sum_i\left[
\log f_N(y_{Gi};\mu_i,\sigma_i)
+ y_{Bi}\log r_i+(1-y_{Bi})\log(1-r_i)
\right].
\]

The Gaussian-density term is constant in \(\alpha\), but remains in the
written joint likelihood and oracle so the model is unambiguous. Numerical
evaluation uses stable `pnorm(..., log.p = TRUE)` complements rather than
forming `1 - pnorm()` in a tail.

**Locked boundary policy:** optimize \(\alpha\) over \([-8,8]\), set
`near_boundary = abs(eta) >= 0.995`, and retain the transformed numerical
ceiling `0.999999`. An interior solution returns `status = "interior"`. A
finite near-boundary solution returns its point estimate but with
`status = "near_boundary"`, an unavoidable diagnostic warning, and no
inferential method. If the optimum reaches `abs(alpha) >= 7.99`, the objective
or score is non-finite, or the required diagnostic cannot be evaluated, return
`status = "boundary_unresolved"` and no public association point estimate.
That result is retained for diagnostics and triggers a new owner/review
decision; it is not silently converted into an interior fit or dropped.

## Context and replacement decision

The earlier Arc 6 DIBP-first plan and the provisional `biv_pair(..., joint =
...)` design are superseded as implementation authorities by this strategy.
They remain useful prior-work records. The durable Arc 6 purpose remains
post-0.6, demand-led two-response modelling—not a full family cross-product.

The core new object is not an ordinary joint maximum-likelihood family fit.
It is a **post-fit association model**:

```r
fit_1 <- drmTMB(..., family = <margin 1>, data = paired_complete_data)
fit_2 <- drmTMB(..., family = <margin 2>, data = paired_complete_data)

assoc <- associate_pairs(
  fit_1, fit_2,
  kernel = latent_normal(),
  association = ~ 1
)
```

`associate_pairs()` is provisional public spelling, subject to Boole/Emmy
review. It requires an explicit named kernel; it has no default association or
independence mode. It must store immutable snapshots/hashes of two fitted
marginal models plus row identity, order, response values, package/version
provenance, and the exact complete-pair analysis rows. It rejects fits unless
all those items and fixed-effect-only eligibility match exactly. It must never
refit margin coefficients or distributional parameters.

## Scientific contract

### Stage 1: frozen margins

Both margins are fitted on exactly the same complete paired rows in the first
slice. This protects the estimand from an unmodelled endpoint-specific missing
data decision. The first slice has fixed effects only and accepts literal
Bernoulli 0/1 values only; binomial trials are a later contract.

### Stage 2: latent-normal association

For each row, the frozen fitted CDFs \(F_{1i}\) and \(F_{2i}\) are connected by
a Gaussian copula with

\[
(Z_{1i}, Z_{2i}) \sim N\left(0,
  \begin{bmatrix}1 & \eta_i\\ \eta_i & 1\end{bmatrix}\right),
\qquad \eta_i=\tanh(A_i\alpha).
\]

The first slice sets \(A_i=1\). Thus \(\eta\) is a latent-normal association
conditional on the fitted marginal models and their covariates. It is neither:

- `rho12`, which remains the existing bivariate-Gaussian residual correlation;
- an observed-scale Pearson correlation or covariance;
- `corpair()`, which remains reserved for a later correlation among shared
  Gaussian random-effect members; nor
- an MCMCglmm threshold/liability covariance.

For a discrete margin, stage 2 uses exact CDF-rectangle probabilities, not
arbitrary PIT pseudo-data. A two-response rectangle requires only bivariate
normal CDF work. The continuous-discrete likelihood is a continuous marginal
density times a conditional-normal CDF difference.

For Arc 6.1 specifically, the continuous margin is Gaussian, so conditioning
on it gives the closed-form expression above. A general bivariate-normal CDF
routine is an *independent validation oracle*, not a hidden production
dependency for this first evaluator.

### Why this is distinct from MCMCglmm

MCMCglmm is the key ecological comparator: it supports different trait families
and estimates latent-scale covariance structures. Threshold-trait latent
residual variance is fixed for identification. That construction is valuable
precedent, but it is a conditional liability GLMM. `latent_normal()` instead
must preserve whichever drmTMB marginal is declared, including a logit
Bernoulli or NB2 margin. The two models should only be compared after matching
their link, scale, and estimand.

## First two lanes

| Lane | Pair | Why now | Exact stage-2 kernel | Claim ceiling |
| --- | --- | --- | --- | --- |
| L1 | Gaussian × Bernoulli | Genuine mixed pair; continuous-discrete likelihood is simple; threshold/correlation identification has an established comparator | density × conditional-normal Bernoulli probability | fixed-effect, complete-pair, intercept-only eta point estimate + diagnostics |
| L2 | Gaussian × NB2 | Meets the demand for overdispersed count distributional regression while retaining an existing drmTMB margin | density × conditional-normal count-CDF interval probability | same, only after L1 review and owner approval |

Gaussian × Gaussian is an oracle/parity comparator, not a new feature. It must
recover the existing bivariate-Gaussian result only under matched fixed-effect,
complete-pair conditions; it does not replace `biv_gaussian()`.

Direct shared-Gamma/bivariate-NB and exact four-cell/odds-ratio models remain
candidate specialised later kernels. They are not substitutes for the general
latent-normal association route and receive their own exact-likelihood and
estimand review before any implementation.

## Relationship to the bivariate series

This first lane is already a **mixed-distribution** proof: it joins a Gaussian
margin and a Bernoulli margin without altering either. It is not a claim that
every family pair is consequently available. The authoritative series overview
specifies the later mixed classes, exact-special-family lanes, adapter
requirements, and one-gate-per-class rule. Its final Arc 6.8 is the explicit
cross-pair integration test of several admitted mixed families. See
[`docs/design/230-arc6-bivariate-series-overview.md`](../design/230-arc6-bivariate-series-overview.md).

### Direct exact kernels remain a parallel optional branch

Some pairs may later warrant a direct construction because it answers a better
scientific question than latent-normal association: shared-Gamma bivariate NB
for shared count intensity, a four-cell binary odds-ratio model, or a directed
conditional model. These are separate lanes, never prerequisites for the
general mixed-family series.

## Validation contract

Before any claim beyond construction, L1 requires:

1. an independent Gaussian-copula oracle, including a numerically independent
   integration check for the continuous-discrete likelihood;
2. exact joint simulation from frozen margins plus latent normal draws;
3. `eta = 0` product-margin, response-swap, and Gaussian × Gaussian parity
   checks;
4. near-boundary, rare/common binary, separation, extreme CDF-tail, and
   cancellation stress tests;
5. a likelihood/profile-grid diagnostic, curvature/score checks, a boundary-hit
   flag, and observed response-pattern counts; and
6. a pre-registered recovery ledger, sample-size ladder, and failure-retention
   rules, ready for execution only after the owner has approved a smoke.

The stage-2 Hessian treats margins as known and cannot support an association
interval. L1 therefore exposes no Wald SE, interval, profile claim, or
capability promotion. A later inference lane must use either a validated
stacked-score/Godambe calculation or a bootstrap that refits both margins and
stage 2; its coverage is a separate simulation question.

The post-fit object explicitly rejects `rho12()`, `corpair()`, `sigma()`,
`residuals()`, `vcov()`, profiles, quantiles, and `emmeans` until each has a
separate contract. Any approved L1 recovery is an internal
operating-characteristic gate only; it earns neither interval nor capability
tier claims.

## Runnable work breakdown after approval

The execution sequence is intentionally small. No slice may begin before the
one above it has delivered its named input. S2 and S3 may run in parallel only
after S1 freezes the contract, and they own disjoint files.

| Slice | Member; model / effort / dispatch | Input → output | Owned files or surface | Dependency and gate |
| --- | --- | --- | --- | --- |
| S0 — plan readback | Ada + Rose; Terra / medium / native explicit | These two authorities + research report → short approved-contract receipt in `docs/design/231-arc6-1-gaussian-bernoulli-contract.md` | New design contract only | Owner accepts the four entry criteria above. No code. |
| S1 — symbolic/API review | Boole, Emmy, Gauss; Terra / high / native explicit | S0 contract → formula grammar, provenance schema, extractor/error matrix, numerical guard decisions | `docs/design/231-arc6-1-gaussian-bernoulli-contract.md` | Blocks all code. A disagreement reopens owner dialogue; it is not silently resolved in code. |
| S2 — post-fit object | Terra builder + Emmy; Terra / high / native explicit | frozen S1 schema → immutable snapshots, row/hash checks, eligibility validator, class and print/summary skeleton | New `R/associate-pairs.R`; targeted `NAMESPACE`/roxygen output | After S1. No `src/` change and no modification to `drmTMB()` fitting. |
| S3 — likelihood/oracle/simulator | Terra builder + Noether; Terra / high / native explicit | S1 equation → stable production likelihood, separately written oracle, latent-normal joint simulator | New `R/associate-pairs-latent-normal.R`; new `R/associate-pairs-oracle.R` | After S1; may proceed alongside S2. No uncertainty interface. |
| S4 — tests and adversarial fixtures | Curie; Terra / medium / native explicit | S2 + S3 → deterministic fixtures and test matrix | New `tests/testthat/test-associate-pairs-contract.R`; `tests/testthat/test-associate-pairs-gaussian-bernoulli.R` | Blocks documentation and review. No smoke/campaign. |
| S5 — user contract | Darwin + Boole; Terra / medium / native explicit | S2--S4 → help, one ecological example, formula/likelihood docs, cross-family explanation and clear unsupported-method errors | `R/associate-pairs.R`; `docs/design/01-formula-grammar.md`; `docs/design/03-likelihoods.md`; `vignettes/cross-family.Rmd` | After S4. Must say “latent-normal association”, never mixed-family `rho12`. |
| S6 — independent verification | Fisher + Rose; Fisher Terra / high, Rose Sol / high; native explicit | S1--S5 + test output → PASS/REPAIR verdict, claim ceiling audit, recovery-ledger and smoke specification | `docs/dev-log/after-task/2026-07-23-arc6-1-implementation-review.md`; planned recovery specification only | **STOP:** owner sees review before any smoke. |
| S7 — smoke decision | Owner; no agent runs it by default | S6 verdict → approve/decline a toy local smoke with exact fixture and expected output | approval recorded in dev-log | A `PASS` review alone authorizes nothing further. |
| S8 — close or hand over | Rose + Melissa; Terra / medium / native explicit | actual work versus this table → after-task, plan-vs-actual record, check-log receipt, validated handoff | `docs/dev-log/after-task/`; `docs/dev-log/plan-actual/`; `docs/dev-log/check-log.md`; handover if needed | Run `Rscript tools/check-after-task.R <report>` and retain its result. No capability tier change by default. |

**Routing receipt for this plan:** the present documentation pass used direct
repo inspection and existing bounded reviews. A Luna scout was not dispatchable
through the active native agent interface; no false Luna-run claim is made.
When implementation begins, S4 is Luna-suitable only if the live tiered
dispatcher is available; otherwise Curie/Terra performs the mechanical fixture
work and records that constrained routing. The implementation fan-out cap is
four producer/reviewer children before the owner smoke checkpoint; no `ultra`
reasoning effort is warranted.

## Test matrix and acceptance criteria

S4 is complete only when these checks are green in the ordinary package test
suite; they are not a recovery campaign:

| Test group | Required assertion | Failure interpretation |
| --- | --- | --- |
| Frozen margins | `coef()`/fitted marginal values stored by `associate_pairs()` equal their original fits exactly; changed fit, rows, response values, order, family, or fixed-effect eligibility is rejected | stage-2 could have moved the estimand or joined incomparable data |
| Algebra | conditional-normal production likelihood agrees with an independent bivariate-normal-CDF/integration oracle | wrong rectangle/threshold orientation or tail calculation |
| Normalization | for fixed \(z\), \(\Pr(B=0\mid z)+\Pr(B=1\mid z)=1\); numerical integration of the two conditional joint contributions over the Gaussian margin is one | invalid joint density/pmf construction |
| Independence | `eta = 0` equals the product-margins likelihood and simulator has no residual association beyond Monte Carlo error | copula construction is wrong |
| Symmetry | swapping endpoint order returns the same maximized association and swaps labelled marginal outputs | endpoint-specific implementation drift |
| Numerical boundaries | rare/common Bernoulli prevalence (0.1/0.5/0.9), large Gaussian scores, near-boundary `eta`, and separated binary fits give either stable diagnostics or a clear refusal | unstable tail arithmetic or an unsupported identification case |
| Optimizer diagnostics | likelihood grid, multistart agreement, finite score/curvature checks, response-pattern counts, and boundary flag are recorded | apparent estimate is a numerical artefact |
| Surface fence | `rho12()`, `corpair()`, `sigma()`, `residuals()`, `vcov()`, profiles, quantiles, and `emmeans` fail with actionable class-specific errors | accidental borrowing of Gaussian-only inference claims |

The only external comparator is conceptual unless links and estimands are made
identical: MCMCglmm's Gaussian–threshold model is useful for a matched-probit
sensitivity comparison, but it is not a numerical oracle for a frozen-logit
IFM fit. The load-bearing comparator is the independent oracle above.

## Sweep receipt

| Surface | Evidence | Finding | Call forced |
| --- | --- | --- | --- |
| Repo state | `git status -sb`; `git log --oneline -12`; `branch_drift_check.sh`; `git worktree list`; `git stash list` | Detached `7bf4124d`, 0 ahead/behind `origin/main`; five untracked Arc 6 planning/research documents; no Arc 6 code. Other worktrees/stashes are historical or foreign lanes, not a resumable Arc 6 implementation. | preserve documents; build only after plan approval |
| Existing package | `R/family.R`, `R/drmTMB.R`, `R/methods.R`, `docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`, and design/229 review | only `biv_gaussian()` has a bivariate engine; existing `rho12()`/prediction/simulation methods are Gaussian-specific; provisional design/229 assumes an exact joint family | add a separate post-fit object; do not retrofit current Gaussian methods |
| Sister/comparator work | gllvm/GLLVM research; Niku et al. 2019 | mixed families and latent factors exist, but are a high-dimensional conditional-factor solution | borrow layer separation, not factor engine |
| Brain | raw-file fallback after `basic-memory ... --hybrid` was blocked by `.basic-memory` permission; query `Arc 6|latent.normal|Gaussian copula|two.stage` | Arc 6 is post-0.6 and demand-led; old note's universal `rho12` statement is superseded | retain scope, replace estimand/API |
| External prior art | NotebookLM `01b63b71-a455-43f6-9041-4be6dabd65e5`; Hadfield/MCMCglmm, brms, gllvm, Masarotto--Varin, IFM sources | no novelty claim; two-stage copula estimation and latent-scale mixed models are established | build a transparent package adaptation, not a claimed invention |
| Verdict | all above | genuine gap is a two-trait, drmTMB margin-first, exact low-dimensional association layer | plan this gap only |

## What the brain already knows

The durable Arc 6 decision is post-0.6 and demand-led, not a release condition
or a reason to reopen CRAN. It separates the existing Gaussian-only `rho12`
and REML surface from new non-Gaussian association work. The direct
`basic-memory` CLI retrieval is currently blocked because it tries to change
permissions under `~/.basic-memory`; the raw-vault fallback and this repo's
handover/design records were used instead. This is a retrieval transport
failure, not evidence that there are no prior decisions.

## What Shinichi told us

- The eventual goal is mixed response families, especially overdispersed
  counts, without a growing set of unrelated public `biv_*()` families.
- Adding association must not silently alter the distributional-regression
  marginal estimates; that selects a staged margin-first fit for the general
  route.
- Gaussian × Gaussian remains valuable, and lognormal × lognormal and
  Student-t × Student-t may support honest exact special residual correlations
  on their transformed/elliptical scales.
- The programme must eventually test several admitted mixed combinations
  together, which is why Arc 6.8 is an explicit integration gate.
- 0.6 remains a development base: do not submit to CRAN or let this work alter
  existing capability counts.

## Ada's recommendation

Approve Arc 6.1 as the smallest real mixed-family proof: Gaussian × Bernoulli
is simple enough to audit exactly, yet exercises the essential continuous–
discrete threshold/CDF machinery and the frozen-margin promise. It does **not**
settle the count problem; Arc 6.2 is reserved for Gaussian × NB2 immediately
after the Arc 6.1 decision gate. The eventual assurance that this is a usable
mixed-family system is Arc 6.8, not an overbroad claim from Arc 6.1.

## Team raised

- **Ranga** — MCMCglmm, brms, GLLVM, Gaussian copula, and direct kernels all
  separate margin choice from a dependence layer, but their estimands differ.
  Recommendation: use a margin-preserving Gaussian copula as the general
  residual-association route.
- **Fisher** — IFM is valid only when labelled conditional on fitted margins;
  discrete association requires rectangles, boundary diagnostics, and two-stage
  uncertainty. Recommendation: L1 point estimate only; Gaussian × Bernoulli.
- **Rose** — a staged association is not an ordinary joint family. Recommendation:
  a distinct post-fit object, explicit complete-pair rows, and capability errors
  before implementation.
- **Ada** — adopt a staged post-fit object now; retain direct kernels as later,
  separately reviewed extensions.

## Decisions locked, questions still open, and approval

Locked by this plan:

- no generic `rho12` for mixed margins;
- no refitting of stage-1 marginal estimates in stage 2;
- no claims of arbitrary pair support, intervals, or coverage; and
- no smoke/compute/capability promotion without separate approval.

The only owner decision still needed before S2/S3 code is to accept all four
parts of this package:

1. accept `associate_pairs(fit_1, fit_2, kernel = latent_normal(),
   association = ~ 1)` as the staged public surface rather than a new
   `biv_*()` family or a joint `drmTMB()` fit;
2. use exactly the same complete paired rows in both first-stage fits;
3. open Gaussian × Bernoulli as Arc 6.1 only and record Gaussian × NB2 as
   Arc 6.2 **queued only**, requiring fresh symbolic review and a new owner
   approval after 6.1; and
4. cap L1 at point estimate plus diagnostics, with two-stage interval inference
   deferred.

The exact `associate_pairs()` argument names remain an implementation detail
for the S1 Boole/Emmy/Gauss contract review; they may not change the estimand,
frozen-margin rule, first-pair boundary, or locked numerical boundary policy.
No other question is held open by this plan.

**Plan-review status:** Ranga's NotebookLM synthesis and the earlier
Fisher/Rose review support the margin-first direction. Before code, Rose must
confirm that this expanded runnable breakdown still preserves the stated scope,
and Fisher or Gauss must confirm the displayed Gaussian–Bernoulli likelihood
and numerical-boundary policy. This is a plan review, not permission to smoke.

## Deferred boundaries

No random/phylogenetic/structured effects, association slopes, partial pairs,
offsets, weights, `mi()`, `meta_V()`, REML, Julia, CRAN work, capability-tier
promotion, or generic family-pair support occurs in this plan without a later,
explicit decision.
