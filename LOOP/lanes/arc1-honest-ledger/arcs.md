# Arcs: from the approved ultra-plan (v2, G0 2026-09-24)

Slice ids refer to `ultra-plan.md`. Status: todo / doing / done / paused / blocked. `paused` = awaiting
Shinichi's named decision; `blocked` = external dependency. Ordinary repair work remains `doing`.

| # | arc | slices | status | gate? |
|---|-----|--------|--------|-------|
| A0 | Recon and overlap check | S0 (+ #1111 hunk overlap, A2; T10 if overlapping) | done (#1111 overlap NONE, roxygen only) | none |
| A1 | Batch 1 | S1a done; S2 done (290 cells, 29 unledgered ADMIT, 39 ungated refusal keys); S8 done (6 likely done, awaiting G3); S9 done (77 files / 63 commits tagged); S1b doing (after S1a: shares write-parity-matrix.R) | doing | none |
| C1 | Checkpoint: rebalance, confirm S3 estimate | Ada | todo | G2 if S3 > 30 min |
| A2 | Model-identity sweep | S3 (pre-run on 3 cells first, D-139) | todo | G2 if > 30 min |
| A3 | Refusals, rows, fences, receipts | S4 then S7 (same files, sequential); S5; S6 | todo | none (T1-T7 answered) |
| A4 | Verify and review | S10 mechanical verify; S11 Rose adversarial (ceiling) | todo | none |
| A5 | Close | S12 Melissa; S13 after-task, AGENT_LOG; draft PRs PR-A..PR-D | todo | G3 for any GitHub comment/close |

Owner answers (2026-09-24): T1-T4, T6 fence now; T5 ledger row + `summary()` note; T7 fold #1304,
comment only after yes; T8 moot (#1421 merged as `7f7293f2d`).

## Changes after dispatch (2026-09-24)
- T11 (Shinichi): 'Profile-likelihood CIs' and 'Parametric bootstrap CIs' read CITED-LIMITED from family interval receipts through the shared cellmap; convention cells excluded (D-234). Implemented in S1b.
- Honest-state rule correction (conductor, after reverify): cited  rows held below covered read CITED-PARTIAL (12 family rows had fallen to UNCITED). For Rose's S11 review.
- C1 re-slicing: every change to R/julia-bridge.R and inst/extdata/julia-gates.tsv (S4 refusals, S7 fence refusals for T1-T4/T6, gate rows for the 39 ungated refusal keys, and the T5 summary() note) goes to ONE builder in sequence (reuse the S1a agent). S5 keeps only ledger TSV rows (julia-capabilities.tsv + dashboard copy) and runs in parallel. S6 becomes conditional on uncited > 0 after S1b.
