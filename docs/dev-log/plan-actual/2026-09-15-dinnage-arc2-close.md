# Plan vs actual — Dinnage audit arc-2 close (Melissa, S5 reconcile)

Plan: `~/.claude/plans/read-agents-md-and-docs-dev-log-handover-giggly-catmull.md` (SLICE TABLE,
FAN-OUT BUDGET, ACCEPTANCE LEDGER, PRE-AUTHORISATION ENVELOPE, DEFER). Read against
`.unlazy/dinnage-3/GATES.md` + `gates/leaf-*.md`, the S2 stop report, and AGENT_LOG.md (checked
directly). Headline change: S2's dispatched builder hit a live sibling session already running the
identical recert in the same worktree, stopped cleanly at its precondition (5 tool uses, no writes),
and the sibling session — the prior arc's own Claude session, acting on Shinichi's direct instruction
"merge #1361 when green" — finished the recert, pushed, flipped the PR to ready, and armed
`pr_merge_when_green.sh`. This run touched neither merge nor ready-flag. S4 (Haiku reverify) has not
yet run, so G1/G2/G3/G5 are still EVIDENCE:pending in the ledger; nothing below double-counts those as
closed.

| Axis | Planned | Actual | Tag | Owner |
|---|---|---|---|---|
| Scope | S2 (Sonnet `tmb_engineer`, this arc's lane) runs dry-run→real recert, CI-mirror checks, commit, push, watch CI | S2 stopped at its clean-tree precondition on detecting a live R process from a different session (`CODEX_COMPANION_SESSION_ID` differs) already recertifying the same receipt; recert instead completed by that sibling session (`1410c27f8`, `f2f8ca436`, `c612ee284`), not by any child of this plan | adaptive — correct collision avoidance, no duplicate/corrupted work, surfaced in chat with a drafted reply (D-87); but the deliverable shifted to an out-of-plan agent | Ada |
| Evidence / verification | G6 (drift check) read manually "by Grace"; G11 (AGENT_LOG) checked by literal substring match | G6 was read and graded by the orchestrator (byte-identical graded fields, ledger tests OK), not by Grace/`reproducibility_engineer` as the ACCEPTANCE LEDGER names; G11 reads MET (`## 2026-09-15` and `#1361` both present in AGENT_LOG.md's first 30k chars — confirmed directly), but by coincidence, from a daily-brain-check entry and the prior arc's own entry — this run's own AGENT_LOG line for today's collision is still pending per the builder/orchestrator status, so the literal check is satisfied without this run's write existing yet | drift | Grace (G6 not independently read by the named reviewer); Rose (G11 literal-check can pass on unrelated content — same class as the wave3 row's "paraphrase vs literal EXPECT" lesson) |
| Model routing | 4 children: S2 Sonnet build, S3 Sonnet `documentation_writer`, S4 Haiku verify, S5 Sonnet-low Melissa; Fable orchestrator-only (D-151); S0 already self-flagged in the plan as "should have been Haiku" | Only 2 children actually spawned (S2 stopped early, S5=me); S3 will now be written inline by the orchestrator rather than by a `documentation_writer` child ("fewer moving parts after the collision"); combined with S0, this is the second slice this arc where Fable does routed specialist work inline instead of dispatching | drift | Ada — D-151 tension recurring twice in one arc is a pattern, not a one-off |
| Safety gates | Envelope: never merge/ready; push only to existing draft PR #1361; MUST STOP on anything touching R/, src/, tests/, or a CI failure outside the ledger test | This run's own actions stayed inside the envelope (no merge, no ready-flag, no R/src/tests edits) — confirmed neither action was taken by this session; merge-ready + auto-merge-arm were the sibling session's actions under Shinichi's own separate instruction, not this plan's authority; separately, S3's records will land via a **new** docs-only PR from `main` after the merge — beyond the envelope's "push to #1361" remote authority, reversible, already flagged to Shinichi | adaptive | Ada |
| Public claims | Report's first line hands Shinichi the merge decision ("PR #1361 green, merge is his call") with drafted replies; DEFER explicitly excludes merge/release/Russell message | Not yet written (S3/S6 pending) — but the merge decision this plan intends to "hand" Shinichi has, per the sibling-session facts above, already been made and armed by him before this report exists; risk that the eventual report repeats it as an open ask rather than stating it is already armed elsewhere | unclear — UNVERIFIED until S3/S6 land | Rose |
| Handoff state | S3 rewrites handover §OWED/§Landing in place on the lane branch; checkpoint STATE updated; close only once ledger/records agree | Handover rewrite, check-log entry, after-task addendum, and this row will NOT land on the lane branch — pushing there would race the merge gate — but on a new docs-only branch from `main`, after the merge, per the board notice's new lanes-branch-from-main convention | adaptive — reasoned, matches the current board convention, flagged as scope extension | Ada |

**Recurring class?** Yes, twice over. (1) Fable performing routed-specialist work inline (S0 here, now
S3) is the same D-151 boundary this team keeps re-approving case by case — worth a standing rule rather
than a per-arc note. (2) A literal-string EXPECT gate reading MET on content it didn't cause (G11) is the
same failure class the 2026-09-14 row already routed to Rose ("specify the literal expected string, not
a paraphrase") — this is now a second instance of the more general risk that a mechanical CHECK can be
satisfied by unrelated prior content.

**Routed to.** Ada — the two model-routing misses (S0, S3) and the post-merge-PR scope extension.
Rose — G11's coincidental-pass pattern, and the not-yet-written report's obligation to state the merge
gate as already armed (by Shinichi, to the sibling session), not as an open ask. Grace — G6 needs her
own read of the recertify-c17 `--dry-run` output before "no drift" counts as closed; the orchestrator's
read does not substitute for the leaf's named reviewer.

**Addendum (Ada, after Melissa's row; events that post-dated it).** The recert run 34965581817 then
failed shard 1 on three tests (one fragile S2 fixture, two env-skip-census lines). The plan's envelope
said MUST STOP on any CI failure outside the ledger test and on anything touching `tests/`. Shinichi's
two mid-turn messages ("please fix these" with the red-runs screenshot; "nearly there not quite" with
the shard-1 email) were read as an explicit instruction to fix the red, so the orchestrator made a
tests-only commit (`6d63da083`: fixture re-sized after a seven-configuration probe; census re-derived)
and re-armed the same `pr_merge_when_green.sh` gate the sibling session had run on his standing
"merge #1361 when green". Tags: the tests/ edit = **adaptive** (user-instructed, evidence-first,
assertions unchanged, recorded here and in the commit body); the re-armed merge gate = **unclear**
(the standing instruction was given to the sibling session, not this one) → routed to Shinichi in the
report, which names it plainly. G11 was tightened to a run-specific literal ("Dinnage arc-2 close")
before the vault entry was written, closing Melissa's coincidental-pass finding for this run.
