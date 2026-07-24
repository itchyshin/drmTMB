# Session Handoff: Arc 7 B0 `meta_V` B3 evidence integration

**Meta:** 2026-07-24 · from Codex · to Codex · goal paused at the task budget
boundary, not scientifically blocked.

## Critical context

You are Codex, picking up a deliberately narrow Arc 7 B0 lane. `meta_V()` is
already implemented and comparator-tested for Gaussian known sampling
covariance. The task is to integrate an existing **negative** B3 small-K
heterogeneity-interval result onto current main, not to build an estimator,
repeat a campaign, or promote a capability.

The old branch `codex/meta-v-b3-contract` is 13 commits ahead and 42 behind
`origin/main`; it must never be merged wholesale. Its retained 16,800-attempt
campaign found 3,712 `sigma` Wald intervals of `[0, Inf]` and all-attempt
finite-and-covering rates of 0.4117--0.8900. This withholds interval validity,
coverage, capability-tier, and public performance claims.

## Goals and roadmap

The immediate mission is Arc 7 B0: make the exact Gaussian ML
`bf(yi ~ x + meta_V(V = V), sigma ~ 1)` contract reproducible and its boundary
honest on a current-main branch. The next, separate research decision would be
whether to develop a new heterogeneity-interval procedure (for example,
profile/bootstrap); it is not in B0.

## What was accomplished

- Arc 6 merged through PR #827 at `origin/main=d7359df2`; post-merge R-CMD-check
  and pkgdown are green.
- Created clean isolated worktree `/private/tmp/drmtmb-arc7-metav-b0` on
  `codex/arc7-metav-b0`, tracking `origin/main`.
- Updated the local-only Shinichi Mission Control status with commit `bd0efa8`
  to show Arc 7 B0 and its no-compute/no-promotion guard.
- Wrote `docs/dev-log/2026-07-24-arc7-metav-b0-ultra-plan.md`.
- Applied only B3 core commit `20ca52f4` as a staged patch. Its one conflict in
  `docs/dev-log/check-log.md` was resolved by retaining both Arc 6 and B3
  historical entries; no B3 source change was dropped.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  'devtools::test(filter = "phase18-meta-v|comparators", reporter = "stop")'`
  passed on that staged patch.

## Current working state

- **Working:** clean isolated worktree at `/private/tmp/drmtmb-arc7-metav-b0`.
- **In progress:** the B3 core patch is staged; the plan file, this handover,
  and the `AGENTS.md` snapshot are not yet staged at handover-writing time.
- **Not yet run:** the approved two-cell local sentinel, final Fisher/Rose
  review, after-task report, PR, or merge.
- **Never run in B0:** Totoro/DRAC compute, a broad recovery/coverage campaign,
  capability promotion, or a public interval-validity claim.

## Key decisions and rationale

1. Preserve all-attempt denominators. A point `sigma(fit)` or
   conditional-on-finite interval result cannot substitute for the true
   `confint(..., method = "wald")` result.
2. Keep the K=12 vector/sigma=0.10/sampling-SD=0.12/seed=4 boundary and K=36
   dense control as the two local sentinels.
3. Selectively port code/tests/ADEMP/decision packet; do not take later B3
   remote launchers, full seed maps, shard logs, or Arc 6 handovers by default.
4. A new remote campaign is unjustified unless a separately approved new
   interval estimand/procedure changes the scientific question.

## Landing state

`/Users/z3437171/shinichi-brain/tools/handoff_gate.sh
/private/tmp/drmtmb-arc7-metav-b0` reported 19 uncommitted items and unrelated
unpushed commits on `codex/arc6-6-bernoulli-nb2-plan`. The table below declares
them rather than hiding them.

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `codex/arc7-metav-b0` B3 core patch + plan + this handover | no at gate; commit/push next | no | none | CARRIED-OVER: staged WIP requires sentinel and review |
| local-only Shinichi vault `bd0efa8` Mission Control status | yes | n/a | n/a | LANDED local-only |
| `claude/handover-freshness-0718` dirty AGHQ/REML checkout | foreign | foreign | unknown | CARRIED-OVER by its owner; do not touch |
| `codex/arc6-6-bernoulli-nb2-plan` unpushed commits | foreign | no | none | CARRIED-OVER by its owner; do not touch |

## Files created or modified in this carried-over lane

- `AGENTS.md`
- `docs/design/48-phase-18-meta-v-ademp.md`
- `docs/dev-log/2026-07-22-meta-v-b3-decision-packet.md`
- `docs/dev-log/2026-07-22-meta-v-b3-ultra-plan.md`
- `docs/dev-log/2026-07-24-arc7-metav-b0-ultra-plan.md`
- `docs/dev-log/after-task/2026-07-22-meta-v-ademp-b3-reconciliation.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/handover/2026-07-24-codex-handover.md`
- `inst/sim/dgp/sim_dgp_meta_v.R`
- `inst/sim/fit/sim_summarise_meta_v.R`
- `inst/sim/run/sim_run_meta_v_smoke.R`
- `inst/sim/run/sim_summary_meta_v_smoke.R`
- `inst/sim/run/sim_write_meta_v_grid.R`
- `tests/testthat/test-comparators.R`
- `tests/testthat/test-phase18-meta-v-dgp.R`
- `tests/testthat/test-phase18-meta-v-grid-writer.R`
- `tests/testthat/test-phase18-meta-v-summary-smoke.R`
- `vignettes/drmTMB.Rmd`, `vignettes/implementation-map.Rmd`,
  `vignettes/meta-analysis.Rmd`, `vignettes/source-map.Rmd`

## Next immediate steps

1. Read `AGENTS.md`, this handover, and the Arc 7 B0 plan.
2. Inspect `git diff --cached` before changing anything; retain the explicit
   exclusions above.
3. Run the two-cell sentinel from the staged core: K=12 vector seed 4 must
   preserve `degenerate_zero_infinite`; K=36 dense control must have a finite
   `sigma` interval. Inspect the manifest and raw interval statuses.
4. Decide whether only compact B3 evidence tables/after-task text are needed;
   do not import full seeds/shard logs or remote tooling without a new reason.
5. Ask Fisher and Rose to review the resulting claim boundary, then write the
   after-task report, commit, push, and open a scoped PR. Do not auto-merge.

## Gotchas and failed approaches

- The primary `/Users/z3437171/Dropbox/Github Local/drmTMB` checkout is a dirty,
  foreign AGHQ/REML lane. Do not use it or clean it.
- `codex/meta-v-b3-contract` is stale. Its wholesale merge carries unrelated
  handovers and very large evidence artifacts.
- Core B3 commit `20ca52f4` conflicts only in `check-log.md`; the correct
  resolution retains both historical blocks.
- Run R with `R_PROFILE_USER=/dev/null Rscript --no-init-file`.
- Do not use `NOT_CRAN=true` to make a claim-bearing full check look clean; it
  is acceptable only for focused development tests recorded as such.

## Mission-control summary

| Repo | Branch / main | CI and what shipped | Plan by leverage |
| --- | --- | --- | --- |
| drmTMB | `codex/arc7-metav-b0` from `d7359df2` | Arc 6 main R-CMD-check/pkgdown green; Arc 7 B3 core patch focused tests pass | two-cell sentinel → claim review → scoped evidence PR |
| Shinichi vault | `master` `bd0efa8` | Mission Control now names Arc 7 B0 | no additional board claim until evidence is reviewed |

## How to resume

In a fresh Codex session, open `/private/tmp/drmtmb-arc7-metav-b0` (or fetch
the pushed `codex/arc7-metav-b0` branch) and paste:

```text
Rehydrate from docs/dev-log/handover/2026-07-24-codex-handover.md and the AGENTS.md snapshot, then continue with the Next Immediate Steps. Read the staged diff before editing; Arc 7 B0 permits only the two-cell local sentinel, not remote compute or a capability claim.
```

Codex owns the next live R/TMB execution: sentinel fits, focused package tests,
and any later rendering. Planning-side work remains limited to the documented
claim and scope review.
