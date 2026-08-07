# drmTMB Active-Lane Split

Meta: 2026-08-07 · canonical baseline `origin/main@13e8cafb0a308b390bb1721f09d4d2db1791c73c`
(prior board meta 2026-08-07 @ `8004fc05862eeb0ee8d0d24277609c3f424a215f` retained in git
history). Capability census is **not** restated here — read the ledger / Mission Control.

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Multi-lane rule.** A single `AGENTS.md` “Latest” pointer must not orphan siblings.
> Rehydrate from **this board** plus the START HERE handover for your lane.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| **0.7 packaging / CRAN rungs** | **`tarball-clean` proven on `main`**. DESCRIPTION **0.6.0**. **No upload.** #942 useful-0.7, #943 handover, and #941 CondExp path repair **merged**; ledger `status_claim` still **`tarball-clean`**. Freeze SHA-256 `c787ee40…`. | [`handover/2026-08-07-cursor-handover.md`](handover/2026-08-07-cursor-handover.md); `platform/PLATFORM-NOT-READY.md`; FREEZE-NOTES under `release/0.7.0-cran-gate/` | Owns release ledger honesty through claimed rung only. Does not touch #858. |
| **useful-0.7 (Cursor)** | **MERGED** [#942](https://github.com/itchyshin/drmTMB/pull/942) → `9e85ff91d`. First-week uncertainty story, vignette, capability skim, `se_group_sd` advice. | after-task `2026-08-07-useful-07-user-facing.md` | Closed for this arc; no platform-clean / DESCRIPTION bump from this lane. |
| **platform-clean (Cursor)** | **MERGED** [#941](https://github.com/itchyshin/drmTMB/pull/941) → `13e8cafb0` as **honest NOT READY docs + path repair**, not as rung advance. win-builder email / FTP-550 adjudication still owed. Highest proven rung remains **`tarball-clean`**. Worktree `~/local-scratch/worktrees/drmTMB-07-platform`. | `platform/PLATFORM-NOT-READY.md`; same handover | Do not claim `platform-clean` or upload until win-builder R-release+R-devel ERROR-free on repaired tarball. |
| 135-trace Prong B campaign | **LANDED** on `main` via **#930** (`8df6f240`). Five PASS promotions; nine WITHHOLD stay PFR. | Historical: [`handover/2026-08-05-cursor-handover-post-135.md`](handover/2026-08-05-cursor-handover-post-135.md) | Closed prereg — do not re-run Totoro; WITHHOLD needs a new prereg. |
| C18 — structured zero-one-beta atom effects | **LANDED on lane (PR #898).** | [`handover/2026-08-02-claude-c18-structured-atoms-handover.md`](handover/2026-08-02-claude-c18-structured-atoms-handover.md) | Historical; spatial ZOB deferred/refused. |
| Current-source interval feasibility | **Arc 0 + Arc 1 landed** via PR #896. | [`handover/2026-08-02-claude-handover.md`](handover/2026-08-02-claude-handover.md) | Historical programme docs; do not reopen frozen denominator casually. |
| Mesh/SPDE | **MERGED** (#893). | — | Closed; do not treat as open foreign blocker. |
| Lane B E0 | PR **#858**, `codex/lane-b-e0-readiness`, remains open draft. | PR #858 | **Foreign.** Preserve Lane B evidence; CRAN/useful lanes must not merge into it. |
| Missing-data cross brief | **MERGED** (#869). | — | Closed. |
| Primary checkout AGHQ debris | `claude/handover-freshness-0718` dirty/stale. | — | **PROTECTED** — never clean, stage, or work there. |

## Closed baseline notes

C17 complete through PR #894. 135-trace land complete through #930. Packaging
through `tarball-clean` complete through #939. **#942 / #943 / #941 merged 2026-08-07**
without advancing beyond `tarball-clean`. Next CRAN claim that needs new evidence is
**`platform-clean`** only after win-builder re-green (ERROR-free).
