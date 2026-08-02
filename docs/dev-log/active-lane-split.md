# drmTMB Active-Lane Split

Meta: 2026-08-02 · canonical baseline `origin/main@c8e04258d9d550384b037b1e2a91734c22aaaab5`

This is the current coordination entrypoint. Read the row for the lane you own
before editing. Concurrent lanes are separated by subject, not by tool name.

| Lane | Subject and state | Current authority | Ownership boundary |
| --- | --- | --- | --- |
| C18 — structured zero-one-beta atom effects | **Planning only.** The proposed programme first splits the ten collapsed structured `zoi`/`coi` ledger rows, then conditionally implements evidence-backed q1 provider cells. | PR #895; [`handover/2026-08-02-claude-handover.md`](handover/2026-08-02-claude-handover.md) on `codex/handover-2026-08-02-c18-to-claude` | Do not mutate overlapping package/TMB/ledger files until PR #893 lands or closes, unless Shinichi gives fresh overlap authorization. |
| Mesh/SPDE | PR #893, `codex/drmtmb-spatial-mesh`, is draft and currently has a failing release check. PR #891 is its green docs-only handover companion. | PRs #893 and #891; [`handover/2026-08-01-codex-mesh-spde-handover.md`](handover/2026-08-01-codex-mesh-spde-handover.md) when available on that branch | Owns mesh/SPDE design and implementation, including broad edits to `R/drmTMB.R`, `src/drmTMB.cpp`, formula/likelihood docs, check-log, and C17 compatibility receipts. |
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
