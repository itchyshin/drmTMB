# Staged-eta full-refit bootstrap: Ultra Plan (Phases 0–2)

> **Superseded 2026-07-25 — campaign stopped.** The infrastructure and tiny
> schema smoke remain developer-only. The partial Fir/Totoro shards are
> provenance only and must not be aggregated into an evidence claim. Reopen
> only after deciding that staged eta needs a public uncertainty interface and
> approving a new, cost-calibrated plan.

```text
🎯 GOAL
PLATFORM: Codex. Deliver an approval-gated implementation and evidence plan for
the fixed-effect, literal-Bernoulli × ordinary-NB2 `associate_pairs()`
full-refit parametric-bootstrap lane. HEADLINE: estimate uncertainty only for
the existing two-stage frozen-margin association-link coefficients, by
resimulating paired outcomes and refitting both margins and the association in
every bootstrap replicate. IN PARALLEL: implementation/oracle design,
simulation-driver and retained-ledger design, and bounded method/data review.
DEFER: all execution; smoke and compute requests; public API; SE/Wald/profile
routes; a Godambe estimator; direct `biv_lognormal()` work; other pair classes,
random effects, missingness, weights, offsets, REML, and richer association
formulas. DISCIPLINE: no implementation or compute before explicit owner
approval; first use a non-empty local smoke after approval, then DRAC (never
GitHub Actions) for the immutable n-ladder; retain every outer and bootstrap
attempt and close with independent Fisher, Noether, and Rose review.
```

## Status

**Execution update (2026-07-24):** the owner approved the finite `[-8,8]`
optimization domain and all-attempt outer denominator. S1–S5 developer
infrastructure is now implemented: the independent DGP oracle, full-refit
helper, dormant 24-cell driver, retained-ledger schema, and focused tests. It
still authorizes neither a smoke, campaign, compute request, public API, nor a
capability claim. A separate approval remains required before the first smoke.

The target is **not** an exact direct-likelihood `rho12` interval. It is the
sampling uncertainty of the two-stage plug-in estimator
\(\widehat\alpha=(\widehat\alpha_0,\widehat\alpha_1)\), where

\[
  \eta(x)=0.999999\tanh(\alpha_0+\alpha_1x).
\]

The current stage-2 curvature is conditional on fitted Bernoulli and NB2
margins, so it omits margin uncertainty and cross-stage covariance. Therefore
`vcov()`, standard errors, Wald intervals, profiles, and `confint()` remain
unavailable until a separately validated route exists.

## Phase 0.25 prior-work sweep receipt — required before decomposition

| Surface | Evidence run | Finding | Call forced |
| --- | --- | --- | --- |
| Repository and git state | `git status -sb`; `git log --oneline -20`; `git branch -a`; `git worktree list`; `git stash list`; `branch_drift_check.sh` | Detached `HEAD` at `d0ac907f`, exactly `0 ahead/0 behind origin/main`. The direct-evidence commits are landed. Retained worktrees include `handover/2026-07-24-codex-staged-eta` and foreign `codex/arc6-6-bernoulli-nb2-plan`; neither is this lane's work. | Build only the genuine staged-uncertainty gap from current `main`; do not merge, amend, push, or attribute foreign lanes. |
| Repo prior work and current contract | `rg` over `R/`, `tests/`, `docs/design/`, and `docs/dev-log/`; read design docs 236, 239, 240 and `R/associate-pairs.R` | Bernoulli×NB2 `association = ~ x` is an implemented beta **point-estimate** route. It has a tail-safe rectangle kernel and source-level simulator, but no two-stage uncertainty estimator. | Reuse the estimator, component extraction, response-order handling, and existing rectangle oracle; add only a separately auditable full-refit bootstrap path after approval. |
| Direct-likelihood evidence | Read `2026-07-24-codex-staged-eta-handover.md`, direct after-task report, and `...biv-lognormal-rho12-totoro-coverage/README.md` | Direct fixed-effect `biv_lognormal()` has a complete exact-likelihood coverage campaign; its profile/Wald/bootstrap results concern constant log-residual `rho12`, not staged `eta`. | Fence it permanently from this lane; reuse only operational lessons (isolated installation check, all-attempt ledgers, reader-facing failure accounting). |
| Sister/twin repos | Brain/repo search for `staged eta`, `Bernoulli NB2`, and `full-refit bootstrap`; no eligible twin implementation found | No sister-repo implementation supplies an uncertainty method for this particular frozen-margin estimator. | No code transfer; retain direct package contracts as technical truth. |
| Brain/context | `basic-memory tool search-notes 'drmTMB staged eta Bernoulli NB2 full-refit parametric bootstrap two-stage conditional curvature margin uncertainty' --hybrid` failed on a sandbox permission change; raw vault fallback `rg` found no additional durable note. Read `memory/00-INDEX.md` and current repo handover/design instead. | Retrieval transport failed, not the record. The project-local handover and design document contain the current decision and scope. | Treat `240` and the handover as the current durable plan-entry record; do not invent a broader prior decision. |
| Grounded data/literature | Gemini Notebook `0f562a5c-81bf-44c4-b5d3-b4880af0a7c7`, two narrow research queries, 12 sources, and a citation-backed question limited to third-party sources | Literature supports full parametric resimulation/refitting in the presence of nuisance parameters as a general bootstrap principle, but does not prove validity for this exact two-stage discrete-copula estimator. Discrete Gaussian-copula likelihoods require special care at CDF jumps/endpoints and are not a claim of arbitrary dependence. | The immutable simulation ladder—not literature alone—must validate the interval. Keep the existing tail-safe NB2 construction and add an independent bootstrap-DGP oracle. |

**Verdict:** **build the gap**. The only new work is a fixed-design,
full-refit parametric bootstrap and its feasibility/recovery/coverage evidence
for the stated Bernoulli×NB2 staged estimand.

## What the brain and repository already establish

- The direct `biv_lognormal()` campaign is complete and closed; it must not be
  reopened or generalized to this estimator.
- The admissible near-term uncertainty route is a full-refit parametric
  bootstrap, not conditional stage-2 curvature or a conditional profile.
- The design freezes the first ladder: 24 cells crossing `n = 120, 240, 480`,
  two Bernoulli prevalences, two NB2 dispersions, and two association vectors;
  covariates are equally spaced on `[-1.4, 1.4]`.
- The design's 399 bootstrap attempts, 380 resolved-association availability
  threshold, link-scale percentile coefficients, and derived \(\eta\) only at
  `x = -1, 0, 1` are retained as starting contracts, subject only to the
  pre-execution clarifications below.

## Exact estimand, DGP, and oracle audit

For each fixed observed covariate row, stage 1 fits
\(p_i=\operatorname{logit}^{-1}(X_{B,i}\widehat\beta_B)\),
\(\mu_i=\exp(X_{C,i}\widehat\beta_C)\), and
\(\sigma_i=\exp(Z_{C,i}\widehat\gamma_C)\). Stage 2 maximizes the
plug-in Bernoulli×NB2 latent-normal rectangle objective over association-link
coefficients. A bootstrap dataset must draw correlated latent normals with the
fitted row-specific \(\widehat\eta_i\), threshold the Bernoulli coordinate,
and map the second coordinate to ordinary NB2 using
`size = sigma^-2`. It must then replace only the two response columns in the
original complete paired data, refit both original fixed-effect ML margin calls
from scratch, and rerun the association fit in the original response order.

The existing `mvtnorm::pmvnorm()` rectangle oracle remains mandatory for the
association kernel, including its `eta = 0` factorization and tail-safe NB2
CDF/survival construction. A **new independent bootstrap-DGP oracle** is also
required: it cannot reuse `drm_pair_nbinom2_quantile_from_normal()` from the
production simulator, or a shared bug could pass both simulation and refit
tests. It must independently construct NB2 `size`, tail probabilities, and
the inverse mapping.

**Pre-implementation decision to resolve:** the prose calls the association
optimization unconstrained, whereas the current implementation searches each
coefficient over `[-8, 8]`. The approved execution plan must either make the
search genuinely unconstrained or define this finite numerical domain,
classify boundary hits as unresolved, and make the simulator, estimator,
diagnostics, and coverage rule agree.

## Grounded audit finding

The external audit supports the conservative direction, not a shortcut:
parametric bootstrap work with nuisance parameters supports resimulating from
fitted parameters and repeating estimation, but it does not certify this exact
estimator. The audit also reinforces the present endpoint/tail discipline for
discrete Gaussian-copula margins. The plan therefore makes a simulation-based
validation claim only after the immutable ladder passes.

The first evidence ladder is simulation data by design; an empirical tutorial
is not a validation substitute and is deferred. The direct penguin data are
positive continuous pairs and are unsuitable as evidence for a Bernoulli×NB2
association interval.

## Phase 1 decomposition

| Slice | Input | Output | Dependencies |
| --- | --- | --- | --- |
| S1: numerical-domain decision | Current `drm_pair_fit_eta()` bound, contracts 236/239/240 | Written bound/unconstrained decision plus fail-closed diagnostic semantics | Owner approval of the plan |
| S2: symbolic + independent-oracle specification | Contracts, source simulator, existing `pmvnorm` test oracle | DGP/refit/oracle design and tests that do not share production quantile code | S1 |
| S3: developer-only full-refit bootstrap driver | Original margin calls, complete data, association formula/control snapshots | Deterministic runner retaining every stage-1/stage-2/bootstrap status and seed | S1, S2 |
| S4: immutable feasibility/recovery driver | Document 240's 24-cell DGP | Outer-attempt and bootstrap-attempt ledgers; cell summary with availability, bias, RMSE, diagnostics | S2, S3 |
| S5: inference gate design | All-attempt ledger schema | Predeclared coefficient and derived-eta coverage/availability rules with binomial MC intervals | S3, S4 |
| S6: approved smoke then DRAC campaign | Installed exact-source package; S3–S5 | Non-empty smoke receipt, then local retained DRAC artifacts | Explicit approval; S1–S5 |
| S7: reader/API decision | Validated campaign result | Narrow interval interface/docs or an explicit no-public-API closeout | S6 and review |
| S8: verification + closeout | S1–S7 artifacts | Independent Fisher/Noether/Rose review, after-task report, M2 D-80 receipt | S7 |

**Parallel after approval:** `{S2, S5}` may begin after S1; `{S3}` follows
S1–S2; `{S4, S5}` then feed S6. No slice may run before explicit approval.

## Phase 2 runnable execution plan

| Slice / member | Model + effort / dispatch | Estimate | Scope and gate |
| --- | --- | ---: | --- |
| RECON — Ada | Luna low / tiered-cli enforced **if live Luna is available**; otherwise Terra low / native explicit | 20 min | Re-read clean state, current contracts, and scope fence before implementation. Current runtime exposes Sol/Terra only, so no Luna was available for this planning pass. |
| S1 — Ada + Noether | Terra high / native explicit | 1–2 h | Resolve `[-8,8]` versus unconstrained target before any bootstrap code. |
| S2 — Noether | Terra high / native explicit | 2–4 h | Write symbolic/DGP/oracle contract; independent NB2 inverse and response-order checks. |
| S3 — Gauss | Terra high / native explicit | 4–6 h | Implement a developer-only full-refit runner and exhaustive retained diagnostics; no public API. |
| S4 — Curie | Terra medium / native explicit | 3–5 h | Implement immutable 24-cell feasibility/recovery ledger and all-attempt summaries. |
| S5 — Fisher | Terra high / native explicit | 2–3 h | Freeze availability, conservative all-attempt and conditional coverage definitions, coefficient/derived-target gates, and MC intervals. |
| S6 — Codex | Terra medium / native explicit | smoke: <1 h; DRAC: 1–3 days | Only after owner compute approval. Smoke proves non-empty valid output; DRAC runs the array, never GitHub Actions. |
| S7 — Pat + Darwin | Terra medium / native explicit | 2–4 h | Decide whether evidence earns a narrow user-facing interval route; otherwise document the refusal. |
| MECHANICAL VERIFY — Curie | Luna low / tiered-cli enforced **if available**; otherwise Terra low / native explicit | 30 min | Confirm counts, ledgers, hashes, links, artifact presence, and that no direct-rho claim leaked. |
| VERIFY — Fisher, Noether, Rose | Two Terra high + one Sol high / native explicit | 3–5 h | Fresh evidence review of inference, symbolic alignment/oracle, and claims/closeout. |
| RECONCILE — Melissa | Terra medium / native explicit | 30 min | Record material plan-versus-actual deviations in `docs/dev-log/plan-actual/`. |

**Fan-out budget:** after approval, at most six new children in the first
producer checkpoint; one ceiling reviewer only. **Luna suitability:** yes for
RECON and mechanical verification, contingent on a live Luna-capable launcher;
the present runtime catalog exposes only Sol/Terra, so the explicit fallback is
Terra-low rather than an unverifiable model claim. **Ultra effort:** no.
**Estimate:** planning fits one session; approved implementation, campaign,
and closure need a handoff because the DRAC campaign is multi-day.

## Immutable evidence rules to lock before execution

1. An outer attempt means every generated DGP dataset in the predeclared
   24-cell grid. The proposed 200 attempts are **all attempts**, not a
   post-hoc retained-success subset.
2. Preserve every failure: each margin fit, association fit, bootstrap margin
   fit, bootstrap association fit, score/curvature/multistart result,
   integration/endpoint status, response-pattern count, seed, and message.
3. An interval is available only with at least 380 resolved associations among
   its 399 attempted bootstrap refits. Availability's denominator is all outer
   attempts. Conservative coverage also uses all outer attempts, treating an
   unavailable interval as non-covering; conditional coverage uses only
   available intervals. Report both with exact binomial intervals and reasons
   for non-availability.
4. Assess each coefficient separately and each derived
   \(\eta(-1),\eta(0),\eta(1)\) separately. Do not pool cells or targets for
   a promotion. Report bias, RMSE, availability, all-attempt coverage, and
   conditional coverage within every immutable cell.
5. Do not add `vcov()`, Wald, profile, or `confint()` support as an incidental
   implementation consequence. A validated stacked-score Godambe method is a
   separate future design/derivation/coverage arc.

## Team raised

- **Fisher** — “200 retained outer attempts” risks contradicting all-attempt
  reporting. Recommendation: define all 200 generated datasets as the
  denominator; retain conditional coverage only as a companion statistic.
- **Noether** — production simulation and tests share the NB2 quantile helper,
  so they cannot detect a common DGP bug. Recommendation: require an
  independent bootstrap-DGP oracle; resolve the `[-8,8]` optimization-domain
  mismatch before claiming estimator alignment.
- **Rose** — the handover is an entry contract, not a completed sweep receipt.
  Recommendation: this document's receipt is the gate; preserve the direct
  evidence fence and require a dated M2 lane receipt at plan close.
- **Ada** — the safe default is one narrow validation lane: first establish
  simulator/refit fidelity and feasibility, then ask for compute approval only
  after a visible, non-empty smoke.

## Ada's recommendation and owner decision

Approve the plan **only** with the two pre-implementation locks above: a
consistent association optimization domain and the all-attempt outer policy.
Then implement the developer-only runner/oracle/ledger without a public
interval method, run a local smoke only after a separate compute approval, and
use DRAC for the full grid.

**Question for Shinichi:** Do you approve that narrow plan and its two locks,
including the intended later DRAC campaign? If so, the next task begins S1–S5;
before the smoke it will return for the separate compute approval required by
this repository.

## Decisions locked

- Direct `biv_lognormal()` `rho12` evidence is closed and out of scope.
- Staged `eta` retains no current SE/Wald/profile/CI/coverage claim.
- The target remains literal-Bernoulli × ordinary-NB2, fixed-effect ML,
  complete paired rows, one numeric association slope, and the documented
  fixed covariate design.
- Full refitting of both margins is mandatory in every bootstrap replicate.
- Plain percentile intervals are the first candidate; no BCa or sandwich
  expansion is bundled into this lane.

## Questions still open

1. Should the optimizer remain finite-domain `[-8,8]` with explicit unresolved
   boundary semantics, or should the implementation be changed to a genuinely
   unconstrained association-link search before the bootstrap begins?
2. What exact cell-level availability and coverage threshold should control any
   later public-API decision? The plan locks the measurements but deliberately
   does not invent a promotion threshold.

## Lane receipt

**LANE: START A FRESH TASK.** The next arc is implementation/campaign work and
must not begin in this planning session. Copy-paste resume prompt:

```text
Read docs/dev-log/2026-07-24-staged-eta-full-refit-bootstrap-ultra-plan.md.
Shinichi has approved the staged Bernoulli x NB2 full-refit-bootstrap plan.
Implement only S1–S5 after recording the optimizer-domain decision; preserve
the all-attempt policy and no-public-inference boundary. Do not run a smoke or
request DRAC compute until the implementation/oracle/ledger are reviewed and
Shinichi separately approves compute.
```
