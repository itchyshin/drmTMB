# Arc 6 — public association inference: preparation ultra-plan

```text
🎯 GOAL
PLATFORM: Codex. Prepare, but do not implement or expose, a public uncertainty
route for the fixed-effect, complete-pair Bernoulli × ordinary-NB2
`associate_pairs()` latent-normal association with `association = ~ 1`.
HEADLINE: turn the already-merged private stacked-score/Godambe diagnostic into
a frozen, pair-specific validation candidate before considering any public API.
IN PARALLEL: symbolic/oracle audit, public-surface design, and a grounded
literature sweep. DEFER: all other pair classes, association slopes, random or
structured effects, missingness, weights, offsets, REML, full-refit campaigns,
and all changes to `vcov()`, `confint()`, profiles, or public documentation.
DISCIPLINE: private results stay private until independently validated; any
simulation or full-refit work needs a fresh owner approval and runs on Totoro or
DRAC, never GitHub Actions; end F0–F2 with a written, non-binding API/claim
recommendation and the exact approval fences for Shinichi; only F5 may decide
on public exposure.
```

**Status:** preparation only · **Date:** 2026-07-26 · **Owner:** Codex

## Lane ownership receipt (D-87/D-88; rechecked 2026-07-26)

`tools/lane_preflight.sh . --hours 36` found foreign active work: PR #851
(Claude's Arc D contract), #852 (the independent `sd()`/scale/interval handover),
#853 (Cox--Reid citation accuracy), and #836 (an earlier handover). This plan
owns only **association**: bivariate `y1`/`y2` dependence, staged `eta`, and
the already private latent-normal sandwich engine. It must not edit, merge,
resolve, or claim any of those PRs.

The earlier Codex Arc D plan (#847) is closed to prevent the duplicated
Arc-D-plan failure recorded in D-87. Its five hard fences are retained in
Claude's `docs/design/247` (PR #851), including no 177-cell campaign on this
association plan's strength and no exposure of PR #846's engine. This document
therefore references that boundary but does not recreate, extend, or decide
Arc D. The retained Arc-D branch is foreign.

## Product boundary

This is the separate bivariate post-fit association lane, not Arc D's `sd()`
clamp/profile-identifiability work. Its estimand is frozen-margin latent-normal
association `eta`, not `rho12`, observed-scale correlation, or a joint-MLE
parameter. Arc D stays with Claude; this plan neither depends on nor edits it.

The eventual product goal is a public association-inference API. That goal does
not license public exposure now: a reusable architecture and deterministic
derivative checks are necessary but not sufficient evidence for a standard error
or interval.

## What “complete Arc 6 association” can honestly mean

Arc 6 is an umbrella two-response programme, so it cannot honestly be marked
complete merely because all currently admitted source routes compile. There are
three different finish lines:

| Finish line | Status now | What remains |
| --- | --- | --- |
| **Association development foundation** — five fixed-effect, complete-pair latent-normal `eta` classes share a private router, pair-specific oracle tests, and integration fences | **Built** | Maintain regression coverage; this is not inference validation. |
| **First public association-inference route (v1)** — one explicitly named pair has validated uncertainty and a fail-closed public API | **Not started** | Complete F0–F5 below for Bernoulli × ordinary-NB2 intercept-only. |
| **All five admitted pairs public for inference** — every pair earns its own recovery and interval-calibration evidence | **Not started** | Four additional pair-specific evidence programmes; Bernoulli × Bernoulli first needs a fresh response-geometry/recovery decision because its retained campaign is HOLD. |

The recommended completion target for the current association sub-arc is the
second row: a single, well-validated public Bernoulli × ordinary-NB2
intercept-only route, plus an explicit private/deferred status for every other
pair. Calling the full Arc 6 umbrella complete would additionally require
separate decisions for direct/exact special models, future family classes, and
their evidence; that is deliberately not an automatic backlog.

### Current association inventory

| Pair / route | Source and oracle state | Recovery / inference state | Arc 6 association action |
| --- | --- | --- | --- |
| Gaussian × Bernoulli | Post-fit `eta` route, independent oracle, integration coverage | Regression smoke only; no recovery or inference claim | Keep private until a later pair-specific admission. |
| Gaussian × NB2 | Post-fit `eta` route, tail-safe oracle, integration coverage | Point-estimate smoke only | Keep private until a later continuous–count admission. |
| Bernoulli × Bernoulli | Post-fit rectangle route and oracle landed | Retained recovery **HOLD** at one interior asymmetric-prevalence cell; no inference | Do not promote or rerun; require a fresh geometry/recovery design before further work. |
| Bernoulli × NB2 | Post-fit rectangle route, private sandwich reference, one private slope diagnostic | No recovery or interval calibration | **Current candidate v1 public route**, intercept-only first. |
| NB2 × NB2 | Post-fit rectangle route, tail oracle, private sandwich adapter | Source tests only; no recovery or inference | Keep private until its own discrete–discrete admission. |
| Exact `biv_lognormal()` / `biv_student()` | Separate exact `rho12` models | Their evidence does not transfer to staged `eta` | Retain as distinct models, not association evidence. |

## What already exists

- PR #844, merged as `6a19dd27`, supplied the private Bernoulli × ordinary-NB2
  stacked-score/Godambe reference and focused deterministic tests.
- PR #846, merged as `1834734a`, generalized it to five private adapters behind
  `drm_pair_general_eta_sandwich()`.
- The router is unexported and `associate_pairs()` does not attach a covariance
  matrix, standard error, Wald interval, profile, bootstrap interval, or public
  validation claim.
- The direct `biv_lognormal()` `rho12` evidence is exact joint-likelihood work
  and is inadmissible as evidence for this two-stage frozen-margin estimand.
- The earlier 24 × 200 × 399 full-refit bootstrap grid remains stopped; its
  partial shards are provenance only and must not be resumed or aggregated.

## Prior-work sweep receipt

| Surface | Evidence | Finding | Call forced by it |
| --- | --- | --- | --- |
| Repository state | `git status --short --branch`; `git log -1 origin/main`; isolated worktree at `af664798` | Clean fresh preparation branch from current `main`. | Keep this plan documentation-only. |
| Narrow reference | PR #844 / `docs/design/244-arc6-staged-eta-godambe-se.md` | Bernoulli × ordinary-NB2 has the reference implementation, including its one slope diagnostic. | Make intercept-only B×NB2 the first *candidate public* route; retain slopes as deferred. |
| General engine | PR #846 / `R/associate-pairs-sandwich*.R` and five adapter test files | All five adapters exist privately with deterministic oracles and fail-closed private results. | Do not rebuild architecture; validate pairs independently. |
| Existing scope decision | `docs/design/240-arc6-staged-eta-uncertainty-followup.md` | Conditional stage-two curvature and profile are not valid two-stage inference; any bootstrap must refit margins and association. | Never expose conditional curvature or profile as a shortcut. |
| Brain | `basic-memory tool search-notes "drmTMB staged eta association sandwich Godambe Arc 6 Arc F uncertainty validation" --hybrid` | Arc 6 is demand-led and staged; no evidence supports treating bivariate `rho12` as staged-eta validation. | Keep the first public claim narrow and pair-specific. |

**Verdict:** resume the existing private diagnostic as a validation problem; do
not build a new association model or reopen Arc D's F5
clamp/profile-identifiability work.

## First candidate public contract

Only after the gates below, the proposed first route is:

```r
association <- associate_pairs(
  fit_bernoulli, fit_nbinom2,
  kernel = latent_normal(), association = ~ 1
)
```

The potential public result would concern the single link-scale association
coefficient `alpha`, with `eta = 0.999999 * tanh(alpha)` available as a derived
quantity. The exact API shape is deliberately undecided: a method such as
`vcov.drm_pair_association()` versus a separate `association_confint()` helper
has different user expectations and must be chosen only after validation.

## Validation ladder

| Phase | Deliverable | Gate | Explicit non-claim |
| --- | --- | --- | --- |
| F0: method freeze | SHA-pinned symbolic statement, fixture set, oracle source, derivative-step ladder, and failure taxonomy | Noether verifies that scores, bread, meat, parameter order, and delta transformation match the code. | No sampling-validity or API claim. |
| F1: deterministic audit | Independent score/Hessian and row-kernel checks at interior, eta-zero, sign, tail, swap, and near-boundary points | Every check passes at predeclared tolerances; malformed and unstable fits remain `unavailable`. | Passing deterministic checks do not validate SE calibration. |
| F2: literature and comparator design | Grounded review of two-step/Godambe inference, finite-sample behaviour, and relevant latent-normal association comparators | Fisher approves estimand, comparator, and failure criteria. | No novelty claim; no compute starts. |
| F3: local smoke | Small full-refit, all-attempt prototype for B×NB2 intercept-only | Refit provenance proves both margins and association are re-estimated each replicate. | Diagnostic only; no public route or coverage conclusion. |
| F4: approved validation | Pre-registered recovery and interval-calibration grid, including availability and all-attempt denominators | Fresh owner approval after F0–F3 review; Totoro/DRAC only. | One pair's evidence does not validate another pair. |
| F5: public API decision | User-facing API proposal, documentation, errors, and capability wording | Fisher, Noether, and Rose agree F4 supports the stated claim; Shinichi approves exposure. | No generic five-pair, slope, RE, missingness, or `rho12` claim. |

## Required evidence for a public claim

The campaign protocol must predeclare the data-generating grid, outer-fit and
inner-refit counts, seeds, all-attempt status accounting, convergence rules,
interval availability denominator, coverage target, Monte Carlo SE, and the
comparison method. It must demonstrate that the proposed standard error reacts
to margin uncertainty; matching the conditional association curvature is not a
success criterion.

The public method must fail closed for incomplete matched rows, failed margin
fits, association boundaries, frozen-margin/provenance mismatch, unstable
derivatives, rank-deficient bread/meat, and unavailable calibration. It must
never silently return a conditional-stage standard error.

## Deferred work

- Gaussian × Bernoulli, Gaussian × NB2, Bernoulli × Bernoulli, and NB2 × NB2
  remain private adapters with their own later validation admission decisions.
- `association = ~ x` remains developer-only even for B×NB2.
- Random/structured effects, missingness, weights, offsets, REML, and all
  association-model expansion remain out of scope.
- `biv_lognormal()` `rho12`, direct profiles, and the stopped bootstrap grid
  remain separate and may not supply evidence here.

## Approval boundary

Approval of this preparation plan authorizes only F0–F2: documentation,
symbolic/oracle audit, API design, and a grounded literature review. It does
not authorize code changes, local refit smoke work, simulation, bootstrap,
Totoro/DRAC work, public API exposure, ledger movement, or a capability claim.

Before F3, return to Shinichi with the frozen-method receipt, literature
synthesis, a one-pair smoke protocol, and a compute recommendation.

## True Ultra Plan execution map

This section makes the preparation plan runnable while preserving its
plan-first boundary. **Only F0–F2 are presently eligible; F3–F5 are locked.**
The planning receipt is
`docs/dev-log/2026-07-26-arc6-association-f0-f2-preparation-receipt.md`.

### What the brain and repository already establish

- The private, general five-adapter router landed at `1834734a`; the B×NB2
  engine and its deterministic fixture are byte-identical at the present
  preparation tip. This is reuse of a private diagnostic, not a new estimator.
- The first target is deliberately only literal Bernoulli × ordinary-NB2 with
  `association = ~ 1`; direct `biv_lognormal()` `rho12` is a separate exact
  likelihood, and all other adapters remain private.
- The prior stopped `24 × 200 × 399` campaign is provenance only. It must not
  be aggregated, resumed, or repurposed as F3/F4 evidence.

### Prior-work sweep receipt

| Surface | Evidence actually inspected | Finding | Call |
| --- | --- | --- | --- |
| Repository and drift | `git status --short --branch`; `git log --oneline -20`; `git worktree list`; `git stash list`; `branch_drift_check.sh` | Detached `ae8d6f5b`, 2 commits ahead / 0 behind `origin/main`; only the three Arc-6 preparation documents are dirty here. Many foreign worktrees exist. | Documentation-only in this worktree; do not touch foreign lanes. |
| Other-platform ownership | `tools/lane_preflight.sh . --hours 36`; `gh pr list --state open`; recent `origin/main` log | #851 Arc D, #852 `sd()`/intervals, #853 Cox--Reid, and #836 are foreign; D-87's earlier duplicate #847 plan is closed. | Association only; leave all four PRs and Arc D/F5 untouched. |
| Existing implementation | `git diff --name-status 1834734a..HEAD -- R/associate-pairs{,-sandwich}.R tests/testthat/test-associate-pairs-staged-sandwich.R`; blob checks | No change to the private B×NB2 source or fixture since #846. | Reuse and pin the existing diagnostic. |
| Twin/sister packages | The prior general-engine plan's targeted `rg` across DRM.jl, GLLVM.jl, and gllvmTMB | No reusable frozen-margin Gaussian-copula sandwich implementation was found. | No cross-repo port or comparator. |
| Brain | Workspace memory registry search for `staged eta association sandwich Godambe Arc 6`; attempted `basic-memory ... --hybrid` | Registry confirms the private stacked-score contract and fences. CLI retrieval was sandbox-blocked when it tried to chmod `~/.basic-memory`. | Use the recorded plan plus repository as the technical basis; do not claim a fresh semantic-search null result. |
| External literature | Primary-record search for Joe (2005), Ko & Hjort (2019), Shih & Louis (1995), and `copula::fitCopula()` IFM documentation | IFM/two-stage inference needs margin uncertainty in its variance; continuous pseudo-observation IFM is not this discrete-rectangle estimator. | Treat `copula` as a negative comparator; validate against full two-stage refits only after approval. |

**Verdict:** build no new association architecture. Validate the already private
B×NB2 diagnostic one pair at a time, beginning only when the owner authorizes
the frozen-method F3 smoke.

### Slices, dependencies, and routing

| Slice | Member | Proposed model / effort / dispatch | Time | Input → output | Dependency and state |
| --- | --- | --- | --- | --- | --- |
| Recon | Ada | Sol / high / native orchestration | done | Repository, brain, twins → sweep receipt | No dependency; completed. |
| F0 method freeze | Noether | Terra / high / native explicit | ~1 h | designs + source → signed symbolic/derivative freeze | Requires plan review; preparation receipt drafted. |
| F1 private-surface audit | Ada + Rose | Terra / medium / native explicit | ~1 h | source/tests/public methods → call-site and failure-taxonomy receipt | Requires F0; preparation receipt drafted. |
| F2 literature/comparator design | Fisher | Terra / high / native explicit | ~2 h | primary IFM/discrete-copula literature → comparator and finite-sample acceptance design | Parallel with F0/F1; preparation receipt drafted. |
| F0–F2 plan review | Noether + Fisher + Rose | native inherited review | done | receipt + plan → READY / NOT READY and corrections | Completed: documentation repairs landed; F1 deterministic execution is still pending approval. |
| F3 smoke protocol | Ada + Fisher | Terra / high / native explicit | ~1 h to write; execution separately approved | F0–F2 verdicts → one-cell full-refit protocol and status schema | **LOCKED** pending first owner approval. |
| F3 local smoke | Codex | Terra / high / native explicit | costed only after protocol | approved protocol → non-empty provenance receipt | **LOCKED**; no remote compute or claims. |
| F4 campaign design/review | Fisher + Rose | Terra / high / native explicit | ~2 h to preregister | F3 receipt → frozen grid, denominators, MCSE, compute plan | **LOCKED** pending second owner approval. |
| F4 validation campaign | Codex | Terra / high / native explicit | Totoro/DRAC estimate only after smoke | approved preregistration → retained all-attempt evidence | **LOCKED**; never GitHub Actions. |
| F5 public-product decision | Fisher + Noether + Rose | Sol / high / native explicit; Sol justified because this is the load-bearing public-claim gate | ~2 h review | F4 evidence → narrow API/claim decision | **LOCKED** pending third owner approval. |
| Mechanical verify | Rose | Luna / low / tiered CLI enforced, if available at execution | ~30 min | non-empty artifacts, SHA/links/counts → verification receipt | Runs only after an approved milestone. |
| Reconcile | Melissa | Terra / medium / native explicit | ~30 min | plan + receipts → plan-vs-actual record | Runs only at a meaningful F3/F4/F5 close. |

**Luna suitability:** yes for a later mechanical artifact/receipt check only;
the plan requires the tiered CLI `--require-scout` route when that execution
slice is authorized. It is not a substitute for Noether/Fisher judgment.
No Luna job is claimed in this preparation phase. **Ultra effort:** no.

**Fan-out budget:** current checkpoint `arc6-public-inference-plan-20260726`;
three review children (Noether, Fisher, and Rose), no new compute children, no ceiling
child. Proposed execution remains below the six-child / one-Sol limit before a
new owner checkpoint. **Context brake:** no compaction; this is a single,
planning-only task.

### Pre-execution reviews and decision rules

`F0–F2 plan review` is an explicit gate, not a claim that the receipt is
already accepted. Noether checks equation/source/derivative alignment; Fisher
checks that finite-sample uncertainty is not inferred from deterministic
agreement; Rose checks the public-claim and API fences. Any NOT READY verdict
returns the plan to documentation-only repair and does not start F3.

### Team-raised corrections (2026-07-26)

- **Noether — NOT READY for F3:** pin the independent numerical-oracle runtime
  and controls, do not call the deterministic matrix passed before its
  zero/negative/tail/near-boundary fixtures are designed and approved, and
  clarify that intercept-only restricts association rather than silently
  simplifying margins.
- **Fisher — NOT READY for F3:** predeclare nested all-attempt denominators and
  mutually exclusive stage-status precedence; distinguish alpha, delta-eta,
  and interval availability; and choose a named F4 interval experiment rather
  than treating full-refit percentile behavior as a generic comparator.
- **Rose — READY after wording repair:** F0–F2 must end in a non-binding
  recommendation, not an F5 decision; Arc D's F5 is separate from this lane's
  F5 public-product gate.

The receipt now incorporates these documentary repairs. F0/F1 deterministic
execution remains pending a separate approval; therefore this is a runnable
Ultra Plan, **not** F3 authorization.

At F3/F4/F5 closure, report **LANE: START A FRESH TASK** because each stage
changes authorization: F3 begins computation, F4 begins a compute campaign,
and F5 considers public product exposure.

### Explicit decisions still owned by Shinichi

1. **F3:** approve only a one-cell local full-refit provenance smoke after
   Noether, Fisher, and Rose accept F0–F2. It must explicitly authorize the
   locked F1 fixture implementation/execution and require it to pass before the
   smoke. The approval must then name the frozen SHA, DGP, seed policy,
   all-attempt status schema, stop rule, and retained receipt. It does not
   authorize F4 or F5.
2. **F4:** after F3 proves actual two-stage refits, approve a pre-registered
   campaign and choose Totoro or DRAC from a costed runbook. It does not
   authorize any public method or capability claim.
3. **F5:** only after F4, decide whether the evidence warrants a fail-closed
   public API for this exact B×NB2 intercept-only route. Fisher, Noether, and
   Rose must first agree on the narrow claim and non-transfer boundaries.
