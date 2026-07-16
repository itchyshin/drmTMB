# Codex handover: Beta phylogenetic LSS planning lane

## Critical context

Arc 1b-S2R is closed and merged. PR #784 merged into `main` as
`b8aa6d701389aad617a4ad8203bdfa3dc1f01495` at
`2026-07-15T20:39:08Z`; its second parent is the exact reviewed head
`24016bf36242e35c7098a9336fa216d17f4a3ad4`. The reviewed PR head passed
GitHub Actions run
[29434103188](https://github.com/itchyshin/drmTMB/actions/runs/29434103188).
The exact post-merge `main` run is
[29449103048](https://github.com/itchyshin/drmTMB/actions/runs/29449103048)
and passed at `2026-07-15T21:01:59Z`; its generated-ledger validation and full
Ubuntu release package check were green, with the release job completing in
22m41s. The merge ceremony is therefore closed on the exact merged tree.

The next lane is the queued **Beta phylogenetic location-scale-scale pilot**.
It is a new goal and a new work lane, not an extension of the relmat-K REML
arc. Begin with an ultra-plan and stop for Shinichi's explicit approval before
editing implementation, tests, generated capability surfaces, or compute
runners.

Keep the two scale axes distinct throughout the plan:

- `sigma` is the Beta family variability submodel, with
  `phi_i = 1 / sigma_i^2`;
- `sd(spp_id, level = "phylogenetic")` is the SD submodel for the latent
  phylogenetic location effect.

## Accomplishments before transfer

- Merged focused PR #784 only after its exact head was green and mergeable.
- Verified the merge commit, both parents, `origin/main`, and ancestry of the
  reviewed head.
- Preserved the exact Arc 1b-S2R claim ceiling at `point_fit_recovery`: the
  dense restricted-likelihood oracle, wrong-orientation sentinel, extractor
  alignment, and all 2,400 predeclared Totoro attempts passed.
- Recorded the queued Beta target, symbolic model, two-PR split, fail-closed
  boundary, ADEMP design, external-data restrictions, and documentation gates
  in
  `docs/dev-log/2026-07-15-next-beta-phylo-lss-candidate-goal.md`.
- Recorded the sequencing and future hierarchical-`sd()` boundary as D-57 in
  Shinichi's durable decisions. The brain change is locally landed at commit
  `426d073`; the brain is intentionally local-only.

## Working state

- Merged technical base: `origin/main` at
  `b8aa6d701389aad617a4ad8203bdfa3dc1f01495`.
- Handover branch:
  `codex/handover-2026-07-15-beta-phylo-lss`, cut directly from that merge.
- PR #781 and all unrelated branches/worktrees remain outside this lane.
- The shared checkout at `/Users/z3437171/Dropbox/Github Local/drmTMB` remains
  on the unrelated `feature/arc4a-profile-coverage` branch. Do not repurpose or
  clean it for this task.

## Decisions and fixed boundaries

1. Use two focused implementation PRs after plan approval:
   first the constant-SD q1 phylogenetic `mu` prerequisite for univariate
   `beta()`, then the direct phylogenetic-SD regression
   `sd(spp_id, level = "phylogenetic") ~ 1 + x`.
2. Cap both claims at `point_fit_recovery`; intervals and coverage do not
   follow from this lane.
3. R/TMB is authoritative. DRM.jl may be an optional comparator only; evidence
   does not transfer between packages.
4. Do not add random effects inside the `sd()` RHS in this lane. A later,
   separate hierarchical-`sd()` subarc may conservatively consider only a
   genuinely coarser replicated grouping level. Same-level terms remain
   rejected.
5. Do not vendor Xi's data, trees, RDS files, or derived fixtures without
   explicit permission or licensing. Any Xi fit is an optional external smoke,
   never recovery evidence.
6. Run simulation campaigns on Totoro or DRAC, never GitHub Actions. Use the
   one-fit to one-replicate-per-cell to full-campaign launch ladder and retain
   every attempt.

## Landing State

| State | Branch or artifact | Why | Resume command |
| --- | --- | --- | --- |
| LANDED | PR #784 / `main` at `b8aa6d70` | Arc 1b-S2R implementation and evidence merged | `gh pr view 784 --json state,mergedAt,mergeCommit` |
| CARRIED-OVER | `codex/handover-2026-07-15-beta-phylo-lss` | Durable handover and planning entry point; no Beta implementation is authorized yet | `git fetch origin && git switch codex/handover-2026-07-15-beta-phylo-lss` |
| CARRIED-OVER, OUT OF SCOPE | Pre-existing local branches reported by `tools/handoff_gate.sh` | They predate this lane and belong to unrelated work; this task neither edits nor claims them | Inspect individually with `git branch -vv` only if their owning task resumes |

## Files created or modified in this handover

- `docs/dev-log/handover/2026-07-15-beta-phylo-lss-codex-handover.md`
- `AGENTS.md`
- `docs/dev-log/check-log.md`

No package implementation, test, documentation-generation, ledger, Mission
Control, or simulation file is changed by this handover.

## Next Immediate Steps

1. Verify live that `origin/main` is still exactly the PR #784 merge and that
   post-merge run 29449103048 remains the successful exact-head receipt.
2. Read this handover, the queued candidate goal, D-57, the current formula
   grammar and likelihood design documents, and the relevant Beta/phylogenetic
   admission, TMB, extractor, prediction, profile, ledger, and rejection tests.
3. Rebuild the live candidate/open-work comparison and overlap check. Stop
   rather than substitute another arc if the Beta lane is no longer the best
   bounded candidate.
4. Use the `ultra-plan`, `symbolic-alignment`, `simulation-design`, and relevant
   R-package/TMB validation skills to produce a copy-paste-ready GOAL plus a
   dependency-ordered two-PR plan.
5. Present the plan to Shinichi and stop. Do not implement, launch compute,
   commit implementation, push an implementation branch, or open an
   implementation PR until he explicitly approves it.
6. After approval, create the first implementation branch from refreshed
   `main` and execute only PR 1's constant-SD Beta phylogenetic location slice
   before considering PR 2.

## Blockers

- Beta implementation is intentionally blocked on explicit approval of the new
  ultra-plan.
- No external blocker is active. Re-read the merge and CI receipts live before
  planning so later repository movement cannot be mistaken for this snapshot.

## Gotchas

- `sigma` is not literally the conditional Beta response SD. The package uses
  `phi = 1 / sigma^2`; retain a wrong-parameterization sentinel using
  `phi = sigma^2`.
- The direct-SD model scales observed phylogenetic tip effects using a
  unit-scale augmented field. Internal nodes do not receive user covariates.
- Intercept-only direct-SD regression must be likelihood- and
  estimate-equivalent to the scalar constant-SD prerequisite.
- Direct-SD predictors must be constant within the target species. Shared
  predictors across `mu`, `sigma`, and latent `sd()` are a deliberate harder
  identification stress, not a reason to relax gates after inspection.
- One observation per species is an information stress case and cannot by
  itself justify a broad identifiability or recovery claim.
- Do not silently widen to REML, q2/q4, phylogenetic slopes, scale-side random
  effects, `zero_one_beta()`, beta-binomial, missing-data combinations, or
  hierarchical random effects inside `sd()`.

## Mission Control / public-surface boundary

| Surface | Current truth | Next-lane rule |
| --- | --- | --- |
| Arc 1b-S2R relmat-K q2 REML | Merged; exact cells at `point_fit_recovery` | Do not reopen or widen |
| Beta phylogenetic constant-SD `mu` | Queued prerequisite | Plan first; promote only after independent recovery evidence |
| Beta direct phylogenetic `sd()` regression | Queued second PR | Keep exact cell fail-closed and capped at `point_fit_recovery` |
| Hierarchical random effects in `sd()` RHS | Planned later subarc only | No active capability claim |

## How to resume

Use this prompt in the fresh Codex task:

> Rehydrate from
> `docs/dev-log/handover/2026-07-15-beta-phylo-lss-codex-handover.md` plus the
> `AGENTS.md` snapshot. Verify the merged-main and exact post-merge CI receipts,
> then ultra-plan the queued Beta phylogenetic LSS goal. Do not implement until
> Shinichi explicitly approves the plan.
