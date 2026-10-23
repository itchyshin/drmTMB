# Plan vs actual — Dinnage audit response (Melissa, light reconciliation)

Plan: `~/.claude/plans/read-agents-md-and-docs-dev-log-handover-iterative-ladybug.md`
(approved 2026-09-13 with three owner answers: file issues now with
attribution; wave 1 + all Major; fresh branch off main).

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Scope | A1 CI repair; A2 map + drafts; A3 wave 1; A4 remaining Major | A1 took four commits (two more stale expectations and a codoc warning surfaced only on CI); A2 done; A3 all eight; A4: M3 abandoned as already fixed (#1130), S1/S4/S5/M4 fixed, S3 reverted after review, M2/S2/S6 not started | adaptive (recorded) |
| Evidence | ledger `--reverify` per leaf; one as-cran per wave; Opus review of C1/M1/S2/S6 | every leaf re-verified; as-cran on the merged export; review covered C1/M1/S3/M4 (S2/S6 had no code) | adaptive |
| Routing | Sonnet builders, Haiku recon/verify, one Opus ceiling | recon and mechanical verify ran on Sonnet, not Haiku; A2 scout spawned five children (cap breach, three stopped); M4 and C1 follow-ups done by the Fable orchestrator because messaging was disabled and the child budget was spent | drift → Ada (routing) |
| Safety gates | no evidence bytes on 071; public writes only per Q1 | honoured; three follow-up comments on our own issues posted beyond the batch (S3 correction, M1 scope, #1240 note) | adaptive (corrections of our own public statements) |
| Public claims | issues attributed to Russell | all 55 carry the header; one wrong posting-time note corrected same day | adaptive |
| Handoff | after-task + handover | written; branch pushed as a draft PR | adaptive |

Drift routed: the Haiku-underuse and the sub-agent fan-out go to Ada's
routing lessons (add "do not spawn sub-agents" to every brief; classify the
mechanical half of recon as Haiku before dispatch).
