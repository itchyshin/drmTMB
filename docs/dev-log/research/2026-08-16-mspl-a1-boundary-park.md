# Park note — MSPL A1 boundary programme (S0–S2)

**Date:** 2026-08-16  
**Reader:** Shinichi / next agent reopening this lane after drmTMB 0.7  
**Disposition:** PARKED — not for 0.7; do not merge to `main` under quiesce  
**Lane tip:** `.worktrees/mspl-s0s1` on `claude/mspl-boundary-s0-s1` @ `d2a7c45e3` (local tip; **ahead of origin by 2** — S1 sign-off `d57e75de1` + S2 A1 penalty). Handover refreshed 2026-08-16 Cursor to match this park (Claude text that still OWED S1/S2 is stale). Push the tip when convenient; still do **not** open a merge-to-main PR.

## Why this park exists

Grok panel consensus (Cursor Ultra, 2026-08-16): park the A1 S0–S2 prototype; no multi-Grok MSPL programme now; drmTMB **0.7 + missing-data first**. S3 stays behind **D-139** compute approval after 0.7.

## What is frozen on the tip (claim fences)

| Slice | State | Claim ceiling |
| --- | --- | --- |
| S0 defect gates | DONE (artifacts on lane) | diagnostic / recovery evidence only |
| S1 derivation (design 256) + Noether/Fisher sign-off | DONE | math alignment only |
| S2 A1 soft-penalty | DONE on tip (`drm_boundary_penalty()` / `penalty=` MAP route) | **experimental MAP**; `confint`/`profile` hard-abort for this penalty class; **not** a public `estimator = "mspl"` overload; **not** all-family |
| S3 campaign | NOT STARTED | needs prereg + **D-139** owner approval; Totoro/DRAC only (D-50) |
| S4 heritability | NOT STARTED | post-S3 |

**Explicit non-claims:** no interval or coverage claim for the S2 penalty; no merge into the frozen 0.7.0 candidate (`302ac2579`); no grouped-binomial MSPL scaling (#984 remains a post-admission documentation fence, not a 0.7 blocker).

## Reopen conditions (all required)

1. drmTMB **0.7 quiesce lifted** (platform matrix complete against `302ac2579`, or owner exception for shipped-file merges).
2. Missing-data lane (#1033 / Claude) is not the active collision subject — or subject split is explicit (D-87/D-88).
3. Fresh **S3 prereg** written; Shinichi approves compute under **D-139** (estimate always; 30 min line for plan approval).
4. Tip pushed and rebased onto then-current `main`; S2 tests re-green before any campaign.

## Do not

- Merge this worktree / branch into `main` during 0.7 quiesce.
- Start S3 or a multi-agent MSPL ultra-plan from this park.
- Touch `R/missing-data.R` or other Claude missing-data files from this lane.
- Treat open issue **#984** (n_eff vs paper `n`) as a reason to reopen S3 — it is documentation for a future Bernoulli-guard lift.

## Pointers

- S2 after-task: `docs/dev-log/after-task/2026-08-16-mspl-s2-boundary-penalty-a1.md`
- S1 sign-off: `docs/dev-log/research/2026-08-16-mspl-s1-signoff-recheck.md`
- Design: `docs/design/256-mspl-boundary-penalty-derivation.md`
- Related open issue (keep; do not duplicate): [#984](https://github.com/itchyshin/drmTMB/issues/984)

## GitHub issue?

**No new issue.** One in-repo park note is enough for claim fences and reopen conditions. Optional later: a short comment on #984 or the MSPL milestone saying “A1 boundary S0–S2 parked post-0.7” — only if Shinichi wants a tracker card without a 0.7 milestone pollution.
