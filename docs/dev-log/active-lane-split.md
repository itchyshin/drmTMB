# drmTMB Active-Lane Split

Meta: 2026-08-08 issue-sweep handover · canonical baseline `origin/main@c996613db1527a9f30cbe27fd29af497390c7985`
(post-#950 R-CMD-check + pkgdown green; prior board meta retained in git history).
Capability census is **not** restated here — read the ledger / Mission Control.

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Multi-lane rule.** A single `AGENTS.md` “Latest” pointer must not orphan siblings.
> Rehydrate from **this board** plus the START HERE handover for your lane.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| **0.7 scope / packaging → Codex** | `main@c996613db`; DESCRIPTION **0.6.0**; post-#950 R-CMD-check + pkgdown green. Exact predecessor `ad475cc39` / `2e5234bd…` remains historically `tarball-clean`, but #950 changed an installed vignette, so current main is not the exact frozen artifact. Next = sweep all 29 open issues and define the finite 0.7 blocker set before any candidate freeze. | [`handover/2026-08-08-codex-handover.md`](handover/2026-08-08-codex-handover.md) | Owns issue-sweep ledger and freeze recommendation only. No implementation, DESCRIPTION bump, platform-clean write, D-43, cran-comments finalization, or upload. Preserve #858 / #937 / historical #947. |
| **win-builder adjudication** | **MERGED** [#946](https://github.com/itchyshin/drmTMB/pull/946) → `5affb962b`. R-release + R-devel **1 NOTE**, CondExp ERROR **cleared** on fixed SHA `f9b9588e…` / 9818425. GHA never started on the PR (docs-only; owner authorized merge anyway). #945 closed (superseded). | after-task `2026-08-07-winbuilder-fixed-adjudication.md`; `platform/winbuilder-emails.md` | Closed for evidence land. Do not write `platform-clean` without owner word. |
| **useful-0.7 (Cursor)** | **MERGED** [#942](https://github.com/itchyshin/drmTMB/pull/942) → `9e85ff91d`. | after-task `2026-08-07-useful-07-user-facing.md` | Closed for this arc. |
| **CondExp path repair** | **MERGED** [#941](https://github.com/itchyshin/drmTMB/pull/941) → `13e8cafb0`. | after-task `2026-08-07-winbuilder-drm-src-path-fix.md` | Closed for the repair; rung claim still owner-gated. |
| 135-trace Prong B campaign | **LANDED** on `main` via **#930** (`8df6f240`). Five PASS promotions; nine WITHHOLD stay PFR. | Historical: [`handover/2026-08-05-cursor-handover-post-135.md`](handover/2026-08-05-cursor-handover-post-135.md) | Closed prereg — do not re-run Totoro; WITHHOLD needs a new prereg. |
| C18 — structured zero-one-beta atom effects | **LANDED on lane (PR #898).** | [`handover/2026-08-02-claude-c18-structured-atoms-handover.md`](handover/2026-08-02-claude-c18-structured-atoms-handover.md) | Historical; spatial ZOB deferred/refused. |
| Current-source interval feasibility | **Arc 0 + Arc 1 landed** via PR #896. | [`handover/2026-08-02-claude-handover.md`](handover/2026-08-02-claude-handover.md) | Historical programme docs; do not reopen frozen denominator casually. |
| Mesh/SPDE | **MERGED** (#893). | — | Closed; do not treat as open foreign blocker. |
| Lane B E0 | PR **#858**, `codex/lane-b-e0-readiness`, remains open draft. | PR #858 | **Foreign.** Preserve Lane B evidence; CRAN lane must not merge into it. |
| GVA decision docs | Open **#937** (`claude/land-gva-decision`). | PR #937 | Optional docs merge; **not** CRAN-blocking; no GVA implementation in 0.7. |
| Missing-data cross brief | **MERGED** (#869). | — | Closed. |
| Primary checkout AGHQ debris | `claude/handover-freshness-0718` dirty/stale. | — | **PROTECTED** — never clean, stage, or work there. |

## Closed baseline notes

C17 complete through PR #894. 135-trace land complete through #930. Packaging
through predecessor `tarball-clean` completed through #949. Reader navigation
then changed installed vignette bytes through #950, so current main must not
inherit that exact-artifact identity. Win-builder predecessor evidence remains
evidence only; **`platform-clean` still needs owner authorization on the eventual
exact 0.7 candidate.** Next Codex work is the issue sweep, then an owner freeze
decision. **#937 and #858 stay open and protected — do not orphan.**
