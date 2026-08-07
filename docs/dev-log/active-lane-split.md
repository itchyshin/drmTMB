# drmTMB Active-Lane Split

Meta: 2026-08-07 · canonical baseline `origin/main@8004fc05862eeb0ee8d0d24277609c3f424a215f`
(prior board meta 2026-08-02 @ `83055ec5846bc2f9b1d939c13aa16c4500181f04` retained in git
history). Capability census is **not** restated here — read the ledger / Mission Control.

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Multi-lane rule.** A single `AGENTS.md` “Latest” pointer must not orphan siblings.
> Rehydrate from **this board** plus the START HERE handover for your lane.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| **0.7 packaging / CRAN rungs** | **`tarball-clean` proven on `main`** via #938→#939. Freeze SHA-256 `c787ee40…`. DESCRIPTION **0.6.0**. **No upload.** | [`handover/2026-08-07-cursor-handover.md`](handover/2026-08-07-cursor-handover.md); FREEZE-NOTES under `release/0.7.0-cran-gate/` | Owns release ledger honesty through claimed rung only. Does not touch #858. |
| **useful-0.7 (Cursor)** | Draft **#942** @ `e6f781388` — first-week uncertainty story, vignette, capability skim, `se_group_sd` advice; vignette CI fix pushed. **CI may still be in flight** (watch `31214014701`). Worktree `~/local-scratch/worktrees/drmTMB-useful-07`. | PR #942; same 2026-08-07 handover | No platform-clean, no `docs/dev-log/release/` edits, no DESCRIPTION bump, no ledger promotions. |
| **platform-clean (Cursor)** | Draft **#941** @ `c5053b6fb`. **NOT READY.** win-builder R-release+R-devel **1 ERROR** on CondExp `drm_src_path`; path repair + resubmit receipt landed; email adjudication owed. Highest proven rung remains **`tarball-clean`**. Worktree `~/local-scratch/worktrees/drmTMB-07-platform`. | PR #941; `platform/PLATFORM-NOT-READY.md` on branch; same 2026-08-07 handover | Do not claim `platform-clean` or upload until win-builder re-greens without ERROR. |
| 135-trace Prong B campaign | **LANDED** on `main` via **#930** (`8df6f240`). Five PASS promotions; nine WITHHOLD stay PFR. | Historical: [`handover/2026-08-05-cursor-handover-post-135.md`](handover/2026-08-05-cursor-handover-post-135.md) | Closed prereg — do not re-run Totoro; WITHHOLD needs a new prereg. |
| C18 — structured zero-one-beta atom effects | **LANDED on lane (PR #898).** | [`handover/2026-08-02-claude-c18-structured-atoms-handover.md`](handover/2026-08-02-claude-c18-structured-atoms-handover.md) | Historical; spatial ZOB deferred/refused. |
| Current-source interval feasibility | **Arc 0 + Arc 1 landed** via PR #896. | [`handover/2026-08-02-claude-handover.md`](handover/2026-08-02-claude-handover.md) | Historical programme docs; do not reopen frozen denominator casually. |
| Mesh/SPDE | **MERGED** (#893). | — | Closed; do not treat as open foreign blocker. |
| Lane B E0 | PR **#858**, `codex/lane-b-e0-readiness`, remains open draft. | PR #858 | **Foreign.** Preserve Lane B evidence; CRAN/useful lanes must not merge into it. |
| Missing-data cross brief | **MERGED** (#869). | — | Closed. |
| Primary checkout AGHQ debris | `claude/handover-freshness-0718` dirty/stale. | — | **PROTECTED** — never clean, stage, or work there. |

## Closed baseline notes

C17 complete through PR #894. 135-trace land complete through #930. Packaging
through `tarball-clean` complete through #939. Next CRAN claim that needs new
evidence is **`platform-clean`** only after win-builder re-green.
