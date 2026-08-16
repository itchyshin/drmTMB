# Plan vs actual — evidence re-wire + tier contract (Melissa)

**Lane:** `claude/lane-irc-legacy-evidence` · 2026-08-15 · **Plan:** the approved ultra-plan
"close the evidence-wiring lane, then decide the tier contract" (W1–W4)

## Verdict

All four planned slices ran and closed. Two substantial slices were **added mid-lane on the owner's
"Keep pushing"** — the 14 assertion sites and the 7 boundary restatements — both of which the plan
had named as open findings but not scheduled. One routing deviation, one process finding.

| Axis | Deviation | Tag |
| --- | --- | --- |
| Scope | W1–W4 as planned; +2 owner-directed slices (the 14 sites; the 7 restatements) | **adaptive** — both were listed as "remaining" in the memo/summary and the owner said to continue |
| Scope | The 16-cell re-wire itself preceded this plan (its first commit) and is reported inside this close | adaptive — continuity of one lane |
| Evidence | The 14-site fix initially shipped vacuous assertions (wrong column names); caught by the planned mutation proof, fixed, swept | **adaptive** — the verification step did its job; recorded prominently |
| Routing | W3 (close-out) ran on the conductor, not `systems_auditor`; W1/W2 likewise conductor as planned | adaptive — context already held; recorded |
| Routing | W4 ran on `inference_reviewer`/opus as planned; its memo **corrected the audit's own published numbers** (112/105 → 105/121) | adaptive — and the correction was adopted |
| Safety gates | Push/merge not exercised mid-lane; B4-CI pins re-frozen only under field-level-diff proof, twice; frozen TSV columns left intact | none |
| Claims | Tier decision made by the **owner** from a memo, not defaulted by the executing session; demotion wording restated to stop prejudging it | none |
| Handoff | After-task PASS, this reconciliation, check-log pending commit; branch to be rebased and PR'd | none |

## Drift

**None charged.** The one near-drift — shipping vacuous assertions — was caught *by the plan's own
verification discipline* (prove the guard can fail) before commit, which is the mechanism working,
not failing. It is recorded in the after-task §6 and §9 rather than buried.

## Process finding for the ledger

Two instances in one day of the same defect shape (wrong-key join → vacuous pass) argue for a
**standing rule**: any new `expect_true(all(...))` on a data-frame column must be paired with a
column-existence assertion or a deliberate-red run. Routed to Rose for the guard decision.
