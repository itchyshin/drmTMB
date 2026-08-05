# Cursor Handover — drmTMB: land the 135-trace promotions, then owner-gated next

**You are Cursor**, picking up the drmTMB interval-evidence lane after the 135-trace
campaign. You inherit **no chat context**. This document plus `AGENTS.md` plus the
current git state are the authoritative record.

**Meta:** 2026-08-05 · from **Cursor** (post-campaign triage + handover) → to **Cursor** ·
worktree `~/local-scratch/worktrees/drmTMB-135trace` · branch `cursor/135-trace-campaign`
@ `8e1af270d` · census on this branch **187 `interval_feasible` / 55 `point_fit_recovery`**
(frozen PFR **54**).

> The morning start doc
> [`2026-08-05-cursor-handover.md`](2026-08-05-cursor-handover.md) told you to **run**
> the campaign. That campaign is **DONE**. Do **not** re-run Totoro or re-promote.

---

## 0. READ THIS FIRST — the working-directory trap

**The primary checkout is still stale and will mislead you.**
`/Users/z3437171/Dropbox/Github Local/drmTMB` sits on `claude/handover-freshness-0718`,
hundreds of commits behind `origin/main`, with a large dirty tree from older sessions
(AGHQ-era debris, ultra-init scaffolding, scratchpads).

- **Do not commit, clean, revert, or stage those files.** They are not this lane's.
- **REPORT to Shinichi (do not `rm`):** stale `.git/index.lock` in the primary checkout
  (harness blocks `.git` deletions).
- **Work in the existing campaign worktree** (already created):

```bash
cd ~/local-scratch/worktrees/drmTMB-135trace
git fetch origin
git status -sb
git log --oneline origin/main..HEAD
```

If that worktree is gone, recreate from the pushed branch (never from the dirty primary):

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git fetch origin
git worktree add ~/local-scratch/worktrees/drmTMB-135trace cursor/135-trace-campaign
cd ~/local-scratch/worktrees/drmTMB-135trace
```

---

## 1. Critical Context

1. **135-trace ran and partially promoted.** Totoro `ok=135 fail=0`. Five cells PASS →
   `interval_feasible`: `mc-0568`, `mc-0576`, `mc-0595`, `mc-0596`, `mc-0653`. Nine WITHHOLD
   stay `point_fit_recovery`. Detail:
   [`after-task/2026-08-05-135-trace-campaign.md`](../after-task/2026-08-05-135-trace-campaign.md).

2. **The aspirational +14 / frozen 59→45 did not happen.** Honest outcome is **+5 / frozen 54**.
   Do not rewrite the prereg after the fact.

3. **Agents are complete for this repo.** `.codex/agents/` and `.claude/agents/` each have
   the full 17 standing specialists (mirrored). No new agents are required to continue.
   Optional gap only: `memory-recall` skill missing (17/18) — ignore for this lane.

4. **Lane preflight will say FOREIGN LANE (codex) because of PR #858.** That is expected.
   Your lane is the **135-trace / interval-evidence** subject. Do not touch #858 files.
   State: `PLATFORM: cursor | LANE: 135-trace-land | FOREIGN LANE: codex+#858`.

---

## 2. What Was Accomplished

| Item | State |
|---|---|
| Morning Cursor start handover (PR #929) | LANDED on `main` |
| Campaign runner + LOOP kit (`6618e4b30`) | Committed on branch; **was** on `origin` |
| Totoro 135-job grid + receipt review | DONE |
| Five PASS ledger promotions + NEWS + frozen guard (`8e1af270d`) | Committed on branch; **was unpushed** at triage — landing is this handoff's job |
| `capability_ledger.py --check` + unittest | OK on the worktree HEAD |
| Primary-checkout ultra-init debris / July AGHQ dirty tree | **NOT this lane** — CARRIED-OVER below |

---

## 3. Current Working State

- **Working:** campaign evidence + promotions on `cursor/135-trace-campaign`.
- **In progress:** push / PR / CI for those commits (see Next Immediate Steps).
- **Not working / blocked:** D-117 *discharge* (owner call); WITHHOLD re-pilot needs a **new**
  prereg (do not reopen this one's receipts); primary checkout debris.

---

## 4. Landing State

`bash ~/shinichi-brain/tools/handoff_gate.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"`
returns **FAIL**. That failure mixes **this lane's unpushed promotion** with **pre-existing
debris** the gate cannot attribute. Declare both:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `cursor/135-trace-campaign` @ `8e1af270d` (promotions) | y | land in this handoff | open draft after push | **OWED → LAND** |
| `cursor/135-trace-campaign` @ `6618e4b30` (runner) | y | y (already on origin) | — | LANDED on branch tip ancestry |
| Morning handover `2026-08-05-cursor-handover.md` via #929 | y | y | #929 merged | LANDED |
| Primary checkout `claude/handover-freshness-0718` dirty tree (~96 uncommitted) | n | n | none | **CARRIED-OVER** — foreign/stale; do not touch. Resume: leave alone; read via `git show origin/main:<path>` |
| Other unpushed historical `claude/*` / `codex/*` branches (gate list) | mixed | n | mixed | **CARRIED-OVER** — other lanes' estate; never clean/force-push/delete |
| Stale `.git/index.lock` (primary) | n/a | n/a | n/a | **REPORT to Shinichi** — do not `rm` |
| PR #858 Lane B E0 | foreign | foreign | #858 open draft | **PROTECTED** foreign codex |
| Mesh/SPDE #893 / missing-data #869 | foreign | foreign | open | **PROTECTED** sibling lanes |

**Resume for CARRIED-OVER primary debris:** none for this lane. Do not adopt it.

---

## 5. Files Created / Modified (this campaign branch)

See the two commits `6618e4b30..8e1af270d` and
[`after-task/2026-08-05-135-trace-campaign.md`](../after-task/2026-08-05-135-trace-campaign.md).
Headline paths:

- `tools/run-135-trace-campaign.R`, `tools/run-135-trace-totoro.sh`,
  `tools/review-135-trace-receipts.R`, `tools/promote-135-trace-passes.py`,
  `tools/capability_ledger.py` (frozen + ARC135 guards)
- `docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign/**`
- `docs/dev-log/after-task/2026-08-05-135-trace-campaign.md`,
  `docs/dev-log/after-task/2026-08-05-135-trace-plan-vs-actual.md`
- ledger / census / surface outputs under `docs/dev-log/dashboard/`
- `NEWS.md`, `LOOP/*`, `docs/dev-log/active-lane-split.md`
- This handover + `AGENTS.md` snapshot refresh

**Never stage from the primary checkout:** its `R/*`, `README.md`, `scratchpad/*`,
`.claude/skills/`, local `docs/dev-log/coordination-board.md` / `phase-snapshot.md`
(ultra-init only — not on `main`), shard logs, or `.worktrees/`.

---

## 6. Environment Cursor needs

| Item | Value |
|---|---|
| **Work in** | `~/local-scratch/worktrees/drmTMB-135trace` |
| R | 4.6.x · `devtools` · `TMB` 1.9.x (match machine; first `load_all()` compiles minutes) |
| Safe verification | `python3 tools/capability_ledger.py --check` · `python3 -m unittest tools.tests.test_capability_ledger` · `python3 tools/profile_truth_gate.py` |
| Optional R check | `Rscript --no-init-file -e 'devtools::load_all(quiet=TRUE); testthat::test_file("tests/testthat/test-profile-targets.R")'` |
| Compute | Totoro only if a **new** prereg is owner-approved — **not** for replaying 135-trace |
| **Never stage** | primary-checkout debris · `#858` / `#893` / `#869` files · `.worktrees/` |

---

## 7. Next Immediate Steps (classify OWED / DONE / RETRACTED / PROTECTED)

Run `bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/drmTMB"`,
diff against git, then execute **only OWED**.

1. **LAND the campaign branch** — if `origin/cursor/135-trace-campaign` is still behind
   `8e1af270d`: `git push -u origin cursor/135-trace-campaign` from the worktree. Open a
   **draft** PR into `main`. Do **not** auto-merge. Wait for CI green on the PR matrix.
2. **Do not re-run** the 135-trace Totoro grid or re-promote WITHHOLD cells under the old prereg.
3. **Surface owner decisions (do not assume):** (a) D-117 discharge; (b) re-score PR #926
   against a corrected falsifier; (c) whether the REML interval finding deserves a design doc;
   (d) whether any WITHHOLD cell gets a **new** prereg (separate goal).
4. **Optional hygiene only after (1) lands:** GitHub `v0.5.0` release title still says
   "first CRAN release" — public retitle needs Shinichi's word (README on `main` already
   targets **0.7.0**).

**DEFER / PROTECTED:** full 7-method coverage grid; `predict()` scale-axis defect; coi reopen;
primary-checkout cleanup; inventing new specialist agents.

---

## 8. Sibling lanes — do not orphan them

Canonical board: [`docs/dev-log/active-lane-split.md`](../active-lane-split.md).

| Lane | Boundary |
|---|---|
| Lane B E0 #858 | FOREIGN codex — preserve |
| Mesh/SPDE #893 | FOREIGN — rebase before any `R/profile.R` conflict |
| Missing-data #869 | FOREIGN docs |
| C18 structured ZOB | LANDED — `mc-0615` withheld; spatial deferred in code |

**Sequential platforms (D-87/D-88):** one active editor per subject. If overlap appears,
surface to Shinichi.

---

## 9. Mission control

| Repo | Branch / main | What shipped | Next by leverage |
|---|---|---|---|
| **drmTMB** | `cursor/135-trace-campaign` @ `8e1af270d` · `origin/main` @ `56449fd64` | 5/14 cells → `interval_feasible` (187/55); truth-gate + frozen guards | **1.** push+PR+CI · **2.** owner D-117 / #926 / REML-doc · **3.** new prereg only if WITHHOLD re-pilot approved |
| Agents | 17/17 Codex↔Claude mirror | ultra-init tiers present on dirty primary only | no agent work owed |

---

## 10. Gotchas & Failed Approaches

- Morning handover's "run the campaign" is **stale** relative to this doc — classify that step
  **DONE**, not OWED.
- `gh pr merge --auto` merges immediately here (no required checks) — never use it as wait-for-green.
- A `cancelled` CI conclusion needs **duration vs ceiling** (75 min), not string matching.
- Do not trust hard-coded-green contract clauses without red-testing
  (`after-task/2026-08-04-prong-b-stack-landing-and-ci-ceiling.md` §9) — the campaign runners
  now compute clamp/LR/unimodality on receipts; keep that discipline for any future prereg.

---

## 11. How to Resume

Start a **fresh Cursor agent** (preferably with cwd =
`~/local-scratch/worktrees/drmTMB-135trace`) and paste:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-05-cursor-handover-post-135.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

Then: lane preflight → classify §7 → land push/PR if still unpushed → stop at G0 for owner
decisions.
