# Session Handoff: Arc 6 bivariate-combinations ultra-plan

Meta: 2026-07-23 · from Codex · target Codex · planning-only fresh lane

## 🎯 GOAL — paste verbatim into the fresh lane

```text
PLATFORM: Codex, solo. Work in a fresh clean drmTMB worktree from current
origin/main; do not co-edit another active drmTMB lane.
DELIVERABLE: a reviewed, durable ultra-plan for the first staged slice of Arc 6:
bivariate combinations across response families. The plan must select or
recommend one demand-led first family pair and state its exact joint-likelihood
and cross-response-dependence estimand, validation/comparator design, and claim
ceiling.
HEADLINE: convert the post-0.6 flagship from a vague all-pairs ambition into one
honest, technically feasible first-slice decision packet. Do not assume a
Gaussian copula or reuse biv_gaussian machinery without a mathematical contract.
IN PARALLEL: run the mandatory repo/sister/brain sweep, inventory existing
biv_gaussian interfaces, and map candidate common ecology/evolution family pairs.
DEFER: implementation, API admission, source/TMB changes, smoke or campaign
compute, coverage/promotion claims, Julia work, CRAN work, and an all-pairs
cross-product.
DISCIPLINE: enter Plan mode and use $ultra-plan through Phases 0–2 only; record
the sweep receipt, obtain Rose plus Fisher/Gauss plan review, and stop for
Shinichi's explicit approval before Phase 3. If later approved, compute runs on
Totoro or DRAC, never GitHub Actions, after a valid smoke.
```

## Critical Context

The completed B3 `meta_V()` campaign is not the next implementation target. Its
repaired contract, smoke, formal Totoro campaign, 96 authenticated receipts, and
retained reduction are complete on `codex/meta-v-b3-contract` at `4d367cad`.
The campaign found 3,712 `sigma` `[0, Inf]` intervals among 16,800 attempts, so
Fisher and Rose withheld every inference, coverage, capability, and public
promotion claim. `meta_V()` remains implemented/tested and tier-unregistered.
CRAN remains **PARKED**, not failed.

The next substantive development direction recorded before 0.6 was **Arc 6**:
stage bivariate models across response families. It is deliberately not an
all-pairs implementation request. The only fitted bivariate route remains
Gaussian × Gaussian (`biv_gaussian`); mixed families are correctly rejected.
The new lane must therefore plan a bounded first slice, not silently turn the
existing Gaussian likelihood into a generic mixed-family wrapper.

## What Was Accomplished

- Completed B3’s approvals, source/host provenance, 96-shard campaign, retained
  reduction, Fisher/Rose review, after-task report, and B3 handover. Read
  `docs/dev-log/after-task/2026-07-23-meta-v-b3-campaign.md` for evidence.
- Confirmed the old mixed-family boundary is still explicit: only all-Gaussian
  composed families fit; Gaussian–Poisson, Gaussian–beta, and reversed mixed
  spellings reject rather than misroute.
- Retrieved the project direction from the local brain (CLI fallback after the
  sandbox blocked `~/.basic-memory` permissions): Arc 6 is the biggest
  post-0.6, demand-staged bivariate programme; non-Gaussian REML is not its
  solution, while any non-Gaussian inference work should consider its distinct
  AGHQ boundary.

## Mission Control

| Repository | Branch / state | What is true | Next leverage | Fence |
| --- | --- | --- | --- | --- |
| drmTMB | `codex/meta-v-b3-contract` pushed, unmerged | B3 has closed the constant-`sigma` Wald channel as promotion evidence | Arc 6 first-pair ultra-plan | no B3 promotion or meta_V redesign by default |
| drmTMB | fresh next lane, not yet created | only Gaussian × Gaussian bivariate likelihood exists | demand-led first mixed-family design decision | no implementation/compute before owner approval |

## Current Working State

- **Working:** B3 records are complete and pushed; raw evidence remains ignored
  locally by design at `inst/sim/results/meta-v-b3-2026-07-23/`.
- **In progress, non-gating:** a failure-collecting uncapped `test_local()`
  rerun writes `/tmp/drmtmb-b3-full-suite-collecting.log`. The prior full run
  stopped on two Phase-18 report-render tests, but both pass in isolation
  (`failed=0`, `error=0`). Treat this as a sequence/environment audit finding,
  not as B3 evidence, until the collecting rerun supplies exact totals.
- **Not started:** Arc 6 planning, implementation, smoke, compute, or any claim.

## Key Decisions & Rationale

- **Arc selection:** Arc 6 is the recorded post-0.6 flagship, not CRAN and not
  a reflexive B3 follow-up. It is large enough to merit a fresh plan but must
  start with a narrow first pair.
- **Mathematical fence:** a future pair requires its own joint likelihood and
  an explicit definition of cross-response dependence. It may be an observed
  residual association, latent association, shared random effect, copula
  parameter, or no residual-association parameter; these are not interchangeable.
- **Estimator fence:** REML remains Gaussian-only. The new plan must not frame
  non-Gaussian REML as Arc 6 work.
- **Evidence fence:** no `supported`/coverage tier can arise from planning.
  Promotion, a smoke, and any Totoro/DRAC campaign need new approval.

## Files Created / Modified

- `AGENTS.md` — new Latest pointer to this Arc 6 plan-only transfer.
- `docs/dev-log/handover/2026-07-23-codex-arc6-ultraplan-handover.md` — this durable handoff.

The preceding B3 diff is already enumerated in
`docs/dev-log/handover/2026-07-23-codex-handover.md`; do not restage its raw
ignored results. Before any new branch, inspect
`git diff --name-only origin/main...codex/meta-v-b3-contract`.

## Landing State

`/Users/z3437171/shinichi-brain/tools/handoff_gate.sh .` reported one other
unpublished branch. It is declared here rather than mixed into B3.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/meta-v-b3-contract` at `4d367cad` plus this handoff commit | yes | yes after this handoff is pushed | none | LANDED on a fetchable feature branch; merge is a maintainer decision |
| `codex/pkgdown-formal-closeout` at `c018908a` | yes | **no** | none | CARRIED-OVER separate audit-provenance lane; do not absorb it into Arc 6. Resume: `git switch codex/pkgdown-formal-closeout && git push origin codex/pkgdown-formal-closeout` only when its owner is ready. |
| `inst/sim/results/meta-v-b3-2026-07-23/` | ignored by design | local only | none | retained raw B3 evidence; never stage |
| `/tmp/drmtmb-b3-full-suite-collecting.log` | no | no | none | transient regression-audit log; read it if present, then record exact totals in a future documentation-only follow-up |

## Plans / Roadmap

The planning authority for Arc 6 is
`docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md:66-83`. It says:

1. the only bivariate route is Gaussian × Gaussian;
2. Arc 6 is staged by demand, not a full cross-product;
3. every pair needs a real joint likelihood and residual-dependence contract;
4. it is post-0.6 and not a release prerequisite.

The old boundary audit at
`docs/dev-log/after-task/2026-05-18-slice-288-mixed-family-status.md` names
the interface/simulation/extractor/prediction/interval surface that the fresh
plan must inventory before recommending an implementation.

## Next Immediate Steps

1. Create a **fresh Codex task and clean worktree from current `origin/main`**.
   Read `AGENTS.md`, this handover, the Arc 6 plan authority, the B3 after-task
   report, and Slice 288’s boundary audit. Do not start from the dirty main
   checkout or force-push any divergent branch.
2. Switch the new task to **Plan mode** and invoke `$ultra-plan`. Complete
   Phase 0 through Phase 2 read-only, including the required sweep receipt.
3. In the sweep, inspect: current branches/worktrees/stashes and drift; the R
   and DRM.jl sibling surfaces; the brain with `search_all_projects: true`;
   existing family registry, TMB model dispatch, simulation/prediction/
   extractor contracts; and the real user demand/available comparators. Offer
   Shinichi a grounded NotebookLM search before relying on external novelty or
   method claims.
4. Produce a new plan artifact with a copy-paste `GOAL`, candidate first-pair
   matrix, symbolic likelihood/dependence alternatives, staged validation and
   smoke/campaign gates, costs/host choice, capability fences, ownership/model
   routing, and a hard **STOP FOR APPROVAL** before Phase 3.
5. Obtain Rose plus Fisher or Gauss review of the *plan*, then ask Shinichi the
   one consequential question: approve the selected first pair and its
   dependence estimand, or choose a different pair. Do not implement before
   that answer.

## Blockers / Open Questions

The first family pair and dependence estimand are intentionally **not decided**.
The safe default is plan-only. A Gaussian–Poisson pair is a plausible
ecology/evolution candidate but is not selected merely for familiarity; the
new lane must test it against demand, comparator feasibility, and a defensible
joint-likelihood interpretation.

The B3 full-suite collecting rerun is not an Arc 6 blocker, but any reported
failure count must be traced before a broad release or public readiness claim.

## Gotchas / Failed Approaches

- `biv_gaussian` is not a generic copula. Do not extend its residual `rho12`
  code by string substitution.
- Do not use a negative `exists()` probe to prove a formula feature absent; use
  a toy fit or read the actual vignette/dispatch route.
- Do not infer coverage/inference readiness from `supported`; fit status and
  inference tier are distinct.
- `devtools::test()` caps displayed failures. Use uncapped
  `testthat::test_local()` and retain both `failed` and `error` columns.
- The three divergent historical branches in `AGENTS.md` must never be
  force-pushed. `c018908a` is a separate unpushed docs lane.

## How to Resume

Open a fresh Codex task in a clean drmTMB checkout and paste:

> Rehydrate from `docs/dev-log/handover/2026-07-23-codex-arc6-ultraplan-handover.md` plus the `AGENTS.md` Latest block. Enter Plan mode, run the Arc 6 bivariate-combinations `$ultra-plan` through Phase 2 only, and stop for my approval before implementation, smoke, compute, capability promotion, or CRAN work.

For live R commands use:

```sh
NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file
```

Codex owns any later live R/TMB fits, rendering, and Totoro/DRAC work. Rose is
mandatory before any public claim. Thread-creation tools are not available in
this session, so the human must open the fresh Codex task and paste the line
above.
