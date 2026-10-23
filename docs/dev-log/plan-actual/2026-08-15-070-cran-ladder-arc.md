# Plan vs actual — the 0.7.0 CRAN ladder arc

**2026-08-15 · Melissa (run in-thread) · lane `claude/07-cran-ladder` · plan:
`~/.claude/plans/soft-snacking-nest.md`**

Six axes, material deviations only. Cosmetic wording and ordering changes are not drift.

## Summary

| axis | verdict |
| --- | --- |
| scope | **adaptive** — one slice reverted on a falsified premise; nothing silently dropped |
| evidence / verification | **adaptive** — one planned verifier reassigned; smoke-first honoured |
| model routing | **drift** — one slice dispatched to an agent that lacked the tools to finish it |
| safety gates | clean — sweep receipt present and evidence-cited; rung never advanced |
| public claims | clean — no rung, no discharge, no submission claimed |
| handoff state | clean — all work committed and pushed; two PRs open |

## Deviations

**1. S2 (D-117 condition 1) was executed, then REVERTED — `adaptive`, but on an orchestrator error.**

Planned: add the 8–16% recovery-bias magnitude user-facing, because the orchestrator's grep found
only the mechanism (`log(g/(g-1))`) and not the number.

Actual: the number was **already on `origin/main`** in four places, phrased `8.3%-15.8%`
(`NEWS.md:186`, `R/profile.R:217`, `man/confint.drmTMB.Rd:271`,
`vignettes/first-week-intervals.Rmd:122`). The orchestrator's search pattern was `8–16 / 8-16`
and missed the actual phrasing. The slice's output was a second, differently-rounded statement of
one measurement in the same help page — precisely the term-drift `AGENTS.md` forbids. All three
files were reverted to `origin/main`.

**Consequence, and it improves the arc:** D-117's condition 1 was never outstanding. **All four
conditions are met**, so the discharge is a pure judgement call with no engineering work attached
— which the D-93 packet then used to reframe §7 as *a bar question, not a transparency question*.
Tagged adaptive rather than drift because the reversal was detected, acted on, and recorded before
anything shipped; but the root cause was a bad premise in the brief, not a bad slice.

**2. Model routing — `drift`. S2 was routed to an agent with the right tier and the wrong tools.**

`documentation_writer` (Sonnet) holds `Read, Edit, Write, Grep, Glob` — **no Bash**. The brief
required `devtools::document()`. The agent could not run it and hand-mirrored the generated `.Rd`
instead, correctly flagging that as unverified.

This is the exact failure the hub names: *dispatch audits the MODEL but never the TOOLS*, so a
slice reads as correctly routed and simply cannot finish. The tier was right; the grant was not.
Harmless here only because the slice was reverted for an unrelated reason. **Owner: Ada
(routing).** Fix: an implementation slice that must run R goes to an agent holding Bash
(`tmb_engineer`, `simulation_tester`) — as S4 was, which is why S4 could run `devtools::document()`
and report zero diff after regeneration.

**3. S7 (judgment verify) reassigned from Fisher to Rose — `adaptive`.**

The plan had Fisher reused for S7 to stay inside the child budget. Fisher wrote S1. Own-the-verifier
forbids the producer judging its own output, so S7 went to Rose (already spawned for S5, so still a
reuse and still inside budget). The plan row was wrong; execution corrected it.

**4. S3 and S8 run in-thread rather than as children — `adaptive`.**

Budget was 6 children. S0, S1, S2, S4, S5 = 5 spawned. S3 (a one-line `DESCRIPTION` edit, once S0
proved a single pin existed) and S8 (this document) were done by the orchestrator. Under budget,
nothing dropped.

**5. Scope addition: PR #1041 — `adaptive`.**

The plan said "small PR" for S4 without committing to opening one. It was opened, because the
commit is a user-facing safety fix that D-117's condition 4 leans on, and leaving it unmerged on a
branch is how it got lost the first time.

## Non-deviations worth recording

- **The sweep receipt was real, and it paid.** The deterministic grep over
  `projects/deep-research/README.md` surfaced `dr20` — Shinichi's own ~90-source harvest built for
  this exact gate. Semantic recall alone would not have produced it, and the D-93 packet's entire
  §4 rests on it. This is the case the receipt gate exists for.
- **Smoke-first honoured.** S4 produced verbatim output showing
  `drmTMB_bootstrap_boundary_warning` firing at point estimate 0.1936 *before* running any suite.
- **The rung never moved.** The gate was re-run after every commit and returned
  `READY FOR CLAIMED RUNG` each time; the ledger JSON has zero diff against `origin/main`.
- **Fenced work stayed fenced.** No re-freeze, no platform matrix, no win-builder, no submission,
  nothing in the missing-data lane, and the stale `.git/index.lock` was reported and not removed.

## Routed to Rose

The one `drift` row (tool-grant mismatch on S2). It is a recurrence of a known class, so it belongs
in the drift ledger rather than being re-learned next arc.
