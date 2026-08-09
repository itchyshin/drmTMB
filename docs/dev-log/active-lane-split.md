# drmTMB Active-Lane Split

Meta: 2026-08-09 staged 0.7 candidate preparation handed to Claude · canonical baseline
`origin/main@ac363cadb605a2eda567de9027b873eebc4788c5` (#954 merged; exact-main
GitHub run `31300437472` green; #953 capability truth and #952 issue sweep remain
the preceding baselines).
Capability census is **not** restated here — read the ledger / Mission Control.

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Multi-lane rule.** A single `AGENTS.md` “Latest” pointer must not orphan siblings.
> Rehydrate from **this board** plus the START HERE handover for your lane.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| **0.7 candidate → Claude release slice (lane 1 of 2)** | **CANDIDATE FROZEN at `tarball-clean`.** `a8f7c47905b0…`, 4,190,882 bytes, built at `cc4f5baee`; `R CMD check --as-cran` **Status: 1 NOTE** (`New submission` only); gate **READY FOR CLAIMED RUNG**. Fourth candidate — three deliberately invalidated under D-49. The 11.11 MB `inst/doc` blocker is RESOLVED (→ 4.605 MB) by moving five vignettes to `vignettes/articles/`. Platform matrix dispatched at `604016a5d`, **results unread**. | [`handover/2026-08-09-claude-handover-d117-discharge.md`](handover/2026-08-09-claude-handover-d117-discharge.md) · [`release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md`](release/0.7.0-cran-gate/FREEZE-NOTES-0.7.0.md) · [`release-audits/2026-08-09-07-decision-packet.md`](release-audits/2026-08-09-07-decision-packet.md) | **Next arc = the D-117 discharge question**, not packaging. Still owner-gated: D-43, `platform-clean` write, final `cran-comments.md`, tag, release, upload, and merging PR #959. **Debt this lane created:** `R CMD check` no longer executes the five relocated vignettes' code (37→32 rebuilt), and pkgdown builds only on `main`, never on a PR. |
| **Complete/quasi-complete separation experiment → Claude task 2 (lane 2 of 2)** | **TRANSFERRED at retained STOP** in `/Users/z3437171/local-scratch/worktrees/drmTMB-separation-s0`, branch `codex/fixed-design-binary-separation-experiment@a28522579` (14 behind / 3 ahead of current main). No package integration or PR. | Local after-task `docs/dev-log/after-task/2026-08-08-separation-s0a2-cone-experiment.md` in that worktree; this Claude task owns only the bounded disposition work. | Preserve existing commits and unpushed state while rehydrating; do not touch lane 1 or the primary checkout. A reviewed finite disposition—MERGE validated package work, DEFER the experiment with no demonstrated defect, or DEFECT repair—is the hard candidate-freeze gate. |
| **0.7 capability truth (Codex)** | **MERGED** via [#953](https://github.com/itchyshin/drmTMB/pull/953) at `08c9f2330`. Fixed-only and multiple-term binomial REML fail early; exactly one ordinary unlabelled intercept or one independent slope is `diagnostic_only`; public `mc-0227` remains ML-Laplace point-fit-recovery and O3 remains internal/non-reportable. | [`after-task/2026-08-08-0.7-capability-truth-reconciliation.md`](after-task/2026-08-08-0.7-capability-truth-reconciliation.md) and [`release-audits/2026-08-08-0.7-capability-truth-reconciliation.md`](release-audits/2026-08-08-0.7-capability-truth-reconciliation.md). | Closed for implementation and truth reconciliation. No DESCRIPTION/platform-clean/D-43/compute/CRAN authority was created. Its #61 decision input now feeds the authorized staged arc above; preserve every unrelated foreign lane. |
| **0.7 scope / packaging → historical decision input** | **Issue sweep COMPLETE on `codex/07-issue-sweep-0808-exec` against `main@efb5af4f`.** Exact 29/29 ledger: #61 is the sole issue-derived procedural candidate blocker; #870 is the sole owner-policy decision; 27 are non-blockers. Five bounded comments posted; zero closures. Its earlier **NO-GO pending authorization** was superseded by Shinichi's staged authorization on 2026-08-09. D-93/D-117 remain independent holds. DESCRIPTION **0.6.0**; current main is neither `tarball-clean` nor `platform-clean`. | [`release-audits/2026-08-08-0.7-issue-sweep.md`](release-audits/2026-08-08-0.7-issue-sweep.md) | Historical input to the authorized two-lane arc. This lane did not implement issues, bump DESCRIPTION, write platform-clean, run D-43/compute, finalize cran-comments, or upload. Preserve #858 / #937 / historical #947. |
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
authorized two-Claude-task arc above: candidate Stage A plus the separate finite
separation disposition. **#937 and #858 stay open and protected — do not orphan.**
