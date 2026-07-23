# Arc 6 first-pair decision and design packet

> **SUPERSEDED AS IMPLEMENTATION AUTHORITY (23 July).** The direction below
> records the earlier DIBP feasibility investigation. Arc 6 is now
> architecture-first: one composable pair API plus a named exact joint kernel,
> with `biv_gaussian()` preserved for compatibility. The current authority is
> [`docs/design/229-arc6-composable-bivariate-pairs.md`](../design/229-arc6-composable-bivariate-pairs.md).
> DIBP is not to be implemented from this packet.

> **23 July reframing — planning only.** Arc 6 is a demand-staged bivariate
> feasibility programme, not an all-pairs implementation promise. The current
> planning focus is the **Poisson × Poisson** candidate below. Count-count,
> binary-binary, and Gaussian-mixed candidates are retained as separately
> gated rows, with Q-series inference readiness as the explicit return path.
> This board records feasibility; it does not add a capability cell, change a
> tier, authorize code, smoke, or compute, or imply any cross-family support.

## Arc 6 staged feasibility board — Mission Control source

| Candidate lane | Scientific estimand to earn | Exact model decision still required | Comparator/oracle route | Feasibility state | Hard fence / next decision |
|---|---|---|---|---|---|
| **P1 Poisson × Poisson** | Paired-count association with extra agreement at small equal counts; derived signed covariance and marginal dispersion | Fixed `Discrete(2)` diagonal-inflated bivariate Poisson (DIBP): baseline private/shared Poisson intensities, diagonal-mixture weight, and three-point diagonal law | Independent R finite-sum pmf + latent-mixture simulator; current `bivpois` only checks the `pi = 0` ordinary-BP limit | **Design review needs changes incorporated below; no code** | Owner selects the `Discrete(2)` law and latent-intensity public semantics; then approve an oracle-first implementation slice |
| C2 Poisson × NB2 | Shared count process with count-specific overdispersion | A named bivariate NB construction (not a label borrowed from univariate NB2) | Independent likelihood and established comparator required | **Parked: model definition absent** | Do not use DIBP evidence as a substitute; demand and prior-art screen before design |
| B3 Binomial × binomial | Paired binary/presence association, naturally interpretable through a (2\times2) joint probability / odds-ratio contract | Marginal-logit plus association parameterization that remains valid at every covariate row | Direct four-cell likelihood and simulator; comparator to be confirmed | **Candidate: likely low-dimensional and interpretable** | Demand screen must choose a real paired-presence question and freeze odds-ratio versus risk-difference estimand |
| G4 Gaussian × Poisson | Continuous–count joint response; latent or conditional association, not a recycled Gaussian `rho12` | A direct joint/conditional model with clear marginal and association meaning | Independent numerical oracle plus a matched package/model comparator | **Parked: high design and identifiability load** | No Gaussian copula shortcut; admit only after P1/B3 establishes the generic bivariate user-surface contract |
| G5 Gaussian × binomial | Continuous–binary paired response | A direct joint/conditional model and identifiable association estimand | Independent oracle plus comparator | **Parked: high design and identifiability load** | Same gate as G4; do not treat it as a simple extension of `biv_gaussian` |
| Q return | Expand the existing Q-series inference-ready surface | No new bivariate likelihood | Existing Q-series recovery/interval infrastructure | **Protected alternative** | Re-prioritize here if P1 demand, model, or numerical gates fail, or after one bivariate slice reaches its declared ceiling |

**Board rule.** Only P1 is eligible to progress. Every other row remains a
planning candidate until it has a separate joint likelihood, association
estimand, user-surface inventory, independent oracle, comparator, and owner
approval. Neither an implemented P1 nor the missing-response board changes the
inference tier of any model-surface cell.

## Current P1 correction from Rose, Fisher, and Gauss

The former shared-component Poisson proposal is superseded as the candidate for
this objective: it permits only non-negative association and has no
underdispersion mechanism. The reviewed P1 candidate is a **fixed-effect
diagonal-inflated bivariate Poisson** with a finite diagonal component. Let

\[
(A_1,A_2,A_0) \sim \operatorname{Pois}(\lambda_1)\times
\operatorname{Pois}(\lambda_2)\times\operatorname{Pois}(\lambda_0),
\qquad B=(A_1+A_0,A_2+A_0),
\]

and, independently, \(H\sim\operatorname{Bernoulli}(\pi)\) and
\(Z\sim\operatorname{Categorical}(q_0,q_1,q_2)\). The observed pair is
\(Y=B\) if \(H=0\) and \(Y=(Z,Z)\) if \(H=1\). Hence, with
\(f_{\rm BP}\) the finite-sum baseline bivariate-Poisson mass function,

\[
f(y_1,y_2)=
\begin{cases}
(1-\pi)f_{\rm BP}(y_1,y_2), & y_1\ne y_2,\\
(1-\pi)f_{\rm BP}(y,y)+\pi q_y, & y_1=y_2=y\in\{0,1,2\},\\
(1-\pi)f_{\rm BP}(y,y), & y_1=y_2=y>2.
\end{cases}
\]

All three \(\lambda\)'s use log links, \(\pi\) uses a logit link, and
\((q_0,q_1,q_2)\) uses two softmax logits. This is a deliberately narrow
**low-count exact-agreement** model, not a generic co-occurrence or latent
abundance model.

The latent shared-base-event intensity is \(\lambda_0\ge0\). The reported
cross-response association is instead the covariate-dependent derived
covariance,

\[
\operatorname{Cov}(Y_1,Y_2)=(1-\pi)\lambda_0+\pi\operatorname{Var}(Z)+
\pi(1-\pi)(m_1-EZ)(m_2-EZ),
\]

where \(m_j=\lambda_j+\lambda_0\). It may be negative; any derived
correlation must be described as a model consequence, never as the Gaussian
residual `rho12` parameter. Likewise
\(\operatorname{Var}(Y_j)-E(Y_j)=\pi(\operatorname{Var}(Z)-EZ)+
\pi(1-\pi)(m_j-EZ)^2\), which permits over- or underdispersion. A
Poisson diagonal component would not meet that last requirement.

**Current review gate:** Rose and Gauss both return **NEEDS CHANGES**, not an
implementation pass. Before code, the owner must approve this exact diagonal
law, decide whether public formulas expose latent intensities rather than
unconditional means, and accept complete pairs only (incomplete bivariate
responses must error in this slice). `bivpois` is a comparator only for the
ordinary bivariate-Poisson \(\pi=0\) limit; it does not validate the DIBP
extension. Fisher's original conditional pass remains applicable only to the
baseline BP limit and its independent finite-sum oracle.

## 🎯 GOAL — paste verbatim into a fresh task

```text
PLATFORM: Codex, solo. Work from a clean drmTMB worktree and do not co-edit a
foreign lane. DELIVERABLE: a narrowly approved first implementation slice for
Arc 6, beginning with the Poisson × Poisson shared-component bivariate-Poisson
candidate only if the owner approves its estimand. HEADLINE: replace the vague
all-pairs ambition with one direct joint likelihood and an honest dependence
meaning; never re-label Gaussian rho12 machinery as generic dependence. IN
PARALLEL: inventory the existing bivariate contract, conduct a demand/prior-art
and comparator sweep, and prepare an independent mathematical oracle. DEFER:
all other family pairs, a mixed-family claim, API admission, implementation,
smoke, campaign compute, capability promotion, Julia, meta_V, and CRAN.
DISCIPLINE: first obtain owner approval of the pair plus estimand; then prove a
toy smoke before an explicitly approved Totoro or DRAC campaign (never GitHub
Actions), retain failures, and make no public claim without Fisher and Rose.
```

## Status and decisions locked

This is a feasibility and design artifact. It authorizes no implementation,
test execution, smoke, campaign, capability-tier change, Julia work, `meta_V()`
follow-up, or CRAN work.

The owner selected **Poisson × Poisson** as the first *same-family,
non-Gaussian shared-event pilot*. Its association estimand is the non-negative
shared-count intensity, with private-plus-shared intensities as the preliminary
mathematical parameterization. It is not a mixed-family delivery and must not
be advertised as one.

**Release and queue fence:** drmTMB 0.6 remains a long-lived development line;
CRAN submission is parked. Arc 6 is not a 0.6 release condition. After the
feasibility verdict, the owner will choose between one narrow Poisson pilot and
returning directly to the Q-series inference programme, whose Mission Control
board reports 23 inference-ready cells among 676 model-surface cells. The
Poisson pilot ends after its exact fixed-effect pair; it does not automatically
open a second family pairing.

## What the brain and repository already establish

- Arc 6 is the post-0.6 flagship, staged by demand rather than a full family
  cross-product; `biv_gaussian` is its sole fitted bivariate route.
- Mixed composed families are deliberately rejected. Admission requires a joint
  likelihood or copula/latent-variable contract plus prediction, simulation,
  extractors, intervals, examples, and an independent likelihood/comparator
  gate.
- The existing `rho12` is a guarded Gaussian residual correlation. It is not
  the association parameter for a count-pair model.
- The Julia twin likewise documents cross-family bivariate models as absent;
  it provides no reusable implementation. Julia remains deferred.
- REML is Gaussian-only. It is not an Arc 6 solution; any AGHQ question is a
  later non-Gaussian random-effect decision, not part of this fixed-effect
  first slice.

## Phase 0.25 prior-work sweep receipt

| Surface | Evidence run | Finding | Forced call |
| --- | --- | --- | --- |
| Repository state | `git status -sb`; `git log --oneline -20`; `git branch -a`; `git worktree list`; `git stash list`; `branch_drift_check.sh` | This worktree is detached at `7bf4124d`, clean; the requested handover is present in later commit `87212996`; several historical bivariate branches are 1,345–1,350 commits behind `main`. | Build the gap in a fresh Arc 6 lane; do not resume or merge stale bivariate branches. |
| Existing repo work | `git show 87212996:docs/dev-log/handover/2026-07-23-codex-arc6-ultraplan-handover.md`; `rg` over `R/`, `src/`, `tests/`, and design/dev-log documents | Gaussian × Gaussian is the only implementation; Slice 288 hardens rejection of all mixed pairs. `drm_bivariate_gaussian_diag_nll()` is explicitly Gaussian. | Reuse only interface-inventory lessons, never the Gaussian likelihood or `rho12` transform. |
| Sister/twin | `git -C DRM.jl status -sb`; `rg` and `sed` over `DRM.jl/docs/src/capabilities.md` | DRM.jl has Gaussian bivariate `rho12` only and marks cross-family bivariate as absent. | No co-option; Julia is fenced. |
| Brain | Raw-file fallback after `basic-memory tool search-notes "Arc 6 bivariate combinations drmTMB" --hybrid` failed because sandboxed CLI attempted to chmod `~/.basic-memory`; read `memory/drmTMB Arc 6 — bivariate combinations across families (post-0.6 flagship).md` and `projects/drmTMB.md`. | The durable decision is demand-staged post-0.6 Arc 6; Gaussian-only REML and non-Gaussian AGHQ are separate estimator boundaries. | Reuse the staged, bounded Arc 6 decision; do not infer a selected first pair. |
| Verdict | Evidence above | No prior cross-family or non-Gaussian bivariate engine is ready to resume. | **Build only the decision gap:** choose one demanded direct joint model, then validate it independently. |

## Candidate first-pair scorecard

| Candidate | Dependence meaning | Why it is a candidate | First-slice concern | Disposition |
| --- | --- | --- | --- | --- |
| Poisson × Poisson shared-component | Shared-count intensity, positive association only | Exact finite-sum pmf and simulator; direct oracle can be independently written. | Same-family rather than mixed-family; boundary at zero association; cannot represent negative association. | **Recommended, conditional on approval and external demand/comparator sweep.** |
| Binomial × binomial four-cell model | Joint cell probabilities / odds ratio | Exact paired-presence interpretation and both association signs possible. | Marginal/association constraints and ecological target need demand evidence. | Hold as the next candidate, not a fallback implementation. |
| Gaussian × Poisson | Latent/coplanar association, not observed `rho12` | Plausible mixed response type. | No selected likelihood, estimand, or comparator/oracle yet; high integration and identifiability risk. | Explicitly deferred. |

## External feasibility findings (planning evidence, not capability evidence)

- The `bivpois` literature contains maximum-likelihood bivariate-Poisson
  regression fitted by EM, providing an external fixed-design comparator when
  its parameterization matches the shared-component model. The current CRAN
  `bivpois` package also supplies density, random-generation, and maximum-
  likelihood functions. It supplements, but cannot replace, an independently
  written finite-sum oracle.
- Ecological multivariate-count work commonly uses latent Poisson-lognormal or
  JSDM models to express general co-abundance, including overdispersion and
  both signs of association. Therefore this pilot is appropriate only when a
  **positive shared-event process** is scientifically meaningful; it is not a
  generic species-co-occurrence route.
- Zero-inflated, overdispersed, negative-association, latent-correlated,
  random-effect, and multi-species cases remain deferred. The first feasibility
  screen must identify a shared-event example and compare the exact likelihood,
  estimates, and fitted means with `bivpois` under the same fixed design.

## Proposed exact mathematical contract (not yet an API decision)

For row \(i\), let independently

\[
U_{0i}\sim\operatorname{Poisson}(\lambda_{0i}),\quad
U_{1i}\sim\operatorname{Poisson}(\lambda_{1i}),\quad
U_{2i}\sim\operatorname{Poisson}(\lambda_{2i}),
\]

and define \(Y_{1i}=U_{0i}+U_{1i}\), \(Y_{2i}=U_{0i}+U_{2i}\). The joint pmf is

\[
P(Y_1=y_1,Y_2=y_2)=e^{-(\lambda_0+\lambda_1+\lambda_2)}
\sum_{k=0}^{\min(y_1,y_2)}
\frac{\lambda_0^k\lambda_1^{y_1-k}\lambda_2^{y_2-k}}
{k!(y_1-k)!(y_2-k)!}.
\]

Thus \(E(Y_j)=\lambda_0+\lambda_j\) and
\(\operatorname{Cov}(Y_1,Y_2)=\lambda_0\geq0\). The estimand is **shared-count
intensity**, not a constant residual correlation. At \(\lambda_0=0\), the
model factorizes into independent Poisson margins and the association parameter
is on the boundary.

Before implementation, the owner must choose one public parameterization:

1. **Recommended for mathematical clarity:** formulas model the three positive
   private/shared intensities; marginal means are derived quantities.
2. Preserve marginal `mu1`/`mu2` formulas and add a constrained shared-intensity
   parameterization. This needs a smooth, auditable mapping that enforces
   \(\lambda_0\leq\min(EY_1,EY_2)\); it is not assumed solved by this plan.

No reuse of `rho12`, `atanh`, Gaussian whitening, or Gaussian missing-response
semantics is permitted. The implementation design must separately state the
one-response-observed likelihood, weights/offsets, and whether random effects
are rejected in the first release (recommended) or independently scoped.

## Execution plan — conditional on approval only

| Slice | Member | Model / effort / dispatch | Time | Input → output | Dependency |
| --- | --- | --- | --- | --- | --- |
| S0 RECON | Ada + scout | Luna / low / tiered-cli enforced | 1–2 h | Current bivariate dispatch and all fitted-surface contracts → implementation/interface inventory | Owner approval; read-only |
| S1 Demand and comparator sweep | Jason/Ranganathan | Terra / medium / native explicit | 0.5–1 d | Ecology/evolution use cases plus external prior art and live comparator inventory → cited pair scorecard | Owner says yes to grounded NotebookLM search |
| S2 Symbolic freeze | Noether + Gauss | Sol / high / native explicit | 0.5 d | Approved candidate → likelihood, parameterization, missingness, association, and formula grammar specification | S1 + owner pair/estimand decision |
| **STOP FOR OWNER APPROVAL** | Shinichi | — | — | Approve pair, exact dependence estimand, public parameterization, and first-slice ceiling | S2 + plan review |
| S3 Independent oracle | Terra builder | Terra / high / native explicit | 1–2 d | Frozen math → standalone pmf/simulator and test fixtures | Approval |
| S4 Package admission | Terra builder | Terra / high / native explicit | 3–5 d | Spec → R/TMB likelihood, parser, prediction/simulation/extractors, explicit rejections, roxygen, formula and likelihood docs | S3 |
| S5 Mechanical verify | Luna scout | Luna / medium / tiered-cli enforced | 0.5 d | Files/tests/docs → mechanical completeness receipt | S4 |
| S6 Toy smoke | Codex | Terra / high / native explicit | <1 h | One non-empty, finite, range-checked known-DGP result → smoke receipt | Separate owner smoke approval |
| S7 Campaign and inference | Curie + Fisher | Terra / high; Sol / xhigh claim gate | Totoro 1–3 d or DRAC array if expanded | Prespecified all-attempt recovery/boundary grid → retained result ledger and claim verdict | Separate owner compute approval after S6 |
| S8 Reconcile/close | Melissa + Rose | Terra / medium / native explicit | 0.5 d | Planned-vs-actual record; after-task report/claim audit | Evidence exists |

Luna suitability is **yes** for S0 and S5 because both are bounded,
read-only/mechanical. No `ultra` effort is authorized. The next production batch
has at most four children and one Sol child. S0/S5 use the tiered dispatcher
with `--require-scout`; S2 needs Sol because the exact estimand and constrained
parameterization are load-bearing. Estimate after approval: one short
implementation session plus a separate compute-approved evidence lane; do not
promise it fits a single session.

## Validation and claim gates

1. **Before any code:** obtain the approval named above; conduct the grounded
   external sweep. Freeze the symbolic likelihood, public formula grammar,
   marginal mapping, missingness, random-effect fence, and explicit unsupported
   pair errors.
2. **Before a smoke:** independently implement/evaluate the finite-sum pmf and
   simulator; prove factorization at \(\lambda_0=0\), Poisson margins/moments,
   response-swap symmetry, and TMB objective/gradient agreement. A discovered
   package comparator is supplementary, not a substitute.
3. **Smoke gate:** owner approval is required. Run one tiny known-DGP fit,
   inspect a fit and output one guard past completion, and retain failures.
4. **Compute gate:** owner approval is separately required. Use Totoro for a
   bounded CPU grid or DRAC arrays for a multi-cell/multi-seed grid; never
   GitHub Actions. Include null, near-boundary, low-count, heterogeneous-
   covariate, and negative-association misspecification DGPs, all-attempt
   denominators, convergence/`pdHess`, and profile geometry.
5. **Claim ceiling:** planning confers no fitted, recovery, interval, coverage,
   capability, or public claim. Even an implemented first pair can claim only
   the measured design and cannot claim mixed-family support, negative
   association, random-effect support, or generic `rho12` compatibility.

## Plan review

Rose requires the demand/comparator sweep, full user-surface inventory,
explicit unsupported errors, a stop before any comparator fit/smoke/compute,
and formula/likelihood documentation plus unselected-pair rejection tests.
Fisher accepts Poisson × Poisson as a bounded pilot only when its same-family
ceiling, \(\lambda_0\geq0\) boundary, positive-only restriction, independent
oracle, and boundary/misspecification diagnostics are explicit. Both reviewers
returned **NEEDS-CHANGES** to the initial decomposition; the changes are
incorporated above. Gauss review remains a required execution gate before a new
TMB objective is merged.

## Feasibility decision gate

The pair, scope, and evidence search are approved. Before any implementation,
Ada must return a concise feasibility verdict on all three conditions:

1. a real shared-event paired-count use case, rather than generic co-abundance;
2. an exact independent finite-sum oracle plus a parameterization-matched
   `bivpois` comparator route; and
3. a bounded fixed-effect API/formula design that does not blur private
   intensities with marginal means.

If all three pass, the owner decides whether to authorize one narrow Poisson
implementation slice. If any fails or the scientific niche is too narrow, Arc
6 stops at feasibility and the next active development arc is Q-series
inference readiness. In either case, 0.6 stays in development and no CRAN work
restarts.

Fisher's revised review is a conditional pass: the oracle must test
\(\lambda_0=0\), interior, and near-boundary association; any later association
inference needs profile behaviour, convergence diagnostics, retained failures,
and separate coverage approval. Rose's scope fence remains unchanged.
