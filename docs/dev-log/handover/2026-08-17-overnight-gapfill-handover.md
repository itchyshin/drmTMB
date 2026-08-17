# Handover — overnight gap-fill (05:40 America/Denver, 2026-08-17)

**Reader:** Shinichi, then the next Cursor / Claude / Codex lane.  
**From:** overnight coordinator on `cursor/overnight-gapfill-board`.  
**CRAN:** still parked. Do not `submit_cran`. Do not email Ligges. Do not touch #1033.

## What landed

| Item | Where | Note |
| --- | --- | --- |
| Overnight board | draft [#1064](https://github.com/itchyshin/drmTMB/pull/1064) | `docs/dev-log/research/2026-08-16-overnight-gapfill-board.md`. Rebased onto `main` after #1062. Docs only. |
| mc-0576 ADEMP freeze | **merged** [#1062](https://github.com/itchyshin/drmTMB/pull/1062) → `main` `186d88038` | Sibling docs-only. Do not launch that campaign. |
| Wave 2 stack refresh | draft [#1060](https://github.com/itchyshin/drmTMB/pull/1060) @ `3e8a9aaec` | Sibling rebased Poisson onto #1059 tip `ae307f4b1`. MERGEABLE. CI not posted at 05:40. **Do not merge.** |

No shipped `R/` or `src/` was merged to `main` by this coordinator.

## What is draft / held

| PR / lane | Head | Status | Do at 05:00 |
| --- | --- | --- | --- |
| [#1059](https://github.com/itchyshin/drmTMB/pull/1059) Wave 1 `mc-0717` | `ae307f4b1` | draft; CI green; **CONFLICTING** vs current `main` (#1062) | Keep. Constant-x abort `3399e7eda` + Totoro 27-fit bank `ae307f4b1` (9/9 recovery, glmmTMB ~1e-5). Rebase onto `main` if wanted; **do not merge**. |
| [#1060](https://github.com/itchyshin/drmTMB/pull/1060) Wave 2 `mc-0718` | `3e8a9aaec` | draft; MERGEABLE; contains 1059 tip | Wait for CI. **Do not merge.** |
| NB2 `mc-0719` | no `origin/` branch | local dirty worktree earlier; **no PR** | Sibling still owns `cursor/ng-correlated-slope-nb2`. Do not collide. |
| Wave 3 lognormal `mc-0720` | worktree only | `/Users/z3437171/local-scratch/lanes/drmTMB-ng-corr-lognormal` is on `3e8a9aaec`. **No implementation commit.** | Start here. See below. |
| [#1063](https://github.com/itchyshin/drmTMB/pull/1063) REML honesty 4a | `b5f9624e0` | open, not draft; **CONFLICTING**; ubuntu FAIL | **Not docs-only.** Touches `R/drmTMB.R` + `man/drmTMB.Rd`. Quiesce: do not merge. |
| [#1061](https://github.com/itchyshin/drmTMB/pull/1061) Julia CRAN filter | `8e7aece55` | draft; CONFLICTING | Owner-only. Do not merge. Do not email Ligges. |
| [#1057](https://github.com/itchyshin/drmTMB/pull/1057) Design 257 | `f08648f1a` | draft; CI green; docs-only | Owner call. |
| [#1033](https://github.com/itchyshin/drmTMB/pull/1033) | — | missing-data | **Off limits.** |
| [#1049](https://github.com/itchyshin/drmTMB/pull/1049) | — | Claude binomial phylo | Foreign. |

## Wave 3 — start this morning

Reserved cell **`mc-0720`**. Stack after Wave 2 tip `3e8a9aaec` (already checked out). If an NB2 PR appears first, rebase onto that tip instead.

Lognormal `model_type == 4` still applies independent `sd * u` and hardcodes `n_mu_re_cors = 0L` in the TMB data list. Poisson Wave 2 already has the design-17 map. Copy that map into the lognormal C++ branch; wedge `validate_positive_continuous_mu_random_terms()` for `{.fn lognormal}` only; allowlist `"lognormal"` in `split_tmb_corpars()`; abort missing-response + inherit the #1059 constant-within-group `x` helper after it is on the stack. Gamma stays rejected. Ceiling = `point_fit_recovery`. Draft PR `cursor/ng-correlated-slope-lognormal`. Do not merge.

Alignment symbols: `sd0`, `sd1`, `rho_re` (never residual `rho12`). Do not reuse `mc-0380`.

## Honesty

The coordinator wrote the board at 18:53 MDT, then the session was paused until 05:39 MDT. Wave 3 code was not implemented in that gap. #1062 merged and #1060/#1063 appeared while the session was dark. This handover is from a live poll at 05:39–05:40 MDT, not from chat memory.

## Next at 05:00 (now)

1. Implement Wave 3 lognormal on the existing worktree; draft PR; do not merge.
2. Leave #1059 / #1060 / #1061 / #1063 unmerged until the owner lifts quiesce.
3. If an NB2 PR appears, rebase lognormal onto it.
4. Gamma (`cursor/ng-correlated-slope-gamma`) only after lognormal local recovery is green.
5. Totoro: skip new smokes unless the owner asks; #1059 already banked 27 fits.
6. CRAN stays parked.
