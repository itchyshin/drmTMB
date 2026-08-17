# Session Handoff: overnight gap-fill → merge-stack finisher

Meta: 2026-08-17 ~05:50 America/Denver · from Cursor (morning after overnight ~45%) · to the autonomous finisher merging **#1057 → #1059 → #1060 → #1061**

You are the merge-stack finisher. Read `AGENTS.md`, this handover, and
`docs/dev-log/research/2026-08-16-overnight-gapfill-board.md` before acting.
**You inherit no authority from the authoring chat.** Classify every item
`OWED` · `DONE` · `RETRACTED` · `PROTECTED` against live GitHub state.

## Critical Context

Shinichi lifted overnight quiesce **only** for this merge order:
**#1057 (design) → #1059 (Wave 1 binomial) → #1060 (Wave 2 Poisson) → #1061 (Julia CRAN-lane skip).**

Do **not** `submit_cran`. Do **not** email Ligges. Do **not** touch **#1033**.
Do **not** start Wave 3 lognormal. Do **not** merge **#1065** (NB2) in this stack.

`#1060` Totoro smoke is **rho 8/9**, not 9/9. Seed `881402`, `n_each = 4`,
`|err| = 0.444` (`rho_re = 0.894` vs 0.45); glmmTMB matched. Do not rewrite
that as 9/9.

`#1063` already **merged** to `main` (`2d92c3666`). The 05:40 handover that
called it CONFLICTING is stale. Ubuntu CI on that merge is **red** (cheap C14
receipt: `R/drmTMB.R` blob `51fd5146` → `9e0e2660`; fingerprint unchanged).
Leave a follow-up C14 refresh; do not reopen #1063.

## What Was Accomplished

- **#1062 MERGED** — mc-0576 ZO-beta sigma-slope ADEMP freeze. Do not launch.
- **#1063 MERGED** — public NG REML is diagnostic binomial O2 only. Ubuntu C14 red (see above).
- **#1059 Wave 1 draft complete** — Totoro PASS, constant-within-group `x` abort. Head `ae307f4b1`. Now **CONFLICTING** vs `main` (#1062 + #1063).
- **#1060 Wave 2 smoke banked** — `e5657ecbf` on `cursor/ng-correlated-slope-wave2`. 27/27 fits; `sd0`/`sd1` 9/9; **`rho_re` 8/9**. PR comment posted. Draft. Base is #1059, not `main`.
- **#1065 NB2 snapshot** — draft `feat(nbinom2): Wave 2.5 ordinary correlated (1+x|g) cell mc-0719` @ `53f447b9f`. Local focused tests 476–478 PASS; C14 4/4. **Not in this merge stack.** No Totoro smoke.
- **Lognormal / Wave 3** — never started. Worktree sits on the Wave 2 tip. Leave it.
- Overnight board **#1064** exists; this file is the morning refresh.

## Current Working State

- **Working:** docs-only #1057 is MERGEABLE and CI-green. #1060 head includes the honest 8/9 smoke bank.
- **In progress:** this finisher rebase+merge stack. #1059 and #1061 are CONFLICTING vs current `main`.
- **Not working / blocked:** `main` ubuntu ledger job is red after #1063 (stale C14 `R/drmTMB.R` blob). #1033 is PROTECTED. CRAN / Ligges stay parked.

## Key Decisions & Rationale

- Overnight quiesce held `R/` / `src/` merges. Shinichi’s morning GO lifts that **only** for #1057→#1059→#1060→#1061.
- #1060 stays a `point_fit_recovery` draft until it lands in this stack. The 8/9 rho miss is a small-`n_each` finite-sample miss shared with glmmTMB, not an extractor split.
- #1065 is a snapshot so NB2 does not rot. It stacks on #1060. Merge it later, after this stack is green, if Shinichi asks.
- Wave 3 is **RETRACTED** as a this-morning task (the 05:40 handover wrongly said “start lognormal”).

## Landing State

| Artifact / branch | Committed | Pushed | PR | State |
| --- | --- | --- | --- | --- |
| `origin/main` `2d92c3666` | y | y | #1062 + #1063 merged | LANDED |
| `cursor/ng-correlated-slope-design` | y | y | [#1057](https://github.com/itchyshin/drmTMB/pull/1057) draft, MERGEABLE | CARRIED-OVER — first merge |
| `cursor/ng-correlated-slope-impl` `ae307f4b1` | y | y | [#1059](https://github.com/itchyshin/drmTMB/pull/1059) draft, CONFLICTING | CARRIED-OVER — rebase onto `main`, then merge |
| `cursor/ng-correlated-slope-wave2` `e5657ecbf` | y | y | [#1060](https://github.com/itchyshin/drmTMB/pull/1060) draft | CARRIED-OVER — merge after #1059; keep 8/9 wording |
| `cursor/070-winbuilder-julia-skip` | y | y | [#1061](https://github.com/itchyshin/drmTMB/pull/1061) draft, CONFLICTING | CARRIED-OVER — rebase, then merge last |
| `cursor/ng-correlated-slope-nb2` `53f447b9f` | y | y | [#1065](https://github.com/itchyshin/drmTMB/pull/1065) draft | CARRIED-OVER — **do not merge in this stack** |
| `cursor/overnight-gapfill-board` | y | y | [#1064](https://github.com/itchyshin/drmTMB/pull/1064) draft, CONFLICTING | CARRIED-OVER — docs; rebase onto `main` if cheap |
| `cursor/ng-correlated-slope-lognormal` | n | n | none | CARRIED-OVER — Wave 3 never started; do not start |
| Dirty Dropbox `claude/handover-freshness-0718` | n | n | none | CARRIED-OVER — do not commit from that checkout |

**Resume for each CARRIED-OVER merge:**

```sh
# 1. #1057 — docs-only, already MERGEABLE
gh pr ready 1057 && gh pr merge 1057 --merge

# 2. #1059 — rebase onto main (conflicts from #1062/#1063, likely check-log / ledger)
git fetch origin
# worktree: .worktrees/ng-corr-w1 or equivalent
git rebase origin/main
# resolve, focused tests, push --force-with-lease
gh pr ready 1059 && gh pr merge 1059 --merge

# 3. #1060 — after #1059 is on main, retarget to main if GitHub still bases on the Wave 1 branch
gh pr edit 1060 --base main
# rebase if needed; do not rewrite the 8/9 smoke after-task
gh pr ready 1060 && gh pr merge 1060 --merge

# 4. #1061 — rebase onto the new main, then merge
git rebase origin/main
gh pr ready 1061 && gh pr merge 1061 --merge
```

## Next Immediate Steps

1. Rehydrate: `bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"`. Take **only** the merge-stack lane. Stay off #1033, #1049, #1065, lognormal.
2. Merge **#1057** first (docs-only, MERGEABLE, CI green).
3. Rebase **#1059** onto `origin/main`. Expect check-log / ledger / NEWS collisions with #1062/#1063. Keep Wave 1 constant-`x` abort and the 9/9 `mc-0717` smoke. Mark ready and merge.
4. Land **#1060** after #1059. Preserve `e5657ecbf` wording: **rho 8/9**. Retarget base to `main` if the Wave 1 branch disappears.
5. Rebase and merge **#1061**. Tests-only Julia CRAN-lane skip. Still do not email Ligges.
6. After the stack: optional cheap C14 receipt refresh on `main` (`R/drmTMB.R` blob drift from #1063). Do not change `source_fingerprint`.
7. Leave #1064 / #1065 / Wave 3 / CRAN for later.

## Blockers / Open Questions

- `#1059` and `#1061` are CONFLICTING. That is the work, not a stop.
- `main` C14 ubuntu red after #1063. Cheap mode. #1059 also touches ledger files; refresh C14 **after** the stack if the blob moves again.
- Whether to merge #1065 after this stack is Shinichi’s call, not this GO.
- Win-builder / Ligges still parked. #1061 only skips live Julia on the CRAN lane.

## Gotchas & Failed Approaches

- The 05:40 handover is **wrong** on #1063 (now merged), #1060 head (now `e5657ecbf`, not `3e8a9aaec`), NB2 (now #1065), and “start Wave 3”. Trust this file.
- Do not copy smoke artifacts through `/Users/z3437171/local-scratch/lanes/drmTMB-ng-corr-stack` — bank already landed from `.worktrees/ng-corr-w2` @ `e5657ecbf`.
- Do not treat #1060 as 9/9. The miss is in `results.tsv` row seed `881402`.
- Do not merge #1060 to `main` before #1059; it is stacked on `cursor/ng-correlated-slope-impl`.
- Dirty Dropbox checkout `claude/handover-freshness-0718` is a July branch. Do not commit from it.
- #1033 is Codex missing-data. Off limits even if it looks like a cheap conflict.

## How to Resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-17-overnight-gapfill-handover.md.
Run lane preflight. Reconcile this handover with live gh pr view 1057,1059,1060,1061,1065.
Continue only the OWED merge stack #1057 → #1059 → #1060 → #1061.
Do not submit_cran. Do not touch #1033. Do not start Wave 3. Do not merge #1065.
```
