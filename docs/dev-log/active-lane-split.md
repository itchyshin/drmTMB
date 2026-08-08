# drmTMB Active-Lane Split

Meta: 2026-08-08 morning verify · canonical baseline `origin/main@5affb962bc2531e6f4dd7536f7b9aedf86556461`
(post-merge ubuntu + pkgdown green; prior board meta 2026-08-07 night retained in git history).
Capability census is **not** restated here — read the ledger / Mission Control.

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Multi-lane rule.** A single `AGENTS.md` “Latest” pointer must not orphan siblings.
> Rehydrate from **this board** plus the START HERE handover for your lane.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| **0.7 packaging / CRAN rungs → Codex** | **`tarball-clean` proven on `main`**. DESCRIPTION **0.6.0**. **No upload.** useful-0.7 + CondExp + win-builder ERROR-free **docs merged** (#942/#941/#946). Post-merge `main` CI **green**. Ledger `status_claim` still **`tarball-clean`** until owner authorizes `platform-clean`. Rescope 0.7 = packaging through `submission-ready` before ~19 Aug UI reopen. Draft handover **#947**. | [`handover/2026-08-07-codex-handover.md`](handover/2026-08-07-codex-handover.md) | Owns freeze / pkgdown / D-43 / cran-comments. Does not bump DESCRIPTION or upload without owner. Does not touch #858 / #937 debris. |
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
through `tarball-clean` complete through #939. **#942 / #943 / #941 / #944 / #946
merged 2026-08-07** without advancing beyond `tarball-clean`. Win-builder is
ERROR-free on `f9b9588e…`; **`platform-clean` still needs owner authorize.**
Next Codex work is freeze → pkgdown → D-43 → cran-comments, then hold until
CRAN UI + owner publish. **#937 and #858 stay open — do not orphan.**
