# drmTMB Active-Lane Split

Meta: 2026-08-19 exact 0.7.0 evidence closeout · candidate source
`6170fbeeea65f22444d7b0934f4e808c40744d22` · artifact SHA-256
`1d6445db583d4e4586d177ce9a6ada78b27373e104a2f6754926b61a188ed9f3`.
Capability census is **not** restated here — read the ledger / Mission Control.

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Multi-lane rule.** A single `AGENTS.md` “Latest” pointer must not orphan siblings.
> Rehydrate from **this board** plus the START HERE handover for your lane.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| **0.7 exact-candidate closeout (Codex)** | Final immutable bytes pass exact-byte local and three-arm win-builder checks; exact-source 3-OS CI and three sanitizer arms also pass. Grace, Rose, and Pat are READY; the executable ledger proves `submission-ready`. | [`release-audits/2026-08-19-070-cran-release-ledger-1d6445db.json`](release-audits/2026-08-19-070-cran-release-ledger-1d6445db.json) and [`release/0.7.0-cran-gate/candidate-6170fbeee/`](release/0.7.0-cran-gate/candidate-6170fbeee/) | PR #1076 merged build-excluded evidence as `7fd86d031`; its real Ubuntu release job passed. No candidate-byte edit, `submit_cran()`, submission, #1033, or `_julia_skip2_artifacts/` action is authorized. `5153ae7e…` and `6b45164b…` are predecessor evidence only. |
| **0.7 capability truth (Codex)** | **MERGED** via [#953](https://github.com/itchyshin/drmTMB/pull/953) at `08c9f2330`. Fixed-only and multiple-term binomial REML fail early; exactly one ordinary unlabelled intercept or one independent slope is `diagnostic_only`; public `mc-0227` remains ML-Laplace point-fit-recovery and O3 remains internal/non-reportable. | [`after-task/2026-08-08-0.7-capability-truth-reconciliation.md`](after-task/2026-08-08-0.7-capability-truth-reconciliation.md) and [`release-audits/2026-08-08-0.7-capability-truth-reconciliation.md`](release-audits/2026-08-08-0.7-capability-truth-reconciliation.md). | Closed for implementation and truth reconciliation. No DESCRIPTION/platform-clean/D-43/compute/CRAN authority was created. Next release action remains the separate #61 owner-authorized exact-candidate decision; preserve every foreign lane below. |
| **0.7 scope / packaging → owner decision** | **Issue sweep COMPLETE on `codex/07-issue-sweep-0808-exec` against `main@efb5af4f`.** Exact 29/29 ledger: #61 is the sole issue-derived procedural candidate blocker; #870 is the sole owner-policy decision; 27 are non-blockers. Five bounded comments posted; zero closures. Candidate-preparation verdict = **NO-GO pending separate owner authorization**. D-93/D-117 remain independent holds. DESCRIPTION **0.6.0**; current main is neither `tarball-clean` nor `platform-clean`. **[Superseded 2026-08-11: `DESCRIPTION` is now `0.7.0` on `main` (PR #996, `a3217da93`) and a frozen candidate has reached `tarball-clean`. `platform-clean` remains unproven — win-builder is absent. The sentence before this bracket describes 2026-08-08 and is kept as the record of that lane, not as current status.]** | [`release-audits/2026-08-08-0.7-issue-sweep.md`](release-audits/2026-08-08-0.7-issue-sweep.md) | Next owner call is whether to authorize a fresh exact-`0.7.0` candidate-preparation arc. This lane did not implement issues, bump DESCRIPTION, write platform-clean, run D-43/compute, finalize cran-comments, or upload. Preserve #858 / #937 / historical #947. |
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
exact 0.7 candidate.** The issue sweep is complete; the next step is Shinichi's
separate candidate-preparation decision. **#937 and #858 stay open and protected — do not orphan.**
