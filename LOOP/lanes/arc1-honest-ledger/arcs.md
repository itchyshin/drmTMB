# Arcs: from the approved ultra-plan (v2, G0 2026-09-24)

Slice ids refer to `ultra-plan.md`. Status: todo / doing / done / paused / blocked. `paused` = awaiting
Shinichi's named decision; `blocked` = external dependency. Ordinary repair work remains `doing`.

| # | arc | slices | status | gate? |
|---|-----|--------|--------|-------|
| A0 | Recon and overlap check | S0 (+ #1111 hunk overlap, A2; T10 if overlapping) | todo | T10 only if overlap |
| A1 | Batch 1 (parallel, 5 live) | S1a honesty state + gate; S1b pin/interval cellmap; S2 admission census; S8 issue census; S9 #1304 absorption note | todo | none |
| C1 | Checkpoint: rebalance, confirm S3 estimate | Ada | todo | G2 if S3 > 30 min |
| A2 | Model-identity sweep | S3 (pre-run on 3 cells first, D-139) | todo | G2 if > 30 min |
| A3 | Refusals, rows, fences, receipts | S4 then S7 (same files, sequential); S5; S6 | todo | none (T1-T7 answered) |
| A4 | Verify and review | S10 mechanical verify; S11 Rose adversarial (ceiling) | todo | none |
| A5 | Close | S12 Melissa; S13 after-task, AGENT_LOG; draft PRs PR-A..PR-D | todo | G3 for any GitHub comment/close |

Owner answers (2026-09-24): T1-T4, T6 fence now; T5 ledger row + `summary()` note; T7 fold #1304,
comment only after yes; T8 moot (#1421 merged as `7f7293f2d`).
