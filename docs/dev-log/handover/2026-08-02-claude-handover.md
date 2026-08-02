# Session Handoff: C18 Structured Zero-One-Beta Atom Effects

Meta: 2026-08-02 · from Codex to a fresh Claude session · planning handoff

You are Claude, starting the next independently scoped drmTMB capability lane.
Read `AGENTS.md`, this handover, and
`docs/dev-log/active-lane-split.md` before acting. You inherit no authority
from the authoring chat; classify every item below as `OWED`, `DONE`,
`RETRACTED`, or `PROTECTED` against current repository and GitHub state.

## Critical Context

C17 is finished. PR #894 merged at
`c8e04258d9d550384b037b1e2a91734c22aaaab5`; detached canonical-main ledger
checks and Mission Control both report `330 implemented / 340 rejected by
design / 17 not implemented = 687`, with no overlay. Do not redo C17.

The highest-yield coherent remainder is the ten-row structured atom block:
`mc-0603:mc-0607` (`zoi`) and `mc-0613:mc-0617` (`coi`). Providers are
`phylo`, `animal`, `relmat`, `spatial`, and `phylo_interaction` for each atom.
Every current row collapses q1/q2/q4/q6/q8/q12, so the first deliverable is a
representation split. Evidence for one exact q1 route must not imply q2+.

PR #893 is an active foreign mesh/SPDE lane. It edits `R/drmTMB.R`,
`src/drmTMB.cpp`, formula and likelihood docs, check-log, and the C17
compatibility receipts. Its release check was red when this handover was
written. C18 may perform read-only Ultra Plan Phases 0–2 now, but must not
claim or mutate overlapping source files until #893 lands/closes or Shinichi
gives fresh overlap authorization.

## Goal / Mission

```text
🎯 GOAL
PLATFORM: Claude. Design and, after explicit plan approval plus the PR #893 overlap gate, implement the representation-first C18 structured zero-one-beta atom programme. HEADLINE: split the ten collapsed structured zoi/coi rows so q1 evidence cannot imply q2+, then admit the maximum independently validated q1 provider cells for phylo, animal, relmat, spatial, and phylo_interaction. IN PARALLEL: read-only source/ledger recon, provider-carrier inventory, oracle and recovery design, and claim-boundary review. DEFER: q2+, profiles, intervals, coverage, inference-ready/support, REML/AGHQ, missingness, simultaneous zoi+coi structured effects unless separately earned, formula-grammar invention, Lane A/B, mesh/SPDE ownership, and foreign branches. DISCIPLINE: canonical main is the count source; write symbolic alignment before code; use Totoro for bounded recovery and DRAC only if the approved grid warrants it; limitations become warnings unless evidence contradicts the exact scope; merge only after unchanged-head CI and fresh authorization.
```

Begin with `$ultra-plan` Phases 0–2. Submit the approval-ready plan to
Shinichi before Phase 3. This Codex handoff task made no C18 source mutation.

## What Was Accomplished

- Closed C17 through PR #894 and verified canonical `main` plus Mission Control.
- Counted the seventeen remaining `not_implemented` model-surface rows directly
  from `docs/dev-log/dashboard/capability-ledger/cells.tsv`.
- Identified the ten structured atom rows as the largest coherent implementation
  programme; the other seven are mostly representative family/dimension
  boundaries.
- Ran the canonical lane preflight. It reported foreign open PRs #893, #891,
  #869, and #858.
- Read PR #893's live changed-file list and CI: it genuinely overlaps C18's
  likely source surface and had a failing `ubuntu-latest (release)` check.
- Confirmed the existing ordinary atom carriers (`u_zoi`, `log_sd_zoi`,
  `u_coi`, `log_sd_coi`) and q1 ordinary recovery tests already exist.
- Confirmed the model-15 structured block currently routes `phylo_mu_dpar == 1`
  to `log_sigma` and all other codes to `eta_mu`; structured `zoi`/`coi`
  routing does not yet exist.
- Created the current active-lane split so mesh, Lane B, missing-data, and C18
  remain visible together.

## Current Working State

- Working: canonical source and runtime are aligned at the PR #894 merge SHA.
- In progress: C18 handover and read-only planning lane.
- Blocked for mutation: PR #893 overlap, unless it lands/closes or Shinichi
  explicitly authorizes concurrent overlap.
- Not attempted: no C18 formula, carrier, TMB, extractor, prediction, test,
  simulation, documentation, or ledger change exists yet.

## Key Decisions and Rationale

1. **Representation first.** The current ten rows each collapse q1 through q12.
   Promoting one after q1 evidence would overclaim q2+. Split the ledger before
   any implementation promotion.
2. **Reuse before redesign.** C17 established independent ordinary `zoi` and
   `coi` latent carriers and full-mixture oracles. Reuse their public,
   extractor, and prediction conventions where mathematically valid, while
   separately designing the structured precision/covariance carrier.
3. **Provider milestones must be independently mergeable.** A likely economical
   order is a representation/carrier foundation, then `phylo`, then
   `animal`/`relmat`, then `spatial` after mesh reconciliation, with
   `phylo_interaction` last. The Ultra Plan may revise this after the sweep.
4. **No automatic ten-cell ceiling.** Splitting aggregate rows can expand the
   registry denominator. Do not promise `340 / 340 / 7` before the generator
   design establishes the honest post-split census.
5. **Positive scoped evidence permits promotion.** Information limitations are
   documented warnings unless recovery/oracle evidence contradicts the exact
   proposed cell.

## Prior-Work Sweep Receipt

| Surface | Evidence | Finding | Consequence |
| --- | --- | --- | --- |
| Canonical repo | `origin/main@c8e04258d`; direct filtered read of `capability-ledger/cells.tsv`; `rg` over model-15 atom/structured carriers | 17 not implemented; ten are collapsed structured atom rows; ordinary `zoi`/`coi` carriers exist; structured atom routing does not | Build only the representation and structured-carrier gap; do not rebuild C17 |
| Live lanes | canonical `lane_preflight.sh`; `gh pr view 891`; `gh pr view 893` | #893 overlaps package/TMB/docs/receipts and release CI is red; #891 is its docs handover | Read-only plan now; source mutation waits on #893 or explicit overlap authority |
| Brain | `search_notes`, `search_all_projects=true`, query `drmTMB after C17 next implementation lane remaining 17 model surface cells structured zoi coi representation-first` | No newer load-bearing queue displaced repository evidence; retrieved history reinforced reuse and honest scope | Repository remains authority; no external search needed for Phase 0–2 |
| Sister/twin | Routed DRM/drmTMB dossier and C17 history; no claimed structured atom twin implementation found in the retrieved record | No banked implementation can be imported as proven | Inspect DRM.jl directly during the Ultra Plan before finalizing |
| Verdict | Combined receipt above | Genuine gap is an honest row split plus structured atom carrier/provider routing | `build-the-gap`, sequentially and provider-scoped |

The receiving Claude session must rerun the complete Ultra Plan Phase 0.25
sweep, including git branches/worktrees/stashes and direct DRM.jl source
inspection, before Phase 1 decomposition.

## Mission-Control Summary

| Repo/lane | Canonical source | CI/runtime | What shipped | Next plan by leverage |
| --- | --- | --- | --- | --- |
| drmTMB | `origin/main@c8e04258d` | PR #894 exact-head CI green; detached ledger checks green; Mission Control `330/340/17`, no overlay | C17 ordinary `zoi` slope plus `coi` intercept/slope cells | C18 representation split, then validated structured atom q1 providers |
| mesh/SPDE | PR #893 draft at `a7967aeab2cc876b7a47f9b7e6ea5e73aed7b779` | `os-matrix` green; release check red at handover time | Fixed-kappa Gaussian mesh/SPDE candidate | Mesh owner repairs/lands or closes; C18 then rebases and reruns compatibility evidence |

## Landing State

The pre-handover gate reported the clean canonical verifier plus a large estate
of unpushed commits on historical/foreign branches. Those branches are not C18
property and remain unchanged.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| C17 PR #894, merge `c8e04258d` | yes | yes | #894 merged | LANDED |
| `codex/lane-c-c17c2-coi-slope@b62b6427` | yes | yes | #894 merged; source retained | LANDED |
| `codex/handover-2026-08-02-c18-to-claude` | yes after handover commit | yes after push | docs-only PR; do not auto-merge | CARRIED-OVER — Claude reads this branch/PR until human merge |
| PR #893 / `codex/drmtmb-spatial-mesh` | foreign | foreign | #893 open draft | CARRIED-OVER — mesh owner; do not edit or merge |
| PR #891 / mesh handover | foreign | foreign | #891 open | CARRIED-OVER — mesh owner; do not edit or merge |
| PR #858 Lane B E0 | foreign | foreign | #858 open | CARRIED-OVER — preserve Lane B |
| PR #869 missing-data cross brief | foreign | foreign | #869 open | CARRIED-OVER — preserve missing-data lane |
| Historical local/remote branch estate flagged by `handoff_gate.sh` | mixed | mixed | mixed | CARRIED-OVER — never clean, force-push, or delete |

## Files Created / Modified

- `AGENTS.md` — prepended the current 2026-08-02 active-lane entrypoint.
- `docs/dev-log/active-lane-split.md` — current multi-lane coordination board.
- `docs/dev-log/handover/2026-08-02-claude-handover.md` — this handover.
- `docs/dev-log/after-task/2026-08-02-c18-claude-handover-lane.md` — lane-creation receipt.

No package, TMB, generated ledger, test, formula, profile, interval, coverage,
Lane A/B, or foreign-branch file is changed by this handover.

## Next Immediate Steps

1. Run lane preflight and reconcile this dated handover against current
   `origin/main`, open PRs, and working trees. Classify every item `OWED`,
   `DONE`, `RETRACTED`, or `PROTECTED`.
2. Enter Plan mode and invoke `$ultra-plan`; state that Phases 0–2 are read-only.
3. Re-read PR #893 and complete the required prior-work sweep: git state/drift,
   C17 source/evidence, structured-provider implementation inventory, and
   DRM.jl twin inspection. Emit the sweep receipt.
4. Write symbolic candidate equations for structured `zoi` and `coi` before
   proposing carrier reuse or new TMB data/parameter blocks.
5. Design the representation split so q1 cells are distinct from q2+ remainder
   and report the resulting conditional census rather than hard-coding a total.
6. Submit one approval-ready Ultra Plan with provider milestones, exact formulas,
   recovery/oracle contracts, Totoro/DRAC routing, plan review, D-43 completion
   panels, landing gates, and Mission Control checks.
7. Do not begin Phase 3 until Shinichi approves the plan and #893 clears or he
   explicitly authorizes overlap.

## Blockers / Open Questions

- **Active blocker:** PR #893 overlaps the likely C18 source surface and is red.
- **Architecture question for the plan:** extend the existing shared structured
  field representation with explicit atom dpar codes, or add atom-specific
  structured carriers? Decide from symbolic alignment, simultaneous-effect
  behaviour, extractor/prediction contracts, and neighbour tests.
- **Scope question only if evidence leaves alternatives:** should the first
  milestone prove one provider for both atoms or one atom across standard
  providers? Ada must recommend a default before asking Shinichi.

No external literature search is needed unless the plan makes a novelty claim.

## Gotchas and Failed Approaches

- Filter ledger counts to `axis == "model_surface"`.
- Never promote an aggregate structured row from q1 evidence.
- Ordinary `u_zoi`/`u_coi` carriers do not prove that a structured
  precision-field representation already exists.
- Do not edit around PR #893 in shared files or compatibility receipts.
- Do not use the dirty main checkout or a C17 verifier as the C18 production
  worktree. Create a fresh clean worktree after the overlap gate clears.
- Do not run recovery campaigns on GitHub Actions. Use Totoro for bounded CPU
  recovery; use DRAC only for an approved larger grid.
- Run R as `R_PROFILE_USER=/dev/null Rscript --no-init-file ...`.
- Do not set `NOT_CRAN=true` for a claim-bearing package check.

## Claude Environment and Routing

Working directory:

```text
/Users/z3437171/Dropbox/Github Local/drmTMB
```

Claude reads `AGENTS.md` through `CLAUDE.md`. Use `.claude/agents/` for bounded
reviewers; Rose is mandatory at plan review and closeout. The in-session
platform owns the work it needs: Claude must run the live R/TMB fits, checks,
rendering, and approved Totoro/DRAC work itself rather than assuming a later
Codex session.

Safe initial verification:

```sh
git status --short --branch
python3 tools/capability_ledger.py --check
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "zero-one-beta", reporter = "summary")'
```

Eventual approved package loop:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::check()'
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::check_pkgdown()'
python3 tools/capability_ledger.py --check
```

Never stage the dirty main checkout, foreign worktrees, PR #893 files, Lane B
artifacts, or unrelated untracked files. Use explicit paths; never `git add -A`.

## How to Resume

Start a fresh authenticated Claude session in the drmTMB repository. Interactive
terminal form:

```sh
claude "Read AGENTS.md and docs/dev-log/handover/2026-08-02-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps."
```

Paste-ready prompt:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
