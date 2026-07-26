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
DRAC, never GitHub Actions; end the planning phase with an explicit API and
claim decision for Shinichi.
```

**Status:** preparation only · **Date:** 2026-07-26 · **Owner:** Codex

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
not build a new association model or reopen F5.

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
