# Reconciliation — drmTMB reverse-parity lane, Claude, 2026-09-01 (Melissa, Phase 4.5)

Read-only diff of planned vs actual. Cosmetic wording/ordering differences omitted.
Sources: `zippy-toasting-lobster.md` (rev 2), `claude/rev-parity-routing-receipt`,
`.unlazy/rev-parity/GATES.md` + `gates/leaf-*.md`, `git branch --list 'claude/rev-parity-*'`,
per-slice after-task notes on each branch.

## Slice disposition — A4, A5, B3, C2–C4, ARC E

| slice | plan said | actual | tag | note |
|---|---|---|---|---|
| A4 | spike ≤45 min, hard stop | HELD | **adaptive** | GATES.md's own cross-lane-collision section measures the reason (216-line diff on `R/julia-bridge.R` vs open PR #1112, D-87/D-88 applies) — evidenced in the ledger itself, not just the receipt. |
| A5 | cross-engine receipt | HELD (depends on A4) | **adaptive** | leaf-a5.md exists, all gates `[ ]` unchecked, no `EVIDENCE: pending` masquerading as met. Consistent HELD, not silently dropped. |
| C2–C4 | spec-gated, stop after C1 pending naming-authority decision | NOT RUN by design | **adaptive** | This was the plan's own design, stated twice (decision map + slice table), and leaf-c1.md G4 confirms C1 touched no R code and ARC C stopped there. |
| **B3** | `documentation_writer`, control-contract docs | NOT RUN | **drift** | No `leaf-b3.md` was ever created (ledger has a1,a2,a3,a4,a5,b1,b2,c1,d2,d3,d4 — no b3), and GATES.md contains zero mentions of B3 anywhere. The only record of its disposition is one line in the coordinator's own self-report ("adaptive — conceptually overlaps PR #1112's own control work. Deferred rather than duplicated."), asserted, not measured the way A4's hold was. A5 and A4 each got a ledger entry even while held; B3 got none. **Route: Ada** (scope) — decide whether B3 needs a leaf/decision record or a formal HELD note in GATES.md before this lane is considered closed. |
| **ARC E** | "ARC E gets one scout ticket, not a build plan" (stated as an in-scope action in the plan's Consequence paragraph, not listed under "Out of scope, with reasons") | No branch, no leaf, no after-task note, no mention in the receipt's routing table at all | **drift** | Unlike C2–C4 (which are explicitly named in the plan's own out-of-scope list with reasons) and unlike A4/B3 (which at least have a HELD line somewhere), ARC E has zero trace anywhere in the executed record — it is not even listed as a row in the receipt's routing table. This is the clean case of a planned deliverable vanishing without a decision. **Route: Ada** (scope) — either dispatch the scout ticket or record an explicit deferral with a reason. |

## Fan-out budget

Plan ceiling: ≤6 children/checkpoint, ≤1 Opus ceiling. Receipt claims: 11 children, 1 ceiling,
across three checkpoints (`/goal` ×2 + "Keep going"), flagged by the receipt itself as an
overage rather than normalised.

Independently reconstructable dispatches from branches + after-task notes: RECON×5 (one batch,
plan itself marks this "spent" outside the checkpoint budget) + D2, D3, D4 (resumed) + A1, A2,
A3 + B1, B2 + C1 + Rose/N4 (the one Opus ceiling) = **10** clearly evidenced non-coordinator
agent dispatches, not 11. A0, D1, board-entry, and the drmjl-findings write-up are explicitly
"*me*" (coordinator session) in the plan's slice table, so they should not count as children.

**Tag: unclear.** I cannot independently land on exactly 11 from the git record — the gap is
one dispatch, and agent-dispatch count is not perfectly 1:1 with visible branches (e.g., a
resumed slice can involve more than one sub-agent turn on the same branch). The ceiling
discipline itself (exactly one Opus child, spent on Rose's N4 verification) **is** independently
confirmed: `N4` in GATES.md names Rose/Opus and no other Opus-tier work appears anywhere in the
ledger or branch set. **Route: Ada** if the exact count matters for future budget audits;
otherwise this is not load-bearing to the lane's substance.

## Gates marked met without evidence

Checked every leaf file for the `- [x]` + `EVIDENCE: pending` signature. **None found.** Every
`[x]` gate across leaf-a1, a2, a3, b1, b2, c1, d2, d3, d4 carries a substantive EVIDENCE line
(commit SHA, measured numbers, or an explicit re-run by the coordinator, several flagged
"REFUTED then FIXED and RE-VERIFIED"). leaf-a4 and leaf-a5 are consistently `[ ]` throughout —
no false claim of completion. GATES.md's own node gates N1, N2, N4, N6 are honestly `[ ]` with
`EVIDENCE: pending`; only N3 and N5 are `[x]`, both with measured evidence (a control run for
N3, a two-direction fence check for N5).

## The two ABANDONs

- **A2-G4** (map-fixed-slot preservation guard): evidenced, not argued. The coordinator
  physically removed the masking branch at `R/drmTMB.R:1214`, reran the suite (10/10 still
  clean-passing), then restored the file byte-identically. A real falsification, correctly
  called ABANDON rather than silently marked met.
- **C1's "cannot determine" rows** (naming spec, `engine="julia"`): leaf-c1.md's evidence says
  this came from reading `coefficient_labels()` and its three callers and finding no label-map
  producer on either side — a source-level negative finding, not a guess dressed up as one.

Both are **legitimate** abandons (falsification-backed), not the weaker "argued" kind the task
asked me to watch for.

## Public claims

Searched plan, receipt, and ledger for capability-ledger/`r_bridge_status`/`julia-capabilities.tsv`
changes, bridge-route promotion language, and any claim that DRM.jl#575 is resolved or that
release is in scope. Every hit is a **fence statement** ("no bridge-route promotion", "D-164
holds the CRAN submission") or a **verified-absence** claim (0 forbidden-path diffs across all
14 branches, N5 evidence). No hit asserts the forbidden claim itself. **No breach found.**

## Safety gates

- DRM.jl fence: GATES.md N5 pins `main@f4778964`(-ish, one entry reads `f47789646f27...` in
  leaf-d3.md — same ref, formatting differs) and reports `FENCE HELD` at arc close, corrected
  once mid-flight (an earlier version of the fence wrongly required a clean DRM.jl working tree;
  the correction is recorded, not silently fixed).
- Forbidden paths (`inst/extdata/julia-capabilities.tsv`, `.github/workflows/`): mechanically
  checked across all 14 branches, 0 changes on every one (N5 evidence).
- D-139 (30-minute compute line): the plan's own "Three corrections I owe you" section discloses
  a breach (three parallel full-suite runs ordered without an estimate) and states the binding
  fix. This is a **disclosed correction**, tagged **adaptive** — it is recorded in the plan
  itself before any further work, which is the intended behaviour of the rule, not a violation
  of it.

## Summary

**Deviations found: 5 — adaptive: 3, drift: 2, unclear: 1.** (Six is a miscount if you total the
rows above at face value because one row, D-139, is a disclosed correction rather than a
plan-vs-actual deviation properly speaking; I have listed it for completeness but it does not
add to the drift count.)

Recount, precisely: **adaptive — 3** (A4 hold, A5 hold, C2–C4 stop-after-C1); **drift — 2** (B3
vanished without a ledger-level decision record; ARC E's scout ticket never dispatched and never
recorded as deferred); **unclear — 1** (fan-out count: receipt says 11, independently
reconstructable count is 10).
