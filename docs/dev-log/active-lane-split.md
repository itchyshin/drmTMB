# drmTMB Active-Lane Split

Meta: 2026-08-02 · canonical baseline `origin/main@83055ec5846bc2f9b1d939c13aa16c4500181f04`
(was `c8e04258d`; PR #896 merged 2026-08-02 and moved the baseline. The
model-surface census is unchanged at `330 / 340 / 17 = 687` — #896 moved five
Gaussian cells' evidence tiers, not their `capability_status`.)

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

> **Filename collision resolved 2026-08-02.** Two lanes independently wrote
> `handover/2026-08-02-claude-handover.md`. That path now belongs to the
> interval-feasibility lane (it landed on `main` via #896); the C18 handover moved
> to `handover/2026-08-02-claude-c18-structured-atoms-handover.md`. Neither
> document was discarded. Name future handovers per lane, not per date alone.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| C18 — structured zero-one-beta atom effects | **LANDED on lane (PR #898).** Split the ten collapsed structured `zoi`/`coi` rows, then promoted seven evidence-backed q1 cells. Lane census 337/350/10 = 697. `mc-0615` withheld at 3/4; spatial `mc-0606`/`mc-0616` deferred **and refused in code**. | Branch `claude/c18-structured-atoms-plan`; PR #895 carries the [`handover/2026-08-02-claude-c18-structured-atoms-handover.md`](handover/2026-08-02-claude-c18-structured-atoms-handover.md) snapshot | Overlap with #893 **authorized** (Shinichi, 2026-08-02). Spatial `mc-0606`/`mc-0616` **deferred**. Makes no interval, coverage, inference-ready, or support claim. |
| Current-source interval feasibility | **Arc 0 + Arc 1 landed** via PR #896. Froze the 82-cell current-source candidate denominator; promoted five direct targets to `interval_feasible` (now 161 `interval_feasible` / 77 `point_fit_recovery`). `mc-0438` is STOP — both tested profiles had nonfinite endpoints. | PR #896; [`handover/2026-08-02-claude-handover.md`](handover/2026-08-02-claude-handover.md) | Owns profile/interval promotion and the frozen manifest. Does not touch structured `zoi`/`coi` representation, the ZOB spec builder, or the model-15 dispatch. |
| **135-trace Prong B campaign (Cursor)** | **DONE (partial promote).** Totoro 135/135; **5 PASS** promoted → census **187 IF / 55 PFR**, frozen PFR **54**. WITHHOLD: mc-0593/0594/0597, five q2 cells, mc-0425. Worktree `~/local-scratch/worktrees/drmTMB-135trace`, branch `cursor/135-trace-campaign` (push/PR pending). | [`after-task/2026-08-05-135-trace-campaign.md`](after-task/2026-08-05-135-trace-campaign.md); artifact dir `simulation-artifacts/2026-08-05-135-trace-campaign/` | Closed for this prereg. WITHHOLD re-pilot needs a new prereg. Does not touch #858 / #893 / #869. |
| Mesh/SPDE | PR #893, `codex/drmtmb-spatial-mesh`, is draft; its release check was pending at last read and its head has moved to `849955f02`. PR #891 is its green docs-only handover companion. | PRs #893 and #891; [`handover/2026-08-01-codex-mesh-spde-handover.md`](handover/2026-08-01-codex-mesh-spde-handover.md) when available on that branch | Owns mesh/SPDE design and implementation, including broad edits to `R/drmTMB.R`, `src/drmTMB.cpp`, formula/likelihood docs, check-log, and C17 compatibility receipts. C18 rebases before editing `R/profile.R`. |
| Lane B E0 | PR #858, `codex/lane-b-e0-readiness`, remains open. | PR #858 | Preserve all Lane B evidence, manifests, classifications, and branches. C18 must not make interval, coverage, inference-ready, or support claims. |
| Missing-data cross brief | PR #869, `claude/missing-data-cross-brief-20260730`, remains open and docs-scoped. | PR #869 | Preserve missing-response and missing-predictor scope; C18 is complete-response only. |

## Closed baseline

C17 is complete through PR #894. Canonical `main` and Mission Control agree on
`330 implemented / 340 rejected by design / 17 not implemented = 687`
model-surface rows. The new C18 programme starts from that SHA and must not
reopen `mc-0577`, `mc-0570`, or `mc-0578`.

## C18 headline

Ten of the seventeen remaining `not_implemented` rows are the structured
zero-one-beta atom block: `mc-0603:mc-0607` for `zoi` and
`mc-0613:mc-0617` for `coi`. Each current row collapses q1 through q12. C18
therefore starts with an honest representation split; q1 evidence must never
promote an aggregate row that implies q2+ support.
