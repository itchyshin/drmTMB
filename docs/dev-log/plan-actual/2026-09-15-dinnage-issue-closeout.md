# Plan vs actual: Dinnage issue close-out (Melissa, light reconciliation)

Plan: `/Users/z3437171/.claude/plans/proud-pondering-lampson.md`. Read against: after-task
`docs/dev-log/after-task/2026-09-15-dinnage-issue-closeout.md`, the ledger
`.unlazy/dinnage-closeout/gates/leaf-closeout.md`, `docs/dev-log/issue-drafts/2026-09-15-dinnage-closeout/REVIEW.md`
and `CLOSED.tsv`, and orchestrator-measured actuals for this lane.

| Axis | Planned | Actual | Tag |
|---|---|---|---|
| Scope | Close the 16 listed issues with evidence comments; comment on #1301; no code, tests, or NEWS; DEFER list untouched | 16 closed exactly as listed, #1301 comment posted, no code, test, or NEWS file touched, DEFER list untouched | adaptive |
| Evidence / verification | G0 to G4 and G6 checked by script before G5 (after-task validator) and G7 (PR merged); recon evidence feeds drafting without further checks | G0 to G4 and G6 met; G5 met inside gate-check, its standalone script halts on the still-pending G7 by design; G7 pending until merge. Separately, recon's `EVIDENCE.tsv` mis-recorded the NEWS wave for #1309 on a case-sensitive text match, but the drafting step found the correct wave independently, so no wrong claim was posted | adaptive |
| Model routing | 4 new children after G0 (L0 haiku, L1 sonnet, L2 opus, L5 haiku), with L4 and L6 reusing L1's agent; ceiling 1 Opus | 6 children dispatched before L5 (L0, L1 twice after an OAuth death, L2, L4, L6), plus L5 running now: L4 and L6 did not reuse L1's agent because the first L1 agent died and the second was never reused. Ceiling held at 1 Opus | drift -> Ada |
| Safety gates | No code, test, or NEWS edits; no message to Russell; merge-when-green pre-authorised at G0 | Matched: no code, test, or NEWS edits; nothing sent to Russell; merge-when-green pre-authorised by Shinichi at G0 | adaptive |
| Public claims | Every comment cites only sha and NEWS evidence; Rose reviews all 17 before posting | Rose reviewed all 17 and applied 3 corrections (#1309, #1312, #1352) before any post, catching claims that would have overstated the evidence. All 17 posted comments carry only reviewed text | adaptive |
| Handoff state | L6 (this reconcile) depends on L5's mechanical verify completing first | L6 is running while L5's Haiku verifier is still in progress, not yet complete. The ledger's own G0 to G4 and G6 evidence is available independent of L5, so this reconcile is not blind, but the declared L5-before-L6 order was not honoured | drift -> Ada |

## Drift routed

Two linked items go to Ada (scope/routing). (1) Model routing: the plan budgeted 4 new children with
L4 and L6 reusing L1's agent. That reuse never happened, and the after-task's "what did not go
smoothly" section names the OAuth death but not the unreused agent, so the child-count overrun is
undercounted in the record. (2) Handoff state: L6 was dispatched before L5 finished, breaking the
plan's stated dependency. Low risk here, since L6's inputs came straight from the committed ledger, but
the ordering itself was not honoured and was not flagged anywhere in the after-task.

## Recurring class

The OAuth-expiry death itself is a platform incident, not plan drift. But failing to reuse an agent
across non-adjacent slices after an earlier dispatch died is the same shape as the wave-3 lane's
SendMessage-unavailable routing lesson (`docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md`): this
belongs in `memory/PLAN-DRIFT-LEDGER.md` as a named, recurring pattern.
