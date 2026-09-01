# GOAL — Arc P1: close DRM.jl#575, promote only what receipts allow (2026-09-01)

RE-READ THIS FILE AT THE START OF EVERY ARC. Approved plan:
~/.claude/plans/read-agents-md-and-docs-dev-log-handover-memoized-popcorn.md
Gates ledger: scratchpad unlazy-parity-arc/ (GATES.md + GATES-p1 lines). Receipts live in
docs/dev-log/evidence/julia-r-parity/ayumi-target/.

DESTINATION: the q4 bridge route reproduces TMB's optimum on the committed fixture within the
fixture's recorded tolerance (expected.meta.toml — read, never invent), with the #575 mechanism
named in writing, and the ledger row promoted only if its pre-written gate passes.

SLICES (state · next action):
- P0 close-out — DONE (Rose R1–R6 applied c65cc77ce; drmTMB branch pushed; DRM.jl PR #576 draft).
- P1.1 DONE (mode-finder/basin) · P1.2a DONE-PLATEAU (src reverted, @test_broken pinned, branch pushed) · P1.3 DONE (feat/575-objective-at pushed) · P1.4/P1.5 GATE-NOT-REACHED (no fix) · P1.6 DONE (issue+artifact+ledger) · V2 running · M2 DONE. ARC CLOSED as honest BLOCKED-on-basin checkpoint; successor work = basin-selection fix (new slice, own plan).
  MECHANISM: mode-finder | objective-translation | inconclusive).
- P1.2a (mode-finder ⇒ Sonnet: failing test first, multistart/robust-LM on the cell) XOR
  P1.2b (objective-translation ⇒ Opus ceiling child: term-by-term REML alignment table) — fork
  decided by P1.1. INCONCLUSIVE ⇒ STOP and ask Shinichi (checkpoint ✱1).
- P1.3 bridge objective_at() evaluator, test-first (reuse agent).
- P1.4 re-measure matched fixture + phylo-mean cell; promotion IFF ll_delta ≤ recorded tol.
- P1.5 generalisation sweep over the other committed parity cells.
- P1.6 surfaces update (TSV next_action, scoreboard PR #576, artifact cabc9c81, mission control)
  + DRAFT fix PR (closes #575 only if P1.4 gate passed) — checkpoint ✱2 if the gate is ambiguous.
- V2 Rose workflow (2 distinct-lens Sonnet refuters + Opus synthesis) — zero unapplied DEMOTEs.
- M2 Melissa plan-vs-actual.

MUST STOP (irreversible fence): merges anywhere · posting to Ayumi's repo · releases/registration
(D-164, D-183) · runs >30 min (D-139) · foreign-lane files · promotion without a verbatim gate pass.
PRE-AUTHORISED: lane-branch edits/commits/pushes, draft PRs, artifact republish at same URL, our
own #575 updates with receipts, local runs ≤30 min.
LOOP RULE: gate-check --reverify before any done-claim; checkpoint commit + one-line board note per
arc; on compaction or fresh session, rehydrate from THIS file + git, not chat memory.
